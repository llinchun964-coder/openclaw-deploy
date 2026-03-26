#!/bin/bash
# 最终测试审批

set -e

APP_ID="cli_a9269e44a8b9dcef"
APP_SECRET="M2iO2Z7Oi0qtBdhcdwkebhGIcqY0lIYa"
APPROVAL_CODE="BD35DFF8-4366-4E0F-8C96-B82C03894A38"
OPEN_ID="ou_4c1164b4efebd32811acdf2cbb077bf4"

echo "🚀 最终测试审批发起..."
echo ""

# 1. 获取 tenant_access_token
echo "1️⃣ 获取 token..."
TOKEN_RESPONSE=$(curl -s -X POST "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" \
  -H "Content-Type: application/json" \
  -d "{\"app_id\":\"$APP_ID\",\"app_secret\":\"$APP_SECRET\"}")

TENANT_ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('tenant_access_token', ''))")

echo "✅ Token 已获取"
echo ""

# 2. 构建表单数据（只填必填的文本字段）
echo "2️⃣ 构建表单数据..."
FORM_DATA='[
  {
    "id": "widget17739007406990001",
    "type": "text",
    "value": "小红书内容发布审批测试"
  },
  {
    "id": "widget17739012670340001",
    "type": "input",
    "value": "测试笔记-如何优雅地改名"
  },
  {
    "id": "widget17739012832660001",
    "type": "textarea",
    "value": "大家好，今天给大家分享一下改名的心得体会...\n\n改名不是一件小事，它关乎你的个人品牌和职场发展..."
  }
]'

# 转义 JSON 字符串
FORM_ESCAPED=$(echo "$FORM_DATA" | python3 -c "import sys, json; print(json.dumps(sys.stdin.read()))")

echo "✅ 表单数据已构建"
echo ""

# 3. 发起审批
echo "3️⃣ 发起审批..."
CREATE_RESPONSE=$(curl -s -X POST "https://open.feishu.cn/open-apis/approval/v4/instances" \
  -H "Authorization: Bearer $TENANT_ACCESS_TOKEN" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d "{
    \"approval_code\": \"$APPROVAL_CODE\",
    \"open_id\": \"$OPEN_ID\",
    \"form\": $FORM_ESCAPED,
    \"title\": \"小红书内容发布 - 测试笔记\"
  }")

echo "审批发起响应："
echo "$CREATE_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$CREATE_RESPONSE"
echo ""

INSTANCE_CODE=$(echo "$CREATE_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('data', {}).get('instance_code', ''))")

if [ -n "$INSTANCE_CODE" ]; then
    echo "✅ 审批发起成功！"
    echo "📋 审批实例代码：$INSTANCE_CODE"
    echo ""
    echo "📝 您现在可以在飞书中审批这个测试单了！"
else
    echo "❌ 审批发起失败"
fi

echo ""
echo "🎉 测试完成！"
