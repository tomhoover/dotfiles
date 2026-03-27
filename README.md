bootstrap a new system:

- Copy desired private repos (gnupg ssh private-vcsh) from IRONKEY to ~/git/

- Recommended: Clone the repo locally, then run the bootstrap script:

  ```bash
  git clone https://github.com/tomhoover/dotfiles.git ~/.dotfiles
  ~/.dotfiles/script/bootstrap
  ```

- Alternative (`curl | bash`) — less transparent, skips version control:

  ```bash
  curl https://raw.githubusercontent.com/tomhoover/dotfiles/master/script/bootstrap | bash
  ```

  ⚠️ **Caution**: Review scripts before running them with `curl | bash`. Prefer
  cloning locally to inspect code and track versions via git.
