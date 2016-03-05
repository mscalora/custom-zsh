# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# theme autoloads

autoload colors
autoload -U add-zsh-hook
autoload -Uz vcs_info


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# theme options

PR_GIT_UPDATE=1
setopt prompt_subst

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# theme aliases

alias hist='history | egrep '
alias upgrade_custom='source $ZSH_CUSTOM/tools/upgrade.sh'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# self-update

ts_file=~/.zsh-custom-update

upgrade_custom_update() {
    echo -n "$1" >! $ts_file
}

upgrade_custom_check() {
  if [[ "$OSTYPE" == darwin* ]]; then
	mac=1
	ts=$(stat -f '%Sm' $ZSH/.git/FETCH_HEAD || echo 'missing' )
  else
	mac=0
	ts=$(stat -c %y $ZSH/.git/FETCH_HEAD || echo 'missing' )
  fi

  prev=$( cat $ts_file || echo 'missing' )
  if [[ "$ts" == $( cat $ts_file || echo 'missing' ) ]] ; then
    #echo 'up to date'
  else
    upgrade_custom_update "$ts"
    upgrade_custom    
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
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
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
$ '

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


