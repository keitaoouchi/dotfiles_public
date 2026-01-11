# Chezmoi移行計画

## 概要

現在のシンボリックリンクベースのdotfilesシステムをchezmoiに移行し、1Password統合でシークレット管理を一元化します。

**移行方針:**
- 一括移行（段階的でなく、一度にすべて移行）
- Dockerテスト環境で十分検証してから本番適用
- ~/.dotfiles_private を1Password統合に置き換え

## 主要な変更点

### 1. シークレット管理の変更
**現状:** `~/.dotfiles_private/secret.sh` で環境変数をexport（主にGITHUBトークン等）
**移行後:** chezmoi + 1Password CLIでテンプレート内から直接シークレット参照

### 2. インストール方法の変化
**現状:** `./start.sh` で一括インストール + シンボリックリンク作成
**移行後:** `chezmoi init --apply` で設定ファイル配置 + スクリプト自動実行

### 3. ファイル配置方法
**現状:** `~/.dotfiles_public/*` → `~/.*` へシンボリックリンク
**移行後:** `~/.local/share/chezmoi/*` → `~/.*` へ実ファイルコピー（chezmoiが管理）

## 移行対象ファイル

| ファイル | テンプレート化 | 理由 |
|---------|---------------|------|
| gitconfig | ✓ (`.tmpl`) | 1Password統合（user.name, user.email, signingkey）+ プラットフォーム別GPGパス |
| gitignore_global | ✗ | 静的ファイル |
| bash_profile | ✗ | シンプルなsourcing処理のみ |
| bashrc | ✓ (`.tmpl`) | プラットフォーム別パス（Homebrew等）+ 1Password統合 |
| alias.sh | ✗ | 静的なエイリアス定義 |
| tmux.conf | ✗ | 静的設定 |
| my.cnf | ✗ | 静的設定（privateフラグ付き） |

## 重要な修正点

### bashrc内のsecret.sh実行
- **現状:** `$HOME/.dotfiles_private/secret.sh` を実行（内部でexport）
- **修正:** 1Password統合に置き換え
  ```bash
  # 旧: $HOME/.dotfiles_private/secret.sh
  # 新: テンプレート内で直接参照
  export GITHUB_TOKEN="{{ onepasswordRead "op://Private/secrets/github_token" }}"
  ```

### mise use -g usage の削除
- **現状:** `start.sh:56` で `mise use -g usage` を実行
- **修正:** 削除（形骸化した古いプラグイン）

## 実装ステップ

### フェーズ1: 1Passwordセットアップ

1. **1Password Vaultに項目を作成**
   ```
   Vault: Private

   Item: dotfiles
   ├─ git_name: keita.oouchi
   ├─ git_email: keita.oouchi@gmail.com
   └─ git_signing_key: ssh-ed25519 AAAAC3Nza...

   Item: secrets
   ├─ github_token: ghp_xxxxx
   └─ (その他のsecret.sh内の環境変数)
   ```

2. **1Password CLI インストール・認証**
   ```bash
   # macOS
   brew install --cask 1password-cli

   # Linux
   curl -sSfo op.zip https://cache.agilebits.com/dist/1P/op2/pkg/v2.23.0/op_linux_amd64_v2.23.0.zip
   unzip -od /usr/local/bin/ op.zip

   # 認証
   eval $(op signin)
   ```

### フェーズ2: chezmoiディレクトリ構造の作成

```
~/.local/share/chezmoi/
├── .chezmoi.toml.tmpl                    # chezmoi設定（1Password有効化）
├── .chezmoiignore                        # プラットフォーム別除外ファイル
├── .chezmoidata/
│   └── packages.yaml                     # パッケージリスト
├── .chezmoiscripts/
│   ├── run_once_before_10-install-prerequisites.sh.tmpl
│   ├── run_once_before_20-install-1password-cli.sh.tmpl
│   ├── run_onchange_after_30-install-packages.sh.tmpl
│   ├── run_onchange_after_40-install-starship.sh.tmpl
│   ├── run_onchange_after_50-install-mise.sh.tmpl
│   ├── run_onchange_after_60-install-fonts.sh.tmpl
│   └── run_once_after_70-configure-shell.sh.tmpl
├── dot_gitconfig.tmpl                    # 1Password統合版gitconfig
├── dot_gitignore_global
├── dot_bash_profile
├── dot_bashrc.tmpl                       # プラットフォーム別 + 1Password統合
├── dot_tmux.conf
├── dot_config/
│   └── private_my.cnf
└── alias.sh                              # bashrcからsourceされる
```

### フェーズ3: テンプレートファイルの作成

#### `.chezmoi.toml.tmpl`
```toml
{{- $email := onepasswordRead "op://Private/dotfiles/git_email" -}}
{{- $name := onepasswordRead "op://Private/dotfiles/git_name" -}}

[data]
  email = {{ $email | quote }}
  git_name = {{ $name | quote }}

[data.homebrew]
{{- if eq .chezmoi.os "darwin" }}
  prefix = "/opt/homebrew"
{{- end }}
```

#### `dot_gitconfig.tmpl`
```ini
[user]
  name = {{ onepasswordRead "op://Private/dotfiles/git_name" }}
  email = {{ onepasswordRead "op://Private/dotfiles/git_email" }}
  signingkey = {{ onepasswordRead "op://Private/dotfiles/git_signing_key" }}

[commit]
  gpgsign = true

[gpg]
  format = ssh

[gpg "ssh"]
{{- if eq .chezmoi.os "darwin" }}
  program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign
{{- else if eq .chezmoi.os "linux" }}
  program = /usr/bin/op-ssh-sign
{{- end }}

# 以下、既存のgitconfig内容をそのままコピー
[color]
  ui = auto
  # ...
```

#### `dot_bashrc.tmpl`
```bash
# aliasの設定
source $HOME/.dotfiles_public/alias.sh

# 1Passwordからのシークレット（旧: ~/.dotfiles_private/secret.sh）
export GITHUB_TOKEN="{{ onepasswordRead "op://Private/secrets/github_token" }}"
# その他のsecret.sh内の環境変数を追加

# macOS固有設定
{{- if eq .chezmoi.os "darwin" }}
export BASH_SILENCE_DEPRECATION_WARNING=1
export PATH={{ .homebrew.prefix }}/bin:{{ .homebrew.prefix }}/sbin:$PATH
java_macos_integration_enable=yes
{{- end }}

# go
if [ ! -d $HOME/.go ]; then
  mkdir $HOME/.go
fi
export GOPATH=$HOME/.go
export PATH=$GOPATH/bin:$PATH

# rust
if [ -d $HOME/.cargo/bin ]; then
  export PATH=$PATH:$HOME/.cargo/bin
fi

# starship
if [ -x "$(command -v starship)" ]; then
  eval "$(starship init bash)"
  starship preset pure-preset -o ~/.config/starship.toml
fi

# mcfly
if [ -x "$(command -v mcfly)" ]; then
  eval "$(mcfly init bash)"
fi

# bash completion
{{- if eq .chezmoi.os "darwin" }}
[[ -r "{{ .homebrew.prefix }}/etc/profile.d/bash_completion.sh" ]] && . "{{ .homebrew.prefix }}/etc/profile.d/bash_completion.sh"
{{- else if eq .chezmoi.os "linux" }}
[[ -r "/usr/share/bash-completion/bash_completion" ]] && . "/usr/share/bash-completion/bash_completion"
{{- end }}

# mise
eval "$({{ .chezmoi.homeDir }}/.local/bin/mise activate bash)"

# OrbStack
source ~/.orbstack/shell/init.bash 2>/dev/null || :
```

#### `.chezmoidata/packages.yaml`
```yaml
packages:
  common:
    - curl
    - git
    - jq
    - openssl
    - tmux
  darwin:
    - bash
    - bash-completion@2
  linux:
    - bash-completion
    - xz-utils

fonts:
  darwin: "font-hack-nerd-font"
  linux: "FiraCode"
```

### フェーズ4: インストールスクリプトの作成

#### `run_onchange_after_30-install-packages.sh.tmpl`
```bash
#!/usr/bin/env bash
set -e

{{- if eq .chezmoi.os "darwin" }}
if ! command -v brew &> /dev/null; then
  echo "Error: Homebrew not installed. Install from https://brew.sh"
  exit 1
fi
brew install {{ range .packages.common }}{{ . }} {{ end }} {{ range .packages.darwin }}{{ . }} {{ end }}
{{- else if eq .chezmoi.os "linux" }}
sudo apt update -y
sudo apt install -y {{ range .packages.common }}{{ . }} {{ end }} {{ range .packages.linux }}{{ . }} {{ end }}
{{- end }}
```

#### `run_onchange_after_50-install-mise.sh.tmpl`
```bash
#!/usr/bin/env bash
set -e

if ! command -v mise &> /dev/null; then
  curl https://mise.run | sh
fi

eval "$({{ .chezmoi.homeDir }}/.local/bin/mise activate bash)"
# 注: "mise use -g usage" は削除（形骸化したコマンド）
```

#### `run_once_after_70-configure-shell.sh.tmpl`
```bash
#!/usr/bin/env bash
set -e

{{- if eq .chezmoi.os "darwin" }}
# macOSの古いbashからHomebrewのbashに切り替え
HOMEBREW_BASH="{{ .homebrew.prefix }}/bin/bash"

if ! grep -q "$HOMEBREW_BASH" /etc/shells; then
  echo "$HOMEBREW_BASH" | sudo tee -a /etc/shells
fi

if [ "$SHELL" != "$HOMEBREW_BASH" ]; then
  chsh -s "$HOMEBREW_BASH"
fi
{{- end }}
```

### フェーズ5: Dockerテスト環境の作成

#### `Dockerfile.chezmoi`
```dockerfile
FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# 最小限の依存関係をインストール
RUN apt-get update && apt-get install -y \
    sudo curl git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 非rootユーザーを作成
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/testuser

# chezmoiをインストール
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

WORKDIR /home/testuser
USER testuser

# モック1Password CLI（テスト用）
RUN mkdir -p /home/testuser/.local/bin && \
    cat > /home/testuser/.local/bin/op << 'EOF' && \
#!/bin/bash
case "$*" in
  *"dotfiles/git_name"*) echo "keita.oouchi" ;;
  *"dotfiles/git_email"*) echo "keita.oouchi@gmail.com" ;;
  *"dotfiles/git_signing_key"*) echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILedvy851ijbMSuMqlZ7uIxtRUCHb8iewwRbftRu1Rty" ;;
  *"secrets/github_token"*) echo "ghp_test_token_1234567890" ;;
  *) echo "test-value" ;;
esac
EOF
    chmod +x /home/testuser/.local/bin/op

ENV PATH="/home/testuser/.local/bin:$PATH"

# chezmoiソースディレクトリをコピー（テスト時）
COPY --chown=testuser:testuser . /home/testuser/.local/share/chezmoi

ENTRYPOINT ["/bin/bash"]
```

### フェーズ6: テスト実行

```bash
# イメージビルド
docker build -f Dockerfile.chezmoi -t dotfiles-chezmoi-test .

# コンテナ起動
docker run -it dotfiles-chezmoi-test

# コンテナ内でchezmoi適用
chezmoi init --apply --verbose

# 検証
ls -la ~/
cat ~/.gitconfig
git config --list | grep user
which starship mise tmux
```

### フェーズ7: 本番移行

#### 移行前チェックリスト
- [ ] 現在のdotfilesをバックアップ
  ```bash
  tar -czf ~/dotfiles-backup-$(date +%Y%m%d-%H%M%S).tar.gz \
    ~/{.gitconfig,.gitignore_global,.bash_profile,.bashrc,.tmux.conf} \
    ~/.config/my.cnf ~/.dotfiles_private/
  ```
- [ ] 1Password Vaultに全シークレットを登録
- [ ] 1Password CLIで認証成功を確認: `op item list --vault Private`
- [ ] Dockerテストで全検証項目パス

#### 移行手順
1. **既存のシンボリックリンクを削除**
   ```bash
   rm -f ~/.gitconfig ~/.gitignore_global ~/.bash_profile ~/.bashrc ~/.tmux.conf
   ```

2. **chezmoiリポジトリをプッシュ（事前にGitHubへ）**
   ```bash
   cd ~/.local/share/chezmoi
   git init
   git add .
   git commit -m "Migrate to chezmoi with 1Password integration"
   git remote add origin https://github.com/keitaoouchi/dotfiles_public.git
   git push -u origin feature/chezmoi
   ```

3. **本番環境でchezmoi初期化**
   ```bash
   # 旧dotfilesをリネーム
   mv ~/.dotfiles_public ~/.dotfiles_public.old

   # 1Password CLI認証
   eval $(op signin)

   # chezmoi適用
   chezmoi init --apply https://github.com/keitaoouchi/dotfiles_public.git

   # 新しいシェルを起動
   exec bash -l
   ```

## 検証計画

### 必須検証項目

**Git設定:**
```bash
git config user.name    # → keita.oouchi (from 1Password)
git config user.email   # → keita.oouchi@gmail.com (from 1Password)
git config commit.gpgsign  # → true

# テストコミット
cd /tmp && git init test-repo && cd test-repo
echo "test" > test.txt
git add test.txt
git commit -m "Test GPG signing"
git log --show-signature  # GPG署名を確認
```

**Bash環境:**
```bash
# エイリアス
alias la  # → ls -la
alias git # → git-switch-trainer（あれば）

# ツール
which starship mise tmux jq git
starship --version
mise --version

# プラットフォーム別パス
echo $PATH | grep -E "(homebrew|local)"  # macOS: homebrew, Linux: local
```

**Tmux:**
```bash
tmux new -s test
# C-q でプレフィックスキーが反応するか確認
# | と - でペイン分割を確認
```

**シークレット:**
```bash
# 環境変数が設定されているか（値は表示しない）
[ -n "$GITHUB_TOKEN" ] && echo "✓ GITHUB_TOKEN loaded" || echo "✗ Missing"
```

**chezmoi状態:**
```bash
chezmoi diff  # → 差分なし
chezmoi managed | wc -l  # → 7ファイル以上
```

### 成功基準

- [ ] 全7設定ファイルがホームディレクトリに配置
- [ ] Git設定が1Passwordから読み込まれている
- [ ] GPG署名でコミットできる
- [ ] Starship promptが表示される
- [ ] mise, tmux, jq等のツールがインストール済み
- [ ] tmuxのプレフィックスキーがC-q
- [ ] エイリアスが機能する
- [ ] GITHUB_TOKEN等の環境変数が設定されている
- [ ] `chezmoi diff` で差分なし
- [ ] プラットフォーム固有の設定が正しい（macOS: Homebrewパス、Linux: apt）

## ロールバックプラン

問題が発生した場合：

```bash
# chezmoi状態を退避
mv ~/.local/share/chezmoi ~/.local/share/chezmoi.backup

# 旧dotfilesに戻す
mv ~/.dotfiles_public.old ~/.dotfiles_public
cd ~/.dotfiles_public
./start.sh

# バックアップから復元（必要なら）
tar -xzf ~/dotfiles-backup-*.tar.gz -C ~/
```

## 移行後のメンテナンス

### dotfilesの変更
```bash
# 方法1: chezmoiエディタで編集
chezmoi edit ~/.bashrc

# 方法2: 直接編集してre-add
vim ~/.bashrc
chezmoi re-add ~/.bashrc

# 適用
chezmoi apply

# コミット
cd ~/.local/share/chezmoi
git add .
git commit -m "Update bashrc"
git push
```

### 他マシンへの同期
```bash
chezmoi update  # ≒ git pull && chezmoi apply
```

### シークレット更新
1Passwordでシークレット変更後：
```bash
chezmoi apply --force
source ~/.bash_profile
```

## クリティカルファイル

実装時に重点的に確認すべきファイル：

1. **start.sh** - インストールロジックを複数スクリプトに分解
2. **bashrc** - プラットフォーム別ロジック + 1Password統合
3. **gitconfig** - ユーザー情報の1Password統合
4. **Dockerfile** - chezmoiテスト環境への変換
5. **alias.sh** - git-switch-trainerの条件付きエイリアス

## タイムライン見積もり

- **フェーズ1-2（1Passwordセットアップ + chezmoi構造作成）:** 1-2時間
- **フェーズ3-4（テンプレート + スクリプト作成）:** 2-3時間
- **フェーズ5-6（Dockerテスト）:** 1-2時間
- **フェーズ7（本番移行 + 検証）:** 1-2時間

**合計:** 5-9時間（複数セッションに分けて実行可能）

## 参考資料

- [chezmoi Documentation](https://www.chezmoi.io/)
- [1Password CLI Documentation](https://developer.1password.com/docs/cli/)
- [chezmoi + 1Password Integration](https://www.chezmoi.io/user-guide/password-managers/1password/)
