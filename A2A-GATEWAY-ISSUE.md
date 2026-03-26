# A2A Gateway Issue Log

## 状态：✅ 已解决 (2026-03-23)

### 历史问题
- 2026-03-21：A2A 通信失败，Worker 熔断
- 根本原因：Master 未启动，Agent Card URL 端口错误，peers 配置不完整

### 修复内容
1. Master 改用 PM2 守护（不再裸跑）
2. 所有 Agent Card URL 修正为实际监听端口
3. 所有 Worker 添加完整 peers 配置（可互相通信）
4. 健康监控每分钟自动检查并重启

### 当前状态
- 通信成功率：100%
- 健康监控：✅ 运行中
