---
name: xhs-cover-quality
description: Produce high-quality Xiaohongshu cover images with consistent brand style and visible Feishu delivery evidence. Use when the user asks for 封面图, 小红书配图, 视觉稿, 设计图, or says 图片质量不好/重做/优化风格. Enforces two-direction drafts, scoring rubric, anti-template checks, and Feishu-visible image delivery (not private dead links).
---

# XHS Cover Quality Skill

## Goal
Deliver covers that are actually usable for account growth:
- visually professional,
- brand consistent,
- readable on mobile,
- visible in Feishu (not just "generated").

## Mandatory Workflow
Use this workflow for every cover request.

1. Clarify task in one line:
   - topic, audience, tone, deadline.
2. Check content dependency:
   - If note/copy draft is NOT ready: only produce style exploration drafts (do not finalize).
   - If note/copy draft is ready: proceed to final production.
3. Create **2 visual directions per theme**.
4. Self-score each draft (0-100) using `DESIGN-QUALITY-RUBRIC.md`.
5. Keep only best direction(s); any score < 85 must be redone.
6. Export final as `1080x1440` PNG.
7. Deliver with Feishu-visible evidence.

## Copy-First Dependency Rule (Hard Gate)
- Final cover production depends on note draft readiness.
- "Ready" means at least:
  - final title,
  - final subtitle (or explicit "no subtitle"),
  - key message angle.
- Without the above, designer may only submit:
  - moodboard/style exploration,
  - layout options,
  - typography experiments.
- Do NOT mark design task completed before copy-ready gate is passed.

## Quality Gates
Reject and redo if any condition is true:
- obvious AI watermark/artifact/template look,
- title unreadable on mobile,
- weak contrast,
- cluttered layout,
- only proposal text, no image,
- image is not directly visible in Feishu.

## Feishu Delivery Rules
- Never treat private external image links as completion evidence.
- Preferred delivery:
  - image inserted into Feishu doc (`feishu_doc upload_image`), or
  - image sent to Feishu chat/group with `messageId`.
- Completion evidence must include:
  - doc/chat link,
  - visible screenshot or messageId,
  - local output path.

## Output Format
When reporting results, use exactly:

```markdown
## 封面交付结果
- 主题：
- 方向：
- 终稿路径：
- 质量评分：
- 飞书可见证据：<doc链接或messageId>
- 备注（如重做）：
```

## Default Design Spec
- Canvas: `1080x1440`
- Safe margins: 80px+
- Typography:
  - one display font style for title,
  - one body/subtitle style,
  - avoid mixed decorative fonts.
- Brand:
  - fixed brand mark in bottom-right safe area,
  - consistent logo size and opacity.
- Composition:
  - one core message per cover,
  - strong visual hierarchy (title > subtitle > brand).

## If User Says "Quality Not Good"
Do not explain first. Execute:
1. mark current draft as failed,
2. identify top 2 visual defects,
3. regenerate 2 improved drafts,
4. deliver best one with evidence.

