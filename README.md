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

| 目录/文件 | 说明 |
|-----------|------|
| `install.sh` | 一键引导脚本：macOS 系统优化 → Homebrew → SDKMAN → SSH → Symlink |
| `Brewfile` | 50+ 包声明：CLI 工具、语言运行时、GUI 应用、npm 包 |
| `.zshrc` | Zsh 主配置：加载 alias/function/env，初始化 SDKMAN/fnm/OrbStack/补全 |
| `.zshenv` | 环境变量：Homebrew USTC 镜像、PATH、CODEX_HOME |
| `.zsh_aliases` | Git / 目录导航 / 文件管理 / Java 版本切换 / K8s 等别名 |
| `.zsh_functions` | 自定义函数：Yazi 集成、端口查杀、Docker 清理、Git 工作流 |
| `.gitconfig` | 全局 Git 配置：vim 编辑器、代理、autosquash、rerere |
| `.gitconfig_work` | 工作 Git 身份（按目录条件 include） |
| `.config/git/ignore` | 全局 gitignore（语言/编辑器/系统通用规则） |
| `.gitattributes` | git-crypt 加密声明 |
| `.editorconfig` | 跨编辑器格式约定（UTF-8、LF、缩进） |

## 安装脚本详解

| 阶段 | 具体操作 |
|------|----------|
| macOS 系统设置 | 主机名、时区 (Asia/Shanghai)、KeyRepeat(1/10)、Dock/Finder 动画加速 |
| Homebrew 安装 | 通过 USTC 镜像安装，信任第三方 tap，执行 `brew bundle` |
| SDKMAN | 安装 Java 8 (zulu)、21、25 (tem)、Maven |
| Symlink 配置文件 | 将 `.zshrc`、`.gitconfig`、`.ssh`、`rclone`、`m2` 等链接到 `$HOME` |
| SSH 密钥 | 检查/生成 Ed25519 密钥，启动 ssh-agent 并加载 |
| 默认 Shell | 切换为 zsh（若未生效） |

## 特性

### Shell 配置链

```text
.zshrc
  ├── .env (敏感环境变量，git-crypt 加密)
  ├── .zshrc.local (机器本地覆盖)
  ├── .zsh_aliases
  ├── .zsh_functions
  ├── .zshenv
  ├── SDKMAN → Java / Maven
  ├── fnm → Node.js
  ├── OrbStack (Docker 替代)
  └── Zsh 补全 & 历史优化
```

### 敏感文件加密 (git-crypt)

以下文件在仓库中透明加密，解锁后可读：

| 文件 | 内容 |
|------|------|
| `.env` | 代理、Token 等环境变量 |
| `.ssh/id_ed25519` | SSH 私钥 |
| `.config/rclone/rclone.conf` | Rclone 云存储配置 |
| `.m2/settings.xml` | Maven 镜像/仓库配置 |
| `.gitconfig_work` | 工作 Git 身份 |

```bash
# 解锁
git-crypt unlock ~/git_crypt_key

# 查看加密状态
git-crypt status
```

### Java 多版本 (SDKMAN)

| 别名 | 命令 | 版本 |
|------|------|------|
| `j8` | `sdk use java 8.0.482-zulu` | Java 8 (Zulu) |
| `j21` | `sdk use java 21-tem` | Java 21 (Temurin) |
| `j25` | `sdk use java 25-tem` | Java 25 (Temurin) |

JVM 优化参数：`-Xms1g -Xmx1g -XX:+UseG1GC`，Maven 堆 1-4G。

### 软件清单 (Brewfile)

| 类别 | 软件 |
|------|------|
| **Shell / 终端** | zsh, bash, ghostty, yazi, fzf, zoxide, eza, bat |
| **开发工具** | git-crypt, git-delta, gh, glab, just, jbang |
| **AI 工具** | codex, claude-code, cursor, cc-switch |
| **语言运行时** | node (fnm), python@3.14 (pipx/uv), java (SDKMAN) |
| **数据库** | mysql-client, duckdb, orbstack, tableplus |
| **网络** | google-chrome, insomnia, xh, wget, switchhosts |
| **云存储** | rclone, aliyunpan, baidunetdisk |
| **安全** | 1password, gnupg |
| **生产力** | feishu, wechat, wetype, typora, intellij-idea |

完整列表见 [`Brewfile`](Brewfile)。

## 日常维护

```bash
dot                          # cd 到 dotfiles 目录
dotpush "chore: update"      # 提交并推送（含默认 commit message）
dotpull                      # 拉取 dotfiles 更新
reload_rc                    # 重新加载 .zshrc

# Git 工作流
gpo                          # git push origin <当前分支>
gmp                          # 切到 main/master 并 pull
gtp                          # 从 main 创建 CalVer tag (vYY.MM.N) 并推送

# 构建产物清理（支持 dry-run）
build_cleanup                # 清除 node_modules/target/dist/__pycache__ 等
build_cleanup -n             # 预览要删除的目录
```

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `DOTFILES_DIR` | `~/.dotfiles` | dotfiles 仓库路径 |
| `CODEX_HOME` | `~/.codex` | Codex 配置目录 |
| `SSH_PRIVATE_KEY_FILE` | `~/.ssh/id_ed25519` | SSH 密钥路径 |
| `HOMEBREW_BOTTLE_DOMAIN` | `mirrors.ustc.edu.cn` | Homebrew USTC 镜像 |

## 参考

- [Mac 开发环境配置清单](https://blog.zhijun.io/posts/mac-development-environment-setup) — 配置思路详解
