export SHELL=$(which zsh)
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt appendhistory
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "$key[Up]" up-line-or-beginning-search
bindkey "$key[Down]" down-line-or-beginning-search

source "$HOME/theme.zsh"

export PATH=$PATH:/usr/local/go/bin
export GOROOT=$(go env GOROOT)
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export PATH=$PATH:$GOBIN

export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/kitty.app/bin:$PATH"
eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)

source /usr/share/doc/fzf/examples/key-bindings.zsh
source /usr/share/doc/fzf/examples/completion.zsh
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

export GPG_TTY=$(tty)

alias gs='git status'
alias gap='git add -p'
alias gcm='git commit -m'
eval "$(zoxide init zsh)"
