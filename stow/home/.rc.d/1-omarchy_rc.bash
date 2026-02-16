# shellcheck shell=bash

# All the default Omarchy aliases and functions
if isomarchy; then
    #sed -i -e 's/\w*eval "$(starship init bash)"/  true/' .local/share/omarchy/default/bash/init
    #sed -i -e 's/\w*eval "$(try init ~\/Work\/tries)"/  true/' .local/share/omarchy/default/bash/init
    sed -i -Ee 's/(^source ~\/.local\/share\/omarchy\/default\/bash\/init)/# \1/' ~/.local/share/omarchy/default/bash/rc
    # shellcheck disable=SC1090
    source ~/.local/share/omarchy/default/bash/rc
fi
