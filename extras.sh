#
# Set the ZSH_CUSTOM_EXTRAS to any non-null value to load extras on startup
#


if [ "$(uname)" = "Darwin" ] ; then
  # Mac only aliases
  ZSH_CUSTOM_MAC=1

  who-is-listening () {
    echo "Listening on port ${1:-80}:"
    lsof -nP -i4TCP | egrep '^COMMAND\s*PID|LISTEN' | egrep --color ".*:${1:-80}.*LISTEN.*|$" || echo "$(tput setaf 1)no one$(tput sgr0)"
  }
else
  # Linux only aliases
  ZSH_CUSTOM_LINUX=1

  who-is-listening () {
    netstat -ltn | egrep ".*:${1:-80}.*|$" --color || echo "$(tput setaf 1)no one$(tput sgr0)"
  }
fi
