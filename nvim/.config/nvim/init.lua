-- ========================================================================
-- SECTION 1: FOUNDATION
-- Core Neovim settings, leaders, options, basic keymaps, basic autocmds
-- ========================================================================
do

  vim.g.mapleader      = ' '   -- Set <space> as the leader key
  vim.g.maplocalleader = ' '   -- See `:help mapleader`
                               -- NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
  vim.opt.wrap          = false
  vim.opt.sidescroll    = 1
  vim.opt.sidescrolloff = 20 -- when scroll to the right
  vim.o.cmdwinheight    = 20 -- bottom buffer when q:



  ------------------------------------------------------
  vim.keymap.set("n", "<leader>t", function()
    vim.cmd("split")
    vim.cmd("terminal")
    vim.cmd("startinsert")
  end, { desc = "Open terminal" })

  vim.keymap.set("n", "<leader>pi", function()
    vim.cmd("rightbelow vsplit")
    vim.cmd("terminal")
    local job_id = vim.b.terminal_job_id
    vim.fn.chansend(job_id, "pi\n")
    vim.cmd("startinsert")
  end, { desc = "Open terminal on right and run pi" })
  ------------------------------------------------------

  vim.api.nvim_create_user_command("Reload", function()
    vim.cmd("silent update")
    local ok, err = pcall(dofile, vim.env.MYVIMRC)
    if ok then
      vim.notify("Reloaded init.lua", vim.log.levels.INFO)
    else
      vim.notify("Reload failed: " .. err, vim.log.levels.ERROR)
    end
  end, {})
  ------------------------------------------------------

  local netrw_picker_group = vim.api.nvim_create_augroup("NetrwPicker", { clear = true })
  vim.keymap.set("n", "<leader>e", function()
  -- If already inside netrw, close it with the same command
  if vim.bo.filetype == "netrw" then
    vim.cmd("close")
    return
  end

  vim.g.netrw_browse_split = 0
  vim.g.netrw_fastbrowse = 0

  local prev_win = vim.api.nvim_get_current_win()

  vim.cmd("botright split")
  vim.cmd("Explore")

  local netrw_win = vim.api.nvim_get_current_win()

  local function fix_netrw_height()
    if vim.api.nvim_win_is_valid(netrw_win) then
      vim.api.nvim_win_set_height(netrw_win, 20)
    end
  end

  local function set_netrw_keymaps(buf)
    vim.keymap.set("n", "<CR>", function()
      local file = vim.fn.expand("<cfile>")
      if file == "" then
        return
      end

      local dir = vim.b.netrw_curdir or vim.fn.getcwd()
      local fullpath = vim.fn.fnamemodify(dir .. "/" .. file, ":p")

      if vim.fn.isdirectory(fullpath) == 1 then
        vim.cmd("Explore " .. vim.fn.fnameescape(fullpath))
        vim.schedule(fix_netrw_height)
        return
      end

      if vim.api.nvim_win_is_valid(netrw_win) then
        vim.api.nvim_win_close(netrw_win, true)
      end

      if vim.api.nvim_win_is_valid(prev_win) then
        vim.api.nvim_set_current_win(prev_win)
        vim.cmd("edit " .. vim.fn.fnameescape(fullpath))
      end
    end, {
      buffer = buf,
      desc = "Pick file and close bottom netrw",
    })
  end

  fix_netrw_height()
  set_netrw_keymaps(vim.api.nvim_get_current_buf())

  vim.api.nvim_create_autocmd("FileType", {
    group = netrw_picker_group,
    pattern = "netrw",
    callback = function(args)
      if vim.api.nvim_get_current_win() == netrw_win then
        set_netrw_keymaps(args.buf)
        vim.schedule(fix_netrw_height)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = netrw_picker_group,
    callback = function()
      if vim.api.nvim_get_current_win() == netrw_win then
        vim.schedule(fix_netrw_height)
      end
    end,
  })
end, { desc = "Toggle file explorer at bottom" })

-- fpaste
   -- Automatically detect files changed outside Neovim.
   -- `autoread` allows clean buffers to reload from disk, while `checktime`
   -- asks Neovim to check for external changes when focus/buffer/cursor events happen.
   -- Guard `getcmdwintype()` because `checktime` is invalid inside the command-line
   -- window opened by q:, q/, or q?.
  vim.opt.autoread = true
   vim.api.nvim_create_autocmd(
    {
      "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" },
    {
      group    = vim.api.nvim_create_augroup("AutoChecktime", { clear = true }),
      pattern  = "*",
      callback = function()
        if vim.fn.getcmdwintype() == "" then
          vim.cmd("checktime")
        end
      end,
    }
  )

  vim.opt.guicursor = {        -- Set cursor shape by mode:
    "n-v-c:block",             -- normal/visual/command                = █
    "i-ci-ve:ver25",           -- insert/command-insert/visual-exclude = ▏
    "r-cr:hor20",              -- replace/command-replace              = ▁
    "o:hor50",                 -- operator-pending                     = _
  }
  vim.o.tabstop     = 2        -- how wide a real tab character appears
  vim.o.shiftwidth  = 2        -- how many spaces indentation uses
  vim.o.softtabstop = 2        -- how many spaces Tab/Backspace feels like while editing
  vim.o.expandtab   = true     -- pressing Tab inserts spaces instead of a real tab character

  vim.loader.enable()          -- Enable faster startup by caching compiled Lua modules



  vim.g.have_nerd_font = false -- Set to true if you have a Nerd Font installed and selected in the terminal

  -- [[ Setting options ]] See `:help vim.o`
  -- NOTE: You can change these options as you wish!
  -- For more options, you can see `:help option-list`

  vim.o.number = true                                 -- Make line numbers default
                                                      -- vim.o.relativenumber = true

  vim.o.mouse = 'a'                                   -- Enable mouse mode, can be useful for resizing splits for example!

   vim.o.showmode = false                           -- Don't show the mode, since it's already in the status line


  vim.schedule(                                       -- Sync clipboard between OS and Neovim.
    function()
      vim.o.clipboard = 'unnamedplus'
    end
  )

  vim.o.breakindent = true                            -- Enable break indent
  vim.o.undofile    = true                            -- Enable undo/redo changes even after closing and reopening a file
  vim.o.ignorecase  = true                            -- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
  vim.o.smartcase   = true
  vim.o.signcolumn  = 'yes'                           -- Keep signcolumn on by default
  vim.o.updatetime  = 250                             -- Decrease update time
  vim.o.timeoutlen  = 300                             -- Decrease mapped sequence wait time

  -- Configure how new splits should be opened
  vim.o.splitright = true                             -- :vnew | :vsplit →
  vim.o.splitbelow = true                             -- :new  | :split  ↓


  vim.o.list        = true                            -- Sets how neovim will display certain whitespace characters in the editor.
  vim.opt.listchars = {                               -- See `:help 'list'`
    tab = '» ',                                       -- and `:help 'listchars'`
    trail = '·',                                      -- and `:help 'listchars'`
    nbsp = '␣'                                        -- Notice listchars is set using `vim.opt` instead of `vim.o`.
  }                                                   -- It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
                                                      -- See `:help lua-options`
                                                      -- and `:help lua-guide-options`

  vim.o.inccommand = 'split'                          -- Preview substitutions live, as you type! :%s/foo/bar/
  vim.o.cursorline = true                             -- Show which line your cursor is on
  vim.o.scrolloff  = 10                               -- Minimal number of screen lines to keep above and below the cursor.

  vim.o.confirm = true                                -- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
                                                      -- instead raise a dialog asking if you wish to save the current file(s)
                                                      -- See `:help 'confirm'`

  -- [[ Basic Keymaps ]] See `:help vim.keymap.set()`

  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>') -- Clear highlights on search when pressing <Esc> in normal mode
                                                      --  See `:help hlsearch`

  -- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
  -- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
  -- is not what someone will guess without a bit more experience.
  --
  -- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
  -- or just use <C-\><C-n> to exit terminal mode
  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
  -- Keybinds to make split navigation easier.
  --  Use CTRL+<hjkl> to switch between windows
  --
  --  See `:help wincmd` for a list of all window commands
  vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
  vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
  vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
  vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

  -- Highlight when yanking (copying) text
  --  Try it with `yap` in normal mode
  --  See `:help vim.hl.on_yank()`
  vim.api.nvim_create_autocmd('TextYankPost', {
    desc     = 'Highlight when yanking (copying) text',
    group    = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function() vim.hl.on_yank() end,
  })

  -- Diagnostic Config & Keymaps
  --  See `:help vim.diagnostic.Opts`
  vim.diagnostic.config {
    update_in_insert = false,
    severity_sort    = true,
    float            = { border = 'rounded', source = 'if_many' },
    underline        = true,

    -- Can switch between these as you prefer
    virtual_text  = true, -- Text shows up at the end of the line
    virtual_lines = false, -- Text shows up underneath the line, with virtual lines

    -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
    jump = {
      on_jump = function(_, bufnr)
        vim.diagnostic.open_float {
          bufnr = bufnr,
          scope = 'cursor',
          focus = false,
        }
      end,
    },
  }

  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
end

-- ============================================================
-- SECTION 2: PLUGIN MANAGER INTRO
-- vim.pack intro, build hooks
-- ============================================================
do
  -- [[ Intro to `vim.pack` ]]
  -- `vim.pack` is a new plugin manager built into Neovim,
  --  which provides a Lua interface for installing and managing plugins.
  --
  --  See `:help vim.pack`, `:help vim.pack-examples` or the
  --  excellent blog post from the creator of vim.pack and mini.nvim:
  --  https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack
  --
  --  To inspect plugin state and pending updates, run
  --    :lua vim.pack.update(nil, { offline = true })
  --
  --  To update plugins, run
  --    :lua vim.pack.update()
  --
  --
  --  Throughout the rest of the config there will be examples
  --  of how to install and configure plugins using `vim.pack`.
  --
  --  In this section we set up some autocommands to run build
  --  steps for certain plugins after they are installed or updated.

  local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd }):wait()
    if result.code ~= 0 then
      local stderr = result.stderr or ''
      local stdout = result.stdout or ''
      local output = stderr ~= '' and stderr or stdout
      if output == '' then output = 'No output from build command.' end
      vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
    end
  end

  -- This autocommand runs after a plugin is installed or updated and
  --  runs the appropriate build command for that plugin if necessary.
  --
  -- See `:help vim.pack-events`
  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      if kind ~= 'install' and kind ~= 'update' then return end

      if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
        run_build(name, { 'make' }, ev.data.path)
        return
      end

      if name == 'LuaSnip' then
        if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then run_build(name, { 'make', 'install_jsregexp' }, ev.data.path) end
        return
      end

      if name == 'nvim-treesitter' then
        if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
        vim.cmd 'TSUpdate'
        return
      end
    end,
  })
end

---Because most plugins are hosted on GitHub, you can use the helper
---function to have less repetition in the following sections.
---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

-- ============================================================
-- SECTION 3: UI / CORE UX PLUGINS
-- guess-indent, gitsigns, which-key, colorscheme, todo-comments, mini modules
-- ============================================================
do
  -- Here is a more advanced configuration example that passes options to `gitsigns.nvim`
  --
  -- See `:help gitsigns` to understand what each configuration key does.
  -- Adds git related signs to the gutter, as well as utilities for managing changes
  vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
  require('gitsigns').setup {
    signs = {
      add =          { text = '+' }, ---@diagnostic disable-line: missing-fields
      change =       { text = '+' }, ---@diagnostic disable-line: missing-fields
      delete =       { text = '-' }, ---@diagnostic disable-line: missing-fields
      topdelete =    { text = '-' }, ---@diagnostic disable-line: missing-fields
      changedelete = { text = '-' }, ---@diagnostic disable-line: missing-fields
    },
  }

  vim.pack.add { { src = gh 'Vonr/align.nvim', branch = "v2", } }

  -- [[ Colorscheme ]]
  -- You can easily change to a different colorscheme.
  -- Change the name of the colorscheme plugin below, and then
  -- change the command under that to load whatever the name of that colorscheme is.
  --
  -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
  vim.pack.add { gh 'Mofiqul/vscode.nvim' }
  ---@diagnostic disable-next-line: missing-fields
  require('vscode').setup {
    styles = {
      comments = { italic = false }, -- Disable italics in comments
    },
  }
  -- Load the colorscheme here.
  -- Like many other themes, this one has different styles, and you could load
  -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
  vim.cmd.colorscheme 'vscode'

  -- [[ mini.ai ]]
  -- Better Around/Inside textobjects
  vim.pack.add { gh 'nvim-mini/mini.ai' }
  local ai = require('mini.ai')
  ai.setup {
    -- Avoid conflicts with built-in incremental selection mappings on Neovim >= 0.12
    mappings = {
      around_next = 'aa',
      inside_next = 'ii',
    },

    n_lines = 500,

    custom_textobjects = {
      -- Function definition via Treesitter
      f = ai.gen_spec.treesitter {
        a = '@function.outer',
        i = '@function.inner',
      },
    },
  }
  local map = function(keys, func, desc, mode)
    mode = mode or 'n'
    vim.keymap.set(mode, keys, func, { desc = desc })
  end
  map(']m', function() ai.move_cursor('right', 'a', 'f', { search_method = 'next' }) end, 'Mini.ai: Next function start')
  map('[m', function() ai.move_cursor('left' , 'a', 'f', { search_method = 'prev' }) end, 'Mini.ai: Previous function start')
  map(']M', function() ai.move_cursor('right', 'a', 'f', { search_method = 'next' }) end, 'Mini.ai: Next function end')
  map('[M', function() ai.move_cursor('left' , 'a', 'f', { search_method = 'prev' }) end, 'Mini.ai: Previous function end')


  -- Dim comments only; keep the rest of the vscode colorscheme unchanged.
  -- Tree-sitter/LSP can use their own comment highlight groups, so override those too.
  local function dim_comments()
    local comment = {
      fg = '#4e574c',
      italic = false,
    }

    for _, group in ipairs {
      'Comment',
      '@comment',
      '@comment.documentation',
      '@comment.error',
      '@comment.warning',
      '@comment.todo',
      '@comment.note',
      '@lsp.type.comment',
    } do
      vim.api.nvim_set_hl(0, group, comment)
    end
  end

  local function soft_diagnostic_underlines()
    -- Soft diagnostic underline colors. `sp` controls underline/undercurl color.
    vim.api.nvim_set_hl(0, 'DiagnosticUnderlineError', { undercurl = true, sp = '#9c3638' })
    vim.api.nvim_set_hl(0, 'DiagnosticUnderlineWarn',  { undercurl = true, sp = '#a69063' })
    vim.api.nvim_set_hl(0, 'DiagnosticUnderlineInfo',  { undercurl = true, sp = '#75beff' })
    vim.api.nvim_set_hl(0, 'DiagnosticUnderlineHint',  { undercurl = true, sp = '#8fbc8f' })


    vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextError', { fg = '#693738', bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextWarn',  { fg = '#a69063', bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextInfo',  { fg = '#75beff', bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextHint',  { fg = '#8fbc8f', bg = 'NONE' })
  end

  local function apply_theme_overrides()
    dim_comments()
    soft_diagnostic_underlines()
  end

  apply_theme_overrides()

  vim.api.nvim_create_autocmd('ColorScheme', {
    pattern = 'vscode',
    callback = apply_theme_overrides,
  })

  vim.api.nvim_set_hl(0, 'Normal',       { bg = '#1D1F23' })     -- main editor background
  vim.api.nvim_set_hl(0, 'NormalNC',     { bg = '#272727' })     -- inactive windows
  vim.api.nvim_set_hl(0, 'NormalFloat',  { bg = '#000000' })     -- floating windows
  vim.api.nvim_set_hl(0, 'FloatBorder',  { bg = '#000000' })     -- float borders
  vim.api.nvim_set_hl(0, 'SignColumn',   { bg = '#1d1f23' })     -- gutter/sign column
  vim.api.nvim_set_hl(0, 'LineNr',       { bg = '#1d1f23', fg = '#363636' })     -- line number column
  vim.api.nvim_set_hl(0, 'CursorLine',   { bg = '#1A1A1A' })     -- current line
  vim.api.nvim_set_hl(0, 'CursorLineNr', { bg = '#000000' })     -- current line number
  vim.api.nvim_set_hl(0, 'StatusLine',   { bg = '#000000' })     -- active statusline
  vim.api.nvim_set_hl(0, 'StatusLineNC', { bg = '#000000' })     -- inactive statusline
  vim.api.nvim_set_hl(0, 'WinSeparator', { bg = '#000000' })     -- window separators
  vim.api.nvim_set_hl(0, 'Pmenu',        { bg = '#000000' })     -- completion menu
  vim.api.nvim_set_hl(0, 'PmenuSel',     { bg = '#272727' })     -- selected completion item
  vim.api.nvim_set_hl(0, 'TabLine',      { bg = '#000000' })     -- tabline
  vim.api.nvim_set_hl(0, 'TabLineSel',   { bg = '#000000' })     -- selected tab
  vim.api.nvim_set_hl(0, 'EndOfBuffer',  { bg = '#1d1f23' })     -- `~` empty buffer area
end

-- ============================================================
-- SECTION 5: LSP
-- LSP keymaps, server configuration, Mason tools installations
-- ============================================================
do
  -- [[ LSP Configuration ]]
  -- Brief aside: **What is LSP?**
  --
  -- LSP is an initialism you've probably heard, but might not understand what it is.
  --
  -- LSP stands for Language Server Protocol. It's a protocol that helps editors
  -- and language tooling communicate in a standardized fashion.
  --
  -- In general, you have a "server" which is some tool built to understand a particular
  -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
  -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
  -- processes that communicate with some "client" - in this case, Neovim!
  --
  -- LSP provides Neovim with features like:
  --  - Go to definition
  --  - Find references
  --  - Autocompletion
  --  - Symbol Search
  --  - and more!
  --
  -- Thus, Language Servers are external tools that must be installed separately from
  -- Neovim. This is where `mason` and related plugins come into play.
  --
  -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
  -- and elegantly composed help section, `:help lsp-vs-treesitter`

  vim.pack.add { gh 'j-hui/fidget.nvim' } -- Useful status updates for LSP.
  require('fidget').setup {}

  --  This function gets run when an LSP attaches to a particular buffer.
  --    That is to say, every time a new file is opened that is associated with
  --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
  --    function will be executed to configure the current buffer
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
    callback = function(event)
      -- NOTE: Remember that Lua is a real programming language, and as such it is possible
      -- to define small helper and utility functions so you don't have to repeat yourself.
      --
      -- In this case, we create a function that lets us more easily define mappings specific
      -- for LSP related items. It sets the mode, buffer and description for us each time.
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      map('gd',  vim.lsp.buf.definition,  '[g]oto [d]efinition')                      -- Jump to the definition of the symbol under your cursor.
      map('gD',  vim.lsp.buf.declaration, '[g]oto [D]eclaration')                     -- WARN: This is not Goto Definition, this is Goto Declaration.
      map('grn', vim.lsp.buf.rename,      '[g]oto [r]e[n]ame')                        -- Rename the variable under your cursor.
      map('gra', vim.lsp.buf.code_action, '[g]oto [r]efactor [action]', { 'n', 'x' }) -- Execute a code action, usually your cursor needs to be on top of an error
      map('K',   vim.lsp.buf.hover,       '[K] Show hover documentation')

      -- Highlight references of the word under your cursor.
      -- Put this inside your LspAttach callback.

      local client = vim.lsp.get_client_by_id(event.data.client_id)

      if client and client:supports_method('textDocument/documentHighlight', event.buf) then
        -- Customize the highlight colors used by vim.lsp.buf.document_highlight()
        vim.api.nvim_set_hl(0, 'LspReferenceText',  { bg = '#72393D' })                    -- red    text
        vim.api.nvim_set_hl(0, 'LspReferenceRead',  { bg = '#395F77' })                    -- blue   read
        vim.api.nvim_set_hl(0, 'LspReferenceWrite', { bg = '#74612D', underline = false }) -- yellow write
        vim.api.nvim_set_hl(0, 'LspReferenceTarget',{ bg = '#30972B' })

        local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })

        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('kickstart-lsp-detach', {
            clear = true,
          }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds {
              group = 'kickstart-lsp-highlight',
              buffer = event2.buf,
            }
          end,
        })
      end

      -- The following code creates a keymap to toggle inlay hints in your
      -- code, if the language server you are using supports them
      --
      -- This may be unwanted, since they displace some of your code
      -- if client and client:supports_method('textDocument/inlayHint', event.buf) then
      --   map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
      -- end
    end,
  })

  -- Enable the following language servers
  --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
  --  See `:help lsp-config` for information about keys and how to configure
  ---@type table<string, vim.lsp.Config>
  local servers = {
    clangd = {},
    gopls = {},
    pyright = {},
    rust_analyzer = {},
    --
    -- Some languages (like typescript) have entire language plugins that can be useful:
    --    https://github.com/pmizio/typescript-tools.nvim
    --
    -- But for many setups, the LSP (`ts_ls`) will work just fine
    ts_ls = {},

    -- stylua is a formatter, not an LSP server. Install it via Mason tools below.

    -- Special Lua Config, as recommended by neovim help docs
    lua_ls = {
      on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

        if client.workspace_folders then
          local path = client.workspace_folders[1].name
          if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
        end

        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
          runtime = {
            version = 'LuaJIT',
            path = { 'lua/?.lua', 'lua/?/init.lua' },
          },
          workspace = {
            checkThirdParty = false,
            -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
            --  See https://github.com/neovim/nvim-lspconfig/issues/3189
            library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
              '${3rd}/luv/library',
              '${3rd}/busted/library',
            }),
          },
        })
      end,
      ---@type lspconfig.settings.lua_ls
      settings = {
        Lua = {
          format = { enable = false }, -- Disable formatting (formatting is done by stylua)
        },
      },
    },
  }

  vim.pack.add {
    gh 'neovim/nvim-lspconfig',
    gh 'mason-org/mason.nvim',
    gh 'mason-org/mason-lspconfig.nvim',
    gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
  }

  -- Automatically install LSPs and related tools to stdpath for Neovim
  require('mason').setup {}

  -- Ensure the servers and tools above are installed
  --
  -- To check the current status of installed tools and/or manually install
  -- other tools, you can run
  --    :Mason
  --
  -- You can press `g?` for help in this menu.
  local ensure_installed = vim.tbl_keys(servers or {})
  vim.list_extend(ensure_installed, {
    -- Formatters / linters that are not LSP servers
    'stylua',
  })

  require('mason-tool-installer').setup { ensure_installed = ensure_installed }

  for name, server in pairs(servers) do
    vim.lsp.config(name, server)
    vim.lsp.enable(name)
  end
end

-- ============================================================
-- SECTION 7: AUTOCOMPLETE & SNIPPETS
-- blink.cmp and luasnip setup
-- ============================================================
do
  -- [[ Snippet Engine ]]

  -- NOTE: You can also specify plugin using a version range for its git tag.
  --  See `:help vim.version.range()` for more info
  vim.pack.add { { src = gh 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' } }
  require('luasnip').setup {}

  -- `friendly-snippets` contains a variety of premade snippets.
  --    See the README about individual language/framework/plugin snippets:
  --    https://github.com/rafamadriz/friendly-snippets
  --
  vim.pack.add { gh 'rafamadriz/friendly-snippets' }
  require('luasnip.loaders.from_vscode').lazy_load()

  -- [[ Autocomplete Engine ]]
  vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range 'v1.*' } }
  require('blink.cmp').setup {
    fuzzy = { implementation = 'rust' },
    keymap = {
      -- 'default' (recommended) for mappings similar to built-in completions
      --   <c-y> to accept ([y]es) the completion.
      --    This will auto-import if your LSP supports it.
      --    This will expand snippets if the LSP sent a snippet.
      -- 'super-tab' for tab to accept
      -- 'enter' for enter to accept
      -- 'none' for no mappings
      --
      -- For an understanding of why the 'default' preset is recommended,
      -- you will need to read `:help ins-completion`
      --
      -- No, but seriously. Please read `:help ins-completion`, it is really good!
      --
      -- All presets have the following mappings:
      -- <tab>/<s-tab>: move to right/left of your snippet expansion
      -- <c-space>: Open menu or open docs if already open
      -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
      -- <c-e>: Hide menu
      -- <c-k>: Toggle signature help
      --
      -- See `:help blink-cmp-config-keymap` for defining your own keymap
      -- ctrl y   : accept
      -- ctrl n p : up and down
      -- ctrl e   : cancel
      preset = 'default',

      -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
      --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
    },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = 'normal',
    },
    completion = {
      -- By default, you may press `<c-space>` to show the documentation.
      -- Optionally, set `auto_show = true` to show the documentation after a delay.
      menu          = { auto_show     = true },
      documentation = { auto_show     = true },
      ghost_text    = { enabled       = false, show_with_menu = false },
      accept        = { auto_brackets = { enabled = true } },

    },

    sources = {
      default = { 'lsp', 'path', 'snippets' },
    },

    snippets = { preset = 'luasnip' },

    -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
    -- which automatically downloads a prebuilt binary when enabled.
    --
    -- By default, we use the Lua implementation instead, but you may enable
    -- the rust implementation via `'prefer_rust_with_warning'`
    --
    -- See `:help blink-cmp-config-fuzzy` for more information

    -- Shows a signature help window while you type arguments for a function
    signature = { enabled = true },
  }
end

-- ============================================================
-- SECTION 8: TREESITTER
-- Parser installation, syntax highlighting, folds, indentation
-- ============================================================
do
  -- [[ Configure Treesitter ]]
  --  Used to highlight, edit, and navigate code
  --
  --  See `:help nvim-treesitter-intro`

  -- NOTE: You can also specify a branch or a specific commit
  vim.pack.add { { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' } }
  vim.pack.add { { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects' } }

  -- Ensure basic parsers are installed
  local parsers = {'javascript', 'typescript', 'go', 'rust', 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }
  require('nvim-treesitter').install(parsers)

  ---@param buf integer
  ---@param language string
  local function treesitter_try_attach(buf, language)
    -- Check if a parser exists and load it
    if not vim.treesitter.language.add(language) then return end
    -- Enable syntax highlighting and other treesitter features
    vim.treesitter.start(buf, language)

    -- Enable treesitter based folds
    -- For more info on folds see `:help folds`
    -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    -- vim.wo.foldmethod = 'expr'

    -- Check if treesitter indentation is available for this language, and if so enable it
    -- in case there is no indent query, the indentexpr will fallback to the vim's built in one
    local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil

    -- Enable treesitter based indentation
    if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
  end

  local available_parsers = require('nvim-treesitter').get_available()
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      local buf, filetype = args.buf, args.match

      local language = vim.treesitter.language.get_lang(filetype)
      if not language then return end

      local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

      if vim.tbl_contains(installed_parsers, language) then
        -- Enable the parser if it is already installed
        treesitter_try_attach(buf, language)
      elseif vim.tbl_contains(available_parsers, language) then
        -- If a parser is available in `nvim-treesitter`, auto-install it and enable it after the installation is done
        require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
      else
        -- Try to enable treesitter features in case the parser exists but is not available from `nvim-treesitter`
        treesitter_try_attach(buf, language)
      end
    end,
  })
end


local NS = { noremap = true, silent = true }


-- Aligns to a string with previews
vim.keymap.set(
    'x',
    'aw',
    function()
        require'align'.align_to_string({
            preview = true,
            regex = false,
        })
    end,
    NS
)


-- Example gawip to align a paragraph to a string with previews
vim.keymap.set(
    'n',
    'gaw',
    function()
        local a = require'align'
        a.operator(
            a.align_to_string,
            {
                regex = false,
                preview = true,
            }
        )
    end,
    NS
)

-- Example gaaip to align a paragraph to 1 character
vim.keymap.set(
    'n',
    'gaa',
    function()
        local a = require'align'
        a.operator(a.align_to_char)
    end,
    NS
)

-- ============================================================
-- SECTION 9: OPTIONAL EXAMPLES / NEXT STEPS
-- kickstart.plugins.* examples
-- ============================================================
do
  require('variable_spotlight').setup()
end

vim.api.nvim_set_hl(0, "Visual", {
  fg = "#ffffff", -- selected text color
  bg = "#3297FD", -- selected background color
})

-- autopairs
-- https://github.com/windwp/nvim-autopairs

vim.pack.add { 'https://github.com/windwp/nvim-autopairs' }
require('nvim-autopairs').setup {}
