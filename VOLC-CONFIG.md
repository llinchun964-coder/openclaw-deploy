# 火山引擎 API 双 Key 轮询配置文档

**版本**: 1.0
**创建时间**: 2026-03-21 16:05 UTC
**负责人**: 南朝译技术（CTO）

---

## 一、配置目标

实现火山引擎 API 的高可用性，通过双 Key 轮询机制确保：
- API 请求不中断
- 自动故障切换
- 配额负载均衡

---

## 二、当前状态

### 现有配置
- **模型提供商**: 阿里云百炼（qwen3.5-plus）
- **API Key**: sk-sp-e6083128df284ca3b4fdbe6d987d576c
- **配置位置**: `/root/.openclaw/openclaw.json`

### 需要切换
- **目标提供商**: 火山引擎（Volcengine Ark）
- **接入点**: https://ark.cn-beijing.volces.com/api/v3
- **模型**: doubao-pro-32k / doubao-pro-256k

---

## 三、双 Key 配置方案

### 3.1 环境变量配置

创建 `/root/.openclaw/.env.volcano`：

```bash
# 火山引擎主 Key
VOLC_API_KEY_PRIMARY=sk-xxxx-primary-key-here
VOLC_API_BASE_PRIMARY=https://ark.cn-beijing.volces.com/api/v3

# 火山引擎备用 Key
VOLC_API_KEY_BACKUP=sk-xxxx-backup-key-here
VOLC_API_BASE_BACKUP=https://ark.cn-beijing.volces.com/api/v3

# 轮询配置
VOLC_ROTATION_ENABLED=true
VOLC_MAX_RETRIES=3
VOLC_TIMEOUT_MS=30000
```

### 3.2 轮询逻辑实现

创建轮询脚本 `/root/.openclaw/workspace/scripts/volcano-rotation.sh`：

```bash
#!/bin/bash
# 火山引擎双 Key 轮询脚本

API_KEY_PRIMARY="${VOLC_API_KEY_PRIMARY}"
API_KEY_BACKUP="${VOLC_API_KEY_BACKUP}"
BASE_URL="https://ark.cn-beijing.volces.com/api/v3"

CURRENT_KEY="${API_KEY_PRIMARY}"
KEY_STATUS="primary"

# 请求函数（带重试和切换）
volcano_request() {
    local endpoint="$1"
    local data="$2"
    local max_retries=3
    local retry=0
    
    while [ $retry -lt $max_retries ]; do
        response=$(curl -s -w "\n%{http_code}" \
            -X POST "${BASE_URL}${endpoint}" \
            -H "Authorization: Bearer ${CURRENT_KEY}" \
            -H "Content-Type: application/json" \
            -d "${data}")
        
        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
            echo "$body"
            return 0
        fi
        
        # 请求失败，切换 Key
        if [ "$KEY_STATUS" = "primary" ]; then
            CURRENT_KEY="${API_KEY_BACKUP}"
            KEY_STATUS="backup"
            log "切换到备用 Key"
        else
            CURRENT_KEY="${API_KEY_PRIMARY}"
            KEY_STATUS="primary"
            log "切换回主 Key"
        fi
        
        retry=$((retry + 1))
        log "请求失败 (HTTP $http_code), 重试 $retry/$max_retries"
    done
    
    log "所有重试失败"
    return 1
}

log() {
    echo "[$(date -Iseconds)] $1" >> /root/.openclaw/logs/volcano-rotation.log
}
```

### 3.3 OpenClaw 配置更新

更新 `/root/.openclaw/openclaw.json` 的 models 部分：

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "火山引擎": {
        "baseUrl": "https://ark.cn-beijing.volces.com/api/v3",
        "apiKey": "${VOLC_API_KEY_PRIMARY}",
        "api": "openai-completions",
        "fallback": {
          "provider": "火山引擎备用",
          "baseUrl": "https://ark.cn-beijing.volces.com/api/v3",
          "apiKey": "${VOLC_API_KEY_BACKUP}"
        },
        "models": [
          {
            "id": "doubao-pro-32k",
            "name": "Doubao Pro 32K"
          },
          {
            "id": "doubao-pro-256k",
            "name": "Doubao Pro 256K"
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "火山引擎/doubao-pro-32k"
      }
    }
  }
}
```

---

## 四、实施步骤

### 步骤 1: 申请火山引擎 API Key
1. 登录火山引擎控制台：https://console.volcengine.com/
2. 进入 Ark 大模型平台
3. 创建两个 API Key（主用 + 备用）
4. 记录 Key 到安全位置

### 步骤 2: 配置环境变量
```bash
# 编辑环境变量文件
nano /root/.openclaw/.env.volcano

# 添加以下内容（替换实际 Key）
export VOLC_API_KEY_PRIMARY="sk-你的主 Key"
export VOLC_API_KEY_BACKUP="sk-你的备用 Key"
export VOLC_API_BASE="https://ark.cn-beijing.volces.com/api/v3"
```

### 步骤 3: 更新 OpenClaw 配置
```bash
# 备份当前配置
cp /root/.openclaw/openclaw.json /root/.openclaw/openclaw.json.backup.$(date +%Y%m%d_%H%M%S)

# 编辑配置
nano /root/.openclaw/openclaw.json

# 更新 models 部分（见上方配置示例）
```

### 步骤 4: 测试轮询机制
```bash
# 测试主 Key
curl -X POST "https://ark.cn-beijing.volces.com/api/v3/chat/completions" \
  -H "Authorization: Bearer $VOLC_API_KEY_PRIMARY" \
  -H "Content-Type: application/json" \
  -d '{"model":"doubao-pro-32k","messages":[{"role":"user","content":"test"}]}'

# 测试备用 Key
curl -X POST "https://ark.cn-beijing.volces.com/api/v3/chat/completions" \
  -H "Authorization: Bearer $VOLC_API_KEY_BACKUP" \
  -H "Content-Type: application/json" \
  -d '{"model":"doubao-pro-32k","messages":[{"role":"user","content":"test"}]}'
```

### 步骤 5: 重启 Gateway
```bash
openclaw gateway restart
```

---

## 五、监控与告警

### 5.1 日志记录
轮询脚本记录所有切换事件到：
`/root/.openclaw/logs/volcano-rotation.log`

### 5.2 监控指标
- API 请求成功率
- Key 切换频率
- 平均响应时间
- 错误类型分布

### 5.3 告警规则
- Key 切换 > 5 次/小时 → 飞书通知
- 连续失败 > 10 次 → 紧急告警
- 响应时间 > 5 秒 → 性能告警

---

## 六、故障排查

### 问题 1: API Key 无效
```bash
# 检查 Key 是否过期
curl -X POST "https://ark.cn-beijing.volces.com/api/v3/chat/completions" \
  -H "Authorization: Bearer $VOLC_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"doubao-pro-32k","messages":[{"role":"user","content":"ping"}]}'
```

### 问题 2: 配额不足
- 登录火山引擎控制台查看配额使用
- 申请提升配额或切换到备用 Key

### 问题 3: 网络问题
```bash
# 测试网络连通性
ping ark.cn-beijing.volces.com
curl -I https://ark.cn-beijing.volces.com/api/v3
```

---

## 七、安全注意事项

1. **Key 保护**:
   - 不要将 Key 提交到 Git
   - 使用环境变量或加密存储
   - 定期轮换 Key

2. **访问控制**:
   - 限制 API Key 的 IP 白名单
   - 设置合理的配额限制
   - 监控异常使用

3. **备份策略**:
   - 配置自动备份到飞书云文档
   - 保留最近 7 天的配置备份

---

*文档状态：待实施*
*下次审查：2026-03-28*
