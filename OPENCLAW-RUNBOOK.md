# OpenClaw 南朝译 — 运行总纲（单一事实来源）

> 用途：把「谁在跑、看什么日志、什么叫真故障、路径别写错」固定下来，减少误判和重复踩坑。  
> 与 `OPERATING-SYSTEM.md`（章程）、`MEMORY.md`（硬规则）、`LESSONS.md`（经验）配套使用。

---

## 1. 拓扑一览

| 角色 | 进程形态 | A2A / 说明 |
|------|-----------|------------|
| Master（南朝译） | PM2 宿主机 | 18800；飞书私聊老板 |
| 技术员 | Docker | 18811 |
| 运营官 | Docker | 18802 |
| 设计师 | Docker | 18803 |
| 南南 | Docker | 18804 |

- **A2A 基址（Master 调员工）**：`http://172.19.0.1:<端口>`（不用容器内 IP，重启会变）。
- **Redis**：宿主机映射常见为 `16379`（以实际 `docker-compose`/配置为准）。

---

## 2. 「健康」vs「在干活」

| 现象 | 含义 |
|------|------|
| `health-monitor` 全绿 | 进程/端口/Redis 可达，**不等于**任务在消队列。 |
| Redis pending 长期不降 | **队列卡住或执行慢**，要查各角色日志与 TASKS，不是「调度死了」。 |
| 飞书「熔断」告警 | 必须以 **Master error 日志里成对的 open/closed 与时间** 为准；勿用截断的 `pm2 logs \| tail` 当唯一证据。 |

---

## 3. 日志与排障优先级

1. **Master**：`/root/.pm2/logs/master-nanchaoyi-error.log`、`...-out.log`  
   - 关注：`peer.circuit`、`401`（embedding/API key）、超时、ENOENT。
2. **健康汇总**：`health-monitor.log`（若存在且持续更新，以它为「是否活着」的主参考）。  
3. **任务审计**：`auto-executor.log`、`auto-executor-anomalies.log`（EVIDENCE_GAP = 缺证据，不自动改任务状态）。
4. **若 `health-check.log` 很久不更新**：可能 cron 已换脚本或路径不一致，以 `health-monitor` 为准或统一脚本。

---

## 4. 路径速查（避免 ENOENT）

| 用途 | 正确路径 |
|------|-----------|
| 团队任务与证据 | `/root/.openclaw/workspace/TASKS.md` |
| 封面质量评分（Master/设计师都认这一份也可） | `/root/.openclaw/workspace/DESIGN-QUALITY-RUBRIC.md` |
| xhs 封面质量技能（含同目录 rubric 副本） | `/root/.openclaw/workspace/skills/xhs-cover-quality/SKILL.md` |
| 宝玉技能单体（如出图兜底） | `/root/.openclaw/workspace/skills/baoyu-skills/skills/baoyu-image-gen/SKILL.md` |
| 宝玉 monorepo 根索引（勿再读不存在的根 `SKILL.md` 旧路径） | `/root/.openclaw/workspace/skills/baoyu-skills/SKILL.md` |
| ClawHub 内置技能（系统包） | `~/.npm-global/lib/node_modules/openclaw/skills/clawhub/SKILL.md`（**不在** workspace/skills 下） |

---

## 5. 熔断告警（控制面）

### 若飞书仍出现「…已暂时隔离…」且标题是「熔断器触发 - 某角色」

说明跑的是 **旧版 `alert-notifier`**（当前仓库已改为合并标题「熔断器触发（N 个角色）」且无「已暂时隔离」这句）。请 **把 `/root/openclaw-control-center` 同步到实际监听 4310 的那台机器**，并 **重启** 该 Node 进程（不是只重启 `master-nanchaoyi`）。

### 环境变量（新代码）

| 变量 | 作用 |
|------|------|
| `OPENCLAW_DISABLE_ALERT_MONITOR=true` | **不启动** 30s 定时器 → **所有**自动飞书告警都不发 |
| `OPENCLAW_DISABLE_FEISHU_ALERTS=true` | 仍检测、仍写告警历史，但 **一律不调飞书 API** |
| `OPENCLAW_FEISHU_CIRCUIT_ALERTS=true` | 默认不写此变量 = **熔断不推飞书**；写 `true` 才推 |

示例 PM2：`openclaw-control-center/ecosystem.monitor.example.config.cjs`。

### 不知道进程在哪时

在**跑 OpenClaw 的那台 Linux**上执行：

```bash
bash /root/openclaw-control-center/scripts/who-runs-ui.sh
```

会列出 `CWD=.../openclaw-control-center` 的 **PID** 和 **UI_MODE** 等环境变量。告警轮询由该进程在启动 UI 时注册（`startAlertMonitor`），**不在** `master-nanchaoyi` 里。

**本次在这台机上已看到的实例（供对照）**：曾有进程 `node --import tsx src/index.ts`，工作目录 `/root/openclaw-control-center`，`UI_MODE=true`（未进 PM2，需记下手头 PID 后 `kill` 再以新环境变量重启）。

---

## 6. 证据闭环（防「说了=做了」）

- 飞书群动作：**可见内容 + `messageId`**（或文档链接）。
- 出图：**飞书内可见图**（上传/文档内嵌），避免仅私有 TOS 直链。
- Master 汇总：对齐 `OPERATING-SYSTEM.md` / `MEMORY.md` 的并行下发与收敛规则。

---

## 7. 运维速查命令（需要时在服务器执行）

```bash
pm2 list
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
redis-cli -p 16379 ping
for p in 18800 18811 18802 18803 18804; do echo -n ":$p "; curl -s -o /dev/null -w '%{http_code}\n' "http://127.0.0.1:$p/" || true; done
```

---

## 8. 常见根因清单

| 症状 | 常见根因 |
|------|-----------|
| embedding / memory 同步 401 | OpenAI（或配置项）API key 无效或环境未注入 |
| 读技能 ENOENT | 文档写了 `workspace/skills/baoyu-skills/SKILL.md` 等错误路径 → 用本节路径表 |
| 熔断误报 | 只看 tail、未配对 closed；或告警进程未更新 |
| pending 不降 | 任务难/阻塞/未真正执行；查对应容器日志与 TASKS |

---

*文档版本：与仓库内实际路径同步维护；变更路径时请同时改本节与相关 SOUL/skills。*
