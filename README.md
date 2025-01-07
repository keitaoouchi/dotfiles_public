### Getting Started

- homebrew入れる
    ```
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```
- SSHエージェント設定
  - 1Passwordをインストールする
  - `vim ~/.config/1Password/ssh/agent.toml` して `vault` を適当な保管庫名に設定
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