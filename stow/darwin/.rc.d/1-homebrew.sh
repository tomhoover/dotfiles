# shellcheck shell=bash disable=SC1090

if command -v brew &>/dev/null; then
    # instruct Homebrew to return to pre-4.0.0 behaviour by cloning the Homebrew/homebrew-core tap during installation
    # https://docs.brew.sh/Installation
    export HOMEBREW_NO_INSTALL_FROM_API=1

    # for brew bump-formula-pr
    export HOMEBREW_DEVELOPER=1

    # # https://github.com/Homebrew/homebrew-command-not-found
    # HB_CNF_HANDLER="$(brew --repository)/Library/Taps/homebrew/homebrew-command-not-found/handler.sh"
    # if [ -f "$HB_CNF_HANDLER" ]; then source "$HB_CNF_HANDLER"; fi

    # Homebrew
    # To enable command-not-found
    # Add the following lines to ~/.zshrc
    HOMEBREW_COMMAND_NOT_FOUND_HANDLER="$(brew --repository)/Library/Homebrew/command-not-found/handler.sh"
    if [ -f "$HOMEBREW_COMMAND_NOT_FOUND_HANDLER" ]; then
        source "$HOMEBREW_COMMAND_NOT_FOUND_HANDLER"
    fi

    # The following PATH definition is required, as .zshrc prepends the MacPorts PATH
    # (PATH="/opt/local/bin:/opt/local/sbin:$PATH"), which places it at a higher
    # precedence than homebrew
    export PATH="$HOME/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

    if [ "$SHEL" = zsh ]; then
        # ==> zsh-completions
        # To activate these completions, add the following to your .zshrc:
        #
        #   if type brew &>/dev/null; then
        #     FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
        #
        #     autoload -Uz compinit
        #     compinit
        #   fi
        #
        # You may also need to force rebuild `zcompdump`:
        #
        #   rm -f ~/.zcompdump; compinit
        #
        # Additionally, if you receive "zsh compinit: insecure directories" warnings when attempting
        # to load these completions, you may need to run these commands:
        #
        #   chmod go-w '/opt/homebrew/share'
        #   chmod -R go-w '/opt/homebrew/share/zsh'

        # fpath=($(brew --prefix)/share/zsh/site-functions $fpath)
        # FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
        # fpath=($(brew --prefix)/share/zsh-completions $fpath)
        FPATH=$(brew --prefix)/share/zsh-completions:$(brew --prefix)/share/zsh/site-functions:$FPATH
    else
        # # TODO
        # # Add tab completion for many Bash commands
        # if which brew > /dev/null && [ -f "$(brew --prefix)/etc/bash_completion" ]; then
        #     source "$(brew --prefix)/etc/bash_completion";
        # elif [ -f /etc/bash_completion ]; then
        #     source /etc/bash_completion;
        # fi;

        # # homebrew bash completions
        # if type brew &>/dev/null; then
        #   HOMEBREW_PREFIX="$(brew --prefix)"
        #   if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then
        #     source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
        #   else
        #     for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*; do
        #       [[ -r "$COMPLETION" ]] && source "$COMPLETION"
        #     done
        #   fi
        # fi

        [[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && source "/opt/homebrew/etc/profile.d/bash_completion.sh"
    fi
    # homebrew automatically installs tailscale cli in /opt/homebrew/bin/tailscale,
    #   so this alias is no longer needed
    # tailscale
    # alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

    # If you're going to build Homebrew formulae from source that link against
    # Python like Tkinter or NumPy (This is only generally the case if you are a
    # developer of such a formula, or if you have an EOL version of MacOS for which
    # prebuilt bottles are no longer provided and you are using such a formula).
    #
    # To avoid them accidentally linking against a Pyenv-provided Python, add the
    # following line into your interactive shell's configuration:
    # alias brew='env PATH="${PATH//$(pyenv root)\/shims:/}" brew'
    # remove .asdf/shims, as well as .pyenv/shims
    # alias brew='env PATH="${PATH//:*\/shims:/:}" brew'
    # alias brew='env PATH="${PATH//:*\\/shims:/:}" brew'

    # # homebrew: ccze has been disabled because it has an archived upstream repository
    # # https://howchoo.com/g/mzm3ztdhm2u/how-to-colorize-your-logs-with-ccze
    # function tailc() {
    #     tail $@ | ccze -A
    # }

fi
