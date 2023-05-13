#!/usr/bin/env bash

[ "$(id -u)" -eq 0 ] && { echo "Run $0 as yourself (not as root), exiting"; exit 1; }

cd "${0%/*}" || exit 2

sudo sed -i 's/^#Color$/Color/' /etc/pacman.conf
sudo sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sudo pacman -S --noconfirm --needed etckeeper git > /dev/null 2>&1
if [ ! -d /etc/.git ] ; then
    pushd /etc || exit 3
    sudo etckeeper init
    sudo git config user.email "root@$(hostname)"
    sudo git config user.name "root"
    sudo etckeeper commit 'Initial commit'
    popd
fi
if ! sudo snapper list > /dev/null ; then
    sudo pacman -S --noconfirm --needed snap-pac snapper > /dev/null 2>&1
    sudo sed -i 's/^#\[root\]$/[root]/' /etc/snap-pac.ini
    sudo sed -i 's/^#important_packages/important_packages/' /etc/snap-pac.ini
    # sudo sed -i 's/^#important_commands/important_commands/' /etc/snap-pac.ini
    sudo sed -i 's/^important_commands.*/important_commands = ["pacman -Syu", "pacman --sync -y -u --"]/' /etc/snap-pac.ini
    sudo umount /.snapshots
    sudo rmdir /.snapshots
    sudo snapper --config root create-config /
    sudo btrfs subvolume delete /.snapshots
    sudo mkdir /.snapshots
    sudo mount -a
    sudo chmod 750 /.snapshots
    sudo chown :wheel /.snapshots
    sudo sed -i 's/^ALLOW_GROUPS=.*/ALLOW_GROUPS="wheel"/' /etc/snapper/configs/root
    sudo snapper --config root create --description 'Initial @ snapshot'
    sudo snapper --config home create-config /home
    sudo sed -i 's/^ALLOW_GROUPS=.*/ALLOW_GROUPS="wheel"/' /etc/snapper/configs/home
    sudo snapper --config home create --description 'Initial @home snapshot'
    sudo pacman -S --noconfirm --needed grub-btrfs inotify-tools rsync > /dev/null 2>&1
    sudo systemctl enable --now grub-btrfsd.service
    sudo systemctl enable --now snapper-cleanup.timer
    sudo systemctl enable --now snapper-timeline.timer
    sudo systemctl enable --now systemd-boot-update
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    if [ ! -e /etc/pacman.d/hooks/95-bootbackup.hook ] ; then
        sudo mkdir -p /etc/pacman.d/hooks
        {
            echo "[Trigger]"
            echo "Operation = Upgrade"
            echo "Operation = Install"
            echo "Operation = Remove"
            echo "Type = Path"
            echo "Target = usr/lib/modules/*/vmlinuz"
            echo ""
            echo "[Action]"
            echo "Depends = rsync"
            echo "Description = Backing up /boot..."
            echo "When = PostTransaction"
            echo "Exec = /usr/bin/rsync -a --delete /boot/ /.bootbackup/"
        } | sudo tee /etc/pacman.d/hooks/95-bootbackup.hook
        sudo mkdir -p /.bootbackup
        sudo rsync -a --delete /boot/ /.bootbackup/
    fi
fi

sudo pacman -S --noconfirm --needed base-devel btrfs-progs edk2-shell efibootmgr gptfdisk inetutils man-db man-pages parted > /dev/null 2>&1
sudo cp /usr/share/edk2-shell/x64/Shell.efi /boot/shellx64.efi
sudo pacman -S --noconfirm --needed acpi bat colordiff diff-so-fancy fzf keychain lsof mc mosh myrepos openssh pipx pyenv syncthing tailscale tmux vcsh vim z zsh > /dev/null 2>&1
sudo systemctl enable --now sshd.service
sudo systemctl enable --now tailscaled
systemctl --user enable --now syncthing.service

mkdir -p ~/.cache/AUR
mkdir -p ~/.config/customizepkg
grep AURDEST             ~/.exports > /dev/null || grep AURDEST             ~/.bashrc > /dev/null || echo "export AURDEST=~/.cache/AUR" >> ~/.bashrc
grep CUSTOMIZEPKG_CONFIG ~/.exports > /dev/null || grep CUSTOMIZEPKG_CONFIG ~/.bashrc > /dev/null || echo "export CUSTOMIZEPKG_CONFIG=~/.config/customizepkg" >> ~/.bashrc

command -v paru > /dev/null || ( cd ~/.cache/AUR && git clone https://aur.archlinux.org/paru-bin.git && cd paru-bin && makepkg -si )

export AURDEST=~/.cache/AUR
# paru customizepkg-git
if [ ! -d "$HOME/.cache/AUR/customizepkg-git" ] ; then
    paru customizepkg-git
fi

export CUSTOMIZEPKG_CONFIG=~/.config/customizepkg
if [ ! -e ~/.config/paru/paru.conf ] ; then
    mkdir -p ~/.config/paru
    {
        echo "[options]"
        echo "BottomUp"
        echo "[bin]"
        echo "PreBuildCommand = customizepkg --modify"
    } >> ~/.config/paru/paru.conf
fi

# # paru aura-bin
# paru console-solarized-git
# paru snapper-rollback
# paru ttf-ms-fonts
# # paru ttf-ms-win10 ttf-ms-win11 ttf-defenestration
# paru update-grub
# paru vi-vim-symlink
# # paru yay-bin

AUR_PKG="aurutils
autofs
brave-bin
console-solarized-git
dropbox
duplicacy
gnome-icon-theme
k3sup-bin
liquidprompt
pyenv-virtualenv
qpdfview
simplescreenrecorder
snapper-rollback
stack-static
ttf-iosevka
ttf-ms-fonts
update-grub
vi-vim-symlink"
while read -r AUR_PKG; do
    if [ ! -d "$HOME/.cache/AUR/$AUR_PKG" ] ; then
        paru $AUR_PKG
    fi
done <<EOF
$AUR_PKG
EOF

echo "" && ip a | grep 'inet ' && echo "" && echo "ssh from bethel to complete setup"
