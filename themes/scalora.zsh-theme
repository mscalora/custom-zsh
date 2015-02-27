# prompt style and colors based on Steve Losh's Prose theme:
# http://github.com/sjl/oh-my-zsh/blob/master/themes/prose.zsh-theme
#
# vcs_info modifications from Bart Trojanowski's zsh prompt:
# http://www.jukie.net/bart/blog/pimping-out-zsh-prompt
#
# git untracked files modification from Brian Carper:
# http://briancarper.net/blog/570/git-info-in-your-zsh-prompt

function virtualenv_info {
    [ $VIRTUAL_ENV ] && echo '('$fg[blue]`basename $VIRTUAL_ENV`%{$reset_color%}') '
}
PR_GIT_UPDATE=1

setopt prompt_subst
autoload colors
colors

autoload -U add-zsh-hook
autoload -Uz vcs_info

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

# enable VCS systems you use
zstyle ':vcs_info:*' enable git svn

# check-for-changes can be really slow.
# you should disable it, if you work with large repositories
zstyle ':vcs_info:*:prompt:*' check-for-changes true

# set formats
# %b - branchname
# %u - unstagedstr (see below)
# %c - stagedstr (see below)
# %a - action (e.g. rebase-i)
# %R - repository path
# %S - path in the repository
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


function steeef_preexec {
    case "$(history $HISTCMD)" in
        *git*)
            PR_GIT_UPDATE=1
            ;;
        *svn*)
            PR_GIT_UPDATE=1
            ;;
    esac
}
add-zsh-hook preexec steeef_preexec

function steeef_chpwd {
    PR_GIT_UPDATE=1
}
add-zsh-hook chpwd steeef_chpwd

function steeef_precmd {
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
add-zsh-hook precmd steeef_precmd

host_color=$orange$ZLOCALCOLOR
hspc=""

if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  host_color=$bg[green]$fg[black]$ZREMOTECOLOR
  host_space=" "
# many other tests omitted
else
  case $(ps -o comm= -p $PPID) in
    sshd|*/sshd) 
      host_color=$bg[green]$fg[black]$ZREMOTECOLOR
      host_space=" "
    ;;
  esac
fi

if [[ "$PROMPT_SYS_NAME$ZSYSNAME" = "" ]] ; then

PROMPT=$'
%{$purple%}%n%{$reset_color%} on %{$host_color%}%{$host_space%}%m%{$host_space%}%{$reset_color%} at %{$turquoise%}%T%{$reset_color%} in %{$limegreen%}%~%{$reset_color%} $vcs_info_msg_0_$(virtualenv_info)%{$reset_color%}
$ '

else

PROMPT=$'
%{$purple%}%n%{$reset_color%} on %{$host_color%}%{$host_space%]$PROMPT_SYS_NAME$ZSYSNAME%{$host_space%}%{$reset_color%} at %{$turquoise%}%T%{$reset_color%} in %{$limegreen%}%~%{$reset_color%} $vcs_info_msg_0_$(virtualenv_info)%{$reset_color%}
$ '

fi

R=$fg[red]
G=$fg[green]
M=$fg[magenta]
RB=$fg_bold[red]
YB=$fg_bold[yellow]
BB=$fg_bold[blue]
RESET=$reset_color

export return_code_prompt="%(?..%{$YB%}%? ↵%{$RESET%})"
export RPS1="${return_code_prompt}"
