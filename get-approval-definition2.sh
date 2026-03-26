#!/bin/bash
# 重新获取审批定义详情

set -e

APP_ID="cli_a9269e44a8b9dcef"
APP_SECRET="M2iO2Z7Oi0qtBdhcdwkebhGIcqY0lIYa"
APPROVAL_CODE="BD35DFF8-4366-4E0F-8C96-B82C03894A38"

echo "🚀 重新获取审批定义详情..."
echo ""

# 1. 获取 tenant_access_token
echo "1️⃣ 获取 token..."
TOKEN_RESPONSE=$(curl -s -X POST "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" \
  -H "Content-Type: application/json" \
  -d "{\"app_id\":\"$APP_ID\",\"app_secret\":\"$APP_SECRET\"}")

TENANT_ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('tenant_access_token', ''))")

echo "✅ Token 已获取"
echo ""

# 2. 获取审批定义
echo "2️⃣ 获取审批定义..."
DEFINITION_RESPONSE=$(curl -s -X GET "https://open.feishu.cn/open-apis/approval/v4/approvals/$APPROVAL_CODE" \
  -H "Authorization: Bearer $TENANT_ACCESS_TOKEN")

echo "审批定义："
echo "$DEFINITION_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$DEFINITION_RESPONSE"
echo ""

echo "🎉 完成！"
