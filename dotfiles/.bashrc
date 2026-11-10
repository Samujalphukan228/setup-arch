#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# Created by `pipx` on 2026-04-08 04:42:08
export PATH="$PATH:/home/samujal/.local/bin"
export PATH="$HOME/.cargo/bin:$PATH"




function jump() {
    local tmp
    tmp=$(mktemp)
    ~/.local/bin/jump-bin "$@" --output "$tmp"
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        rm -f "$tmp"
        return 1
    fi
    if [ -s "$tmp" ]; then
        local target
        target=$(cat "$tmp")
        rm -f "$tmp"
        cd "$target" || return 1
    else
        rm -f "$tmp"
    fi
}
alias ss='secret set'
alias sg='secret get'
alias sx='secret copy'
alias sl='secret list'
alias sd='secret delete'
alias sc='secret change-password'

function jump() {
    if [ "$1" = "-" ]; then
        local tmp=$(mktemp)
        ~/.local/bin/jump-bin - --output "$tmp"
        local exit_code=$?
        if [ $exit_code -ne 0 ]; then rm -f "$tmp"; return 1; fi
        if [ -s "$tmp" ]; then
            local target=$(cat "$tmp"); rm -f "$tmp"; cd "$target" || return 1
        else rm -f "$tmp"; fi
        return 0
    fi

    local tmp=$(mktemp)
    ~/.local/bin/jump-bin "$@" --output "$tmp"
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then rm -f "$tmp"; return 1; fi
    if [ -s "$tmp" ]; then
        local target=$(cat "$tmp"); rm -f "$tmp"; cd "$target" || return 1
    else rm -f "$tmp"; fi
}

function exp() {
    local tmp=$(mktemp)
    ~/.local/bin/jump-bin --explore "${1:-.}" --output "$tmp"
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then rm -f "$tmp"; return 1; fi
    if [ -s "$tmp" ]; then
        local target=$(cat "$tmp"); rm -f "$tmp"; cd "$target" || return 1
    else rm -f "$tmp"; fi
}



# jump shell wrapper — v0.4.0
# Directory jumper + file explorer
# Installed into ~/.bashrc or ~/.zshrc by install.sh

JUMP_BIN="${JUMP_BIN:-$HOME/.local/bin/jump-bin}"

_jump_cd() {
    local tmp
    tmp=$(mktemp)
    "$JUMP_BIN" "$@" --output "$tmp"
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        rm -f "$tmp"
        return 1
    fi
    if [ -s "$tmp" ]; then
        local target
        target=$(cat "$tmp")
        rm -f "$tmp"
        cd "$target" || return 1
    else
        rm -f "$tmp"
    fi
}

function jump() {
    if [ "$1" = "-" ]; then
        _jump_cd -
        return $?
    fi
    _jump_cd "$@"
}

function exp() {
    _jump_cd --explore "${1:-.}"
}

# end jump shell wrapper
# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
[[ -r "$HOME/.grok/completions/bash/grok.bash" ]] && source "$HOME/.grok/completions/bash/grok.bash"
# <<< grok installer <<<

# opencode
export PATH=/home/samujal/.opencode/bin:$PATH

# strix
export PATH=/home/samujal/.strix/bin:$PATH
export PATH="$HOME/.local/share/npm/bin:$PATH"
export OLLAMA_API_BASE=http://127.0.0.1:11434
