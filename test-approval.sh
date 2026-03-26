#!/bin/bash
# 测试飞书审批 API

set -e

# 从配置中获取凭证
APP_ID="cli_a9269e44a8b9dcef"
APP_SECRET="M2iO2Z7Oi0qtBdhcdwkebhGIcqY0lIYa"

echo "🚀 开始测试飞书审批 API..."
echo ""

# 1. 获取 tenant_access_token
echo "1️⃣ 正在获取 tenant_access_token..."
TOKEN_RESPONSE=$(curl -s -X POST "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" \
  -H "Content-Type: application/json" \
  -d "{\"app_id\":\"$APP_ID\",\"app_secret\":\"$APP_SECRET\"}")

TENANT_ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('tenant_access_token', ''))")

if [ -z "$TENANT_ACCESS_TOKEN" ]; then
    echo "❌ 错误：无法获取 tenant_access_token"
    echo "响应：$TOKEN_RESPONSE"
    exit 1
fi

echo "✅ 获取到 tenant_access_token"
echo ""

# 2. 获取审批定义列表
echo "2️⃣ 正在获取审批定义列表..."
APPROVAL_LIST=$(curl -s -X GET "https://open.feishu.cn/open-apis/approval/v4/external/approvals" \
  -H "Authorization: Bearer $TENANT_ACCESS_TOKEN")

echo "📋 审批定义列表："
echo "$APPROVAL_LIST" | python3 -m json.tool 2>/dev/null || echo "$APPROVAL_LIST"
echo ""

# 3. 尝试获取实例列表（备用 API
echo "3️⃣ 正在尝试其他审批 API..."
echo "尝试获取审批实例列表（v4 API："
INSTANCE_LIST=$(curl -s -X GET "https://open.feishu.cn/open-apis/approval/v4/instances?page_size=10" \
  -H "Authorization: Bearer $TENANT_ACCESS_TOKEN")

echo "$INSTANCE_LIST" | python3 -m json.tool 2>/dev/null || echo "$INSTANCE_LIST"

echo ""
echo "🎉 测试完成！"
