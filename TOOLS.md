# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

## Master · A2A 路由（南朝译）

敏感 token **仅本文件**；`SOUL.md` 只写「见本节」。

| 角色 | `peer-url`（宿主机访问 Docker 网桥时常用） |
|------|------------------------------------------|
| Master（本机网关，非 peer 消息目标） | `http://172.19.0.1:18800` |
| 数据官 | `http://172.19.0.1:18811` |
| 运营官 | `http://172.19.0.1:18802` |
| 设计师 | `http://172.19.0.1:18803` |
| 命名官（南南） | `http://172.19.0.1:18804` |

**A2A 共享 token**（`a2a-send.mjs --token`）：`13ee86891304d966456def36705ed344`

脚本路径：`/root/.openclaw/workspace/plugins/a2a-gateway/skill/scripts/a2a-send.mjs`（若部署不同，以本机为准）。

## Master · 飞书（知识库 / 看板）

| 项 | 值 |
|----|-----|
| 知识库根 `node_token` | `V0WLwOHRzikdvokQJAdcosxtnDI` |
| `space_id` | `7621385108884327356` |
| 小红书成稿台账 Wiki | https://fcnnipdwrnch.feishu.cn/wiki/SoBBw6HK5i5hBnkDOFWcQZ97nJI?from=from_copylink |
| Bitable 任务管理（示例） | https://fcnnipdwrnch.feishu.cn/base/XeTgbViCuaQPTls7nDScL10dngd |

成稿台账**列名与状态规则**以运营工作区为准：**`/root/.openclaw/ops/private-workspace/TOOLS.md`**（单一事实来源，避免此处重复过期）。

## Master · team-tasks 数据目录

`task_manager.py` 默认 `TEAM_TASKS_DIR` 可能指向他机路径，**本机建议**：

```bash
export TEAM_TASKS_DIR=/root/.openclaw/workspace/data/team-tasks
```

再执行 `task_manager.py`；项目 JSON 会落在该目录下。

---

Add whatever helps you do your job. This is your cheat sheet.
