#!/bin/bash
# 简化版审批测试

set -e

APP_ID="cli_a9269e44a8b9dcef"
APP_SECRET="M2iO2Z7Oi0qtBdhcdwkebhGIcqY0lIYa"
APPROVAL_CODE="BD35DFF8-4366-4E0F-8C96-B82C03894A38"

echo "🚀 简化版审批测试..."
echo ""

# 获取 tenant_access_token
echo "1️⃣ 获取 token..."
TOKEN_RESPONSE=$(curl -s -X POST "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" \
  -H "Content-Type: application/json" \
  -d "{\"app_id\":\"$APP_ID\",\"app_secret\":\"$APP_SECRET\"}")

TENANT_ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('tenant_access_token', ''))")

echo "✅ Token 已获取"
echo ""

# 让老板先测试手动发起一个审批
echo "📋 测试步骤："
echo ""
echo "1️⃣ 请您先在飞书中手动发起一个审批："
echo "   - 打开飞书 → 工作台 → 审批"
echo "   - 找到'小红书内容发布审批'"
echo "   - 填写测试数据并提交"
echo ""
echo "2️⃣ 提交后告诉我，我来通过 API 获取这个审批实例"
echo ""
echo "这样我们就能确认："
echo "- 审批流程是否正常工作"
echo "- API 能正确读取到审批数据"
echo "- 为后续自动发起审批做准备"
