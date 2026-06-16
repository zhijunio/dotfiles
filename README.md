# Dotfiles

面向 macOS 的开发环境：通过 **symlink** 管理配置文件，配合 `install.sh`、Homebrew 与 [Brewfile](Brewfile)。

参考 [yasik/dotfiles](https://github.com/yasik/dotfiles)。

## 仓库结构

```
dotfiles/
├── install.sh
├── sync-secrets.sh
├── Brewfile
├── config/                 # symlink → ~/.config/* 或 ~/.ssh/config
│   ├── kaku/kaku.lua
│   ├── git/ignore
│   ├── gh/config.yml
│   └── ssh/config
├── templates/              # secrets 渲染 + gitconfig 模板
```

## 安装

```sh
git clone git@github.com:zhijunio/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
cp templates/secrets.env.example ~/.secrets/env   # 填写真实值
chmod 600 ~/.secrets/env
./install.sh
```

`install.sh` 会配置 macOS / Homebrew / SDKMAN、symlink 配置，并在存在 `~/.secrets/env` 时调用 `sync-secrets.sh`（依赖 `gettext` 提供的 `envsubst`）。

## Secrets 工作流

**原则：** 密钥只在 `~/.secrets/env`（base64 私钥 + token），**不提交**；仓库只有 `templates/`。

| 类型 | 处理方式 |
|------|----------|
| Shell 变量（API token 等） | `~/.secrets/env` → `.zshrc` 启动时 `source` |
| 结构化文件（XML、ini） | `templates/*.template` → `sync-secrets.sh` 渲染到 `~` |
| GPG 私钥 armored | `GPG_PRIVATE_KEY_B64` → `GPG_PRIVATE_KEY_FILE`（供 GitHub `GPG_SECRET_KEY`） |
| SSH 私钥 | `~/.secrets/env` 中 `SSH_PRIVATE_KEY_B64` → `sync-secrets.sh` 解码到 `SSH_PRIVATE_KEY_FILE`；公钥在 `ssh/id_ed25519.pub` |

公钥在 `ssh/id_ed25519.pub`（symlink）；私钥用 env base64 恢复：

```sh
# 写入 ~/.secrets/env
base64 < ~/.ssh/id_ed25519 | tr -d '\n'    # → SSH_PRIVATE_KEY_B64
base64 < ~/.secrets/gpg-private.asc | tr -d '\n'  # → GPG_PRIVATE_KEY_B64
```

### 更新密钥后同步到 ~

```sh
./sync-secrets.sh
# 或
dot && ./sync-secrets.sh
```

### 渲染目标

| 模板 | 输出 |
|------|------|
| `templates/gitconfig.template` | `~/.gitconfig` |
| `templates/gitconfig-work.template` | `~/.gitconfig_work`（`~/work/` 下生效） |
| `templates/wakatime.cfg.template` | `~/.wakatime.cfg` |
| `templates/m2-settings.xml.template` | `~/.m2/settings.xml` |
| `templates/rclone.conf.template` | `~/.config/rclone/rclone.conf` |

### Symlink 目标（`install.sh`）

| 仓库路径 | 输出 |
|----------|------|
| `.zshenv` / `.zshrc` / `.zsh_aliases` / `.zsh_functions` | `~` |
| `config/kaku/kaku.lua` | `~/.config/kaku/kaku.lua` |
| `config/git/ignore` | `~/.config/git/ignore` |
| `config/gh/config.yml` | `~/.config/gh/config.yml` |
| `config/ssh/config` | `~/.ssh/config` |
| `ssh/id_ed25519.pub` | `~/.ssh/id_ed25519.pub` |

`~/.gitconfig` 由 `templates/gitconfig.template` 渲染（个人/公司身份、`GIT_HTTP_PROXY` 等均在 `~/.secrets/env`）。

## 日常维护

```sh
dot                    # 进入 dotfiles 目录
dotpush "update zsh"   # 提交并推送
dotpull                # 拉取最新
```

修改已 symlink 的 `~/.zshrc` 等即改仓库；改 `~/.secrets/env` 后跑 `./sync-secrets.sh`。

## 本地覆盖（不提交）

| 文件 | 用途 |
|------|------|
| `~/.secrets/env` | 全部密钥与 export |
| `~/.zshenv.local` | 早期 PATH / 代理 |
| `~/.zshrc.local` | 交互式覆盖（`DOTFILES_DIR` 等） |

## 参考

- [Mac 开发环境配置清单](https://blog.zhijun.io/posts/mac-development-environment-setup)
