---
name: 监控系统统一方案
description: 南朝译监控系统从 Python 迁移到 Control Center 的完整方案
type: project
---

**监控系统统一完成 - 2026-03-23**

**Why:**
- 两个监控系统（Python web-monitor.py 和 Control Center）功能重复，维护成本高
- Python 监控网页功能孤立，无法与其他 Control Center 功能联动
- Control Center 有更好的扩展性和技术栈一致性

**How to apply:**
1. 旧 Python 监控进程已停止（`pkill -f web-monitor.py`）
2. 所有监控功能整合到 Control Center UI: http://127.0.0.1:4310
3. **总览页面**直接显示南朝译系统健康卡片（6 个实例状态、A2A 健康度）
4. 导航栏"南朝译监控"入口可查看完整监控详情
5. 三个 API 端点提供数据：`/api/docker/containers`, `/api/a2a/endpoints`, `/api/collaboration/log`

**启动命令:**
```bash
cd /root/openclaw-control-center
npm run dev:ui  # 或后台运行：nohup npm run dev:ui > /root/.openclaw/logs/control-center.log 2>&1 &
```

**监控的 6 个实例：**
- CEO (Master/PM2) - 18789/18800
- CTO (技术员) - 18811
- 运营官 - 18813
- 设计师 - 18815
- 南南 - 18817
- Redis 记忆池 - 16379

**文件位置:**
- 适配器：`/root/openclaw-control-center/src/adapters/docker-monitor.ts`
- UI server: `/root/openclaw-control-center/src/ui/server.ts`
- 使用文档：`/root/.openclaw/monitor-readme.md`

**全模块整合效果:**
| 页面 | 整合内容 |
|------|----------|
| 总览页 | 系统健康卡片（6 实例状态、A2A 健康） |
| 员工页 | 4 个 Worker 作为员工显示（CTO/运营官/设计师/南南） |
| 记忆页 | Redis 记忆池 + 各 Worker 会话文件状态表 |
| 协作页 | A2A 协作日志（PM2 日志解析） |
| 南朝译监控 | 完整监控表格（CPU/内存/延迟/协作日志） |

**数据流:**
- `docker-monitor.ts` 提供 5 个函数：`getContainerStatuses()`, `getA2AEndpoints()`, `getCollaborationLog()`, `getNanchaoyiStaffMembers()`, `getNanchaoyiMemoryStatus()`
- server.ts 按需加载数据并渲染到对应页面
- 每次访问页面自动刷新数据
