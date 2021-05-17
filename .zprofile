source ~/code/forestgagnon/dotfiles/zsh-themes/forest-mac.zsh-theme
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

export GPG_TTY=$(tty)

alias k='kubectl --context=docker-desktop'

eval "$(zoxide init zsh)"


########## GIT ##########
alias gs='git status'
alias gaa='git add .'
alias gap='git add -p'
alias gcm='git commit -m'
alias gpsh='git push'
alias gdf='git diff'
alias gb="git for-each-ref --sort=committerdate refs/heads/ --format='%(color:magenta bold blink)%(HEAD)%(color:reset) %(color:white bold)%(refname:short)%(color:reset) %(color:cyan)%(objectname:short)%(color:reset) (%(color:green)%(committerdate:relative)%(color:reset)) %(color:normal dim)%(contents:subject)%(color:reset)'"
alias glg="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gwip="git commit -m 'wip'"
alias gdu="git checkout -- ." # Discard all unstaged changes
gireb() { git rebase -i HEAD~"$1"; }
git-current-branch() { git rev-parse --abbrev-ref HEAD | tr -d '\n'; }
git-recent-branches() { git for-each-ref --count=10 --sort=-committerdate refs/heads/ --format="%(refname:short)"; }
alias gcbc='git-current-branch | pbcopy' # Copy current branch name to clipboard
alias git-reset-to-origin='git reset --hard origin/$(git-current-branch)'

alias nb='new_branch -r'
alias mb='merge_branch'
alias up='git pull --rebase'
git-cleanup() {
  local show_force_hint=true
  local branch_delete_command='xargs git branch -d'
  while true; do
    case "$1" in
      --force ) branch_delete_command='xargs git branch -D'; show_force_hint=false; shift;;
      * ) break ;;
    esac
  done
  git fetch --prune
  git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | eval $branch_delete_command
  if [[ "$show_force_hint" == true ]]
    then
      echo "\nNOTE: run this with --force to ignore warnings and also delete unmerged local branches"
  fi
}
gsquash() {
  git diff-index --quiet HEAD --
  if [[ $? != 0 ]]
  then
    echo "\n Error! Your working tree has uncommitted changes! No squashing for you!"
    return
  fi
  echo 'The following commits will be squashed into one:\n'
  git --no-pager log --abbrev-commit --pretty=oneline HEAD~"$1"..HEAD
  echo '\nContinue? (y/n) \c'
  read yn
  if [[ "$yn" == 'y' ]]
  then
    git reset --soft HEAD~"$1"
    git commit
    echo "\n$fg[green]Success!$fg[default] Squashed the last $1 commits into new commit $fg[yellow]$(git rev-parse HEAD)$fg[default]"
  fi
}

# Menu generator aliases
alias gc="menu-generator -p 'git-checkout-fancy ' -m 'git-recent-branches-menu-array-generator'"
alias gireb-on="menu-generator -p 'git fetch && git rebase origin/' -m 'git-recent-branches-menu-array-generator'"
alias gbc="menu-generator -p 'echo ' -s ' | pbcopy' -m 'git-recent-branches-menu-array-generator'"


git-recent-branches-menu-array-generator() {
  local -a BRANCHES
  local -a COLORED_BRANCHES
  git for-each-ref --count=10 --sort=-committerdate refs/heads/ --format="%(refname:short)" | while read branch; do
    local date="$(git for-each-ref --sort=committerdate refs/heads/"$branch" --format='%(committerdate:relative)' --count=1)"
    local hash="$(git rev-list "$branch" --max-count=1)"
    case $branch in
      $(git-current-branch))
        COLORED_BRANCHES+=("\"$fg[magenta]* $fg[yellow]${branch}$fg[default] ($fg[green]$date$fg[default]) ${hash}\"");;
      *)
        COLORED_BRANCHES+=("\"$fg[white]${branch}$fg[default] ($fg[green]$date$fg[default]) ${hash}\"");;
    esac
    BRANCHES+=(${branch})
  done

  echo "VALUES=($BRANCHES) LABELS=($COLORED_BRANCHES)"
}

# This function executes a command which is formed by concatenating a prefix string,
# a value returned from a select menu, and a suffix string.
# USAGE: -m should be a function which echos a string defining two arrays, one for VALUES and one for LABELS:
# e.g. echo "VALUES=($VALUES) LABELS=($LABELS)"
# -p is a prefix for the expression returned by the menu, -s is a suffix
# Remember to add spacing at the end of your prefix and/or the beginning of your suffix if needed
menu-generator() {
  local PREFIX=""
  local SUFFIX=""
  local MENU_ARRAY_GENERATOR=""

  while true; do
    case "$1" in
      -p ) PREFIX="$2"; shift; shift ;;
      -s ) SUFFIX="$2"; shift; shift ;;
      -m ) MENU_ARRAY_GENERATOR="$2"; shift; shift ;;
      * ) break ;;
    esac
  done

  local -a VALUES
  local -a LABELS

  eval $($MENU_ARRAY_GENERATOR)
  select label in $LABELS
  do
    local value=$(echo ${VALUES[REPLY]})
    echo ${PREFIX}${value}${SUFFIX}
    eval ${PREFIX}${value}${SUFFIX}
    break
  done
}

git-checkout-fancy() {
  case $1 in
    $(git-current-branch))
      echo "$fg[red]${1} is already checked out.";;
    *) git checkout $1;;
  esac
}

# NAVIGATION
alias f='open -a Finder ./'

########## DOCKER / KUBERNETES ##########
alias kp='kparanoid'
alias kill-context='kubectl config get-contexts | yank | xargs kubectl config delete-context && kubectl config use-context docker-for-desktop'

########## SYSTEM ##########
grep-and-kill-pid() { ps aux | grep ${@:1} | yank | xargs kill -9; }
alias kl='grep-and-kill-pid'
alias hosts='sudo vim /etc/hosts'
alias flushdns='sudo killall -HUP mDNSResponder && sudo dscacheutil -flushcache'

cloudbuildwatch() {
  gcloud builds list "$@" | grep WORKING | yank | xargs gcloud builds log --stream "$@"
}

tmp() {
  cd $(mktemp -d)
}

# Docker image runners

dockeri() {
  docker run --rm -it "$@"
}

alpine() {
  dockeri "$@" alpine
}

alpine-pwd() {
  alpine --workdir=/mountdir -v "$PWD:/mountdir" "$@"
}

ubuntu() {
  dockeri "$@" ubuntu
}
