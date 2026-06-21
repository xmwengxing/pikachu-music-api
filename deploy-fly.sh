#!/bin/bash
# 一键部署 go-music-api 到 Fly.io
# 用法：FLY_TOKEN=xxx ./deploy-fly.sh
set -e

cd "$(dirname "$0")"

if [ -z "$FLY_TOKEN" ]; then
    echo "❌ 请先设置环境变量 FLY_TOKEN"
    echo "   到 https://fly.io/user/personal_access_tokens 创建 token"
    echo "   然后: export FLY_TOKEN=你的token"
    exit 1
fi

if ! command -v fly &> /dev/null; then
    echo "❌ fly CLI 未安装。运行: curl -L https://fly.io/install.sh | sh"
    exit 1
fi

echo "🔐 登录 Fly.io..."
fly auth token "$FLY_TOKEN"

# 检查 app 是否存在
if ! fly apps list | grep -q pikachu-music-api; then
    echo "📦 创建 Fly app..."
    fly apps create pikachu-music-api --org personal
fi

# 创建 volume（持久化 cookies.json）
echo "💾 创建持久化卷（cookies.json 1GB）..."
if ! fly volumes list -a pikachu-music-api | grep -q cookies; then
    fly volumes create cookies --size 1 -r sin -a pikachu-music-api || true
fi

# 部署
echo "🚀 部署..."
fly deploy --remote-only

# 健康检查
echo "🏥 等待 health check..."
sleep 10
URL="https://pikachu-music-api.fly.dev"
echo "🔍 检查 $URL/api/v1/music/search?q=test&type=song&n=1"
curl -sS "$URL/api/v1/music/search?q=test&type=song&n=1" | head -c 200
echo ""
echo ""
echo "✅ 部署完成！"
echo "   URL: $URL"
echo "   客户端 baseUrl 填: $URL/api/v1"
echo "   open:  fly open -a pikachu-music-api"
