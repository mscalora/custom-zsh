# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# theme autoloads

autoload colors
autoload -U add-zsh-hook
autoload -Uz vcs_info

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# theme options

PR_GIT_UPDATE=1
setopt prompt_subst

setopt histignorespace

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# theme aliases

alias hist='history | egrep '

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# theme aliases

autoload -Uz modify-current-argument

expand-and-abspath () {
    REPLY=${~1}
    REPLY=${REPLY:a}
}

abspath-word() {
    modify-current-argument expand-and-abspath
}

zle -N abspath-word

rel-arg-to-cwd() {
	REPLY="`python -c 'import os, sys ; sys.stdout.write(os.path.relpath(sys.argv[1]))' $1`"
}

relpath-word() {
  modify-current-argument rel-arg-to-cwd
}

zle -N relpath-word

swap-quotes() { BUFFER="$( echo -n "$BUFFER" | tr "\"'" "'\"")" }

zle -N swap-quotes

code() {
  if [ -d "/Applications/Visual Studio Code.app" ] ; then
    open -a "/Applications/Visual Studio Code.app" $*
  elif [ -d "/Applications/Code.app" ] ; then
    open -a "/Applications/Code.app" $*
  else
    open "https://code.visualstudio.com/download"
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# custom keys

bindkey "\x1b\x1b\x5b\x41" beginning-of-line  # option up for iTerm
bindkey "\x1b\x1b\x5b\x42" end-of-line        # option down for iTerm
bindkey "\x1b\x1b\x5b\x43" forward-word       # option right for iTerm
bindkey "\x1b\x1b\x5b\x44" backward-word      # option left for iTerm

bindkey "^[[:u" undo
bindkey "^[[:r" redo

bindkey "å" abspath-word
bindkey "Å" relpath-word
bindkey "ß" swap-quotes

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# extra completions

for inc in $ZSH_CUSTOM/plugins/*.inc(.N) ; do 
  source $inc
done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# self-update

ts_file=~/.zsh-custom-update

upgrade_custom() {
  printf '\033[0;34m%s\033[0m\n' "Upgrading the custom files"
  pushd "$ZSH_CUSTOM" >/dev/null
  if git pull --rebase --stat origin master
  then
    printf '\033[0;32m%s\033[0m\n' '                _                  '
    printf '\033[0;32m%s\033[0m\n' '  ___  ___ __ _| | ___  _ __ __ _  '
    printf '\033[0;32m%s\033[0m\n' ' / __|/ __/ _` | |/ _ \| |__/ _` | '
    printf '\033[0;32m%s\033[0m\n' ' \__ \ ❨_| ❨_| | | ❨_❩ | | | ❨_| | '
    printf '\033[0;32m%s\033[0m\n' ' |___/\___\__,_|_|\___/|_|  \__,_| '
    printf '\033[0;32m%s\033[0m\n' '                                   '
    printf '\033[0;34m%s\033[0m\n' 'Hooray! The custom files have been updated and/or are at the current version.'
  else
    printf '\033[0;31m%s\033[0m\n' 'There was an error updating. Try again later? You can trigger an update with: upgrade_custom'
  fi
  popd >/dev/null
}

upgrade_custom_update() {
  echo -n "$1" >! $ts_file
}

upgrade_custom_check() {
  local ts
  local prev='missing-ts'
  if [[ -f $ZSH/.git/FETCH_HEAD ]] ; then
    if [[ "$OSTYPE" == darwin* ]]; then
      ts=$(stat -f '%Sm' $ZSH/.git/FETCH_HEAD || echo 'missing' )
    else
      ts=$(stat -c %y $ZSH/.git/FETCH_HEAD || echo 'missing' )
    fi

    if [[ -f $ts_file ]] ; then
      prev=$(cat $ts_file)
    fi

    if [[ $ts != $prev ]] ; then
      upgrade_custom_update "$ts"
      upgrade_custom    
    fi
  fi
}

upgrade_custom_check

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# theme color vars

colors

#use extended color pallete if available
if [[ $TERM = *256color* || $TERM = *rxvt* ]]; then
    turquoise="%F{81}"
    orange="%F{166}"
    purple="%F{135}"
    hotpink="%F{161}"
    limegreen="%F{118}"
else
    turquoise="$fg[cyan]"
    orange="$fg[yellow]"
    purple="$fg[magenta]"
    hotpink="$fg[red]"
    limegreen="$fg[green]"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# style section

zstyle ':vcs_info:*' enable git svn
zstyle ':vcs_info:*:prompt:*' check-for-changes true

PR_RST="%{${reset_color}%}"
FMT_BRANCH="(%{$turquoise%}%b%u%c${PR_RST})"
FMT_ACTION="(%{$limegreen%}%a${PR_RST})"
FMT_UNSTAGED="%{$orange%}●"
FMT_STAGED="%{$limegreen%}●"

zstyle ':vcs_info:*:prompt:*' unstagedstr   "${FMT_UNSTAGED}"
zstyle ':vcs_info:*:prompt:*' stagedstr     "${FMT_STAGED}"
zstyle ':vcs_info:*:prompt:*' actionformats "${FMT_BRANCH}${FMT_ACTION}"
zstyle ':vcs_info:*:prompt:*' formats       "${FMT_BRANCH}"
zstyle ':vcs_info:*:prompt:*' nvcsformats   ""

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# custom hooks

function z_custom_preexec {
    case "$(history $HISTCMD)" in
        *git*)
            PR_GIT_UPDATE=1
            ;;
        *svn*)
            PR_GIT_UPDATE=1
            ;;
    esac
}
add-zsh-hook preexec z_custom_preexec

function z_custom_chpwd {
    PR_GIT_UPDATE=1
}
add-zsh-hook chpwd z_custom_chpwd

function z_custom_precmd {
    if [[ -n "$PR_GIT_UPDATE" ]] ; then
        # check for untracked files or updated submodules, since vcs_info doesn't
        if git ls-files --other --exclude-standard 2> /dev/null | grep -q "."; then
            PR_GIT_UPDATE=1
            FMT_BRANCH="(%{$turquoise%}%b%u%c%{$hotpink%}●${PR_RST})"
        else
            FMT_BRANCH="(%{$turquoise%}%b%u%c${PR_RST})"
        fi
        zstyle ':vcs_info:*:prompt:*' formats "${FMT_BRANCH} "

        vcs_info 'prompt'
        PR_GIT_UPDATE=
    fi
}
add-zsh-hook precmd z_custom_precmd

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# virtual environment info

function virtualenv_info {
    [ $VIRTUAL_ENV ] && echo '('$fg[blue]`basename $VIRTUAL_ENV`%{$reset_color%}') '
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# detect remote connections

# detect if this is a remote connection
remote=0
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ $PPID -eq 0 ]; then
  remote=1
else
  case $(ps -o comm= -p $PPID) in
    sshd|*/sshd) 
      remote=1
    ;;
  esac
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# host colors

local_color=${ZLOCALCOLOR:-$orange}
remote_color=${ZREMOTECOLOR:-$bg[green]$fg[black]}
[[ $remote = 1 ]] && PAD=" " || PAD=""
[[ $remote = 1 ]] && ZHOST_COLOR="$remote_color" || ZHOST_COLOR="$local_color"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# override system names

OVERRIDE_SYSNAME=${PROMPT_SYS_NAME:-$ZSYSNAME}
ZSYSNAME=${OVERRIDE_SYSNAME:-$(echo $(hostname) | cut -d "." -f1)}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# final prompt

PROMPT=$'
%{$purple%}%n%{$reset_color%} on %{$ZHOST_COLOR%}%{$PAD%}$ZSYSNAME%{$PAD%}%{$reset_color%} at %{$turquoise%}%T%{$reset_color%} in %{$limegreen%}%~%{$reset_color%} $vcs_info_msg_0_$(virtualenv_info)%{$reset_color%}
${ZPTAIL-$ }'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# final return status prompt

# R=$fg[red]
# G=$fg[green]
# M=$fg[magenta]
# RB=$fg_bold[red]
# YB=$fg_bold[yellow]
# BB=$fg_bold[blue]
# RESET=$reset_color

export RPS1="%(?..%{$fg_bold[yellow]%}%? ↵%{$reset_color%})"


