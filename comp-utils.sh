# Resolve alias/command → which → real source → load matching completion
load_completion() {
    local quiet=0 verbose=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -q|--quiet) quiet=1; shift ;;
            -v|--verbose) verbose=1; shift ;;
            -*) echo "Unknown option: $1"; return 1 ;;
            *) break ;;
        esac
    done
    local cmd="$1"
    [[ -z "$cmd" ]] && { echo "Usage: load_completion [-q|--quiet] [-v|--verbose] <name>"; return 1 }

    # Find the real target using which
    local target
    target=$(which "$cmd" 2>/dev/null) || return 1

    # Follow symlinks to the actual file
    if [[ -L "$target" ]]; then
        target=$(readlink -f "$target")
    fi

    # Handle common wrappers like "uv run ..."
    [[ "$target" == *"uv run "* ]] && target=${target##*uv run }

    local dir="${target:h}"
    local name="${target:t:r}"          # basename without .py / .sh etc.

    local comp
    for cand in "$dir/completions/${name}.zsh" "$dir/completions/_${name}" "$dir/completions/_${name}.zsh"; do
        if [[ -f "$cand" ]]; then
            comp="$cand"
            break
        fi
    done

    if [[ -n "$comp" ]]; then
        [[ $verbose -eq 1 ]] && echo "Loaded: $comp"
        source "$comp"
        return 0
    else
        [[ $quiet -eq 0 ]] && echo "No completion found for $name in $dir/completions/"
        return 1
    fi
}

# Completion for load_completion: suggests symlinks (links) in /usr/local/bin
_load_completion() {
    local -a links
    for f in /usr/local/bin/*; do
        [[ -L $f ]] && links+=(${f:t})
    done
    _describe 'links in /usr/local/bin' links
}

compdef _load_completion load_completion