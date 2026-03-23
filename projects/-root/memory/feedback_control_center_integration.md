---
name: Control Center 多实例监控集成
description: 南朝译多实例架构的 Docker 容器和 A2A 端点监控集成方案
type: feedback
---

**Control Center 集成方案（已验证）**

在 `/root/openclaw-control-center/` 基础上添加轻量监控适配器，而非直接修改 18000 行的 server.ts。

**Why:**
- server.ts 有 18000 行，直接修改容易引入错误
- 多实例架构（Master+4 Worker+Redis）需要专门的监控逻辑
- 保持 Control Center 核心代码不变，便于后续同步上游更新

**How to apply:**
1. 创建独立适配器文件 `src/adapters/docker-monitor.ts`
2. 在 server.ts 中添加导入（约第 48 行）
3. 在 server.ts 中添加 API 路由（约第 1836 行，`/api/action-queue/acks/prune-preview` 之后）
4. 三个新 API 端点：
   - `/api/docker/containers` - Master(PM2)+Worker(Docker)+Redis 状态
   - `/api/a2a/endpoints` - A2A 端点健康检查（HTTP 200 验证）
   - `/api/collaboration/log` - 从 PM2 日志解析跨 Agent 通信

**WORKER_MAP 映射:**
- tech → CTO (技术员) :18811
- ops → 运营官 :18813
- image → 设计师 :18815
- naming → 南南 :18817

**验证方法:**
```bash
curl http://127.0.0.1:4310/api/docker/containers
curl http://127.0.0.1:4310/api/a2a/endpoints
curl http://127.0.0.1:4310/api/collaboration/log
```
