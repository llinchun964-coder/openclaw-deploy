---
name: monitor_webpage_bugfix
description: 监控网页 web-monitor.py 的 deque 切片 bug 修复方案
type: feedback
---

**问题**：`web-monitor.py` 中 `deque` 对象不支持切片操作 `history[-30:]`，会导致 `TypeError: sequence index must be integer, not 'slice'`

**修复方法**：在访问历史数据前先将 `deque` 转为 `list`：

```python
# 错误写法
cpu_chart = generate_svg_chart([h["cpu"] for h in history[-30:]], 180, 50, "#ff6b6b")

# 正确写法
history_list = list(history)
cpu_chart = generate_svg_chart([h["cpu"] for h in history_list[-30:]], 180, 50, "#ff6b6b")
```

**为什么**：Python 的 `collections.deque` 虽然支持索引访问，但不支持切片操作。需要先转换为 `list` 才能使用切片。

**如何应用**：如果监控网页启动失败且日志显示 `deque` 切片错误，检查 `/root/.openclaw/web-monitor.py` 第 408-410 行附近，确保所有 `history[-30:]` 都改为 `list(history)[-30:]`。

**启动命令**：
```bash
nohup python3 /root/.openclaw/web-monitor.py > /root/.openclaw/logs/web-monitor.log 2>&1 &
```

**访问地址**：`http://198.200.39.21:18080`
