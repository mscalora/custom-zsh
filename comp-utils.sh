# Resolve alias/command → which → real source → load matching completion
load_completion() {
    local cmd="$1"
    [[ -z "$cmd" ]] && { echo "Usage: load_completion <name>"; return 1 }

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
    local comp="$dir/completions/${name}.zsh"

    if [[ -f "$comp" ]]; then
        source "$comp"
        return 0
    else
        echo "No completion found: $comp"
        return 1
    fi
}