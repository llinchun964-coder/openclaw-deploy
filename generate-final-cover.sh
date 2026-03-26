#!/bin/bash

# 最终封面图生成 - 用Seedream
curl -s -X POST "https://ark.cn-beijing.volces.com/api/v3/images/generations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer c158c7e4-9677-476c-a19d-46e213b712dd" \
  -d '{
    "model": "doubao-seedream-5-0-260128",
    "prompt": "Xiaohongshu (Little Red Book) cover image, 3:4 vertical ratio, 1080x1440, high quality, professional social media design. Bold, eye-catching title at top: \"5 BIG MISTAKES Adults Make When Changing Names!\", subtitle below: \"Nan Chaoyi Teacher'\''s Guide\", clean and modern design, brand color #FF2442 (Xiaohongshu red) as accent, background in soft light gray, simple geometric elements, logo in bottom right corner at 20% opacity, slogan \"Nan Chaoyi · Make Names More Powerful\" at bottom, professional typography, high contrast, easy to read on mobile, no AI artifacts, no watermark.",
    "response_format": "b64_json",
    "size": "2K",
    "stream": false,
    "watermark": true
  }' > /root/.openclaw/workspace/xiaohongshu_images/new/final-cover.json 2>&1
