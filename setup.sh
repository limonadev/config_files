#!/bin/zsh

set -e

log() { echo -e "\033[1;32m$1\033[0m"; }

# Get the directory where this script is located (works from any location)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# -------------------------------------
# 1. Xcode Command Line Tools
# -------------------------------------
log "🔧 Checking Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    log "🛠 Installing Xcode Command Line Tools..."
    xcode-select --install

    log "⌛ Waiting for installation to complete..."
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    log "✅ Xcode Command Line Tools installed."
else
    log "✅ Xcode Command Line Tools already installed."
fi

# -------------------------------------
# 2. Homebrew
# -------------------------------------
log "🍺 Checking Homebrew..."
if ! command -v brew &>/dev/null; then
    log "📥 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"  # for Apple Silicon
else
    log "✅ Homebrew already installed."
fi

log "🔁 Updating Homebrew..."
brew update

# -------------------------------------
# 3. Fonts (MesloLGS Nerd Font)
# -------------------------------------
log "🔤 Installing MesloLGS Nerd Font for Powerlevel10k..."
if brew list --cask font-meslo-for-powerlevel10k &>/dev/null; then
    log "✅ MesloLGS Nerd Font already installed."
else
    brew install --cask font-meslo-for-powerlevel10k || {
        log "⚠️  Font installation had issues (may already be installed), continuing..."
    }
fi

# -------------------------------------
# 3.1. Configure Terminal Font
# -------------------------------------
log "⚙️ Configuring terminal font to 'MesloLGS NF'..."

# Configure Terminal.app font
if [ -d "/Applications/Utilities/Terminal.app" ]; then
    log "📝 Setting font for Terminal.app..."
    # Get the default profile name (usually "Basic" or "Pro")
    DEFAULT_PROFILE=$(defaults read com.apple.Terminal "Default Window Settings" 2>/dev/null || echo "Basic")
    
    # Set the font for the default profile (font name is "MesloLGS NF" with space)
    defaults write com.apple.Terminal "Window Settings.$DEFAULT_PROFILE" Font -string "MesloLGS NF"
    defaults write com.apple.Terminal "Window Settings.$DEFAULT_PROFILE" FontSize -float 12.0
    defaults write com.apple.Terminal "Window Settings.$DEFAULT_PROFILE" FontAntialias -bool true
    
    # Also set for all existing profiles
    for profile in $(defaults read com.apple.Terminal "Window Settings" 2>/dev/null | grep -o '"[^"]*"' | tr -d '"'); do
        defaults write com.apple.Terminal "Window Settings.$profile" Font -string "MesloLGS NF" 2>/dev/null
        defaults write com.apple.Terminal "Window Settings.$profile" FontSize -float 12.0 2>/dev/null
        defaults write com.apple.Terminal "Window Settings.$profile" FontAntialias -bool true 2>/dev/null
    done
    
    log "✅ Terminal.app font configured (restart Terminal to see changes)."
fi

# -------------------------------------
# 4. Install CLI Tools & Casks
# -------------------------------------
install_if_missing() {
    if ! brew list "$1" &>/dev/null && ! brew list --cask "$1" &>/dev/null; then
        log "📦 Installing $1..."
        brew install "$1" || brew install --cask "$1"
    else
        log "✅ $1 already installed."
    fi
}

# CLI tools
install_if_missing openjdk@17
sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
install_if_missing nvm
brew tap leoafarias/fvm
install_if_missing fvm

# Ruby installation
log "💎 Installing Ruby tools..."
install_if_missing chruby
install_if_missing ruby-install

# Install Ruby 3.4.3 if not already installed
log "💎 Checking Ruby 3.4.3 installation..."
if [ ! -d "$HOME/.rubies/ruby-3.4.3" ]; then
    log "📦 Installing Ruby 3.4.3..."
    ruby-install ruby 3.4.3
else
    log "✅ Ruby 3.4.3 already installed."
fi

# mise installation
log "🔧 Installing mise..."
install_if_missing mise

# GUI apps
# Check if Brave Browser is installed
if [ ! -d "/Applications/Brave Browser.app" ]; then
    echo "Brave Browser not found. Installing..."
    brew install --cask brave-browser
else
    echo "Brave Browser is already installed."
fi

# Check if Cursor is installed
if [ ! -d "/Applications/Cursor.app" ]; then
    echo "Cursor not found. Installing..."
    brew install --cask cursor
else
    echo "Cursor is already installed."
fi

# Setup Cursor CLI command
log "🔧 Setting up Cursor CLI command..."
CURSOR_BIN="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"

if [ -f "$CURSOR_BIN" ]; then
    # Determine the best location for the symlink
    # Prefer /opt/homebrew/bin for Apple Silicon (no sudo needed)
    # Fall back to /usr/local/bin (may need sudo)
    if [ -d "/opt/homebrew/bin" ] && [ -w "/opt/homebrew/bin" ]; then
        CURSOR_SYMLINK="/opt/homebrew/bin/cursor"
        USE_SUDO=false
    elif [ -d "/opt/homebrew/bin" ]; then
        CURSOR_SYMLINK="/opt/homebrew/bin/cursor"
        USE_SUDO=true
    elif [ -w "/usr/local/bin" ]; then
        CURSOR_SYMLINK="/usr/local/bin/cursor"
        USE_SUDO=false
    else
        CURSOR_SYMLINK="/usr/local/bin/cursor"
        USE_SUDO=true
    fi
    
    # Create symlink if it doesn't exist or is broken
    if [ ! -L "$CURSOR_SYMLINK" ] || [ ! -e "$CURSOR_SYMLINK" ]; then
        log "📎 Creating symlink for cursor command at $CURSOR_SYMLINK..."
        if [ "$USE_SUDO" = true ]; then
            sudo ln -sf "$CURSOR_BIN" "$CURSOR_SYMLINK"
        else
            ln -sf "$CURSOR_BIN" "$CURSOR_SYMLINK"
        fi
        log "✅ Cursor CLI command installed at $CURSOR_SYMLINK"
    else
        log "✅ Cursor CLI command already set up at $CURSOR_SYMLINK"
    fi
else
    log "⚠️  Cursor binary not found at $CURSOR_BIN"
fi

# Check if Insomnia is installed
if [ ! -d "/Applications/Insomnia.app" ]; then
    echo "Insomnia not found. Installing..."
    brew install --cask insomnia
else
    echo "Insomnia is already installed."
fi

# -------------------------------------
# 4.1. Setup Cursor Settings
# -------------------------------------
log "⚙️ Setting up Cursor user settings..."
CURSOR_SETTINGS_SOURCE="$SCRIPT_DIR/cursor/settings.json"
CURSOR_USER_DIR="$HOME/Library/Application Support/Cursor/User"
CURSOR_SETTINGS_TARGET="$CURSOR_USER_DIR/settings.json"

if [ -f "$CURSOR_SETTINGS_SOURCE" ]; then
    mkdir -p "$CURSOR_USER_DIR"
    log "📋 Copying Cursor settings..."
    cp "$CURSOR_SETTINGS_SOURCE" "$CURSOR_SETTINGS_TARGET"
    log "✅ Cursor settings configured."
else
    log "⚠️  Cursor settings file not found at $CURSOR_SETTINGS_SOURCE"
fi

# -------------------------------------
# 4.2. Setup Git Configuration
# -------------------------------------
log "⚙️ Setting up Git configuration..."
GITCONFIG_SOURCE="$SCRIPT_DIR/.gitconfig"
GITCONFIG_TARGET="$HOME/.gitconfig"

if [ -f "$GITCONFIG_SOURCE" ]; then
    log "📋 Copying Git config..."
    cp "$GITCONFIG_SOURCE" "$GITCONFIG_TARGET"
    log "✅ Git configuration set up."
else
    log "⚠️  Git config file not found at $GITCONFIG_SOURCE"
fi

# -------------------------------------
# 4.3. Setup SSH Configuration and Keys
# -------------------------------------
log "🔐 Setting up SSH configuration..."
SSH_DIR="$HOME/.ssh"
SSH_CONFIG_SOURCE="$SCRIPT_DIR/.ssh/config"
SSH_CONFIG_TARGET="$SSH_DIR/config"

# Create .ssh directory if it doesn't exist
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [ -f "$SSH_CONFIG_SOURCE" ]; then
    log "📋 Copying SSH config..."
    cp "$SSH_CONFIG_SOURCE" "$SSH_CONFIG_TARGET"
    chmod 600 "$SSH_CONFIG_TARGET"
    log "✅ SSH configuration set up."
else
    log "⚠️  SSH config file not found at $SSH_CONFIG_SOURCE"
fi

# Generate SSH key if it doesn't exist
SSH_KEY="$SSH_DIR/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
    log "🔑 Generating SSH key..."
    ssh-keygen -t ed25519 -C "limonadev@gmail.com" -f "$SSH_KEY" -N ""
    log "✅ SSH key generated at $SSH_KEY"
    log "📋 Public key (add this to GitHub):"
    cat "$SSH_KEY.pub"
    log ""
    log "🔗 Add your SSH key to GitHub: https://github.com/settings/keys"
else
    log "✅ SSH key already exists at $SSH_KEY"
fi

# -------------------------------------
# 5. Setup NVM
# -------------------------------------
log "📂 Ensuring NVM directory exists..."
mkdir -p ~/.nvm

# -------------------------------------
# 6. Oh My Zsh
# -------------------------------------
log "💻 Checking Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    export RUNZSH=no
    log "📥 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    log "✅ Oh My Zsh already installed."
fi

# -------------------------------------
# 7. Powerlevel10k
# -------------------------------------
log "✨ Installing Powerlevel10k theme..."
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
else
    log "✅ Powerlevel10k already installed."
fi

# -------------------------------------
# 8. Oh My Zsh Plugins
# -------------------------------------
log "🔌 Installing Zsh plugins..."
plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

[[ -d "$plugins_dir/zsh-syntax-highlighting" ]] || \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugins_dir/zsh-syntax-highlighting"

[[ -d "$plugins_dir/zsh-autosuggestions" ]] || \
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$plugins_dir/zsh-autosuggestions"

# -------------------------------------
# 8.1. Copy Powerlevel10k Configuration
# -------------------------------------
log "⚙️ Setting up Powerlevel10k configuration..."
P10K_SOURCE="$SCRIPT_DIR/.p10k.zsh"
P10K_TARGET="$HOME/.p10k.zsh"

if [ -f "$P10K_SOURCE" ]; then
    log "📋 Copying Powerlevel10k config..."
    cp "$P10K_SOURCE" "$P10K_TARGET"
    log "✅ Powerlevel10k configuration set up."
else
    log "⚠️  Powerlevel10k config file not found at $P10K_SOURCE"
fi

# -------------------------------------
# 8.2. Copy .zprofile and add brew line
# -------------------------------------
log "⚙️ Setting up .zprofile..."
ZPROFILE_SOURCE="$SCRIPT_DIR/.zprofile"
ZPROFILE_TARGET="$HOME/.zprofile"

if [ -f "$ZPROFILE_SOURCE" ]; then
    log "📋 Copying .zprofile..."
    cp "$ZPROFILE_SOURCE" "$ZPROFILE_TARGET"
    # Add brew line since brew is installed during this script
    if ! grep -q "eval \"\$(/opt/homebrew/bin/brew shellenv)\"" "$ZPROFILE_TARGET"; then
        log "🍺 Adding brew line to .zprofile..."
        echo "" >> "$ZPROFILE_TARGET"
        echo "# Added for brew" >> "$ZPROFILE_TARGET"
        echo "eval \"\$(/opt/homebrew/bin/brew shellenv)\"" >> "$ZPROFILE_TARGET"
    fi
    log "✅ .zprofile set up (brew line added)."
else
    log "⚠️  .zprofile file not found at $ZPROFILE_SOURCE"
fi

# -------------------------------------
# 9. Generate .zshrc
# -------------------------------------
log "⚙️ Writing ~/.zshrc..."
cat <<'EOF' > ~/.zshrc
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
)
source $ZSH/oh-my-zsh.sh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Needed for zsh-autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# nvm auto detect node version on cd
# place this after nvm initialization!
autoload -U add-zsh-hook

load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc

# [Ruby]
# Use Homebrew's opt symlink which points to the current version
if [ -f "/opt/homebrew/opt/chruby/share/chruby/chruby.sh" ]; then
  source /opt/homebrew/opt/chruby/share/chruby/chruby.sh
  source /opt/homebrew/opt/chruby/share/chruby/auto.sh
  chruby 3.4.3
fi

# [mise]
eval "$(mise activate zsh)"

# Java
export JAVA_HOME=`/usr/libexec/java_home -v 17`

# Flutter web debugging with Brave Browser
export CHROME_EXECUTABLE="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"

# Android/adb
# Uncomment after Android Studio is installed
# export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools
EOF

# -------------------------------------
# 10. Install additional tools after .zshrc is set up
# -------------------------------------
log "📦 Installing additional tools (sourcing .zshrc for environment)..."

# Source .zshrc to get all environment variables
source ~/.zshrc

# Install CocoaPods with Ruby
log "📦 Installing CocoaPods..."
if command -v gem &>/dev/null && command -v chruby &>/dev/null; then
    if ! command -v pod &>/dev/null; then
        gem install cocoapods
        log "✅ CocoaPods installed."
    else
        log "✅ CocoaPods already installed."
    fi
else
    log "⚠️  Ruby/gem not available, skipping CocoaPods installation"
fi

# Install Flutter with fvm
log "📦 Installing Flutter with fvm..."
if command -v fvm &>/dev/null; then
    fvm install stable
    log "✅ Flutter stable installed via fvm."
else
    log "⚠️  fvm not available, skipping Flutter installation"
fi

# Install Flutter and Dart with mise (latest stable versions)
log "📦 Installing Flutter and Dart with mise (stable versions)..."
if command -v mise &>/dev/null; then
    # Try @stable first, fallback to @latest if @stable not supported
    if mise install flutter@stable 2>/dev/null; then
        log "✅ Flutter stable installed via mise."
    else
        # @stable might not be supported, use @latest which should be stable
        mise install flutter@latest
        log "✅ Flutter latest installed via mise."
    fi
    
    if mise install dart@stable 2>/dev/null; then
        log "✅ Dart stable installed via mise."
    else
        # @stable might not be supported, use @latest which should be stable
        mise install dart@latest
        log "✅ Dart latest installed via mise."
    fi
else
    log "⚠️  mise not available, skipping Flutter/Dart installation"
fi

# Install Cursor Extensions
log "🔌 Installing Cursor extensions..."
CURSOR_EXTENSIONS_SOURCE="$SCRIPT_DIR/cursor/extensions.txt"

if [ -f "$CURSOR_EXTENSIONS_SOURCE" ]; then
    # Check if cursor CLI is available
    if command -v cursor &>/dev/null && cursor --version &>/dev/null; then
        log "📦 Installing extensions from extensions.txt..."
        installed_count=0
        skipped_count=0
        
        while IFS= read -r extension || [ -n "$extension" ]; do
            # Skip empty lines and comments
            [[ -z "$extension" || "$extension" =~ ^[[:space:]]*# ]] && continue
            
            # Trim whitespace
            extension=$(echo "$extension" | xargs)
            [[ -z "$extension" ]] && continue
            
            log "  📦 Installing $extension..."
            if cursor --install-extension "$extension" &>/dev/null; then
                ((installed_count++))
            else
                log "  ⚠️  Failed to install $extension (may already be installed)"
                ((skipped_count++))
            fi
        done < "$CURSOR_EXTENSIONS_SOURCE"
        
        log "✅ Installed $installed_count extension(s), $skipped_count skipped/failed."
    else
        log "⚠️  Cursor CLI not available. The symlink may need a moment to be recognized."
        log "   Try running: source ~/.zshrc or restart your terminal"
    fi
else
    if [ ! -f "$CURSOR_EXTENSIONS_SOURCE" ]; then
        log "⚠️  Extensions file not found at $CURSOR_EXTENSIONS_SOURCE"
        log "   To export extensions: cursor --list-extensions > cursor/extensions.txt"
    fi
fi

log "✅ Setup complete."
log "📝 Terminal font has been configured. Restart your terminal to see the changes."
log "📝 Please install JetBrains Toolbox and Android Studio manually to enable adb commented export on .zshrc"
log "🔄 Uncomment the JetBrains Toolbox line in .zprofile after installing JetBrains Toolbox"
log "🔄 Restart your terminal or run: source ~/.zshrc"
log ""
log "🐙 GitHub Setup:"
log "   - Git config and SSH config have been set up"
log "   - If an SSH key was generated, add it to GitHub: https://github.com/settings/keys"
