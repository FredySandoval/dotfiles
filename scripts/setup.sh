sudo pacman -S --needed --noconfirm   \
fnm       \
pnpm      \
git-delta \
pass      \
pass-otp  \
rustup    \
go        \
lazygit   \
dolphin   \
tmux      \
starship  \
stow      \
zig       \

paru -S --needed --noconfirm --removemake neovim-nightly google-chrome

if ! rustup show active-toolchain >/dev/null 2>&1; then
  rustup default stable
fi

files=(
  "/usr/lib/browserpass/hosts/chromium/com.github.browserpass.native.json"
)

for file in "${files[@]}"; do
  if [ -e "$file" ]; then
    # browserpass
    sudo mkdir -p /etc/opt/chrome/native-messaging-hosts
    sudo ln -sf /usr/lib/browserpass/hosts/chromium/com.github.browserpass.native.json \
      /etc/opt/chrome/native-messaging-hosts/com.github.browserpass.native.json
  fi
done

# Blender GPU support
# sudo pacman -S hip-runtime-amd \
# 	  hiprt                  \
# 	  rocminfo               \
# sudo usermod -aG render,video "$USER"
