export PATH="$HOME/.local/bin:$PATH"

export HOMEBREW_API_DOMAIN="https://mirrors.aliyun.com/homebrew/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.aliyun.com/homebrew/homebrew-bottles"
export HOMEBREW_PIP_INDEX_URL="https://pypi.mirrors.ustc.edu.cn/simple"
export HOMEBREW_NO_AUTO_UPDATE=1

export JAVA_OPTS="-Xms1g -Xmx1g -XX:+UseG1GC -XX:+UseStringDeduplication"
export MAVEN_OPTS="-Xms1g -Xmx4g -XX:+TieredCompilation -XX:TieredStopAtLevel=1"

export CODEX_HOME=/Users/zhijunio/.codex

[[ -f ~/.env ]] && source ~/.env