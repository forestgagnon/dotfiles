function symlink {
  ln -sf $1 $2
}

DIR=$(dirname "$0")
PARENT_PATH=$(pwd -P)
CONFIG_DIR="${PARENT_PATH}/${DIR}"
cd ~

########## CONFIG DOTFILES ##########
symlink $CONFIG_DIR/.bash_profile .bash_profile
symlink $CONFIG_DIR/.vimrc .vimrc
symlink $CONFIG_DIR/.zshrc .zshrc
symlink $CONFIG_DIR/.spacemacs .spacemacs

########## ITERM ##########
symlink $CONFIG_DIR/iterm-colors/ .
symlink $CONFIG_DIR/iterm2-profile/ .

########## HAMMERSPOON, KARABINER ##########
symlink $CONFIG_DIR/.hammerspoon/ .
symlink $CONFIG_DIR/karabiner/ .config

########## LINTER CONFIGS ##########
shopt -s dotglob
for config in $CONFIG_DIR/linter-configs/*; do symlink $config $(basename $config); done
shopt -u dotglob

########## ZSH THEMES ##########
for file in $CONFIG_DIR/zsh-themes/*; do symlink $file .oh-my-zsh/themes/$(basename $file); done