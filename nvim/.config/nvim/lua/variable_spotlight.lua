local M = {}

local ns = vim.api.nvim_create_namespace 'VariableSpotlight'

local scope_node_types = {
  javascript = {
    function_declaration = true,
    function_expression = true,
    arrow_function = true,
    method_definition = true,
  },
  typescript = {
    function_declaration = true,
    function_expression = true,
    arrow_function = true,
    method_definition = true,
  },
  python = { function_definition = true },
  rust = {
    function_item = true,
    closure_expression = true,
  },
}

local body_node_types = {
  statement_block = true,
  function_body = true,
  block = true,
  block_expression = true,
}

local buffer_state = {}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = 'VariableSpotlight' })
end

local function get_state(bufnr)
  buffer_state[bufnr] = buffer_state[bufnr] or { active = false }
  return buffer_state[bufnr]
end

local function clear_spotlight(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  get_state(bufnr).active = false
  vim.b[bufnr].variable_spotlight_active = false
end

local function language_for_buffer(bufnr)
  local ft = vim.bo[bufnr].filetype
  local lang = vim.treesitter.language.get_lang(ft) or ft
  if scope_node_types[lang] then return lang end
  return nil
end

local function ensure_parser(bufnr, lang)
  local ok = pcall(vim.treesitter.get_parser, bufnr, lang)
  if ok then return true end

  ok = pcall(vim.treesitter.start, bufnr, lang)
  if not ok then return false end

  ok = pcall(vim.treesitter.get_parser, bufnr, lang)
  return ok
end

local function walk(node, callback)
  callback(node)
  for child in node:iter_children() do
    walk(child, callback)
  end
end

local function range_before(a, b)
  if a[1] ~= b[1] then return a[1] < b[1] end
  return a[2] < b[2]
end

local function range_equal(a, b)
  return a[1] == b[1] and a[2] == b[2]
end

local function add_dim_range(bufnr, start_pos, end_pos)
  if range_equal(start_pos, end_pos) or not range_before(start_pos, end_pos) then return end

  vim.api.nvim_buf_set_extmark(bufnr, ns, start_pos[1], start_pos[2], {
    end_row = end_pos[1],
    end_col = end_pos[2],
    hl_group = 'VariableSpotlightDim',
    priority = 10000,
  })
end

local function function_signature_range(function_node)
  local sr, sc, er, ec = function_node:range()
  local signature_end = { er, ec }

  for child in function_node:iter_children() do
    if body_node_types[child:type()] then
      local br, bc = child:range()
      signature_end = { br, bc }
      break
    end
  end

  return { sr, sc }, signature_end
end

local function root_for_buffer(bufnr, lang)
  local parser = vim.treesitter.get_parser(bufnr, lang)
  local tree = parser:parse()[1]
  return tree and tree:root() or nil
end

local function buffer_end_pos(bufnr)
  local last_row = vim.api.nvim_buf_line_count(bufnr) - 1
  local last_line = vim.api.nvim_buf_get_lines(bufnr, last_row, last_row + 1, false)[1] or ''
  return { last_row, #last_line }
end

local function collect_function_signatures(root, lang)
  local signatures = {}
  local valid_scope_types = scope_node_types[lang]

  walk(root, function(node)
    if valid_scope_types[node:type()] then
      local start_pos, end_pos = function_signature_range(node)
      signatures[#signatures + 1] = { start_pos = start_pos, end_pos = end_pos }
    end
  end)

  table.sort(signatures, function(a, b)
    return range_before(a.start_pos, b.start_pos)
  end)

  return signatures
end

local function apply_signature_spotlight(bufnr)
  clear_spotlight(bufnr)

  local lang = language_for_buffer(bufnr)
  if not lang then
    notify('Variable spotlight is not configured for this filetype', vim.log.levels.WARN)
    return false
  end

  if not ensure_parser(bufnr, lang) then
    notify(('No Tree-sitter parser available for %s'):format(lang), vim.log.levels.WARN)
    return false
  end

  local root = root_for_buffer(bufnr, lang)
  if not root then
    notify('No Tree-sitter root found', vim.log.levels.WARN)
    return false
  end

  local signatures = collect_function_signatures(root, lang)
  local cursor = { 0, 0 }
  local final_pos = buffer_end_pos(bufnr)

  for _, signature in ipairs(signatures) do
    add_dim_range(bufnr, cursor, signature.start_pos)
    if range_before(cursor, signature.end_pos) then
      cursor = signature.end_pos
    end
  end

  add_dim_range(bufnr, cursor, final_pos)
  return true
end

local function toggle_signature_spotlight()
  local bufnr = vim.api.nvim_get_current_buf()
  local state = get_state(bufnr)

  if state.active then
    clear_spotlight(bufnr)
    return
  end

  if apply_signature_spotlight(bufnr) then
    state.active = true
    vim.b[bufnr].variable_spotlight_active = true
  end
end

function M.setup()
  local comment_hl = vim.api.nvim_get_hl(0, { name = 'Comment', link = false })
  vim.api.nvim_set_hl(0, 'VariableSpotlightDim', vim.tbl_extend('force', comment_hl, {
    italic = true,
  }))

  vim.api.nvim_create_user_command('VariableSpotlightScope', function(args)
    if args.fargs[1] ~= 'function' then
      notify("Only 'function' scope supported", vim.log.levels.WARN)
      return
    end

    toggle_signature_spotlight()
  end, {
    nargs = 1,
    complete = function(arglead)
      if vim.startswith('function', arglead) then return { 'function' } end
      return {}
    end,
    desc = 'Toggle function-signature spotlight for the current buffer',
  })

  vim.api.nvim_create_autocmd('BufWipeout', {
    group = vim.api.nvim_create_augroup('VariableSpotlightCleanup', { clear = true }),
    callback = function(args)
      buffer_state[args.buf] = nil
    end,
  })
end

return M
