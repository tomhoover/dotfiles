[ "${DOTFILE_DEBUG:-}" ] && echo "$(date '+%Y-%m-%d %H:%M') :: :: DARWIN_BASH_PROFILE_LOADED" | tee -a /tmp/shell-init.txt
[ "${DOTFILE_DEBUG:-}" ] && echo "$PATH" >>/tmp/shell-init.txt
export DARWIN_BASH_PROFILE_LOADED=1

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob;

# Append to the Bash history file, rather than overwriting it
shopt -s histappend;

# Autocorrect typos in path names when using `cd`
shopt -s cdspell;

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
    shopt -s "$option" 2> /dev/null;
done;

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2 | tr ' ' '\n')" scp sftp ssh;

# Add tab completion for `defaults read|write NSGlobalDomain`
# You could just use `-g` instead, but I like being explicit
complete -W "NSGlobalDomain" defaults;

# Add `killall` tab completion for common apps
complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter" killall;

[ -r /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv bash)"
[ -r /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv bash)"

[ "${DOTFILE_DEBUG:-}" ] && echo "$(date '+%Y-%m-%d %H:%M') :: :: DARWIN_BASH_PROFILE_ENDED" | tee -a /tmp/shell-init.txt
