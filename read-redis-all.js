
const redis = require('redis');

async function readRedis() {
  const client = redis.createClient({
    socket: {
      host: '172.19.0.1',
      port: 16379
    }
  });

  client.on('error', (err) => console.log('Redis Client Error', err));

  await client.connect();

  const keys = await client.keys('*');
  console.log('All keys found:', keys);

  for (const key of keys) {
    const value = await client.get(key);
    console.log(`\n${key}:\n${value}`);
  }

  await client.disconnect();
}

readRedis().catch(console.error);
