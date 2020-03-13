if type rg >/dev/null ; then

  if ! type search_all_up >/dev/null ; then
    source $ZSH_CUSTOM/utils.sh
  fi

  if ! type rg_local >/dev/null ; then
    if which rg >/dev/null ; then

      rgplus () {
        FOUND="$(search_all_up .ripgreprc search_up .rgrc search_up ripgrep.config || echo $HOME/.ripgreprc)"
        if [[ -f "$FOUND" ]] ; then
        if [[ "$*" =~ --dry-run ]] ; then
          echo RIPGREP_CONFIG_PATH="$FOUND" rg "$@"
        else
          RIPGREP_CONFIG_PATH="$FOUND" command rg "$@"
        fi
        else
        if [[ "$*" =~ --dry-run ]] ; then
          echo rg "$@"
        else
          command rg "$@"
        fi
        fi
      }

      alias xg=rgplus
      alias xgrep=rgplus

      if which compdefd >/dev/null ; then
        compdef _rg rgplus=rg
      fi

    fi
  fi
fi