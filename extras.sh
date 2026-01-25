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

# Function to live tail Apache logs with excluded terms
livetailx() {
    # Check if at least one exclude term is provided
    if [[ $# -eq 0 ]]; then
        echo "Usage: livetailx <exclude_term1> [exclude_term2 ...]"
        return 1
    fi

    # Escape dots in exclude terms and join with regex OR (|)
    local exclude_pattern=$(echo "$@" | sed 's/\./\\./g' | tr ' ' '|')

    # Tail all .log files, excluding lines matching the pattern
    tail -f /var/log/apache2/*.log | grep -v -E "$exclude_pattern"
}

json-extract () {
  if [[ "$1" == "" || "$1" == "-h" || "$1" == "-?" || "$1" == "--help" ]] ; then
    echo 'Extract top level property value from json document'
    echo '  Usage: json-extract <property> [ <file-path> ]'
    echo '  Example 1: json-extract status /tmp/response.json'
    echo '  Example 2: echo $JSON_STRING | json-extract status'
    echo '  Status codes: 0 - success, 1 - json parse error, 2 - property missing'
  else
    python3 -c $'import sys, json;\ntry: obj = json.load(open(sys.argv[2])); \nexcept: sys.exit(1)\ntry: v=obj[sys.argv[1]]; print(json.dumps(v) if  isinstance(v, dict) else v)\nexcept: sys.exit(2)' "$1" "${2:-/dev/stdin}"
  fi
}
