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

export N_PREFIX=$HOME/.n
export PATH="$PATH:$N_PREFIX/bin"

source /usr/share/doc/fzf/examples/key-bindings.zsh
source /usr/share/doc/fzf/examples/completion.zsh
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

export GPG_TTY=$(tty)

alias gs='git status'
alias gap='git add -p'
alias gcm='git commit -m'
alias gwip='git commit -m "wip"'
alias gpsh='git push'
alias up='git pull --rebase'
eval "$(zoxide init zsh)"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/forest/google-cloud-sdk/path.zsh.inc' ]; then . '/home/forest/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/forest/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/forest/google-cloud-sdk/completion.zsh.inc'; fi
