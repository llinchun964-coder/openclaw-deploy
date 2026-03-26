#!/bin/bash
# 测试发起审批

set -e

APP_ID="cli_a9269e44a8b9dcef"
APP_SECRET="M2iO2Z7Oi0qtBdhcdwkebhGIcqY0lIYa"
APPROVAL_CODE="BD35DFF8-4366-4E0F-8C96-B82C03894A38"

echo "🚀 测试发起审批..."
echo ""

# 1. 获取 tenant_access_token
echo "1️⃣ 获取 token..."
TOKEN_RESPONSE=$(curl -s -X POST "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" \
  -H "Content-Type: application/json" \
  -d "{\"app_id\":\"$APP_ID\",\"app_secret\":\"$APP_SECRET\"}")

TENANT_ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('tenant_access_token', ''))")

echo "✅ Token 已获取"
echo ""

# 2. 先获取当前用户的 open_id
echo "2️⃣ 获取当前用户信息..."
USER_RESPONSE=$(curl -s -X GET "https://open.feishu.cn/open-apis/contact/v3/users/me" \
  -H "Authorization: Bearer $TENANT_ACCESS_TOKEN")

echo "用户信息："
echo "$USER_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$USER_RESPONSE"
echo ""

# 3. 尝试发起审批（需要先获取用户 open_id
echo "3️⃣ 尝试获取审批定义详情..."
DEFINITION_RESPONSE=$(curl -s -X GET "https://open.feishu.cn/open-apis/approval/v4/external/approvals/$APPROVAL_CODE" \
  -H "Authorization: Bearer $TENANT_ACCESS_TOKEN")

echo "审批定义详情："
echo "$DEFINITION_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$DEFINITION_RESPONSE"
echo ""

echo "📋 总结："
echo "审批代码：$APPROVAL_CODE"
echo ""
echo "下一步：需要获取发起人（南朝译）的 open_id 才能发起审批"
echo "请您告诉我："
echo "1. 您想让谁作为发起人？（南朝译？还是您自己？）"
echo "2. 或者您在飞书中找到南朝译的个人信息页面，把 URL 发给我"
