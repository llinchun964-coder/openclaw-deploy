#!/usr/bin/env python3
"""
共享 LanceDB 实例初始化脚本
用于跨容器的语义搜索共享
"""

import lancedb
import os

# 共享数据库路径
DB_PATH = "/root/.openclaw/shared-memory/lancedb"

# 确保目录存在
os.makedirs(DB_PATH, exist_ok=True)

# 连接数据库
db = lancedb.connect(DB_PATH)

# 创建记忆表
if "memories" not in db.table_names():
    db.create_table("memories", [
        {"name": "content", "type": "utf8"},
        {"name": "category", "type": "utf8"},
        {"name": "employee", "type": "utf8"},
        {"name": "created_at", "type": "timestamp"},
    ])
    print("✅ 创建 memories 表成功")
else:
    print("ℹ️  memories 表已存在")

# 创建任务状态表
if "task_status" not in db.table_names():
    db.create_table("task_status", [
        {"name": "task_id", "type": "utf8"},
        {"name": "status", "type": "utf8"},
        {"name": "progress", "type": "int32"},
        {"name": "employee", "type": "utf8"},
        {"name": "updated_at", "type": "timestamp"},
    ])
    print("✅ 创建 task_status 表成功")
else:
    print("ℹ️  task_status 表已存在")

# 创建项目表
if "projects" not in db.table_names():
    db.create_table("projects", [
        {"name": "project_id", "type": "utf8"},
        {"name": "name", "type": "utf8"},
        {"name": "description", "type": "utf8"},
        {"name": "members", "type": "utf8"},
        {"name": "created_at", "type": "timestamp"},
    ])
    print("✅ 创建 projects 表成功")
else:
    print("ℹ️  projects 表已存在")

print(f"\n📁 数据库位置: {DB_PATH}")
print("✅ 共享 LanceDB 初始化完成！")