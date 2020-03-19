if type rg >/dev/null ; then

  _rg_search_all_up() {
    # extended from https://stackoverflow.com/a/19011599/370746
    local look=${PWD%/}
    while [[ -n $look ]]; do
        for name ; do
          [[ -e $look/$name ]] && {
              printf '%s\n' "$look/$name"
              return
          }
        done
        look=${look%/*}
    done
    [[ -e /$1 ]] && echo /
  }


  if ! type rgplus >/dev/null ; then
    if type rg >/dev/null ; then

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

      if type compdef >/dev/null ; then
        compdef xg=rg
        compdef xgrep=rg
        compdef rgplus=rg
      fi

    fi
  fi
fi