# LESSONS.md - 踩坑记录
# 遇到新问题就补在这里，所有Worker启动时必读

## 飞书能力
- 各机器人（image-bot/ops-bot/tech-bot等）本身就是飞书机器人，直接回复就是发消息
- 不需要 feishu-chat 工具，那个文件不存在但不影响发消息
- 看到 feishu-chat SKILL.md not found 报错，忽略，不影响正常功能
- 群发失败时必须返回真实报错，不要用“没有工具”替代失败原因

## 飞书场景判断
- 老板李林春私信CEO = 私聊，只有CEO和老板能看到
- 在私聊里@员工没有意义，他们看不到
- 要让员工在飞书群发言：通过A2A通知员工，让他们自己去群里发

## 执行验收（强制）
- “已发群”不算完成，必须回传 messageId 才算完成
- 公开讨论任务必须回传参与人 + 各自 messageId（缺任意一个都不允许收尾）
- Master 未收齐 messageId 前，不得回复“任务完成”
- 图片类任务（封面/配图/图片交付）以“飞书文档/飞书群里可直接看到的图片”为准；禁止仅提交外部私有直链（可能403打不开）。缺可见图片证据一律视为未完成或需重做。
- 图片类任务新增必填验收字段：`prompt_source`、`prompt_id`、`prompt_title`、`final_prompt`、`generation_provider`、`generation_model`、`visible_image_evidence`。缺任意字段，不得标记完成。
- 图片主通道失败或质量不达标时，必须自动触发 fallback 出图（baoyu-image-gen），并回传 `primary_failed_reason` 与 `fallback_provider/model`。
- `prompt_source` 合法值仅允许：`nano-banana`、`xhs-cover-skill`、`custom`。使用 `xhs-cover-skill` 时禁止照搬模板示例中的固定水印/固定署名文本。

## A2A通信
- Worker间通信只用 http://172.19.0.1:端口，不用容器IP
- 容器重启后IP会变，172.19.0.x 会失效

## 任务管理
- 启动时必须先读 TASKS.md，有未完成任务优先处理
- 完成任务后通知Master，说明任务ID格式：task:时间戳

## A2A派活失败（2026-03-25）
- 现象：Master说"A2A不能用"，自己乱找脚本路径
- 原因：TOOLS.md里只有地址表，没有写发消息的命令，模型不知道用a2a-send.mjs
- 解决：在TOOLS.md里加入完整的a2a-send.mjs调用命令和各员工端口

## Master误判A2A消息来源（2026-03-25）
- 现象：员工通过A2A汇报，Master回复"这是私聊设计师看不到"
- 原因：SOUL.md里私聊规则没有区分飞书消息和A2A消息
- 解决：在SOUL.md里补充"A2A消息来源判断"，说明飞书=老板，A2A=员工

## Worker收到任务停住不动（2026-03-26）
- 现象：Master汇报"全员开始执行"，但日志显示员工没有任何动作
- 原因1：TOOLS.md是空模板，员工不知道有哪些工具可用
- 原因2：Master派任务太模糊，只说"做封面图"，员工不知道下一步
- 解决：给每个Worker写具体的TOOLS.md；Master派任务必须带完整命令+路径+汇报方式

## 设计师不用TOOLS.md里的命令，去找不存在的技能（2026-03-26）
- 现象：设计师收到图片任务，去找nano-banana-pro-prompts-recommend-skill，文件不存在
- 原因：设计师的SOUL.md里可能有旧的技能引用，优先级高于TOOLS.md
- 解决：在设计师SOUL.md里明确写"生成图片只用TOOLS.md里的curl命令，禁止找其他技能"

## Master读文件路径错误（2026-03-26）
- 现象：Master去读 /root/.openclaw/naming/workspace/ 报文件不存在
- 原因：正确路径是 /root/.openclaw/naming/private-workspace/，少了private-
- 解决：在SOUL.md里写死所有员工的正确路径
