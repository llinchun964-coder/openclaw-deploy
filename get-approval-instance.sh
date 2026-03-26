#!/bin/bash
# 获取审批实例详情

set -e

APP_ID="cli_a9269e44a8b9dcef"
APP_SECRET="M2iO2Z7Oi0qtBdhcdwkebhGIcqY0lIYa"
INSTANCE_ID="7618849151110892733"

echo "🚀 获取审批实例详情..."
echo "实例 ID：$INSTANCE_ID"
echo ""

# 1. 获取 tenant_access_token
echo "1️⃣ 获取 token..."
TOKEN_RESPONSE=$(curl -s -X POST "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" \
  -H "Content-Type: application/json" \
  -d "{\"app_id\":\"$APP_ID\",\"app_secret\":\"$APP_SECRET\"}")

TENANT_ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('tenant_access_token', ''))")

echo "✅ Token 已获取"
echo ""

# 2. 获取审批实例详情
echo "2️⃣ 获取审批实例详情（v4 API）..."
INSTANCE_RESPONSE=$(curl -s -X GET "https://open.feishu.cn/open-apis/approval/v4/instances/$INSTANCE_ID" \
  -H "Authorization: Bearer $TENANT_ACCESS_TOKEN")

echo "审批实例详情："
echo "$INSTANCE_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$INSTANCE_RESPONSE"
echo ""

echo "🎉 完成！"
