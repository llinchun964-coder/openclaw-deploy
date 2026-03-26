# FEEDBACK-LOG.md - 错误教训记录

**最后更新**: 2026-03-22

---

## 🚨 2026-03-22: A2A 全员报到故障

### 问题描述
老板要求通知四位数字员工到群里报到，但 A2A 通信完全失败。

### 根本原因：6 个配置错误叠加

| # | 问题 | 影响 | 修复方案 |
|---|------|------|----------|
| 1 | **feishu 插件没有软链接** | 主动发消息的工具不可用 | 创建软链接 `ln -s ~/.npm-global/lib/node_modules/openclaw/extensions/feishu ~/.openclaw/plugins/feishu` |
| 2 | **A2A 端口全部错误** | SEO-Master 找不到员工容器 | 核对 TOOLS.md 中的端口映射表，使用正确的端口 |
| 3 | **容器 a2a 端口没有对外映射** | 外部无法访问容器的 A2A 服务 | 检查 `docker port` 确认端口映射，使用容器内网 IP+内部端口 |
| 4 | **host.docker.internal 在 Linux 不生效** | 容器找不到宿主机 | Linux 使用 `172.17.0.1` 或宿主机公网 IP，不能用 `host.docker.internal` |
| 5 | **feishu 配对没有批准** | 员工 bot 无法识别用户 | 在飞书批准 bot 配对请求 |
| 6 | **defaultAgentId 配置错误** | A2A 收到任务但找不到对应 agent | 检查各容器 `config.json` 中的 `defaultAgentId` 配置 |

### 排查过程
1. 尝试 `localhost:18904` → 失败（端口未监听）
2. 检查 `docker ps` → 容器都在运行
3. 检查 `ss -tlnp` → 只有 18901(CTO) 和 18800(CEO) 在监听
4. 获取容器内网 IP → `docker inspect <container>`
5. 尝试内网 IP+内部端口 → 成功！

### 正确的 A2A 调用方式

```bash
# 获取容器内网 IP
IP=$(docker inspect <container-name> --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')

# 获取容器内部 A2A 端口
PORT=$(docker port <container-name> | grep 1880 | cut -d: -f2)

# 调用 A2A
curl -X POST http://$IP:$PORT/a2a/jsonrpc \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer 13ee86891304d966456def36705ed344' \
  -d '{...}'
```

### 容器端口映射表（修复后）

| 容器 | 内网 IP | 内部端口 | 宿主机端口 | 用途 |
|------|---------|----------|------------|------|
| openclaw-tech | 172.19.0.4 | 18801 | 18901 | CTO A2A |
| openclaw-image | 172.19.0.5 | 18803 | 18803 | 设计师 A2A |
| openclaw-ops | 172.19.0.3 | 18802 | 18802 | 运营官 A2A |
| openclaw-naming | 172.19.0.2 | 18804 | 18804 | 南南 A2A |
| 宿主机 | - | 18800 | 18800 | CEO A2A |

### 关键教训

1. **不要假设端口** - 每次先 `docker port` 确认实际映射
2. **Linux 没有 host.docker.internal** - 用内网 IP 或公网 IP
3. **多层配置要逐层验证** - 容器网络、端口映射、插件配置、bot 配对
4. **错误会叠加** - 单个小问题不致命，但多个叠加会导致系统完全瘫痪
5. **记录端口表** - 在 TOOLS.md 维护最新的端口映射表

### 修复验证
```bash
# 验证 A2A 通信
curl http://172.19.0.4:18801/a2a/jsonrpc -X POST ...

# 验证飞书消息
# 观察飞书群是否有 bot 消息
```

---

## 📝 维护清单

### 定期检查（每周）
- [ ] 检查所有容器运行状态 `docker ps`
- [ ] 检查端口映射 `docker port <container>`
- [ ] 测试 A2A 通信（发送测试消息）
- [ ] 检查飞书 bot 配对状态

### 故障排查顺序
1. 容器是否在运行？`docker ps`
2. 端口是否映射？`docker port`
3. 端口是否监听？`ss -tlnp`
4. 网络是否通？`curl http://<ip>:<port>/status`
5. A2A 是否工作？发送测试消息
6. 飞书是否配对？检查 bot 状态

---

_记录人：南朝译（CEO）_
_日期：2026-03-22_
