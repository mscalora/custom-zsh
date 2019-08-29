#! /usr/bin/env zsh
# to help editors with syntax coloring etc.

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
# autoload function setup

FPATH=$ZSH_CUSTOM/functions:$FPATH

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# theme aliases

ts() {
  date +"%Y-%m-%dT%H:%M:%S"
}

tss() {
  python -c "import datetime ; print datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3]"
}

hist() {
  CI=""
  if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]] ; then
    echo "Usage:"
    echo "    $0 [ -i ] <number>       - show last <number> items"
    echo "    $0 [ -i ] <regexp>       - search history for <regexp>"
    echo "    $0 [ -i ] <regexp> <number>  - show last <number> items that match <regexp>"
    echo "    $0 [ -i ] <number> <regexp>  - search last <number> items for <regexp>"
    echo "    $0 [ -i ] <regexp1> <regexp2>  - search history for <regexp1> AND <regexp2>"
    echo "    $0 <number1> <number2>     - show <number2> items starting at <number1>"
    echo ""
    echo "  Options:"
    echo "    -i         - use case insensitive search for regexp"
    echo "    --help -h or -?  - show this help"
    echo ""
  elif [[ "$1" == "-e" || "$1" == "--edit" ]] ; then
    fc -W
    if [[ -e ~/temp ]] ; then
      BACKUP_HISTORY=~/temp/zsh_history-backup-$(date "+%Y%m%d").txt
    else
      BACKUP_HISTORY=/tmp/zsh_history-backup-$(date "+%Y%m%d").txt
    fi
    cp ~/.zsh_history $BACKUP_HISTORY
    printf '\033[0;34m%s\033[0;32m%s\033[0m\n' "ZSH command history backed up to " "$BACKUP_HISTORY"
    nano +999999 ~/.zsh_history
    fc -R
  else
    if [[ "$1" == "-i" ]] then
      CI="-i"
      shift
    fi
    if [[ "$1" == "" ]] ; then
      echo "Last 50 history items"
      history | tail -n 50
    elif [[ $1 =~ ^[0-9]+$ ]] ; then
      if [[ "$2" == "" ]] ; then
        echo "Last $1 history items"
        history | tail -n $1
      elif [[ "$2" =~ ^[0-9]+$ ]] ; then
        echo "History items $1 through $(( $1 + $2 ))"
        history | head -n $(( $1 + $2 )) | tail -n $2
      else
        echo "Last $1 history items that also match $2"
        history | tail -n $1 | egrep $CI $2
      fi
    else
      if [[ "$2" == "" ]] ; then
        echo "History items that match $1"
        history | egrep $CI $1
      elif [[ "$2" =~ ^[0-9]+$ ]] ; then
        echo "Last $2 matches of $1 in history"
        history | egrep $CI $1 | tail -n $2
      else
        echo "History items that match $1 and $2"
        history | egrep $CI $1 | egrep $CI $2
      fi
    fi
  fi
}

# platform specific aliases

if [ "$(uname)" = "Darwin" ] ; then
  # Mac only aliases
  alias usb="ioreg -p IOUSB"
else
  # Linux only aliases
  alias usb=lsusb
fi

autoload -Uz modify-current-argument

toggle-path-py() {
  REPLY="$(python - $1 <<EOF
"Toggle between relative and absolute path, surrounding quotes or initial quote"
import os, sys
a = sys.argv[1]
f = a[:1]
e = ''
if f == '~':
  a = os.path.expanduser(a)
  f = ''
elif f == '"' or f == "'":
  a = a[1:]
  if a[-1:] == f:
    e = f
    a = a[:-1]
else:
  f = ''
b = os.path.relpath(a) if a[:1] == '/' else os.path.abspath(a)
sys.stdout.write(f+b+e)
EOF
)"
}

toggle-path() {
  modify-current-argument toggle-path-py
}

zle -N toggle-path
bindkey "å" toggle-path    # OPTION-a
bindkey "\ea" toggle-path  # ESC-a

toggle-case() {
  if [[ "$1" =~ '^[^a-z]*$' ]] ; then
    REPLY="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  else
    REPLY="$(echo "$1" | tr '[:lower:]' '[:upper:]')"
  fi
}

toggle-case-word() {
  modify-current-argument toggle-case
}

toggle-case-all() {
  toggle-case "$BUFFER"
  BUFFER="$REPLY"
}

zle -N toggle-case-word
zle -N toggle-case-all
bindkey "¬" toggle-case-word  # OPTION-l
bindkey "Ò" toggle-case-all   # OPTION-SHIFT-L

swap-quotes() {
  if [[ "$1" =~ "[\"']" ]] ; then
    REPLY="$( echo -n "$1" | tr "\"'" "'\"")"
  else
    REPLY="'$1'"
  fi
}

swap-quotes-word() {
  modify-current-argument swap-quotes
}

swap-quotes-all() {
  BUFFER="$( echo -n "$BUFFER" | tr "\"'" "'\"")"
}

zle -N swap-quotes-all
zle -N swap-quotes-word
bindkey "Œ" swap-quotes-all  # OPTION-SHIFT-Q
bindkey "œ" swap-quotes-word # OPTION-q

send-to-history() {
  print -S "$BUFFER"
  BUFFER=
}

zle -N send-to-history
bindkey '˙' send-to-history # options-h

autoload -Uz zle-delete-last-parameter
zle -N zle-delete-last-parameter
bindkey '∑' zle-delete-last-parameter  # option w

insert-date() {
  LBUFFER="$LBUFFER$(date '+%Y-%m-%d')"
}

insert-date-time() {
  LBUFFER="$LBUFFER$(date '+%Y-%m-%d-%H:%M:%S')"
}

zle -N insert-date
zle -N insert-date-time
bindkey '∂' insert-date # options-d
bindkey 'Î' insert-date # options-shift-d

keys() {
  local KG="$(tput sgr0)$(tput setaf 2)"
  local KBG="$(tput sgr0)$(tput bold)$(tput setaf 2)"
  local KC="$(tput sgr0)$(tput setaf 6)"
  local KR="$(tput sgr0)"
  echo ""
  echo "$KG===== THEME SHORTCUTS ====="
  echo ""
  echo "$KBG       OPTION-a -$KC asolute-path - toggle path between absolute and relative, expands ~, etc"
  echo "$KR"
  echo "$KBG       OPTION-h -$KC Send command line to history and clear"
  echo "$KR"
  echo "$KBG       OPTION-l -$KC toggle the case of the current word"
  echo "$KBG SHIFT-OPTION-l -$KC toggle the case of the whole command line"
  echo "$KR"
  echo "$KBG       OPTION-q -$KC quote the current word or toggle the quote type if already quoted"
  echo "$KBG SHIFT-OPTION-Q -$KC toggle all of the existing quotes on the command line"
  echo "$KR"
  echo "$KBG       OPTION-w -$KC remove the last parameter on the command line"
  echo "$KR"
  echo "$KBG       OPTION-d -$KC insert the date YYYY-MM-DD into the command line at the cursor"
  echo "$KBG SHIFT-OPTION-D -$KC insert the date YYYY-mm-dd-HH:MM:SS into the command line at the cursor"
  echo "$KR"
  echo "$KBG       OPTION-z -$KC undo the last command line change (try '!!' tab, then OPTION-z)"
  echo "$KBG SHIFT-OPTION-Z -$KC redo the last command line change"
  echo "$KR"
  echo "$KG===== ZSH SHORTCUTS REMINDER ====="
  echo ""
  echo "$KBG         CTRL-q -$KC \"kill line\" clear the command line, (NOTE †: OPTION-z to undo!)"
  echo "$KBG         CTRL-w -$KC \"kill word\" delete the word to the left †"
  echo "$KBG         CTRL-k -$KC \"kill right\" clear the command line right of the cursor †"
  echo "$KBG         CTRL-u -$KC \"kill left\" clear the command line left of the cursor †"
  echo "$KBG    OPTION-LEFT -$KC move left one word"
  echo "$KBG   OPTION-RIGHT -$KC move right one word"
 }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# smart alias type functions

export NATIVE_CODE="$(which code 2>/dev/null)"

code() {
  if [[ $REMOTE_SESSION == 1 ]] ; then
    ${EDITOR:?nano} $*
  elif [ -x "$NATIVE_CODE" ] ; then
    "$NATIVE_CODE" $*
  elif [ -d "/Applications/Visual Studio Code.app" ] ; then
    open -a "/Applications/Visual Studio Code.app" $*
  elif [ -d "/Applications/Code.app" ] ; then
    open -a "/Applications/Code.app" $*
  else
    open "https://code.visualstudio.com/download"
  fi
}

wls() {
  if [[ "$1" == "" ]] ; then
    printf "Usage:  wls <command>\n"
    return
  fi
  if ! type "$1" ; then
    return
  fi
  local ctype="$(type "$1")"
  if [[ "$ctype" =~ " not found" ]] ; then
    echo "NOT FOUND"
  elif [[ "$ctype" =~ " is an alias" ]] ; then
    echo "ALIAS"
  elif [[ "$ctype" =~ " is a shell function" ]] ; then
    echo "FUNCTION"
  elif [[ "$ctype" =~ " is a shell builtin" ]] ; then
    echo "SHELL BUILTIN"
  elif [[ "$ctype" =~ " is " ]] ; then
    echo "PROGRAM IN PATH"
    local cpath="$(which "$1")"
    ls -la "$cpath"
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# autoload stuff

autoload setup-nanorc
[ ! -f ~/.nanorc ] && setup-nanorc
unset -f setup-nanorc

autoload ssh-clear
autoload dur

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# command options

# syntax coloring if gnu 
# Mac: brew install source-highlight
# apt: sudo apt-get install source-highlight
if hash src-hilite-lesspipe.sh 2>/dev/null; then
  export LESSOPEN="| $(which src-hilite-lesspipe.sh) %s"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# custom keys

bindkey "\x1b\x1b\x5b\x41" beginning-of-line  # option up for iTerm
bindkey "\x1b\x1b\x5b\x42" end-of-line        # option down for iTerm
bindkey "\x1b\x1b\x5b\x43" forward-word       # option right for iTerm
bindkey "\x1b\x1b\x5b\x44" backward-word      # option left for iTerm

bindkey "^[[:u" undo
bindkey "Ω" undo
bindkey "^[[:r" redo
bindkey "¸" redo

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# for extra completions, any .inc file in plugins is included

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
# git stuff

PRRST="$FX[reset]"
source $ZSH_CUSTOM/git-super-status.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# mike's special extras

if [[ "$HOME" =~ 'mscalora|app' || ! -z "$ZSH_CUSTOM_EXTRAS" ]] ; then
  source $ZSH_CUSTOM/extras.sh
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# virtual environment info

virtualenv_info() {
    [ $VIRTUAL_ENV ] && echo '('$fg[blue]`basename $VIRTUAL_ENV`$PRRST') '
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# detect remote connections

# detect if this is a remote connection
export REMOTE_SESSION=0
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ $PPID -eq 0 ]; then
  export REMOTE_SESSION=1
else
  case $(ps -o comm= -p $PPID) in
    su|sshd|*/sshd) 
      export REMOTE_SESSION=1
    ;;
  esac
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# host colors

local_color=${ZLOCALCOLOR:-$orange}
remote_color=${ZREMOTECOLOR:-$bg[green]$fg[black]}
[[ $REMOTE_SESSION = 1 ]] && PAD=" " || PAD=""
[[ $REMOTE_SESSION = 1 ]] && ZHOST_COLOR="$remote_color" || ZHOST_COLOR="$local_color"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# override system names

OVERRIDE_SYSNAME=${PROMPT_SYS_NAME:-$ZSYSNAME}
ZSYSNAME=${OVERRIDE_SYSNAME:-$(echo $(hostname) | cut -d "." -f1)}

if [[ "$(ps -o comm= -p $PPID)" == "su" ]] ; then
  SUING="su as "
else
  SUING=""
fi

UNAME="$SUING%n"
if [[ "$(whoami)" == "root" ]] ; then
  UNAME="$bg[red]$fg[yellow] $SUING%n "
fi

if ! declare -f extra_user_prompt > /dev/null ; then 
  extra_user_prompt() {
    echo -n '' 
    # redefine this function to display something additional in your prompt
    # for example, put the following line in your ~/.zshrc
    #   extra_user_prompt() { echo -n 'Node ' ; node --version }
    # to show your currently install version of node
  }
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# final prompt

XUSER_DEFAULT="$(tput bold)$(tput setaf 3)"
XUSER="${XUSERCOLOR:-$XUSER_DEFAULT}"

PROMPT=$'$(git-super-status 1)
%{$purple%}$UNAME$PRRST on %{$ZHOST_COLOR%}%{$PAD%}$ZSYSNAME%{$PAD%}$PRRST at %{$turquoise%}%T$PRRST in %{$limegreen%}%~$PRRST $(git-super-status-prompt)$(virtualenv_info)$PRRST%{$XUSER%}$(extra_user_prompt)$PRRST
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

export RPS1="%(?..%{$fg_bold[yellow]%}%? ↵$PRRST)"
