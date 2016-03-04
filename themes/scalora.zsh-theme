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
# zzzzzzzzzzzz

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
# colors

host_color=${ZLOCALCOLOR:-$orange}

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
[[ $remote = 1 ]] && PAD=" " || PAD=""
[[ $remote = 1 ]] && ZHOST_COLOR="$bg[green]$fg[black]$ZREMOTECOLOR" || ZHOST_COLOR="$host_color"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# override system names

OVERRIDE_SYSNAME=${PROMPT_SYS_NAME:-$ZSYSNAME}
ZSYSNAME=${OVERRIDE_SYSNAME:-$(echo $(hostname) | cut -d "." -f1)}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# zzzzzzzzzzzz

PROMPT=$'
%{$purple%}%n%{$reset_color%} on %{$ZHOST_COLOR%}%{$PAD%}$ZSYSNAME%{$PAD%}%{$reset_color%} at %{$turquoise%}%T%{$reset_color%} in %{$limegreen%}%~%{$reset_color%} $vcs_info_msg_0_$(virtualenv_info)%{$reset_color%}
$ '




