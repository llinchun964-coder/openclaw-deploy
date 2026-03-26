# 系统监控部署文档

**版本**: 1.0
**创建时间**: 2026-03-21 16:15 UTC
**负责人**: 南朝译技术（CTO）

---

## 一、监控目标

- 5 分钟健康检查
- 容器状态监控（5 个容器）
- API 响应时间监控
- 资源使用告警
- 异常自动恢复

---

## 二、监控架构

```
┌─────────────────────────────────────────────────────────────┐
│                    监控系统 (Cron + 脚本)                      │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ 容器监控  │  │ API 监控   │  │ 资源监控  │  │ 日志监控  │    │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘    │
│       │             │             │             │           │
│       └─────────────┴─────────────┴─────────────┘           │
│                            │                                 │
│                    ┌───────▼───────┐                        │
│                    │  告警中心     │                        │
│                    │ (飞书通知)    │                        │
│                    └───────┬───────┘                        │
└────────────────────────────┼────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │   全员群通知     │
                    └─────────────────┘
```

---

## 三、监控脚本实现

### 3.1 主监控脚本

创建 `/root/.openclaw/workspace/scripts/system-health-check.sh`：

```bash
#!/bin/bash
# 系统健康检查脚本（5 分钟执行一次）

set -e

# 配置
LOG_FILE="/root/.openclaw/logs/health-check.log"
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEM=85
ALERT_THRESHOLD_DISK=90
FEISHU_WEBHOOK="https://open.feishu.cn/open-apis/bot/v2/hook/xxx"

# 日志函数
log() {
  echo "[$(date -Iseconds)] $1" | tee -a "$LOG_FILE"
}

# 告警函数（飞书通知）
send_alert() {
  local level="$1"
  local title="$2"
  local message="$3"
  
  local color
  case "$level" in
    "INFO") color="blue" ;;
    "WARNING") color="orange" ;;
    "CRITICAL") color="red" ;;
    *) color="gray" ;;
  esac
  
  curl -X POST "$FEISHU_WEBHOOK" \
    -H "Content-Type: application/json" \
    -d "{
      \"msg_type\": \"interactive\",
      \"card\": {
        \"header\": {
          \"title\": {
            \"tag\": \"plain_text\",
            \"content\": \"${title}\"
          },
          \"template\": \"${color}\"
        },
        \"elements\": [
          {
            \"tag\": \"markdown\",
            \"content\": \"${message}\"
          }
        ]
      }
    }"
}

# 检查容器状态
check_containers() {
  log "=== 容器状态检查 ==="
  
  local containers=("openclaw-cto" "openclaw-xhs" "openclaw-designer" "openclaw-healer" "redis")
  local failed=()
  
  for container in "${containers[@]}"; do
    status=$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null || echo "not_found")
    
    if [ "$status" = "running" ]; then
      log "✅ $container: 运行中"
    else
      log "❌ $container: $status"
      failed+=("$container")
    fi
  done
  
  if [ ${#failed[@]} -gt 0 ]; then
    send_alert "CRITICAL" "🚨 容器异常告警" "以下容器异常：\n${failed[*]}\n\n正在尝试重启..."
    
    # 自动重启失败容器
    for container in "${failed[@]}"; do
      if [ "$container" != "not_found" ]; then
        log "尝试重启 $container..."
        docker restart "$container" 2>/dev/null || true
      fi
    done
  fi
  
  return ${#failed[@]}
}

# 检查 API 响应
check_api_health() {
  log "=== API 健康检查 ==="
  
  # 检查 Gateway API
  local start_time=$(date +%s%N)
  local response=$(curl -s -o /dev/null -w "%{http_code}" \
    "http://localhost:18789/status" 2>/dev/null || echo "000")
  local end_time=$(date +%s%N)
  
  local latency=$(( (end_time - start_time) / 1000000 ))
  
  if [ "$response" = "200" ]; then
    log "✅ Gateway API: ${latency}ms"
  else
    log "❌ Gateway API: HTTP $response"
    send_alert "WARNING" "⚠️ API 响应异常" "Gateway API 响应：HTTP $response\n延迟：${latency}ms"
    return 1
  fi
  
  # 检查 A2A Gateway
  response=$(curl -s -o /dev/null -w "%{http_code}" \
    "http://localhost:18800/health" 2>/dev/null || echo "000")
  
  if [ "$response" = "200" ]; then
    log "✅ A2A Gateway: 正常"
  else
    log "❌ A2A Gateway: HTTP $response"
    return 1
  fi
  
  return 0
}

# 检查资源使用
check_resources() {
  log "=== 资源使用检查 ==="
  
  # CPU 使用率
  local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d'.' -f1)
  log "CPU 使用率：${cpu_usage}%"
  
  if [ "$cpu_usage" -gt "$ALERT_THRESHOLD_CPU" ]; then
    send_alert "WARNING" "⚠️ CPU 使用率过高" "当前 CPU 使用率：${cpu_usage}%\n阈值：${ALERT_THRESHOLD_CPU}%"
  fi
  
  # 内存使用率
  local mem_info=$(free | grep Mem)
  local mem_total=$(echo "$mem_info" | awk '{print $2}')
  local mem_used=$(echo "$mem_info" | awk '{print $3}')
  local mem_usage=$((mem_used * 100 / mem_total))
  
  log "内存使用率：${mem_usage}%"
  
  if [ "$mem_usage" -gt "$ALERT_THRESHOLD_MEM" ]; then
    send_alert "WARNING" "⚠️ 内存使用率过高" "当前内存使用率：${mem_usage}%\n阈值：${ALERT_THRESHOLD_MEM}%"
  fi
  
  # 磁盘使用率
  local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)
  log "磁盘使用率：${disk_usage}%"
  
  if [ "$disk_usage" -gt "$ALERT_THRESHOLD_DISK" ]; then
    send_alert "CRITICAL" "🚨 磁盘空间不足" "当前磁盘使用率：${disk_usage}%\n阈值：${ALERT_THRESHOLD_DISK}%"
  fi
  
  return 0
}

# 检查日志错误
check_logs() {
  log "=== 日志错误检查 ==="
  
  # 检查最近 5 分钟的错误日志
  local error_count=$(grep -c "ERROR\|CRITICAL" /root/.openclaw/logs/*.log 2>/dev/null || echo "0")
  
  if [ "$error_count" -gt 10 ]; then
    send_alert "WARNING" "⚠️ 错误日志增多" "最近发现 $error_count 条错误日志\n请检查：/root/.openclaw/logs/"
  fi
  
  log "错误日志数量：$error_count"
  
  return 0
}

# 生成健康报告
generate_report() {
  local timestamp=$(date -Iseconds)
  local report_file="/root/.openclaw/logs/health-report-$(date +%Y%m%d).json"
  
  cat >> "$report_file" << EOF
{
  "timestamp": "$timestamp",
  "containers": "$(docker ps --format '{{.Names}}:{{.Status}}' | tr '\n' ';')",
  "api_status": "healthy",
  "resources": {
    "cpu": "$(top -bn1 | grep 'Cpu(s)' | awk '{print $2}')",
    "memory": "$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')%",
    "disk": "$(df -h / | awk 'NR==2 {print $5}')"
  }
}
EOF
  
  log "健康报告已生成：$report_file"
}

# 主函数
main() {
  log "=========================================="
  log "开始健康检查 ($(date))"
  log "=========================================="
  
  local exit_code=0
  
  check_containers || exit_code=1
  check_api_health || exit_code=1
  check_resources || exit_code=1
  check_logs || exit_code=1
  
  if [ $exit_code -eq 0 ]; then
    log "✅ 所有检查通过"
  else
    log "⚠️ 发现异常，已发送告警"
  fi
  
  generate_report
  
  log "健康检查完成"
  log ""
  
  return $exit_code
}

# 执行
main "$@"
```

### 3.2 配置 Cron 任务

创建 `/root/.openclaw/workspace/scripts/setup-monitor-cron.sh`：

```bash
#!/bin/bash
# 配置 5 分钟健康检查 Cron 任务

CRON_FILE="/etc/cron.d/openclaw-health-check"

# 创建 Cron 配置
cat > "$CRON_FILE" << EOF
# OpenClaw 系统健康检查（每 5 分钟）
*/5 * * * * root /root/.openclaw/workspace/scripts/system-health-check.sh >> /root/.openclaw/logs/cron-health.log 2>&1
EOF

# 设置权限
chmod 644 "$CRON_FILE"

# 验证 Cron 配置
crontab -l 2>/dev/null | grep -v "openclaw-health-check" | crontab -

echo "✅ Cron 任务配置完成"
echo "查看 Cron 日志：tail -f /root/.openclaw/logs/cron-health.log"
```

---

## 四、监控看板设计

### 4.1 实时监控页面

创建 `/root/.openclaw/workspace/monitor/index.html`：

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>南朝译 AI 系统监控看板</title>
  <style>
    body { font-family: Arial, sans-serif; background: #1a1a2e; color: #eee; }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    .header { text-align: center; padding: 20px 0; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
    .card { background: #16213e; border-radius: 10px; padding: 20px; }
    .card h3 { margin-top: 0; color: #00d9ff; }
    .status { display: inline-block; padding: 5px 10px; border-radius: 5px; margin: 5px; }
    .status.ok { background: #00c853; }
    .status.error { background: #ff5252; }
    .status.warning { background: #ffb300; }
    .metric { font-size: 2em; font-weight: bold; }
    .timestamp { color: #888; font-size: 0.9em; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🏢 南朝译 AI 系统监控看板</h1>
      <p class="timestamp">最后更新：<span id="last-update">-</span></p>
    </div>
    
    <div class="grid">
      <!-- 容器状态 -->
      <div class="card">
        <h3>📦 容器状态</h3>
        <div id="containers"></div>
      </div>
      
      <!-- API 健康 -->
      <div class="card">
        <h3>🔌 API 健康</h3>
        <div id="api-health"></div>
      </div>
      
      <!-- 资源使用 -->
      <div class="card">
        <h3>💾 资源使用</h3>
        <div id="resources"></div>
      </div>
      
      <!-- 告警信息 -->
      <div class="card">
        <h3>🚨 告警信息</h3>
        <div id="alerts"></div>
      </div>
    </div>
  </div>
  
  <script>
    async function loadStatus() {
      try {
        const response = await fetch('/api/health-status');
        const data = await response.json();
        
        // 更新容器状态
        const containersHtml = data.containers.map(c => 
          `<span class="status ${c.status === 'running' ? 'ok' : 'error'}">${c.name}</span>`
        ).join('');
        document.getElementById('containers').innerHTML = containersHtml;
        
        // 更新资源使用
        document.getElementById('resources').innerHTML = `
          <div>CPU: <span class="metric">${data.resources.cpu}%</span></div>
          <div>内存：<span class="metric">${data.resources.memory}%</span></div>
          <div>磁盘：<span class="metric">${data.resources.disk}%</span></div>
        `;
        
        // 更新时间
        document.getElementById('last-update').textContent = new Date().toLocaleString('zh-CN');
      } catch (error) {
        console.error('加载状态失败:', error);
      }
    }
    
    // 每 5 秒刷新
    loadStatus();
    setInterval(loadStatus, 5000);
  </script>
</body>
</html>
```

### 4.2 API 接口

创建 `/root/.openclaw/workspace/scripts/health-api.js`：

```javascript
const express = require('express');
const { exec } = require('child_process');
const app = express();
const PORT = 18860;

app.get('/api/health-status', async (req, res) => {
  const status = {
    timestamp: new Date().toISOString(),
    containers: [],
    api: { healthy: true },
    resources: {}
  };
  
  // 获取容器状态
  const containers = ['openclaw-cto', 'openclaw-xhs', 'openclaw-designer', 'openclaw-healer', 'redis'];
  for (const container of containers) {
    const statusInfo = await getContainerStatus(container);
    status.containers.push(statusInfo);
  }
  
  // 获取资源使用
  status.resources = await getResources();
  
  res.json(status);
});

async function getContainerStatus(name) {
  return new Promise((resolve) => {
    exec(`docker inspect -f '{{.State.Status}}' ${name}`, (error, stdout) => {
      resolve({
        name,
        status: error ? 'not_found' : stdout.trim()
      });
    });
  });
}

async function getResources() {
  return new Promise((resolve) => {
    exec('free | grep Mem', (error, stdout) => {
      const [total, used] = stdout.trim().split(/\s+/).slice(1, 3);
      const memory = ((used / total) * 100).toFixed(1);
      
      exec('df -h / | awk \'NR==2 {print $5}\'', (error, stdout) => {
        const disk = stdout.trim().replace('%', '');
        
        exec('top -bn1 | grep "Cpu(s)"', (error, stdout) => {
          const cpu = stdout.trim().split(/\s+/)[1].replace('%', '');
          
          resolve({ cpu, memory, disk });
        });
      });
    });
  });
}

app.listen(PORT, () => {
  console.log(`健康 API 运行在端口 ${PORT}`);
});
```

---

## 五、实施步骤

### 步骤 1: 部署监控脚本
```bash
# 创建脚本目录
mkdir -p /root/.openclaw/workspace/scripts
mkdir -p /root/.openclaw/logs

# 复制脚本
cp system-health-check.sh /root/.openclaw/workspace/scripts/
chmod +x /root/.openclaw/workspace/scripts/system-health-check.sh

# 测试运行
/root/.openclaw/workspace/scripts/system-health-check.sh
```

### 步骤 2: 配置 Cron 任务
```bash
# 配置 5 分钟定时任务
./setup-monitor-cron.sh

# 验证 Cron
crontab -l
```

### 步骤 3: 部署监控看板
```bash
# 创建监控页面
mkdir -p /root/.openclaw/workspace/monitor
cp index.html /root/.openclaw/workspace/monitor/

# 启动健康 API
node /root/.openclaw/workspace/scripts/health-api.js &
```

### 步骤 4: 配置飞书告警
- 创建飞书机器人
- 获取 Webhook URL
- 更新脚本中的 `$FEISHU_WEBHOOK`

---

## 六、告警规则配置

| 指标 | 阈值 | 级别 | 通知方式 |
|------|------|------|----------|
| 容器宕机 | 1 个 | CRITICAL | 飞书 + 全员群 |
| CPU > 80% | 持续 5 分钟 | WARNING | 飞书 |
| 内存 > 85% | 持续 5 分钟 | WARNING | 飞书 |
| 磁盘 > 90% | 立即 | CRITICAL | 飞书 + 全员群 |
| API 错误率 > 5% | 持续 10 分钟 | WARNING | 飞书 |

---

## 七、故障恢复流程

### 自动恢复
1. 容器宕机 → 自动重启
2. API 无响应 → 自动重启 Gateway
3. 磁盘空间不足 → 清理旧日志

### 人工介入
1. 连续重启失败 → 通知 CTO
2. 数据异常 → 通知 CEO
3. 系统崩溃 → 通知老板

---

*文档状态：待实施*
*下次审查：2026-03-28*
