# macOS Dotfiles

使用 SDKMAN、Homebrew 和少量 Shell 配置管理 macOS 开发环境。

## 功能

- 通过 SDKMAN 管理 Java 和 Maven，Homebrew 管理 Node
- 通过 `Brewfile` 安装 Homebrew formula 和 cask
- 通过 bootstrap.sh 管理 Git、Zsh、Maven 配置的 symlink
- 通过 Bitwarden 恢复 SSH 私钥、rclone 配置和 `.env`
- Bitwarden 记录不存在或读取失败时打印警告并继续执行
- 根据 `WORK_NAME` 和 `WORK_EMAIL` 生成 `~/.gitconfig.work`
- 自动安装 Oh My Zsh
- 保持 TablePlus 的 Homebrew 安装状态不参与自动升级

## 前置条件

- macOS
- Xcode Command Line Tools
- Homebrew
- 能访问 Bitwarden，并准备好对应的 Secure Note
- 当前 shell 已设置 `WORK_NAME` 和 `WORK_EMAIL`（如果需要工作 Git 身份）

## 安装

```bash
git clone https://github.com/zhijunio/dotfiles.git ~/github/dotfiles
cd ~/github/dotfiles
./bootstrap.sh
```

bootstrap.sh 会：

1. 安装或使用 Homebrew，并按 Brewfile 安装依赖
2. 安装或使用 SDKMAN，并安装 Java、Maven
3. 临时使用 Bitwarden CLI 读取配置
4. 尝试恢复 SSH 私钥、rclone 配置和 .env
5. 生成 ~/.gitconfig.work（如果两个工作身份环境变量都存在）
6. 创建 dotfiles symlink，并安装 Oh My Zsh

已有配置不会被无条件覆盖。已有 SSH 私钥会跳过恢复；已有内容不同的 ~/.env 会停止安装。

## Git 身份

默认 Git 身份位于 dotfiles/.gitconfig。

工作目录下的仓库通过条件配置加载：

```bash
[includeIf "gitdir:~/work/"]
path = ~/.gitconfig.work
```

生成工作身份：

```bash
export WORK_NAME="Your Work Name"
export WORK_EMAIL="your.name@company.example"
./bootstrap.sh
```

工作邮箱只写入本机的 ~/.gitconfig.work，不会写入仓库。

## 配置文件

- dotfiles/.zshrc：Zsh、Oh My Zsh、SDKMAN、direnv、Starship 和 OrbStack
- dotfiles/.zshenv：PATH、Homebrew 镜像、Java/Maven 环境
- dotfiles/.aliases：常用命令别名
- dotfiles/.functions：Shell 函数
- dotfiles/.gitconfig：Git 默认配置和条件身份配置
- dotfiles/settings.xml：Maven 配置
- Brewfile：Homebrew 软件清单

## 日常维护

检查缺失的 Homebrew 依赖：

```bash
brew bundle check --file Brewfile --verbose
```

安装缺失依赖，但不升级已有软件：

```bash
brew bundle install --file Brewfile --no-upgrade --verbose
```

查看 SDKMAN 管理的工具：

```bash
sdk current
sdk list java
```

Java 默认使用 `8.0.504+1-zulu`、`21.0.0.0+35-tem`、`25.0.3.0+9-tem` 和 `27.0.0.0+35-tem`。版本不可用时，可通过同名环境变量覆盖，例如 `SDKMAN_JAVA_25_VERSION=25.0.1-tem ./bootstrap.sh`。

更新配置后重新应用：

```bash
./bootstrap.sh
```
## 验证

```bash
bash -n bootstrap.sh
git diff --check
sdk current
brew bundle check --file Brewfile --verbose
```

## macOS 系统设置

需要应用 macOS 系统偏好设置时，单独执行：

```bash
./setup_macos.sh
```

该脚本会修改主机名、时区、键盘重复速度、Dock 和 Finder 设置。
