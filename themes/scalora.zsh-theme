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
  else
    if [[ "$1" == "-i" ]] then
      CI="-i"
      shift
    fi
    if [[ "$1" == "" ]] ; then
      echo "Last 50 history items"
      history | tail -n 50
    elif [[ $1 =~ [0-9]+ ]] ; then
      if [[ "$2" == "" ]] ; then
        echo "Last $1 history items"
        history | tail -n $1
      elif [[ "$2" =~ [0-9]+ ]] ; then
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
      elif [[ "$2" =~ [0-9]+ ]] ; then
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
bindkey '˙' send-to-history

autoload -Uz zle-delete-last-parameter
zle -N zle-delete-last-parameter
bindkey '∑' zle-delete-last-parameter

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

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# local system setup

setup_nano() {
  cat >>~/.nanorc <<"EOF"
# AUTO CREATED NANORC FILE
set quiet
set autoindent
set constantshow
set positionlog
set tabsize 4
set tabstospaces
set nowrap
set suspend
set titlecolor brightyellow,blue
set statuscolor brightyellow,blue
bind ^S savefile main
bind ^G findnext main
bind M-G findprevious main
set backupdir $HOME/temp/nano-backups

set numbercolor cyan,black
set linenumbers
set keycolor cyan,black
set functioncolor blue,black

# ----- # put personal settings under this line # ----- #

EOF

  if [ ! -d $HOME/temp/nano-backups ] ; then
    mkdir $HOME/temp/nano-backups
  fi

  # try to find the best path to nanorc syntax file files
  find -L /usr/local/share -mount \! -perm -g+r,u+r,o+r -prune -o -name css.nanorc -print | head -n 1 | sed -e 's/css/*/' | sed -e 's/^/include /' >>~/.nanorc

  echo "=================================================="
  echo "A nice .nanorc file was created for you, it won't"
  echo "have any affect unless you run nano. You can turn"
  echo "off all of the affects of this change by running:"
  echo "echo \"#\" >~/.nanorc"
  echo "=================================================="
}

[ ! -f ~/.nanorc ] && setup_nano
#unset -f setup_nano

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# custom keys

bindkey "\x1b\x1b\x5b\x41" beginning-of-line  # option up for iTerm
bindkey "\x1b\x1b\x5b\x42" end-of-line        # option down for iTerm
bindkey "\x1b\x1b\x5b\x43" forward-word       # option right for iTerm
bindkey "\x1b\x1b\x5b\x44" backward-word      # option left for iTerm

bindkey "^[[:u" undo
bindkey "^[[:r" redo

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

z_custom_preexec() {
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

z_custom_chpwd() {
    PR_GIT_UPDATE=1
}
add-zsh-hook chpwd z_custom_chpwd

z_custom_precmd() {
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

virtualenv_info() {
    [ $VIRTUAL_ENV ] && echo '('$fg[blue]`basename $VIRTUAL_ENV`%{$reset_color%}') '
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

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# final prompt

PROMPT=$'
%{$purple%}$UNAME%{$reset_color%} on %{$ZHOST_COLOR%}%{$PAD%}$ZSYSNAME%{$PAD%}%{$reset_color%} at %{$turquoise%}%T%{$reset_color%} in %{$limegreen%}%~%{$reset_color%} $vcs_info_msg_0_$(virtualenv_info)%{$reset_color%}
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
