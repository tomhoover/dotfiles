# shellcheck shell=bash
[ "${DOTFILE_DEBUG:-}" ] && echo "$(date '+%Y-%m-%d %H:%M') :: :: FUNCTIONS_LOADED" | tee -a /tmp/shell-init.txt
[ "${DOTFILE_DEBUG:-}" ] && echo "$PATH" >>/tmp/shell-init.txt
export FUNCTIONS_LOADED=1

# Simple calculator
calc() {
  local result=""
  result="$(printf "scale=10;%s\n" "$*" | bc --mathlib | tr -d '\\\n')"
  #                       └─ default (when `--mathlib` is used) is 20
  #
  if [[ "$result" == *.* ]]; then
    # improve the output for decimal numbers
    printf "%s" "$result" \
      | sed -e 's/^\./0./' `# add "0" for cases like ".5"` \
        -e 's/^-\./-0./' `# add "0" for cases like "-.5"` \
        -e 's/0*$//;s/\.$//' # remove trailing zeros
  else
    printf "%s" "$result"
  fi
  printf "\n"
}

# Create a new directory and enter it
md() {
  mkdir -p "$@" && cd "$_" || return
}

# Change working directory to the top-most Finder window location
cdf() { # short for `cdfinder`
  cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')" || return
}

# Create a .tar.gz archive, using `zopfli`, `pigz` or `gzip` for compression
targz() {
  local tmpFile="${*%/}.tar"
  tar -cvf "${tmpFile}" --exclude=".DS_Store" "${@}" || return 1

  size=$(
    stat -f"%z" "${tmpFile}" 2>/dev/null # OS X `stat`
    stat -c"%s" "${tmpFile}" 2>/dev/null # GNU `stat`
  )

  local cmd=""
  if ((size < 52428800)) && hash zopfli 2>/dev/null; then
    # the .tar file is smaller than 50 MB and Zopfli is available; use it
    cmd="zopfli"
  else
    if hash pigz 2>/dev/null; then
      cmd="pigz"
    else
      cmd="gzip"
    fi
  fi

  echo "Compressing .tar using \`${cmd}\`…"
  "${cmd}" -v "${tmpFile}" || return 1
  [ -f "${tmpFile}" ] && rm "${tmpFile}"
  echo "${tmpFile}.gz created successfully."
}

# # Determine size of a file or total size of a directory
# fs() {
#   if du -b /dev/null >/dev/null 2>&1; then
#     local arg=-sbh
#   else
#     local arg=-sh
#   fi
#   if (($#)); then
#     du $arg -- "$@"
#   else
#     du $arg .[^.]* ./*
#   fi
# }

## Use Git's colored diff when available
#hash git &>/dev/null;
# if [ $? -eq 0 ]; then
#   function diff() {
#     git diff --no-index --color-words "$@";
#   }
# fi;

# Create a data URL from a file
dataurl() {
  local mimeType
  mimeType=$(file -b --mime-type "$1")
  if [[ $mimeType == text/* ]]; then
    mimeType="${mimeType};charset=utf-8"
  fi
  echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

# Create a git.io short URL
gitio() {
  if [ -z "${1}" ] || [ -z "${2}" ]; then
    echo "Usage: \`gitio slug url\`"
    return 1
  fi
  curl -i http://git.io/ -F "url=${2}" -F "code=${1}"
}

# Start an HTTP server from a directory, optionally specifying the port
server() {
  local port="${1:-8000}"
  sleep 1 && open "http://localhost:${port}/" &
  # Set the default Content-Type to `text/plain` instead of `application/octet-stream`
  # And serve everything as UTF-8 (although not technically correct, this doesn't break anything for binary files)
  python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port"
}

# Start a PHP server from a directory, optionally specifying the port
# (Requires PHP 5.4.0+.)
phpserver() {
  local port="${1:-4000}"
  local ip
  ip=$(ipconfig getifaddr en1)
  sleep 1 && open "http://${ip}:${port}/" &
  php -S "${ip}:${port}"
}

# Compare original and gzipped file size
gz() {
  local origsize
  origsize=$(wc -c <"$1")
  local gzipsize
  gzipsize=$(gzip -c "$1" | wc -c)
  local ratio
  ratio=$(echo "$gzipsize * 100 / $origsize" | bc -l)
  printf "orig: %d bytes\n" "$origsize"
  printf "gzip: %d bytes (%2.2f%%)\n" "$gzipsize" "$ratio"
}

# Syntax-highlight JSON strings or files
# Usage: `json '{"foo":42}'` or `echo '{"foo":42}' | json`
json() {
  if [ -t 0 ]; then # argument
    python -mjson.tool <<<"$*" | pygmentize -l javascript
  else # pipe
    python -mjson.tool | pygmentize -l javascript
  fi
}

# Run `dig` and display the most useful info
digga() {
  dig +nocmd "$1" any +multiline +noall +answer
}

# UTF-8-encode a string of Unicode symbols
escape() {
  # shellcheck disable=SC2046
  printf "\\\x%s" $(printf "%s" "$@" | xxd -p -c1 -u)
  # print a newline unless we're piping the output to another program
  if [ -t 1 ]; then
    echo "" # newline
  fi
}

# Decode \x{ABCD}-style Unicode escape sequences
unidecode() {
  perl -e "binmode(STDOUT, ':utf8'); print \"$*\""
  # print a newline unless we're piping the output to another program
  if [ -t 1 ]; then
    echo "" # newline
  fi
}

# Get a character's Unicode code point
codepoint() {
  perl -e "use utf8; print sprintf('U+%04X', ord(\"$*\"))"
  # print a newline unless we're piping the output to another program
  if [ -t 1 ]; then
    echo "" # newline
  fi
}

# Show all the names (CNs and SANs) listed in the SSL certificate
# for a given domain
getcertnames() {
  if [ -z "${1}" ]; then
    echo "ERROR: No domain specified."
    return 1
  fi

  local domain="${1}"
  echo "Testing ${domain}…"
  echo "" # newline

  local tmp
  tmp=$(echo -e "GET / HTTP/1.0\nEOT" \
    | openssl s_client -connect "${domain}:443" -servername "${domain}" 2>&1)

  if [[ "${tmp}" = *"-----BEGIN CERTIFICATE-----"* ]]; then
    local certText
    certText=$(echo "${tmp}" \
      | openssl x509 -text -certopt "no_aux, no_header, no_issuer, no_pubkey, \
      no_serial, no_sigdump, no_signame, no_validity, no_version")
    echo "Common Name:"
    echo "" # newline
    echo "${certText}" | grep "Subject:" | sed -e "s/^.*CN=//" | sed -e "s/\/emailAddress=.*//"
    echo "" # newline
    echo "Subject Alternative Name(s):"
    echo "" # newline
    echo "${certText}" | grep -A 1 "Subject Alternative Name:" \
      | sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2
    return 0
  else
    echo "ERROR: Certificate not found."
    return 1
  fi
}

# `v` with no arguments opens the current directory in Vim, otherwise opens the
# given location
v() {
  if [ $# -eq 0 ]; then
    vim .
  else
    vim "$@"
  fi
}

# `e` with no arguments opens the current directory in $EDITOR, otherwise opens the
# given location
e() {
  if [ $# -eq 0 ]; then
    $EDITOR .
  else
    $EDITOR "$@"
  fi
}

# `o` with no arguments opens the current directory, otherwise opens the given
# location
o() {
  if [ $# -eq 0 ]; then
    open .
  else
    open "$@"
  fi
}

# `tre` is a shorthand for `tree` with hidden files and color enabled, ignoring
# the `.git` directory, listing directories first. The output gets piped into
# `less` with options to preserve color and line numbers, unless the output is
# small enough for one screen.
#    tree -aC -I '.git|node_modules|bower_components' --dirsfirst "$@" | less -FRNX;
tre() {
  tree -aC -I '.git|node_modules|bower_components' --dirsfirst "$@" | less -FRX
}

# unalias grep to allow the following function definition; grml .zshrc sets 'alias grep=grep --color=auto'
unalias grep 2>/dev/null

# add line numbers when when grep is the only command on the line;
# otherwise, omit them when piping thru grep
# https://unix.stackexchange.com/questions/25546/grep-alias-line-numbers-unless-its-in-a-pipeline/25549#25549
grep() {
  if [ -t 1 ] && [ -t 0 ]; then
    command grep --color=auto -n "$@"
  else
    command grep "$@"
  fi
}

# note taking function and command completion
## https://www.reddit.com/r/vim/comments/8xzpkz/you_probably_dont_need_vimwiki/e27k7qv?utm_source=share&utm_medium=web2x
export NOTE_DIR="$HOME/Vault" # no trailing slash
_n() {
  local lis cur
  lis=$(find "${NOTE_DIR}/" -name "*.md" \
    | sed -e "s|${NOTE_DIR}/||" \
    | sed -e 's/\.md$//')
  # shellcheck disable=SC2154
  cur=${comp_words[comp_cword]}
  # shellcheck disable=SC2034,SC2207
  compreply=($(compgen -w "$lis" -- "$cur"))
}
n() {
  : "${NOTE_DIR:?'NOTE_DIR env var not set'}"
  if [ $# -eq 0 ]; then
    local file
    file=$(find -L "${NOTE_DIR}/" -name "*.md" \
      | sed -e "s|${NOTE_DIR}/||" \
      | sed -e 's/\.md$//' \
      | fzf \
        --multi \
        --select-1 \
        --exit-0 \
        --preview="cat ${NOTE_DIR}/{}.md" \
        --preview-window=right:70%:wrap)
    [[ -n $file ]] \
      && ${EDITOR:-vim} "${NOTE_DIR}/${file}.md"
  else
    case "$1" in
      "-d")
        rm "${NOTE_DIR}"/"$2".md
        ;;
      i)
        cd "${NOTE_DIR}" && ${EDITOR:-vim} index.md
        ;;
      *)
        ${EDITOR:-vim} "${NOTE_DIR}"/"$*".md
        ;;
    esac
  fi
}
# complete -f _n n

# journal entry
j() {
  : "${NOTE_DIR:?'NOTE_DIR env var not set'}"
  local note_file
  note_file="${NOTE_DIR}/$(date '+%Y').md"
  local date_time
  date_time="$(date '+%Y-%m-%d %H:%M')"
  printf "\n[%s]\n\n" "${date_time}" >>"${note_file}"
  if [ "$#" -eq 0 ]; then
    if [ -p "/dev/stdin" ]; then
      (
        cat
        printf "\n\n"
      ) >>"${note_file}"
    else
      ${EDITOR:-vim} +10000 "${note_file}"
    fi
  else
    printf "%s\n\n" "$*" >>"${note_file}"
  fi
}

hl() {
  # cd ~/fin/hledger/hoover || return
  # ./export.sh && [ -f "$1.journal" ] && hledger -s -f "$1.journal" "${@:2}" || echo "Syntax: hl xxx[.journal] xx xx xx"
  cd ~/fin/hledger/hoover && ./export.sh || return
  if [ -f "$1.journal" ]; then
    hledger -s -f "$1.journal" "${@:2}"
  else
    hledger -s -f "all.journal" "${@:1}"
  fi
}

mra() {
  cd "$HOME" && mr "${@:1}"
  cd - || return
}

mrs() {
  cd "$HOME/src" && mr "${@:1}"
  cd - || return
}

mrg() {
  cd "$HOME/src/github.com" && mr "${@:1}"
  cd - || return
}

# https://docs.gitignore.io/install/command-line
# bash:
# function gi() { curl -sL https://www.toptal.com/developers/gitignore/api/$@ ;}
# zsh:
gi() { curl -sLw "\n" "https://www.toptal.com/developers/gitignore/api/$*"; }

# local docker registry query
drlist() { curl -sX GET http://bethel:5001/v2/_catalog | jq; }
drtags() { curl -sX GET "http://bethel:5001/v2/$1/tags/list" | jq; }

# grep mrconfig
gmr() {
  grep -in "$@" ~/.mrconfig ~/src/.mrconfig ~/src/gh/.mrconfig ~/src/3dPrinting/.mrconfig ~/.config/mr/*
}
# grep dotfiles
gdot() {
  grep -in "$@" ~/.profile ~/.bash_profile ~/.bashrc ~/.zshenv ~/.zprofile ~/.zshrc ~/.zshrc.local ~/.config/dotfiles/* ~/.dotfiles/stow/**/.rc.d/*
}

# edit mrconfig
emr() {
  if [ "$#" -eq 0 ]; then
    $EDITOR ~/.mrconfig ~/src/.mrconfig ~/src/gh/.mrconfig ~/src/3dPrinting/.mrconfig ~/.config/mr/*
  else
    local -a files
    while IFS= read -r f; do files+=("$f"); done < <(grep -l "$@" ~/.mrconfig ~/src/.mrconfig ~/src/gh/.mrconfig ~/src/3dPrinting/.mrconfig ~/.config/mr/* 2>/dev/null)
    [[ ${#files[@]} -gt 0 ]] && $EDITOR "${files[@]}"
  fi
}
# edit dotfiles
edot() {
  if [ "$#" -eq 0 ]; then
    $EDITOR ~/.profile ~/.bash_profile ~/.bashrc ~/.zshenv ~/.zprofile ~/.zshrc ~/.zshrc.local ~/.config/dotfiles/* ~/.dotfiles/stow/**/.rc.d/*
  else
    local -a files
    while IFS= read -r f; do files+=("$f"); done < <(grep -l "$@" ~/.profile ~/.bash_profile ~/.bashrc ~/.zshenv ~/.zprofile ~/.zshrc ~/.zshrc.local ~/.config/dotfiles/* ~/.dotfiles/stow/**/.rc.d/* 2>/dev/null)
    [[ ${#files[@]} -gt 0 ]] && $EDITOR "${files[@]}"
  fi
}

# https://github.com/jdx/fnox/discussions/320
# usage: fnox-reencrypt default staging dev prod
fnox-reencrypt() {
  if [ $# -eq 0 ]; then echo "Must supply at least one profile (e.g. 'fnox-reencrypt default staging dev prod')"; fi
  for profile in "$@"; do
    fnox list --profile "$profile" | awk '/provider \(age\)/ {print $1}' | while read -r env_key; do
      fnox set "$env_key" "$(fnox get "$env_key" --profile "$profile")" --provider age --profile "$profile"
    done
  done
}

# https://yazi-rs.github.io/docs/quick-start
y() {
  local tmp cwd
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd <"$tmp"
  [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || return
  rm -f -- "$tmp"
}

m() {
  if [ "$#" -eq 0 ]; then
    mise tasks ls
    command make help
  else
    if grep "$@" <<<"$(mise tasks ls)" >/dev/null 2>&1; then
      mise run "$@"
    else
      make "$@"
    fi
  fi
}

ghc() {
  REPO=$(gh repo view "$1" | awk "/^name:/{print \$2}")
  gh repo clone "${REPO}" "${HOME}/src/gh/${REPO}" && cd "${HOME}/src/gh/${REPO}" || return
}

ai() {
  opencode run --agent free "$*"
}

# find file
ff() {
  # fd --hidden -t f -E '[A-Z]*' "$@" ~
  fd --hidden -t f -E 'Library' -g "$*" ~ | sort
}

# find string
fs() {
  # rg --vimgrep "$@" ~/.[!.]* ~/[a-z]* ~/[!A-Za-z]* 2>/dev/null | grep -v '.zsh_history' | sort
  rg --hidden --vimgrep --glob '!.zsh_history' --glob '!Library/**' "$*" ~ 2>/dev/null | sort
}
