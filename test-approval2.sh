#!/bin/bash
# 尝试不同的审批 API

set -e

APP_ID="cli_a9269e44a8b9dcef"
APP_SECRET="M2iO2Z7Oi0qtBdhcdwkebhGIcqY0lIYa"

echo "🚀 尝试其他审批 API..."
echo ""

# 获取 tenant_access_token
TOKEN_RESPONSE=$(curl -s -X POST "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" \
  -H "Content-Type: application/json" \
  -d "{\"app_id\":\"$APP_ID\",\"app_secret\":\"$APP_SECRET\"}")

TENANT_ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('tenant_access_token', ''))")

echo "✅ Token 已获取"
echo ""

# 尝试不同的 API 端点
echo "1️⃣ 尝试 v1 审批列表 API..."
curl -s -X GET "https://open.feishu.cn/open-apis/approval/v1/external/approvals" \
  -H "Authorization: Bearer $TENANT_ACCESS_TOKEN" | python3 -m json.tool 2>/dev/null || echo "返回原始内容"
echo ""

echo "2️⃣ 尝试 /approval/list API..."
curl -s -X GET "https://open.feishu.cn/open-apis/approval/v1/list" \
  -H "Authorization: Bearer $TENANT_ACCESS_TOKEN" | python3 -m json.tool 2>/dev/null || echo "返回原始内容"
echo ""

echo "3️⃣ 尝试 /approval/definitions API..."
curl -s -X GET "https://open.feishu.cn/open-apis/approval/v1/definitions" \
  -H "Authorization: Bearer $TENANT_ACCESS_TOKEN" | python3 -m json.tool 2>/dev/null || echo "返回原始内容"
echo ""

echo "🤔 建议："
echo "请您在飞书管理后台查看您创建的审批流程，找到以下信息："
echo "1. 审批流程的名称"
echo "2. 审批流程的代码/ID（approval_code）"
echo ""
echo "或者您可以试试："
echo "在飞书审批管理后台，点击您创建的审批流程，在 URL 中应该能看到 approval_code"
