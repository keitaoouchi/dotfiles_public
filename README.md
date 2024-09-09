### Getting Started

- homebrew入れる
    ```
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    ```
- ssh config
  - https://developer.1password.com/docs/ssh/agent/config/#from-the-1password-app
- dotfilesを落としてくる
    ```
    git clone https://github.com/keitaoouchi/dotfiles_public.git .dotfiles_public
    git clone https://github.com/keitaoouchi/dotfiles_private.git .dotfiles_private
    ```
- start.shを実行
    ```bash
    cd .dotfiles_public
    ./start.sh
    ```