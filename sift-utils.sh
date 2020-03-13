#!/usr/bin/env bash

if type sift >/dev/null ; then

  TRANSLATIONS=$'
    s/--near/--surrounded-by/g
    s/--not-near/--not-surrounded-by/g
    s/--within/--surrounded-within/g
    s/--not-within/--surrounded-within/g
    s/--before/--preceded-by/g
    s/--not-before/--preceded-by/g
    s/--after/--followed-by/g
    s/--not-after/--followed-by/g
    s/--file-has/--file-matches/g
    s/--file-has/--file-matches/g
  '

  siftplus () {
    local ARGS=()
    local DRY_RUN=
    local ALL_OPTS
    local HELP=

    for ARG ; do
      if [[ $ARG == "--" ]] ; then
        break
      elif [[ $ARG == "--trace" ]] ; then
        local TRACE=1
      fi
    done

    for ARG ; do

      if [[ $TRACE ]] ; then
        echo -e "\nARG=$ARG"
      fi

      if [[ $ARG == "--" || $NO_MORE_OPTIONS ]] ; then
        local NO_MORE_OPTIONS=1
      elif [[ $ARG == "--dry-run" ]] ; then
        DRY_RUN=1
        continue
      elif [[ $ARG == "--trace" ]] ; then
        continue
      elif [[ $ARG == "--help" || $ARG == "-h"  || $ARG == "-?" ]] ; then
        HELP=1
      else
        ARG="$(echo $ARG | sed -e "$TRANSLATIONS")"
      fi

      ARGS+=($ARG)

      if [[ $TRACE ]] ; then
        echo "ARGS=$ARGS"
      fi

    done

    if [[ $DRY_RUN ]] ; then
      echo sift ${ARGS[@]}
    else
      command sift ${ARGS[@]}

      if [[ $HELP ]] ; then
        echo "$(tput setaf 6)Option Aliases$(tput sgr0)"
        echo "$(tput setaf 6)      --near=PATTERN                         same as --surrounded-by$(tput sgr0)"
        echo "$(tput setaf 6)      --within=PATTERN                       same as --surrounded-within$(tput sgr0)"
        echo "$(tput setaf 6)      --before=PATTERN                       same as --preceded-by$(tput sgr0)"
        echo "$(tput setaf 6)      --after=PATTERN                        same as --followed-by$(tput sgr0)"
        echo "$(tput setaf 6)      --file-has=PATTERN                     same as --file-matches$(tput sgr0)"
      fi
    fi
  }

  alias sift=siftplus
  alias sift!='command sift'

#  if which compdefd >/dev/null ; then
#    compdef _siftplus siftplus=sift
#  fi
fi