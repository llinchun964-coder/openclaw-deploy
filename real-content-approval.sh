#!/bin/bash
# 模拟真实小红书内容审批

set -e

APP_ID="cli_a9269e44a8b9dcef"
APP_SECRET="M2iO2Z7Oi0qtBdhcdwkebhGIcqY0lIYa"
APPROVAL_CODE="BD35DFF8-4366-4E0F-8C96-B82C03894A38"
OPEN_ID="ou_4c1164b4efebd32811acdf2cbb077bf4"

echo "🚀 模拟真实小红书内容审批流程..."
echo ""
echo "📝 【南朝译老师产出内容】"
echo "------------------------"
echo ""

# 模拟内容
TITLE="2026年改名攻略：这3个名字让你职场顺风顺水"
CONTENT="大家好，我是南朝译老师！\n\n今天给大家分享2026年最值得推荐的3个改名方向：\n\n1️⃣ 【领导力方向】\n名字里带\"轩\"、\"宇\"、\"宸\"，彰显领导气质\n\n2️⃣ 【亲和力方向】\n名字里带\"涵\"、\"雅\"、\"柔\"，让人感觉亲切好相处\n\n3️⃣ 【财运方向】\n名字里带\"鑫\"、\"源\"、\"盛\"，寓意财源广进\n\n记住：改名不是玄学，是心理学！一个好名字能给你积极的心理暗示，让你更自信地面对职场挑战！\n\n—— 南朝译老师"

echo "📌 标题：$TITLE"
echo ""
echo "📄 内容："
echo "$CONTENT"
echo ""
echo "------------------------"
echo ""
echo "📤 【CEO 提交审批】"
echo ""

# 1. 获取 tenant_access_token
echo "1️⃣ 获取 token..."
TOKEN_RESPONSE=$(curl -s -X POST "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" \
  -H "Content-Type: application/json" \
  -d "{\"app_id\":\"$APP_ID\",\"app_secret\":\"$APP_SECRET\"}")

TENANT_ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('tenant_access_token', ''))")

echo "✅ Token 已获取"
echo ""

# 2. 构建表单数据
echo "2️⃣ 构建表单数据..."
FORM_DATA="[
  {
    \"id\": \"widget17739007406990001\",
    \"type\": \"text\",
    \"value\": \"南朝译老师小红书笔记-2026改名攻略\"
  },
  {
    \"id\": \"widget17739012670340001\",
    \"type\": \"input\",
    \"value\": \"$TITLE\"
  },
  {
    \"id\": \"widget17739012832660001\",
    \"type\": \"textarea\",
    \"value\": \"$CONTENT\"
  }
]"

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
    \"title\": \"南朝译小红书笔记 - $TITLE\"
  }")

echo "审批发起响应："
echo "$CREATE_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$CREATE_RESPONSE"
echo ""

INSTANCE_CODE=$(echo "$CREATE_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('data', {}).get('instance_code', ''))")

if [ -n "$INSTANCE_CODE" ]; then
    echo "✅ 审批发起成功！"
    echo "📋 审批实例代码：$INSTANCE_CODE"
    echo ""
    echo "📋 【完整流程演示】"
    echo "------------------------"
    echo "1️⃣ 南朝译老师 → 产出内容"
    echo "2️⃣ CEO（南朝译）→ 提交飞书审批"
    echo "3️⃣ 老板（李林春）→ 审批同意"
    echo "4️⃣ 小红书运营官 → 收到通知并发布"
    echo "------------------------"
    echo ""
    echo "📝 现在请老板您去飞书中审批这个内容！"
    echo "审批通过后，我们继续开发下一步：监听审批结果并通知运营官！"
else
    echo "❌ 审批发起失败"
fi

echo ""
echo "🎉 模拟完成！"
