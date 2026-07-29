# -----------------------------------------------------------------------------
# zshenv: 所有 zsh 进程都要读取的最小全局变量
# -----------------------------------------------------------------------------
[[ -f ~/.env ]] && source ~/.env

export JAVA_OPTS="-Xms1g -Xmx1g -XX:+UseG1GC -XX:+UseStringDeduplication"
export MAVEN_OPTS="-Xms1g -Xmx4g -XX:+TieredCompilation -XX:TieredStopAtLevel=1"

export CODEX_HOME=/Users/zhijunio/.codex
