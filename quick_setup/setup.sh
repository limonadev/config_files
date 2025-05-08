#!/bin/zsh

set -e

log() { echo -e "\033[1;32m$1\033[0m"; }

# -------------------------------------
# 1. Xcode Command Line Tools
# -------------------------------------
log ":wrench: Checking Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    log "🛠 Installing Xcode Command Line Tools..."
    xcode-select --install

    log ":hourglass: Waiting for installation to complete..."
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    log ":white_check_mark: Xcode Command Line Tools installed."
else
    log ":white_check_mark: Xcode Command Line Tools already installed."
fi

# -------------------------------------
# 2. Homebrew
# -------------------------------------
log ":beer: Checking Homebrew..."
if ! command -v brew &>/dev/null; then
    log ":inbox_tray: Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"  # for Apple Silicon
else
    log ":white_check_mark: Homebrew already installed."
fi

log ":repeat: Updating Homebrew..."
brew update

# -------------------------------------
# 3. Fonts (MesloLGS Nerd Font)
# -------------------------------------
log ":abc: Installing MesloLGS Nerd Font for Powerlevel10k..."
brew install font-meslo-for-powerlevel10k

# -------------------------------------
# 4. Install CLI Tools & Casks
# -------------------------------------
install_if_missing() {
    if ! brew list "$1" &>/dev/null && ! brew list --cask "$1" &>/dev/null; then
        log ":package: Installing $1..."
        brew install "$1" || brew install --cask "$1"
    else
        log ":white_check_mark: $1 already installed."
    fi
}

# CLI tools
install_if_missing openjdk@17
sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
install_if_missing nvm
brew tap leoafarias/fvm
install_if_missing fvm

# GUI apps
# Check if Google Chrome is installed
if [ ! -d "/Applications/Google Chrome.app" ]; then
    echo "Google Chrome not found. Installing..."
    brew install --cask google-chrome
else
    echo "Google Chrome is already installed."
fi

# Check if Visual Studio Code is installed
if [ ! -d "/Applications/Visual Studio Code.app" ]; then
    echo "Visual Studio Code not found. Installing..."
    brew install --cask visual-studio-code
else
    echo "Visual Studio Code is already installed."
fi

# -------------------------------------
# 5. Setup NVM
# -------------------------------------
log ":open_file_folder: Ensuring NVM directory exists..."
mkdir -p ~/.nvm

# -------------------------------------
# 6. Oh My Zsh
# -------------------------------------
log ":computer: Checking Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    export RUNZSH=no
    log ":inbox_tray: Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    log ":white_check_mark: Oh My Zsh already installed."
fi

# -------------------------------------
# 7. Powerlevel10k
# -------------------------------------
log ":sparkles: Installing Powerlevel10k theme..."
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
else
    log ":white_check_mark: Powerlevel10k already installed."
fi

# -------------------------------------
# 8. Oh My Zsh Plugins
# -------------------------------------
log ":electric_plug: Installing Zsh plugins..."
plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

[[ -d "$plugins_dir/zsh-syntax-highlighting" ]] || \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugins_dir/zsh-syntax-highlighting"

[[ -d "$plugins_dir/zsh-autosuggestions" ]] || \
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$plugins_dir/zsh-autosuggestions"

# -------------------------------------
# 9. Generate .zshrc
# -------------------------------------
log ":gear: Writing ~/.zshrc..."
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

# Java
export JAVA_HOME=`/usr/libexec/java_home -v 17`

# Android/adb
# Uncomment after Android Studio is installed
# export PATH=$PATH:/Users/enigma/Library/Android/sdk/platform-tools/
EOF


log ":white_check_mark: Setup complete."
log ":memo: Please change your terminal font to 'MesloLGS NF' manually."
log ":memo: Please install JetBrains Toolbox and Android Studio manually to enable adb commented export on .zshrc"
log ":arrows_counterclockwise: Uncomment the lines in the .zprofile file, only after brew and/or JetBrains Toolbox are installed"
log ":arrows_counterclockwise: Restart your terminal or run: source ~/.zshrc"
