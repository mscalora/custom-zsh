
search_all_up() {
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
