# 飞书审批流程集成文档

**版本**: 1.0
**创建时间**: 2026-03-21 16:10 UTC
**负责人**: 南朝译技术（CTO）

---

## 一、审批流程设计

### 1.1 业务场景
小红书内容发布审批流程，确保内容质量并符合公司策略。

### 1.2 审批节点设计

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  运营官提交  │ -> │  技术部审核  │ -> │   CEO 审批   │ -> │  老板确认   │
│  (小红书运营)│    │  (格式检查)  │    │  (内容策略)  │    │  (最终发布) │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
     5 分钟              10 分钟             30 分钟            1 小时
```

### 1.3 审批权限矩阵

| 角色 | 提交 | 审核 | 批准 | 查看 |
|------|------|------|------|------|
| 小红书运营 | ✅ | ❌ | ❌ | ✅ |
| CTO（技术）| ❌ | ✅ | ❌ | ✅ |
| CEO（南朝译）| ❌ | ✅ | ✅ | ✅ |
| 老板（李林春）| ❌ | ✅ | ✅ | ✅ |

---

## 二、飞书审批 API 配置

### 2.1 权限确认
已确认飞书应用权限包含：
- ✅ `approval:approval` - 审批实例管理
- ✅ `approval:definition` - 审批定义管理
- ✅ `contact:contact` - 联系人信息
- ✅ `im:message` - 消息通知

### 2.2 审批流程创建

#### 方法 A: 使用飞书审批设计器（推荐）
1. 登录飞书开放平台：https://open.feishu.cn/
2. 进入应用管理 → 审批
3. 创建新审批流程："小红书内容发布审批"
4. 配置审批节点（见 1.2）
5. 发布审批流程

#### 方法 B: 使用 API 创建
```bash
# 创建审批实例
curl -X POST https://open.feishu.cn/open-apis/approval/v4/instances \
  -H "Authorization: Bearer $FEISHU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "process_code": "小红书内容发布审批",
    "form_items": [
      {
        "item_name": "内容标题",
        "item_value": "标题内容"
      },
      {
        "item_name": "内容正文",
        "item_value": "正文内容"
      },
      {
        "item_name": "配图链接",
        "item_value": "https://..."
      },
      {
        "item_name": "发布时间",
        "item_value": "2026-03-21 20:00"
      }
    ]
  }'
```

### 2.3 审批回调处理

创建 Webhook 处理器 `/root/.openclaw/workspace/scripts/feishu-approval-webhook.js`：

```javascript
const express = require('express');
const crypto = require('crypto');

const app = express();
const PORT = 18850;

// 飞书验证令牌
const VERIFICATION_TOKEN = 'your_verification_token';

app.post('/webhook/feishu/approval', (req, res) => {
  const { challenge, token, type, event } = req.body;
  
  // 验证请求
  if (type === 'url_verification') {
    res.send({ challenge });
    return;
  }
  
  // 处理审批事件
  if (type === 'event_callback') {
    handleApprovalEvent(event);
    res.send({ success: true });
  }
});

function handleApprovalEvent(event) {
  const { instance_code, status, approve_time } = event;
  
  console.log(`审批实例 ${instance_code} 状态变更为 ${status}`);
  
  // 状态映射
  const statusMap = {
    'APPROVAL_STATUS_APPROVED': '✅ 已通过',
    'APPROVAL_STATUS_REJECTED': '❌ 已拒绝',
    'APPROVAL_STATUS_WITHDRAWN': '⚠️ 已撤回'
  };
  
  // 通知相关人员
  notifyStakeholders(instance_code, statusMap[status]);
}

function notifyStakeholders(instanceCode, status) {
  // 发送飞书消息到全员群
  const message = `
【审批结果通知】
实例编号：${instanceCode}
状态：${status}
时间：${new Date().toISOString()}
  `;
  
  // 调用飞书消息 API
  sendFeishuMessage('oc_dacac93e9e4cd765a169b5f5796f1a5c', message);
}

app.listen(PORT, () => {
  console.log(`审批 Webhook 运行在端口 ${PORT}`);
});
```

---

## 三、审批流程集成实现

### 3.1 提交审批函数

创建 `/root/.openclaw/workspace/scripts/submit-approval.sh`：

```bash
#!/bin/bash
# 小红书内容发布审批提交脚本

FEISHU_APP_ID="cli_a9269e44a8b9dcef"
FEISHU_APP_SECRET="M2iO2Z7Oi0qtBdhcdwkebhGIcqY0lIYa"

# 获取 Access Token
get_access_token() {
  response=$(curl -s -X POST https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal \
    -H "Content-Type: application/json" \
    -d "{
      \"app_id\": \"$FEISHU_APP_ID\",
      \"app_secret\": \"$FEISHU_APP_SECRET\"
    }")
  
  echo "$response" | jq -r '.tenant_access_token'
}

# 提交审批实例
submit_approval() {
  local title="$1"
  local content="$2"
  local image_url="$3"
  local publish_time="$4"
  
  local token=$(get_access_token)
  
  response=$(curl -s -X POST https://open.feishu.cn/open-apis/approval/v4/instances \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d "{
      \"process_code\": \"小红书内容发布审批\",
      \"form_items\": [
        {\"item_name\": \"内容标题\", \"item_value\": \"$title\"},
        {\"item_name\": \"内容正文\", \"item_value\": \"$content\"},
        {\"item_name\": \"配图链接\", \"item_value\": \"$image_url\"},
        {\"item_name\": \"发布时间\", \"item_value\": \"$publish_time\"}
      ]
    }")
  
  instance_code=$(echo "$response" | jq -r '.instance_code')
  
  if [ -n "$instance_code" ] && [ "$instance_code" != "null" ]; then
    echo "✅ 审批提交成功：$instance_code"
    log_approval "$instance_code" "$title" "PENDING"
  else
    echo "❌ 审批提交失败：$response"
    return 1
  fi
}

log_approval() {
  local instance_code="$1"
  local title="$2"
  local status="$3"
  
  echo "[$(date -Iseconds)] $instance_code | $title | $status" >> /root/.openclaw/logs/approvals.log
}

# 使用示例
# submit_approval "标题" "内容" "https://..." "2026-03-21 20:00"
```

### 3.2 审批状态查询

```bash
# 查询审批实例状态
curl -X GET "https://open.feishu.cn/open-apis/approval/v4/instances/${INSTANCE_CODE}" \
  -H "Authorization: Bearer $TOKEN"
```

### 3.3 审批结果处理

```bash
# 审批通过 → 自动发布
if [ "$STATUS" = "APPROVAL_STATUS_APPROVED" ]; then
  echo "审批通过，开始发布..."
  /root/.openclaw/workspace/scripts/publish-xhs.sh "$INSTANCE_CODE"
fi

# 审批拒绝 → 通知运营修改
if [ "$STATUS" = "APPROVAL_STATUS_REJECTED" ]; then
  echo "审批拒绝，通知运营修改..."
  notify_operator "$INSTANCE_CODE" "$REJECT_REASON"
fi
```

---

## 四、审批流程测试

### 4.1 测试场景

| 测试用例 | 预期结果 | 状态 |
|----------|----------|------|
| 正常提交流程 | 审批实例创建成功 | ⏳ 待测试 |
| 审批通过流程 | 自动发布内容 | ⏳ 待测试 |
| 审批拒绝流程 | 通知运营修改 | ⏳ 待测试 |
| 超时未审批 | 自动提醒审批人 | ⏳ 待测试 |
| 撤回审批 | 流程终止 | ⏳ 待测试 |

### 4.2 测试脚本

创建 `/root/.openclaw/workspace/scripts/test-approval-flow.sh`：

```bash
#!/bin/bash
# 审批流程测试脚本

echo "=== 飞书审批流程测试 ==="
echo ""

# 测试 1: 提交审批
echo "测试 1: 提交审批实例..."
result=$(submit_approval "测试标题" "测试内容" "https://example.com/image.jpg" "2026-03-21 20:00")
if [[ "$result" == *"✅"* ]]; then
  echo "✅ 测试 1 通过"
  INSTANCE_CODE=$(echo "$result" | grep -oP ':\K.*')
else
  echo "❌ 测试 1 失败"
  exit 1
fi

# 测试 2: 查询状态
echo "测试 2: 查询审批状态..."
status=$(query_approval_status "$INSTANCE_CODE")
if [ "$status" = "PENDING" ]; then
  echo "✅ 测试 2 通过"
else
  echo "❌ 测试 2 失败"
fi

echo ""
echo "=== 测试完成 ==="
```

---

## 五、监控与日志

### 5.1 审批日志格式
```
[时间戳] 实例编号 | 内容标题 | 状态 | 操作人
```

### 5.2 监控指标
- 审批平均耗时
- 审批通过率
- 各节点处理时间
- 超时审批数量

### 5.3 告警规则
- 审批超时（>2 小时）→ 飞书提醒
- 连续拒绝（>3 次）→ 通知 CEO
- 审批积压（>10 个）→ 通知审批人

---

## 六、实施步骤

### 步骤 1: 创建审批流程（飞书后台）
- 时间：16:30-17:00
- 负责人：CTO
- 输出：审批流程 ID

### 步骤 2: 配置 Webhook
- 时间：17:00-17:30
- 负责人：CTO
- 输出：Webhook URL

### 步骤 3: 集成发布系统
- 时间：17:30-18:30
- 负责人：CTO + 运营
- 输出：集成测试报告

### 步骤 4: 全员培训
- 时间：18:30-19:00
- 负责人：CEO
- 输出：培训记录

---

## 七、安全与合规

1. **权限控制**:
   - 审批流程仅限授权人员访问
   - 敏感内容加密存储

2. **数据保留**:
   - 审批记录保留 90 天
   - 发布内容永久存档

3. **审计日志**:
   - 所有操作记录日志
   - 定期审计审批流程

---

*文档状态：待实施*
*下次审查：2026-03-28*
