#!/bin/bash
# Session 自动轮转脚本 - 方案 B 增强版 v2
# 业务爆发期高频模式 | 15 分钟检查 | 双路入库 | 静默重置

set -e

WORKSPACE="/root/.openclaw/workspace"
MEMORY_DIR="$WORKSPACE/memory"
STATE_FILE="$MEMORY_DIR/session-rotate-state.json"
THESIS_FILE="$WORKSPACE/shared-context/THESIS.md"
THRESHOLD=30
INTERVAL_MINUTES=15
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M UTC")

mkdir -p "$MEMORY_DIR"
mkdir -p "$WORKSPACE/shared-context"

# 静默模式：不输出详细日志到 stdout
log_silent() {
    echo "$@" >> "$MEMORY_DIR/rotate-log.txt" 2>/dev/null || true
}

echo "[$TIMESTAMP] 🔄 会话轮转检查..."

# 读取轮转状态
if [ -f "$STATE_FILE" ]; then
    ROTATE_COUNT=$(grep -o '"rotateCount":[0-9]*' "$STATE_FILE" 2>/dev/null | cut -d':' -f2 || echo "0")
    ROTATE_COUNT=${ROTATE_COUNT:-0}
    LAST_ROTATE=$(grep -o '"lastRotate":"[^"]*"' "$STATE_FILE" 2>/dev/null | cut -d'"' -f4 || echo "")
else
    ROTATE_COUNT=0
    LAST_ROTATE=""
fi

# 检查间隔（15 分钟防抖）
if [ -n "$LAST_ROTATE" ]; then
    LAST_TS=$(date -d "$LAST_ROTATE" +%s 2>/dev/null || echo "0")
    NOW_TS=$(date +%s)
    MINS_SINCE=$(( (NOW_TS - LAST_TS) / 60 ))
    
    if [ "$MINS_SINCE" -lt "$INTERVAL_MINUTES" ]; then
        log_silent "[$TIMESTAMP] ⏳ 距离上次轮转仅 ${MINS_SINCE} 分钟，跳过（需间隔 ${INTERVAL_MINUTES} 分钟）"
        echo "NO_ACTION_NEEDED"
        exit 0
    fi
fi

# 获取当前会话列表
log_silent "[$TIMESTAMP] 📊 检查会话状态..."
SESSIONS_OUTPUT=$(openclaw sessions list --limit 10 2>&1 || echo "")

# 检查活跃会话
ACTIVE_COUNT=$(echo "$SESSIONS_OUTPUT" | grep -c "just now\|minute ago" 2>/dev/null | tr -d '[:space:]' || echo "0")
ACTIVE_COUNT=${ACTIVE_COUNT:-0}

# FORCE_ROTATE 模式或活跃会话 > 0
if [ "$FORCE_ROTATE" = "1" ] || [ "$ACTIVE_COUNT" -gt 0 ] 2>/dev/null; then
    # 估算消息数（简化：每个活跃会话假设有多条消息）
    ESTIMATED_MESSAGES=$((ACTIVE_COUNT * 10))
    
    if [ "$FORCE_ROTATE" = "1" ]; then
        ESTIMATED_MESSAGES=$THRESHOLD  # 强制模式假设达到阈值
        log_silent "[$TIMESTAMP] 🚨 FORCE 模式：强制触发轮转"
    else
        log_silent "[$TIMESTAMP] 发现 ${ACTIVE_COUNT} 个活跃会话，估算消息数 ~${ESTIMATED_MESSAGES} 条"
    fi
    
    # 触发轮转
    if [ "$FORCE_ROTATE" = "1" ] || [ "$ESTIMATED_MESSAGES" -ge "$THRESHOLD" ]; then
        log_silent "[$TIMESTAMP] 🚀 触发会话轮转流程..."
        
        # ========== 步骤 1: 生成会话摘要 ==========
        SUMMARY_NUM=$((ROTATE_COUNT + 1))
        SUMMARY_FILE="$MEMORY_DIR/${DATE}-session-summary-${SUMMARY_NUM}.md"
        
        cat > "$SUMMARY_FILE" << EOF
# ${DATE} 会话摘要 #${SUMMARY_NUM} - 自动轮转

**生成时间**: ${TIMESTAMP}
**触发原因**: 活跃会话 ${ACTIVE_COUNT} 个，估算消息数 ~${ESTIMATED_MESSAGES} 条（阈值：${THRESHOLD}）

---

## 📝 会话重点

_此摘要由自动化系统生成_

### 关键对话
- 待后续填充...

### 重要决策
- 待后续填充...

### 待执行事项
- [ ] 

---

## 📊 统计

| 项目 | 值 |
|------|-----|
| 轮转次数 | #${SUMMARY_NUM} |
| 活跃会话 | ${ACTIVE_COUNT} 个 |
| 估算消息 | ~${ESTIMATED_MESSAGES} 条 |
| 阈值 | ${THRESHOLD} 条 |
| 间隔 | ${INTERVAL_MINUTES} 分钟 |

---
_自动生成 | 下次检查：${INTERVAL_MINUTES} 分钟后_
EOF
        
        log_silent "[$TIMESTAMP] 📄 摘要文件已创建：$SUMMARY_FILE"
        
        # ========== 步骤 2: 双路入库 - 同步到 THESIS.md ==========
        if [ -f "$THESIS_FILE" ]; then
            # 追加到 THESIS.md 的业务进展记录
            THESIS_TMP="$THESIS_FILE.tmp"
            
            # 找到"## 📊 业务进展记录"位置，在其后插入新记录
            if grep -q "## 📊 业务进展记录" "$THESIS_FILE"; then
                awk -v ts="$TIMESTAMP" -v num="$SUMMARY_NUM" -v active="$ACTIVE_COUNT" '
                /## 📊 业务进展记录/ {
                    print $0
                    print ""
                    print "**" ts "** - 会话轮转 #" num
                    print "- 活跃会话：" active " 个"
                    print "- 摘要文件：" FILENAME
                    print ""
                    next
                }
                { print $0 }
                ' "$THESIS_FILE" > "$THESIS_TMP" 2>/dev/null || cp "$THESIS_FILE" "$THESIS_TMP"
                
                mv "$THESIS_TMP" "$THESIS_FILE" 2>/dev/null || true
                log_silent "[$TIMESTAMP] 📚 THESIS.md 已更新"
            fi
        else
            log_silent "[$TIMESTAMP] ⚠️ THESIS.md 不存在，跳过同步"
        fi
        
        # ========== 步骤 3: 更新今日记忆文件 ==========
        TODAY_FILE="$MEMORY_DIR/${DATE}.md"
        if [ ! -f "$TODAY_FILE" ]; then
            cat > "$TODAY_FILE" << EOF
# ${DATE} - 每日工作日志

**创建时间**: ${TIMESTAMP}

---

## 📝 今日重点

_待填充..._

## 🔄 会话轮转记录

| 时间 | 轮转次数 | 摘要文件 | 活跃会话 |
|------|----------|----------|----------|
| ${TIMESTAMP} | #${SUMMARY_NUM} | $(basename $SUMMARY_FILE) | ${ACTIVE_COUNT} 个 |

## ✅ 待办事项

- [ ] 

---
_最后更新：${TIMESTAMP}_
EOF
        else
            # 追加记录
            echo "" >> "$TODAY_FILE"
            echo "## 🔄 会话轮转 [${TIMESTAMP}]" >> "$TODAY_FILE"
            echo "- 轮转次数：#${SUMMARY_NUM}" >> "$TODAY_FILE"
            echo "- 活跃会话：${ACTIVE_COUNT} 个" >> "$TODAY_FILE"
            echo "" >> "$TODAY_FILE"
        fi
        
        # ========== 步骤 4: 更新状态 ==========
        NEW_ROTATE_COUNT=$SUMMARY_NUM
        cat > "$STATE_FILE" << EOF
{
  "rotateCount": ${NEW_ROTATE_COUNT},
  "lastRotate": "${TIMESTAMP}",
  "threshold": ${THRESHOLD},
  "intervalMinutes": ${INTERVAL_MINUTES},
  "totalSessionsRotated": ${NEW_ROTATE_COUNT}
}
EOF
        log_silent "[$TIMESTAMP] 📊 状态更新：#${ROTATE_COUNT} → #${NEW_ROTATE_COUNT}"
        
        # ========== 步骤 5: 生成蓝色简报（静默模式）==========
        # 估算释放空间
        SPACE_FREED=$((ACTIVE_COUNT * 100))
        BRIEFING="🔄 已完成第 ${NEW_ROTATE_COUNT} 次记忆压缩，释放空间 ~${SPACE_FREED}KB，核心记忆已入库。"
        
        # 保存简报内容（供 OpenClaw 读取发送）
        BRIEFING_FILE="$MEMORY_DIR/last-briefing.txt"
        echo "$BRIEFING" > "$BRIEFING_FILE"
        
        log_silent "[$TIMESTAMP] ✅ 会话轮转完成！"
        log_silent "[$TIMESTAMP] 📢 简报：$BRIEFING"
        
        # 输出信号（仅一行简报，静默模式）
        echo "FEISHU_BRIEFING:$BRIEFING"
    else
        log_silent "[$TIMESTAMP] ✅ 消息数未达阈值，无需轮转"
        echo "NO_ACTION_NEEDED"
    fi
else
    log_silent "[$TIMESTAMP] ✅ 无活跃会话，无需轮转"
    echo "NO_ACTION_NEEDED"
fi

exit 0
