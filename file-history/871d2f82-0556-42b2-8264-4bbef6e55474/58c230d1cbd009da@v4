---
name: monitor_task_management
description: 监控网页任务管理功能的完整实现，包括 API、表单和自动同步
type: project
---

**功能**：在 `/root/.openclaw/web-monitor.py` 监控网页中添加了完整的任务队列管理功能。

**实现内容**：
1. **任务状态查看** - `get_worker_tasks()` 获取 4 个 Worker 的任务状态
2. **任务历史追踪** - `get_task_history()` 和 `add_task_to_history()` 记录和查看任务历史
3. **创建任务表单** - 前端表单可选择 Worker、任务类型，输入任务描述
4. **手动刷新按钮** - 点击刷新任务状态和历史
5. **自动定时刷新** - 页面每 5 秒自动刷新整体状态
6. **REST API 接口**:
   - `GET /api/tasks` - 获取任务列表和历史
   - `GET /api/workers` - 获取 Worker 列表
   - `POST /api/task/create` - 创建新任务

**API 请求格式**：
```json
POST /api/task/create
{
  "worker": "tech|ops|image|naming",
  "type": "code|review|content|design|naming|debug|general",
  "content": "任务描述"
}
```

**UI 组件**：
- 任务卡片网格：显示每个 Worker 的待处理任务数量、角色、最近任务
- 创建任务表单：Worker 选择器 + 任务类型 + 输入框 + 发送按钮
- 任务历史列表：时间 + Worker + 类型 + 状态

**数据源**：
- Worker 任务数：`docker exec openclaw-{worker} ls /root/.openclaw/a2a-tasks/pending/ | wc -l`
- 最近任务：`pm2 logs master-nanchaoyi --lines 50 --nostream | grep -i 'dispatch.*{worker}'`
- 任务历史：存储在 `/root/.openclaw/logs/task-history.json`

**注意事项**：
- 当前 Worker 容器内没有 `/root/.openclaw/a2a-tasks/pending/` 目录，任务数显示 0
- 任务历史通过 `add_task_to_history()` 记录，CLI 创建任务时自动调用
- 如需完整 A2A 任务集成，需在 Master 分发任务时记录历史

**访问地址**：`http://198.200.39.21:18080`

**重启命令**：
```bash
pkill -f "web-monitor.py" && nohup python3 /root/.openclaw/web-monitor.py > /root/.openclaw/logs/web-monitor.log 2>&1 &
```

---

## 第一阶段增强（2026-03-23）

**新增功能**：

| 功能 | 函数 | 说明 |
|------|------|------|
| 员工状态卡片 | `get_staff_status()` | 区分工作/待命/失联三态，显示最后活跃时间 |
| 协作追踪 | `get_collaboration_log()` | 从 PM2 日志解析 A2A 跨 agent 通信链路 |
| Token 消耗 | `get_token_usage()` | 统计各 Worker token 使用量（需对接日志解析） |
| 记忆状态 | `get_memory_status()` | 检查 Redis 记忆键和会话文件数量 |

**UI 布局**：
- 主内容区：容器状态、任务管理、日志、记忆状态
- 侧边栏：员工状态、协作追踪、异常告警、Token 消耗
