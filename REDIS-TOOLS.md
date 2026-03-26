# Redis 共享记忆池使用指南

## 连接信息
- 地址：172.19.0.1:16379（容器内用这个）
- 宿主机：127.0.0.1:16379

## 任务完成后写入进度
```bash
redis-cli -h 172.19.0.1 -p 16379 HSET task:进度 角色 "完成内容简述"
redis-cli -h 172.19.0.1 -p 16379 EXPIRE task:进度 86400
```

## 查看所有人进度
```bash
redis-cli -h 172.19.0.1 -p 16379 HGETALL task:进度
```

## 写入长期记忆
```bash
redis-cli -h 172.19.0.1 -p 16379 SET memory:关键词 "内容" EX 604800
```

## 读取长期记忆
```bash
redis-cli -h 172.19.0.1 -p 16379 GET memory:关键词
```

## 使用规则
- 完成重要任务后必须写入 Redis
- key 格式：task:日期:任务名
- 南朝译可随时查询所有人进度
