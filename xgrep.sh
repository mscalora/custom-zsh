# source to add xgrep frontend functions

xgrep () {
  $ZSH_CUSTOM/xgrep.py "$@" >/tmp/xgrep.sh 2>/tmp/xgrep.err
  if [ -s /tmp/xgrep.err ] ; then
    echo -e "$(tput setaf 1)$(cat /tmp/xgrep.err)$(tput sgr0)"
  fi
  source /tmp/xgrep.sh
}

dgrep () {
  $ZSH_CUSTOM/xgrep.py "$@" --debug >/tmp/xgrep.sh 2>/tmp/xgrep.err
  if [ -s /tmp/xgrep.err ] ; then
    echo -e "$(tput setaf 1)$(cat /tmp/xgrep.err)$(tput sgr0)"
  fi
  source /tmp/xgrep.sh
}
