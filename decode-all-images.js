const fs = require('fs');

// 解码第1张
const json1 = fs.readFileSync('/root/.openclaw/workspace/xiaohongshu_images/new/cover-1.json', 'utf8');
const data1 = JSON.parse(json1);
const b64_1 = data1.data[0].b64_json;
const buffer1 = Buffer.from(b64_1, 'base64');
fs.writeFileSync('/root/.openclaw/workspace/xiaohongshu_images/new/cover-1-workplace.png', buffer1);
console.log('Saved: cover-1-workplace.png');

// 解码第2张
const json2 = fs.readFileSync('/root/.openclaw/workspace/xiaohongshu_images/new/cover-2.json', 'utf8');
const data2 = JSON.parse(json2);
const b64_2 = data2.data[0].b64_json;
const buffer2 = Buffer.from(b64_2, 'base64');
fs.writeFileSync('/root/.openclaw/workspace/xiaohongshu_images/new/cover-2-ancient.png', buffer2);
console.log('Saved: cover-2-ancient.png');

// 解码第3张
const json3 = fs.readFileSync('/root/.openclaw/workspace/xiaohongshu_images/new/cover-3.json', 'utf8');
const data3 = JSON.parse(json3);
const b64_3 = data3.data[0].b64_json;
const buffer3 = Buffer.from(b64_3, 'base64');
fs.writeFileSync('/root/.openclaw/workspace/xiaohongshu_images/new/cover-3-tech.png', buffer3);
console.log('Saved: cover-3-tech.png');

console.log('All images decoded!');
