<div align="center">
  <h1>Dotfiles</h1>
  <p>zhijunio 的 macOS 开发环境 · 通过 symlink 管理配置文件</p>
</div>

一键引导，从零到完整开发环境 —— 一套 dotfiles 搞定 Shell 配置、开发工具链、Java 多版本管理、敏感文件加密。

## 快速开始

```bash
git clone git@github.com:zhijunio/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
exec zsh -l
```

## 项目结构

| 目录/文件               | 说明 |
|-------------------------|------|
| `install.sh`            | 一键引导脚本：macOS 系统优化 → Homebrew → mise → SSH → Symlink |
| `Brewfile`              | 50+ 包声明：CLI 工具、语言运行时、GUI 应用、npm 包 |
| `.zprofile`             | 登录 shell：Homebrew shellenv、登录期 PATH |
| `.zshrc`                | Zsh 补全、历史、alias/function、mise、Starship、OrbStack 配置 |
| `.config/starship.toml` | Starship Pure preset，安装时链接到 `~/.config/starship.toml` |
| `.zshrc.local.example`  | 本机交互式 Shell 模板：Maven、个人工具 PATH；不覆盖已有 `~/.zshrc.local` |
| `.zshenv`               | 所有 Zsh 进程共享的 `.env`、JVM/Maven 参数和 `CODEX_HOME` |
| `.aliases`              | Git / 目录导航 / 文件管理 / Java 版本切换 / K8s 等别名 |
| `.functions`            | 自定义函数：Yazi 集成、端口查杀、Docker 清理、Git 工作流 |
| `.gitconfig`            | 全局 Git 配置：delta、push/rebase 默认值、rerere |
| `.gitconfig.local.example` | 本机 Git 模板：代理和 `~/work/` 身份路由 |
| `.gitconfig.work.local.example` | 本机工作身份模板；实际身份不进入仓库 |
| `.config/gh/config.yml` | GitHub CLI 配置：git protocol、pager、aliases |
| `.config/ghostty/config` | Ghostty 字号、窗口边距、光标和键位配置 |
| `.wakatime.cfg`         | WakaTime API 密钥 |
| `.config/git/ignore`    | 全局 gitignore（语言/编辑器/系统通用规则） |
| `.gitattributes`        | git-crypt 加密声明 |
| `.editorconfig`         | 跨编辑器格式约定（UTF-8、LF、缩进） |

## 安装脚本详解

| 阶段 | 具体操作 |
|------|----------|
| macOS 系统设置 | 主机名、时区 (Asia/Shanghai)、KeyRepeat(1/10)、Dock/Finder 动画加速 |
| Homebrew 安装 | 通过 USTC 镜像安装，信任第三方 tap，执行 `brew bundle` |
| mise | 安装 Node、pnpm、Python、Java 等版本 |
| Symlink 配置文件 | 链接共享配置；首次创建本机 Git 与 Zsh 配置，已有 local 文件保持不变 |
| SSH 密钥 | 检查/生成 Ed25519 密钥，启动 ssh-agent 并加载 |
| 默认 Shell | 切换为 zsh（若未生效） |

## 特性

### Shell 配置链

```text
zsh -l
  ├── .zshenv
  │   └── .env (敏感环境变量，git-crypt 加密)
  ├── .zprofile
  └── .zshrc
      ├── Starship Pure preset
      ├── .aliases / .functions
      └── Zsh 补全、选项与历史
```

`.zprofile` 保留 Homebrew shellenv 和登录期镜像变量：放入 `.zshrc` 会使非交互登录 Shell 缺少 Homebrew PATH，放入 `.zshenv` 则会污染所有 Zsh 进程。

### Git、Shell 与终端工作流

- Git 使用 `delta` pager、histogram diff、首次 push 自动设置 upstream，并在 rebase 时自动 stash。
- `~/.gitconfig.local` 保存代理和 `~/work/` 身份路由；工作身份位于 `~/.gitconfig.work.local`，避免全局覆盖个人身份。
- `.zshrc` 加载共享 Shell 配置和本机 `~/.zshrc.local`；Prompt 由 Starship 的 Pure preset 提供。
- `gpf` 使用 `--force-with-lease` 安全强推；`gclean-preview` 仅预览待清理文件。
- `gswi` 使用 `fzf` 选择本地分支；`gmp` 根据 `origin/HEAD` 切换默认分支，并以 fast-forward-only 模式拉取。
- Ghostty 配置位于 `~/.config/ghostty/config`，由仓库统一管理。
- mise 保留全局固定版本，同时识别 Node、pnpm 和 Java 的项目版本文件。

### 敏感文件加密 (git-crypt)

以下文件在仓库中透明加密，解锁后可读：

| 文件 | 内容 |
|------|------|
| `.env` | 代理、Token 等环境变量 |
| `.ssh/id_ed25519` | SSH 私钥 |
| `.config/rclone/rclone.conf` | Rclone 云存储配置 |
| `.m2/settings.xml` | Maven 镜像/仓库配置 |
| `.wakatime.cfg` | WakaTime API 密钥 |

Git 工作身份存放在未纳入版本控制的 `~/.gitconfig.work.local`，不再通过 git-crypt 保存。

仓库已用 git-crypt 初始化，采用**对称密钥**模式。

#### 首次使用（新机器）

```bash
# 用密钥文件解锁（密钥需从密码管理器导出）
git-crypt unlock /path/to/dotfiles-git-crypt.key

# 解锁后文件自动解密，可正常查看/编辑
cat .env

# 确认加密状态
git-crypt status
```

#### 日常工作

git-crypt 是透明加密 —— 解锁后 `git add`、`git commit`、`git diff` 全部照常，敏感文件在推送时自动加密：

```bash
dotpush "feat: update env"   # 自动加密后推送
```

#### 锁定仓库（可选）

离开机器时可锁定仓库，加密文件在本地变为不可读：

```bash
git-crypt lock
# 锁定后 cat .env 会看到乱码
# 再次使用前需 git-crypt unlock
```

#### 密钥管理

```bash
# 导出对称密钥（仅初始化时执行一次）
git-crypt export-key ~/dotfiles-git-crypt.key
# 密钥存入密码管理器后删除本地副本
```

> 密钥文件 `dotfiles-git-crypt.key` 请安全保存在 1Password / Bitwarden 等密码管理器。**密钥丢失后无法恢复加密文件。**

#### 常见问题

**Q: 提交时报错说文件被加密？**  
检查是否已执行 `git-crypt unlock`。如果已经 unlock 仍有问题，重试：
```bash
git-crypt unlock /path/to/dotfiles-git-crypt.key
```

**Q: 如何判断文件是否加密？**  
```bash
git-crypt status          # 列出加密/未加密状态
head -c 20 .env           # 加密文件头部为 GITCRYPT...
```

**Q: 为什么 `git-crypt lock` 提示权限错误？**  
macOS 安全策略可能保护密钥文件，不影响 encrypt/decrypt 功能。如需锁定，直接删除密钥文件：
```bash
rm -rf .git/git-crypt/keys
```
### Java 多版本（mise）

- `j8` → `mise shell java@zulu-8`
- `j21` → `mise shell java@21`
- `j25` → `mise shell java@25`

JVM 参数：`-Xms1g -Xmx1g -XX:+UseG1GC`。

### 软件清单 (Brewfile)

- 终端：zsh, bash, ghostty, starship, yazi, fzf, zoxide, eza, bat
- 开发：git-crypt, git-delta, gh, glab, just, jbang
- AI：codex, claude-code, cursor, cc-switch
- 运行时：node / pnpm / python / java（mise）
- 数据库：mysql-client, duckdb, orbstack, tableplus
- 网络：google-chrome, insomnia, xh, wget, switchhosts
- 云存储：rclone, aliyunpan, baidunetdisk
- 安全：gnupg
- 生产力：feishu, wechat, wetype, typora, intellij-idea

完整列表见 [`Brewfile`](Brewfile)。

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `DOTFILES_DIR` | `~/.dotfiles` | dotfiles 仓库路径 |
| `CODEX_HOME` | `~/.codex` | Codex 配置目录 |
| `SSH_PRIVATE_KEY_FILE` | `~/.ssh/id_ed25519` | SSH 密钥路径 |
| `HOMEBREW_BOTTLE_DOMAIN` | `mirrors.ustc.edu.cn` | Homebrew USTC 镜像 |

## 参考

- [Mac 开发环境配置清单](https://blog.zhijun.io/posts/mac-development-environment-setup) — 配置思路详解
