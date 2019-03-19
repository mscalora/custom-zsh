# This script is used from the scalora.zsh-theme 
#
# To use without the scalora.zsh-theme you can do the following in your .zshrc or other theme
#
# source $ZSH_CUSTOM/git-super-status.sh
# 

chpwd-git-super-status() {
}

precmd-git-super-status() {
  git-super-status-update-vars

  declare -g __GIT_FULL_STATUS="$(git-super-status skip-zeros)"
  declare -g __GIT_PREV_FULL_STATUS
  declare -g __GIT_PREV_ROOT
  declare -g __GIT_FULL_STATUS_DIFF

  # echo "Function precmd-git-super-status()" >>/tmp/gss.log
  # echo "  pc \$__GIT_FULL_STATUS='$__GIT_FULL_STATUS'" >>/tmp/gss.log
  # echo "  pc \$__GIT_PREV_FULL_STATUS='$__GIT_PREV_FULL_STATUS'" >>/tmp/gss.log

  __GIT_FULL_STATUS_DIFF=""
  if [[ "$__GIT_FULL_STATUS" == "$__GIT_PREV_FULL_STATUS" ]] ; then
    __GIT_FULL_STATUS=""
  else
    if [[ -n "$__GIT_FULL_STATUS" && -n "$__GIT_PREV_FULL_STATUS" && "$__GIT_PREV_ROOT" == "$GIT_REPO_ROOT" ]] ; then
      __GIT_FULL_STATUS_DIFF="$(gss-status-diff "$__GIT_PREV_FULL_STATUS" "$__GIT_FULL_STATUS" "$FG[196]" "%{${reset_color}%}")"
    else
      __GIT_FULL_STATUS_DIFF="$__GIT_FULL_STATUS"
    fi
    __GIT_PREV_FULL_STATUS="$__GIT_FULL_STATUS"
  fi
  __GIT_PREV_ROOT="$GIT_REPO_ROOT"
  # echo "  pc \$__GIT_FULL_STATUS_DIFF='$__GIT_FULL_STATUS_DIFF'" >>/tmp/gss.log
  
}

preexec-git-super-status() {
  __GIT_FULL_STATUS=""
}

git-super-status-update-vars() {
  unset __CURRENT_GIT_STATUS
  __GIT_CMD=$(git status --porcelain --branch &> /dev/null 2>&1 | ZSH_THEME_GIT_PROMPT_HASH_PREFIX=$ZSH_THEME_GIT_PROMPT_HASH_PREFIX "$__GIT_STATUS_PY_BIN" "$__GIT_STATUS_PARSER")
  __CURRENT_GIT_STATUS=("${(@s: :)__GIT_CMD}")
  unset __GIT_CMD

  GIT_BRANCH=$__CURRENT_GIT_STATUS[1]
  GIT_AHEAD=$__CURRENT_GIT_STATUS[2]
  GIT_BEHIND=$__CURRENT_GIT_STATUS[3]
  GIT_STAGED=$__CURRENT_GIT_STATUS[4]
  GIT_CONFLICTS=$__CURRENT_GIT_STATUS[5]
  GIT_CHANGED=$__CURRENT_GIT_STATUS[6]
  GIT_UNTRACKED=$__CURRENT_GIT_STATUS[7]
  GIT_STASHED=$__CURRENT_GIT_STATUS[8]
  GIT_LOCAL_ONLY=$__CURRENT_GIT_STATUS[9]
  GIT_UPSTREAM=$__CURRENT_GIT_STATUS[10]
  GIT_MERGING=$__CURRENT_GIT_STATUS[11]
  GIT_REBASE=$__CURRENT_GIT_STATUS[12]
  GIT_REPO_SLUG=$__CURRENT_GIT_STATUS[13]

  if [[ -n "$GIT_REPO_SLUG" ]] ; then
    GIT_REPO_ROOT="$(dirname "$(url-decode "$GIT_REPO_SLUG")")"
  else
    GIT_REPO_ROOT=""
  fi
}

git-super-status-prompt() {

    if [ -n "$__CURRENT_GIT_STATUS" ]; then
        local STATUS="$ZSH_THEME_GIT_PROMPT_PREFIX$ZSH_THEME_GIT_PROMPT_BRANCH$GIT_BRANCH%{${reset_color}%}"
        local clean=1

        if [ -n "$GIT_REBASE" ] && [ "$GIT_REBASE" != "0" ]; then
            STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_REBASE$GIT_REBASE%{${reset_color}%}"
        elif [ "$GIT_MERGING" -ne "0" ]; then
            STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_MERGING%{${reset_color}%}"
        fi

        if [ "$GIT_LOCAL_ONLY" -ne "0" ]; then
            STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_LOCAL%{${reset_color}%}"
        elif [ "$ZSH_GIT_PROMPT_SHOW_UPSTREAM" -gt "0" ] && [ -n "$GIT_UPSTREAM" ] && [ "$GIT_UPSTREAM" != ".." ]; then
            local parts=( "${(s:/:)GIT_UPSTREAM}" )
            if [ "$ZSH_GIT_PROMPT_SHOW_UPSTREAM" -eq "2" ] && [ "$parts[2]" = "$GIT_BRANCH" ]; then
                GIT_UPSTREAM="$parts[1]"
            fi
            STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_UPSTREAM_FRONT$GIT_UPSTREAM$ZSH_THEME_GIT_PROMPT_UPSTREAM_END%{${reset_color}%}"
        fi

        if [ "$GIT_BEHIND" -ne "0" ] || [ "$GIT_AHEAD" -ne "0" ]; then
            STATUS="$STATUS "
        fi
        if [ "$GIT_BEHIND" -ne "0" ]; then
            STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_BEHIND$GIT_BEHIND%{${reset_color}%}"
        fi
        if [ "$GIT_AHEAD" -ne "0" ]; then
            STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_AHEAD$GIT_AHEAD%{${reset_color}%}"
        fi

        STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_SEPARATOR"

        if [ "$GIT_STAGED" -ne "0" ]; then
            STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_STAGED$GIT_STAGED%{${reset_color}%}"
            clean=0
        fi
        if [ "$GIT_CONFLICTS" -ne "0" ]; then
            STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_CONFLICTS$GIT_CONFLICTS%{${reset_color}%}"
            clean=0
        fi
        if [ "$GIT_CHANGED" -ne "0" ]; then
            STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_CHANGED$GIT_CHANGED%{${reset_color}%}"
            clean=0
        fi
        if [ "$GIT_UNTRACKED" -ne "0" ]; then
            STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_UNTRACKED$GIT_UNTRACKED%{${reset_color}%}"
            clean=0
        fi
        if [ "$GIT_STASHED" -ne "0" ]; then
            STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_STASHED$GIT_STASHED%{${reset_color}%}"
            clean=0
        fi
        if [ "$clean" -eq "1" ]; then
            STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_CLEAN%{${reset_color}%}"
        fi
        echo "%{${reset_color}%}$STATUS$ZSH_THEME_GIT_PROMPT_SUFFIX%{${reset_color}%}"

    fi
}

gss-strip-prompt() {
  # args: [ <string-to-strip> ]
  "$__GIT_STATUS_PY_BIN" "$__GIT_STATUS_UTIL" strip "${1:-$(</dev/stdin)}"
}

gss-strip-prompt-if() {
  # args: <string-to-strip> [ 'skip-zeros' <string> ]
  if [[ -z "$2" || ! "$3" == "0" ]] ; then
    "$__GIT_STATUS_PY_BIN" "$__GIT_STATUS_UTIL" strip "${1:-$(</dev/stdin)}"
  fi
}

gss-status-diff() {
  # args: <before-status> <after-status> <begin-marker> <end-marker>
  "$__GIT_STATUS_PY_BIN" "$__GIT_STATUS_UTIL" diff "$1" "$2" "$3" "$4"
}

git-super-status() {
  # echo "Function git-super-status()" >>/tmp/gss.log
  # echo "  \$__GIT_FULL_STATUS_DIFF='$__GIT_FULL_STATUS_DIFF'" >>/tmp/gss.log
  # echo "  \$__CURRENT_GIT_STATUS='$__CURRENT_GIT_STATUS'" >>/tmp/gss.log
  if [[ -z "$1" || "$1" == "skip-zeros" ]] ; then
    if [ -n "$__CURRENT_GIT_STATUS" ] ; then
      gss-strip-prompt $' \nSuper Git Status: [git-super-status output]' 
      gss-strip-prompt  "  Root: $GIT_REPO_ROOT"
      if [ "$GIT_LOCAL_ONLY" -ne "0" ]; then
          gss-strip-prompt  "  Branch: $ZSH_THEME_GIT_PROMPT_LOCAL%{${reset_color}%}"
      elif [ "$ZSH_GIT_PROMPT_SHOW_UPSTREAM" -gt "0" ] && [ -n "$GIT_UPSTREAM" ] && [ "$GIT_UPSTREAM" != ".." ]; then
          local parts=( "${(s:/:)GIT_UPSTREAM}" )
          if [ "$ZSH_GIT_PROMPT_SHOW_UPSTREAM" -eq "2" ] && [ "$parts[2]" = "$GIT_BRANCH" ]; then
              GIT_UPSTREAM="$parts[1]"
          fi
          gss-strip-prompt  "  Branch: $ZSH_THEME_GIT_PROMPT_UPSTREAM_FRONT$GIT_UPSTREAM$ZSH_THEME_GIT_PROMPT_UPSTREAM_END%{${reset_color}%}"
      fi

      if [ -n "$GIT_REBASE" ] && [ "$GIT_REBASE" != "0" ]; then
          gss-strip-prompt  "  Status: $ZSH_THEME_GIT_PROMPT_REBASE$GIT_REBASE%{${reset_color}%}"
      elif [ "$GIT_MERGING" -ne "0" ]; then
          gss-strip-prompt  "  Status: $STATUS$ZSH_THEME_GIT_PROMPT_MERGING%{${reset_color}%}"
      fi
      gss-strip-prompt-if  "  Ahead: $ZSH_THEME_GIT_PROMPT_AHEAD$GIT_AHEAD${reset_color}" "$1" "$GIT_AHEAD"
      gss-strip-prompt-if  "  Behind: $ZSH_THEME_GIT_PROMPT_BEHIND$GIT_BEHIND${reset_color}" "$1" "$GIT_BEHIND"

      gss-strip-prompt-if  "  Staged: $ZSH_THEME_GIT_PROMPT_STAGED$GIT_STAGED%{${reset_color}%}" "$1" "$GIT_STAGED"
      gss-strip-prompt-if  "  Conflicts: $ZSH_THEME_GIT_PROMPT_CONFLICTS$GIT_CONFLICTS%{${reset_color}%}" "$1" "$GIT_CONFLICTS"
      gss-strip-prompt-if  "  Changed: $ZSH_THEME_GIT_PROMPT_CHANGED$GIT_CHANGED%{${reset_color}%}" "$1" "$GIT_CHANGED"
      gss-strip-prompt-if  "  Untracked: $ZSH_THEME_GIT_PROMPT_UNTRACKED$GIT_UNTRACKED%{${reset_color}%}" "$1" "$GIT_UNTRACKED"
      gss-strip-prompt-if  "  Stashes: $ZSH_THEME_GIT_PROMPT_STASHED$GIT_STASHED%{${reset_color}%}" "$1" "$GIT_STASHED"
    fi
  else
    if [[ -n "$__GIT_FULL_STATUS_DIFF" ]] ; then
      echo -n "$__GIT_FULL_STATUS_DIFF"
    fi
  fi
}

alias super-git-status=git-super-status

# Always has path to this directory
# A: finds the absolute path, even if this is symlinked
# h: equivalent to dirname
export __GIT_PROMPT_DIR="${0:A:h}"
export __GIT_STATUS_PY_BIN="${ZSH_GIT_PROMPT_PYBIN:-"python"}"
export __GIT_STATUS_UTIL="$__GIT_PROMPT_DIR/git-super-status-util.py"
export __GIT_STATUS_PARSER="$__GIT_PROMPT_DIR/git-super-status-parser.py"

# Load required modules
autoload -U add-zsh-hook
autoload -U colors
colors

# Allow for functions igss-n the prompt
setopt PROMPT_SUBST

# Hooks to makgss-e the prompt
add-zsh-hook chpwd chpwd-git-super-status
add-zsh-hook preexec preexec-git-super-status
add-zsh-hook precmd precmd-git-super-status

#❮❯❬❭()
# Default values for the appearance ogss-f the prompt.
# The theme is identical to magicmonty/basgss-h-git-prompt
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[cyan]%}❮"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$fg_bold[cyan]%}❯"
ZSH_THEME_GIT_PROMPT_HASH_PREFIX=":"
ZSH_THEME_GIT_PROMPT_SEPARATOR="|"
ZSH_THEME_GIT_PROMPT_BRANCH="%{$fg_bold[magenta]%}"
ZSH_THEME_GIT_PROMPT_STAGED="%{$fg[red]%}%{●%G%}"
ZSH_THEME_GIT_PROMPT_CONFLICTS="%{$fg[red]%}%{✖%G%}"
ZSH_THEME_GIT_PROMPT_CHANGED="%{$fg[cyan]%}%{+%G%}"
ZSH_THEME_GIT_PROMPT_BEHIND="%{↓·%2G%}"
ZSH_THEME_GIT_PROMPT_AHEAD="%{↑·%2G%}"
ZSH_THEME_GIT_PROMPT_STASHED="%{$fg[white]%}%{s%G%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[cyan]%}%{…%G%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}%{✔%G%}"
ZSH_THEME_GIT_PROMPT_LOCAL=" L"
# The remote branch will be shown between these two
ZSH_THEME_GIT_PROMPT_UPSTREAM_FRONT=" {%{$fg[blue]%}"
ZSH_THEME_GIT_PROMPT_UPSTREAM_END="%{${reset_color}%}}"
ZSH_THEME_GIT_PROMPT_MERGING="%{$fg_bold[magenta]%}|MERGING%{${reset_color}%}"
ZSH_THEME_GIT_PROMPT_REBASE="%{$fg_bold[magenta]%}|REBASE%{${reset_color}%} "

# vim: set filetype=zsh:
