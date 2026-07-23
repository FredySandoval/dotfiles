#!/usr/bin/env bash
set -euo pipefail

# Arch setup script
pacman_pkgs=(
  base-devel           # build essentials
  git
  fnm                  # dev tools
  pnpm
  git-delta
  rustup
  go
  zig
  lazygit
  pass                 # password management
  pass-otp
  browserpass
  browserpass-chromium
  tmux                 # shell & desktop
  starship
  stow
  dolphin
  caligula
)

aur_pkgs=(
  neovim-nightly-bin   # prebuilt; use neovim-nightly to build from source
  google-chrome
)

# Helpers
msg()  { echo -e "\033[1;32m==>\033[0m $*";          }
warn() { echo -e "\033[1;33mwarning:\033[0m $*" >&2; }

# Cleanup any tempdirs on exit (fires even when set -e aborts the script)
tmpdirs=()
cleanup() {
  ((${#tmpdirs[@]})) && rm -rf "${tmpdirs[@]}"
}
trap cleanup EXIT

install_paru() {
  msg "Bootstrapping paru from the AUR..."

  local tmpdir
  tmpdir=$(mktemp -d)
  tmpdirs+=("$tmpdir")

  git clone https://aur.archlinux.org/paru-bin.git "$tmpdir/paru-bin"
  (cd "$tmpdir/paru-bin" && makepkg -si --noconfirm)
}

# Keep sudo credentials fresh so makepkg/paru don't stall mid-script
msg "Requesting sudo credentials..."
sudo -v
( while true; do sleep 60; sudo -n true 2>/dev/null || exit; done ) &
sudo_keepalive_pid=$!
trap 'kill "$sudo_keepalive_pid" 2>/dev/null; cleanup' EXIT

# Packages
msg "Installing official repo packages..."
sudo pacman -S --needed --noconfirm "${pacman_pkgs[@]}"

command -v paru >/dev/null 2>&1 || install_paru

msg "Installing AUR packages..."
paru -S --needed --noconfirm --removemake "${aur_pkgs[@]}"

# Rust toolchain (idempotent, so no fragile version-dependent check needed)
msg "Ensuring default Rust toolchain is stable..."
rustup default stable

# Browserpass native messaging host for Chrome
browserpass_host=/usr/lib/browserpass/hosts/chromium/com.github.browserpass.native.json
chrome_hosts_dir=/etc/opt/chrome/native-messaging-hosts

if [ -e "$browserpass_host" ]; then
  msg "Linking browserpass native messaging host for Chrome..."
  sudo mkdir -p "$chrome_hosts_dir"
  sudo ln -sf "$browserpass_host" "$chrome_hosts_dir/"
else
  warn "$browserpass_host not found; skipping Chrome browserpass link"
fi

msg "Done."



# Blender GPU support
# sudo pacman -S hip-runtime-amd \
# 	  hiprt                  \
# 	  rocminfo               \
# sudo usermod -aG render,video "$USER"
