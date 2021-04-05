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
HISTSIZE=1000000
SAVEHIST=1000000

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
# bindkey "$key[Up]" up-line-or-beginning-search
# bindkey "$key[Down]" down-line-or-beginning-search

export PATH=$PATH:/usr/local/go/bin
export GOROOT=$(go env GOROOT)
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export PATH=$PATH:$GOBIN

export PATH="$HOME/.cargo/bin:$PATH"

export N_PREFIX=$HOME/.n
export PATH="$PATH:$N_PREFIX/bin"

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

export GPG_TTY=$(tty)

alias gs='git status'
alias gap='git add -p'
alias gcm='git commit -m'
alias gwip='git commit -m "wip"'
alias gpsh='git push'
alias up='git pull --rebase'
eval "$(zoxide init zsh)"
