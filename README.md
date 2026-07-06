# Dotfiles

面向 macOS 的开发环境：通过 **symlink** 管理配置文件，配合 `install.sh`、Homebrew 与 [Brewfile](Brewfile)。

## 特性

- 使用 brew 管理软件
- 使用 git-crypt 传输敏感数据

## 安装

```sh
git clone git@github.com:zhijunio/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## git-crypt

```bash
git-crypt init
git-crypt export-key ~/git_crypt_key
git-crypt unlock ~/git_crypt_key
git-crypt status

```

## 日常维护

备份 brew

```sh
dot 
brew bundle dump
```

## 参考

- [Mac 开发环境配置清单](https://blog.zhijun.io/posts/mac-development-environment-setup)
