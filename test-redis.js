
const redis = require('redis');

async function testRedis() {
  const client = redis.createClient({
    socket: {
      host: '172.19.0.1',
      port: 16379
    }
  });

  client.on('error', (err) => console.log('Redis Client Error', err));

  try {
    await client.connect();
    console.log('✅ Redis连接成功');
    
    const info = await client.info();
    console.log('\nRedis服务器信息:');
    console.log(info);
    
    await client.set('test-key', 'test-value');
    const value = await client.get('test-key');
    console.log('\n测试写入/读取成功:', value);
    
    await client.del('test-key');
  } catch (err) {
    console.log('❌ 错误:', err);
  }

  await client.disconnect();
}

testRedis().catch(console.error);
