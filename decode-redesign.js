const fs = require('fs');

const json = fs.readFileSync('/root/.openclaw/workspace/xiaohongshu_images/new/redesign-1.json', 'utf8');
const data = JSON.parse(json);
const b64 = data.data[0].b64_json;
const buffer = Buffer.from(b64, 'base64');
fs.writeFileSync('/root/.openclaw/workspace/xiaohongshu_images/new/redesign-1.png', buffer);
console.log('Saved: redesign-1.png');
