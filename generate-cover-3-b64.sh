#!/bin/bash

# 第3张：科技风 - b64_json
curl -X POST "https://ark.cn-beijing.volces.com/api/v3/images/generations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer c158c7e4-9677-476c-a19d-46e213b712dd" \
  -d '{
    "model": "doubao-seedream-5-0-260128",
    "prompt": "小红书封面图，科技风格，科技蓝配紫色，大字标题：AI+传统文化，科学取名，副标题：南朝译老师独创，科技网格背景配光点效果，logo有发光效果，3:4比例，高清晰度",
    "response_format": "b64_json",
    "size": "2K",
    "stream": false,
    "watermark": true
  }' 2>&1
