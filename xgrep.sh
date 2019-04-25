# source to add xgrep frontend functions

xgrep () {
  if [ -f /tmp/xgrep.err ] ; then rm /tmp/xgrep.err ; fi
  $ZSH_CUSTOM/xgrep.py "$@" >/tmp/xgrep.sh 2>/tmp/xgrep.err
  if [ -s /tmp/xgrep.err ] ; then
    echo -e "$(tput setaf 1)$(cat /tmp/xgrep.err)$(tput sgr0)"
    return 1
  fi
  source /tmp/xgrep.sh
}

dgrep () {
  if [ -f /tmp/xgrep.err ] ; then rm /tmp/xgrep.err ; fi
  $ZSH_CUSTOM/xgrep.py "$@" --debug >/tmp/xgrep.sh 2>/tmp/xgrep.err
  if [ -s /tmp/xgrep.err ] ; then
    echo -e "$(tput setaf 1)$(cat /tmp/xgrep.err)$(tput sgr0)"
    return 1
  fi
}
