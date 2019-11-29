# source to add url-encode and url-decode

# see https://stackoverflow.com/a/29565580/370746 & https://stackoverflow.com/a/35512655/370746

url-encode() {
  if [[ "$1" == "-h" || "$1" == "-?" || "$1" == "--help" ]] ; then
    echo "  URL Encodes first argument or stdin"
    echo "  Usage: url-encode [ <string> ]"
    echo "  Example: url-encode 'This & that!'"
    echo "  Output: This%20%26%20that%21"
  else
    if which python >/dev/null ; then local py=python ; else local py=python3 ; fi
    "$py" -c $'try: import urllib.parse as urllib\nexcept: import urllib\nimport sys\nprint(urllib.quote(sys.argv[1]))' "${1:-$(</dev/stdin)}"
  fi
}

url-decode() {
  if [[ "$1" == "-h" || "$1" == "-?" || "$1" == "--help" ]] ; then
    echo "  Decodes URL encoded first argument or stdin"
    echo "  Usage: url-decode [ <string> ]"
    echo "  Examle: url-decode This%20%26%20that%21"
    echo "  Output: This & that!"
  else
    if which python >/dev/null ; then local py=python ; else local py=python3 ; fi
    "$py" -c $'try: import urllib.parse as urllib\nexcept: import urllib\nimport sys\nprint(urllib.unquote(sys.argv[1]))' "${1:-$(</dev/stdin)}"
  fi
}
