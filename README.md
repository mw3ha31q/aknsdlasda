## Project Structure

```
sablier-frontend/
├── package.json
├── astro.config.mjs
├── .env.example
├── src/
│   ├── layouts/
│   │   └── Layout.astro
│   ├── pages/
│   │   ├── index.astro
│   │   ├── login.astro
│   │   ├── streams/
│   │   │   ├── index.astro
│   │   │   └── create.astro
│   │   ├── coins/
│   │   │   ├── index.astro
│   │   │   └── create.astro
│   │   └── chains/
│   │       ├── index.astro
│   │       └── create.astro
│   ├── middleware.ts
│   ├── lib/
│   │   ├── mongodb.ts
│   │   └── auth.ts
│   └── components/
│       └── Nav.astro
└── tsconfig.json
```

## 1. package.json

```json
{
  "name": "sablier-frontend",
  "type": "module",
  "version": "1.0.0",
  "scripts": {
    "dev": "astro dev",
    "start": "astro dev",
    "build": "astro build",
    "preview": "astro preview"
  },
  "dependencies": {
    "astro": "^4.3.0",
    "@astrojs/node": "^8.0.0",
    "@astrojs/tailwind": "^5.1.0",
    "mongodb": "^6.3.0",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    "nanoid": "^5.0.4",
    "zod": "^3.22.4"
  },
  "devDependencies": {
    "@types/bcryptjs": "^2.4.6",
    "@types/jsonwebtoken": "^9.0.5",
    "tailwindcss": "^3.4.0"
  }
}
```

## 2. astro.config.mjs

```javascript
import { defineConfig } from 'astro/config';
import node from '@astrojs/node';
import tailwind from '@astrojs/tailwind';

export default defineConfig({
  output: 'server',
  adapter: node({
    mode: 'standalone'
  }),
  integrations: [tailwind()]
});
```

## 3. .env.example

```
MONGODB_URI=mongodb://localhost:27017
JWT_SECRET=your-secret-key-here
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123
```

## 4. tsconfig.json

```json
{
  "extends": "astro/tsconfigs/strict",
  "compilerOptions": {
    "types": ["astro/client"]
  }
}
```

## 5. src/lib/mongodb.ts

```typescript
import { MongoClient, Db, Collection } from 'mongodb';

const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const dbName = 'sablier-db';

let client: MongoClient | null = null;
let db: Db | null = null;

export async function connectDB() {
  if (db) return db;
  
  try {
    client = new MongoClient(uri);
    await client.connect();
    db = client.db(dbName);
    console.log('Connected to MongoDB');
    return db;
  } catch (error) {
    console.error('MongoDB connection error:', error);
    throw error;
  }
}

export async function getCollection<T = any>(name: string): Promise<Collection<T>> {
  const database = await connectDB();
  return database.collection<T>(name);
}

export interface Stream {
  streamId: string;
  coinKey: string;
  amount: number;
}

export interface Coin {
  key: string;
  coin: string;
  image: string;
  chainId: string;
}

export interface Chain {
  chainId: string;
  chainName: string;
  chainImage: string;
}
```

## 6. src/lib/auth.ts

```typescript
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'default-secret-key';
const ADMIN_USERNAME = process.env.ADMIN_USERNAME || 'admin';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'admin123';

// Hash the admin password
const ADMIN_PASSWORD_HASH = bcrypt.hashSync(ADMIN_PASSWORD, 10);

export function verifyPassword(username: string, password: string): boolean {
  if (username !== ADMIN_USERNAME) return false;
  return bcrypt.compareSync(password, ADMIN_PASSWORD_HASH);
}

export function generateToken(username: string): string {
  return jwt.sign({ username }, JWT_SECRET, { expiresIn: '24h' });
}

export function verifyToken(token: string): { username: string } | null {
  try {
    return jwt.verify(token, JWT_SECRET) as { username: string };
  } catch {
    return null;
  }
}
```

## 7. src/middleware.ts

```typescript
import { defineMiddleware } from "astro/middleware";
import { verifyToken } from "./lib/auth";

const publicRoutes = ['/login'];

export const onRequest = defineMiddleware(async ({ url, cookies, redirect }, next) => {
  const pathname = url.pathname;
  
  // Allow public routes
  if (publicRoutes.includes(pathname)) {
    return next();
  }
  
  // Check for auth token
  const token = cookies.get('auth-token')?.value;
  
  if (!token || !verifyToken(token)) {
    return redirect('/login');
  }
  
  return next();
});
```

## 8. src/layouts/Layout.astro

```astro
---
import Nav from '../components/Nav.astro';

export interface Props {
  title: string;
}

const { title } = Astro.props;
---

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>{title}</title>
</head>
<body class="bg-gray-50">
  <Nav />
  <main class="container mx-auto px-4 py-8">
    <slot />
  </main>
</body>
</html>
```

## 9. src/components/Nav.astro

```astro
---
const currentPath = Astro.url.pathname;
---

<nav class="bg-white shadow-sm border-b">
  <div class="container mx-auto px-4">
    <div class="flex justify-between items-center h-16">
      <div class="flex space-x-8">
        <a href="/" class="text-xl font-bold">Sablier Admin</a>
        <div class="flex items-center space-x-4">
          <a href="/streams" class={`hover:text-blue-600 ${currentPath.includes('/streams') ? 'text-blue-600' : ''}`}>
            Streams
          </a>
          <a href="/coins" class={`hover:text-blue-600 ${currentPath.includes('/coins') ? 'text-blue-600' : ''}`}>
            Coins
          </a>
          <a href="/chains" class={`hover:text-blue-600 ${currentPath.includes('/chains') ? 'text-blue-600' : ''}`}>
            Chains
          </a>
        </div>
      </div>
      <form action="/api/logout" method="POST">
        <button type="submit" class="text-red-600 hover:text-red-800">Logout</button>
      </form>
    </div>
  </div>
</nav>
```

## 10. src/pages/login.astro

```astro
---
import Layout from '../layouts/Layout.astro';
import { verifyPassword, generateToken } from '../lib/auth';

let error = '';

if (Astro.request.method === 'POST') {
  const formData = await Astro.request.formData();
  const username = formData.get('username')?.toString() || '';
  const password = formData.get('password')?.toString() || '';
  
  if (verifyPassword(username, password)) {
    const token = generateToken(username);
    Astro.cookies.set('auth-token', token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      path: '/'
    });
    return Astro.redirect('/');
  } else {
    error = 'Invalid username or password';
  }
}
---

<Layout title="Login">
  <div class="max-w-md mx-auto mt-20">
    <div class="bg-white p-8 rounded-lg shadow-md">
      <h1 class="text-2xl font-bold mb-6">Login</h1>
      
      {error && (
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
          {error}
        </div>
      )}
      
      <form method="POST">
        <div class="mb-4">
          <label class="block text-sm font-medium mb-2" for="username">Username</label>
          <input 
            type="text" 
            id="username" 
            name="username" 
            required
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        
        <div class="mb-6">
          <label class="block text-sm font-medium mb-2" for="password">Password</label>
          <input 
            type="password" 
            id="password" 
            name="password" 
            required
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        
        <button 
          type="submit"
          class="w-full bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700"
        >
          Login
        </button>
      </form>
    </div>
  </div>
</Layout>
```

## 11. src/pages/index.astro

```astro
---
import Layout from '../layouts/Layout.astro';
import { getCollection } from '../lib/mongodb';

const streams = await getCollection('streams');
const coins = await getCollection('coins');
const chains = await getCollection('chains');

const streamCount = await streams.countDocuments();
const coinCount = await coins.countDocuments();
const chainCount = await chains.countDocuments();
---

<Layout title="Dashboard">
  <h1 class="text-3xl font-bold mb-8">Dashboard</h1>
  
  <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
    <div class="bg-white p-6 rounded-lg shadow">
      <h2 class="text-xl font-semibold mb-2">Streams</h2>
      <p class="text-3xl font-bold text-blue-600">{streamCount}</p>
      <a href="/streams" class="text-sm text-blue-600 hover:text-blue-800 mt-2 inline-block">
        View all →
      </a>
    </div>
    
    <div class="bg-white p-6 rounded-lg shadow">
      <h2 class="text-xl font-semibold mb-2">Coins</h2>
      <p class="text-3xl font-bold text-green-600">{coinCount}</p>
      <a href="/coins" class="text-sm text-green-600 hover:text-green-800 mt-2 inline-block">
        View all →
      </a>
    </div>
    
    <div class="bg-white p-6 rounded-lg shadow">
      <h2 class="text-xl font-semibold mb-2">Chains</h2>
      <p class="text-3xl font-bold text-purple-600">{chainCount}</p>
      <a href="/chains" class="text-sm text-purple-600 hover:text-purple-800 mt-2 inline-block">
        View all →
      </a>
    </div>
  </div>
</Layout>
```

## 12. src/pages/streams/index.astro

```astro
---
import Layout from '../../layouts/Layout.astro';
import { getCollection, type Stream } from '../../lib/mongodb';

const streamsCollection = await getCollection<Stream>('streams');
const streams = await streamsCollection.find({}).toArray();
---

<Layout title="Streams">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold">Streams</h1>
    <a href="/streams/create" class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
      Create Stream
    </a>
  </div>
  
  <div class="bg-white rounded-lg shadow overflow-hidden">
    <table class="min-w-full">
      <thead class="bg-gray-50">
        <tr>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
            Stream ID
          </th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
            Coin Key
          </th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
            Amount
          </th>
        </tr>
      </thead>
      <tbody class="bg-white divide-y divide-gray-200">
        {streams.map(stream => (
          <tr>
            <td class="px-6 py-4 whitespace-nowrap font-medium">{stream.streamId}</td>
            <td class="px-6 py-4 whitespace-nowrap">{stream.coinKey}</td>
            <td class="px-6 py-4 whitespace-nowrap">{stream.amount}</td>
          </tr>
        ))}
      </tbody>
    </table>
    
    {streams.length === 0 && (
      <div class="text-center py-8 text-gray-500">
        No streams found
      </div>
    )}
  </div>
</Layout>
```

## 13. src/pages/streams/create.astro

```astro
---
import Layout from '../../layouts/Layout.astro';
import { getCollection, type Stream, type Coin } from '../../lib/mongodb';

const coinsCollection = await getCollection<Coin>('coins');
const coins = await coinsCollection.find({}).toArray();

let success = false;
let error = '';

function generateStreamId(): string {
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const digits = '0123456789';
  
  const part1 = letters[Math.floor(Math.random() * 26)] + letters[Math.floor(Math.random() * 26)];
  const part2 = digits[Math.floor(Math.random() * 10)];
  const part3 = Array.from({ length: 4 }, () => digits[Math.floor(Math.random() * 10)]).join('');
  
  return `${part1}-${part2}-${part3}`;
}

if (Astro.request.method === 'POST') {
  try {
    const formData = await Astro.request.formData();
    const coinKey = formData.get('coinKey')?.toString() || '';
    const amount = parseFloat(formData.get('amount')?.toString() || '0');
    
    if (!coinKey || isNaN(amount) || amount <= 0) {
      error = 'Please fill all fields correctly';
    } else {
      const streamsCollection = await getCollection<Stream>('streams');
      
      // Generate unique stream ID
      let streamId = generateStreamId();
      let exists = await streamsCollection.findOne({ streamId });
      
      while (exists) {
        streamId = generateStreamId();
        exists = await streamsCollection.findOne({ streamId });
      }
      
      await streamsCollection.insertOne({
        streamId,
        coinKey,
        amount
      });
      
      success = true;
    }
  } catch (err) {
    error = 'Failed to create stream';
    console.error(err);
  }
}
---

<Layout title="Create Stream">
  <div class="max-w-2xl mx-auto">
    <h1 class="text-3xl font-bold mb-6">Create Stream</h1>
    
    {success && (
      <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
        Stream created successfully!
        <a href="/streams" class="ml-2 underline">View all streams</a>
      </div>
    )}
    
    {error && (
      <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
        {error}
      </div>
    )}
    
    <div class="bg-white rounded-lg shadow p-6">
      <form method="POST">
        <div class="mb-4">
          <label class="block text-sm font-medium mb-2" for="coinKey">Coin</label>
          <select 
            id="coinKey" 
            name="coinKey" 
            required
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="">Select a coin</option>
            {coins.map(coin => (
              <option value={coin.key}>{coin.key} ({coin.coin})</option>
            ))}
          </select>
        </div>
        
        <div class="mb-6">
          <label class="block text-sm font-medium mb-2" for="amount">Amount</label>
          <input 
            type="number" 
            step="0.01"
            id="amount" 
            name="amount" 
            required
            placeholder="0.00"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        
        <div class="flex gap-4">
          <button 
            type="submit"
            class="bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700"
          >
            Create Stream
          </button>
          <a 
            href="/streams"
            class="bg-gray-200 text-gray-800 py-2 px-4 rounded-lg hover:bg-gray-300"
          >
            Cancel
          </a>
        </div>
      </form>
    </div>
  </div>
</Layout>
```

## 14. src/pages/coins/index.astro

```astro
---
import Layout from '../../layouts/Layout.astro';
import { getCollection, type Coin } from '../../lib/mongodb';

const coinsCollection = await getCollection<Coin>('coins');
const coins = await coinsCollection.find({}).toArray();
---

<Layout title="Coins">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold">Coins</h1>
    <a href="/coins/create" class="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700">
      Create Coin
    </a>
  </div>
  
  <div class="bg-white rounded-lg shadow overflow-hidden">
    <table class="min-w-full">
      <thead class="bg-gray-50">
        <tr>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
            Key
          </th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
            Coin
          </th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
            Image
          </th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
            Chain ID
          </th>
        </tr>
      </thead>
      <tbody class="bg-white divide-y divide-gray-200">
        {coins.map(coin => (
          <tr>
            <td class="px-6 py-4 whitespace-nowrap font-medium">{coin.key}</td>
            <td class="px-6 py-4 whitespace-nowrap">{coin.coin}</td>
            <td class="px-6 py-4 whitespace-nowrap">
              {coin.image && <img src={coin.image} alt={coin.coin} class="h-8 w-8" />}
            </td>
            <td class="px-6 py-4 whitespace-nowrap">{coin.chainId}</td>
          </tr>
        ))}
      </tbody>
    </table>
    
    {coins.length === 0 && (
      <div class="text-center py-8 text-gray-500">
        No coins found
      </div>
    )}
  </div>
</Layout>
```

## 15. src/pages/coins/create.astro

```astro
---
import Layout from '../../layouts/Layout.astro';
import { getCollection, type Coin, type Chain } from '../../lib/mongodb';

const chainsCollection = await getCollection<Chain>('chains');
const chains = await chainsCollection.find({}).toArray();

let success = false;
let error = '';

if (Astro.request.method === 'POST') {
  try {
    const formData = await Astro.request.formData();
    const coin = formData.get('coin')?.toString() || '';
    const image = formData.get('image')?.toString() || '';
    const chainId = formData.get('chainId')?.toString() || '';
    
    if (!coin || !chainId) {
      error = 'Coin name and chain are required';
    } else {
      const coinsCollection = await getCollection<Coin>('coins');
      
      const key = `${coin.toLowerCase()}-${chainId}`;
      
      // Check if coin already exists
      const exists = await coinsCollection.findOne({ key });
      if (exists) {
        error = 'Coin with this key already exists';
      } else {
        await coinsCollection.insertOne({
          key,
          coin,
          image,
          chainId
        });
        
        success = true;
      }
    }
  } catch (err) {
    error = 'Failed to create coin';
    console.error(err);
  }
}
---

<Layout title="Create Coin">
  <div class="max-w-2xl mx-auto">
    <h1 class="text-3xl font-bold mb-6">Create Coin</h1>
    
    {success && (
      <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
        Coin created successfully!
        <a href="/coins" class="ml-2 underline">View all coins</a>
      </div>
    )}
    
    {error && (
      <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
        {error}
      </div>
    )}
    
    <div class="bg-white rounded-lg shadow p-6">
      <form method="POST">
        <div class="mb-4">
          <label class="block text-sm font-medium mb-2" for="coin">Coin Name</label>
          <input 
            type="text" 
            id="coin" 
            name="coin" 
            required
            placeholder="e.g. Bitcoin"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        
        <div class="mb-4">
          <label class="block text-sm font-medium mb-2" for="image">Image URL</label>
          <input 
            type="url" 
            id="image" 
            name="image"
            placeholder="https://example.com/coin-image.png"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        
        <div class="mb-6">
          <label class="block text-sm font-medium mb-2" for="chainId">Chain</label>
          <select 
            id="chainId" 
            name="chainId" 
            required
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="">Select a chain</option>
            {chains.map(chain => (
              <option value={chain.chainId}>{chain.chainName}</option>
            ))}
          </select>
        </div>
        
        <div class="flex gap-4">
          <button 
            type="submit"
            class="bg-green-600 text-white py-2 px-4 rounded-lg hover:bg-green-700"
          >
            Create Coin
          </button>
          <a 
            href="/coins"
            class="bg-gray-200 text-gray-800 py-2 px-4 rounded-lg hover:bg-gray-300"
          >
            Cancel
          </a>
        </div>
      </form>
    </div>
  </div>
</Layout>
```

## 16. src/pages/chains/index.astro

```astro
---
import Layout from '../../layouts/Layout.astro';
import { getCollection, type Chain } from '../../lib/mongodb';

const chainsCollection = await getCollection<Chain>('chains');
const chains = await chainsCollection.find({}).toArray();
---

<Layout title="Chains">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold">Chains</h1>
    <a href="/chains/create" class="bg-purple-600 text-white px-4 py-2 rounded-lg hover:bg-purple-700">
      Create Chain
    </a>
  </div>
  
  <div class="bg-white rounded-lg shadow overflow-hidden">
    <table class="min-w-full">
      <thead class="bg-gray-50">
        <tr>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
            Chain ID
          </th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
            Chain Name
          </th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
            Image
          </th>
        </tr>
      </thead>
      <tbody class="bg-white divide-y divide-gray-200">
        {chains.map(chain => (
          <tr>
            <td class="px-6 py-4 whitespace-nowrap font-medium">{chain.chainId}</td>
            <td class="px-6 py-4 whitespace-nowrap">{chain.chainName}</td>
            <td class="px-6 py-4 whitespace-nowrap">
              {chain.chainImage && <img src={chain.chainImage} alt={chain.chainName} class="h-8 w-8" />}
            </td>
          </tr>
        ))}
      </tbody>
    </table>
    
    {chains.length === 0 && (
      <div class="text-center py-8 text-gray-500">
        No chains found
      </div>
    )}
  </div>
</Layout>
```

## 17. src/pages/chains/create.astro

```astro
---
import Layout from '../../layouts/Layout.astro';
import { getCollection, type Chain } from '../../lib/mongodb';

let success = false;
let error = '';

if (Astro.request.method === 'POST') {
  try {
    const formData = await Astro.request.formData();
    const chainName = formData.get('chainName')?.toString() || '';
    const chainImage = formData.get('chainImage')?.toString() || '';
    
    if (!chainName) {
      error = 'Chain name is required';
    } else {
      const chainsCollection = await getCollection<Chain>('chains');
      
      const chainId = chainName.toLowerCase().replace(/\s+/g, '-');
      
      // Check if chain already exists
      const exists = await chainsCollection.findOne({ chainId });
      if (exists) {
        error = 'Chain with this ID already exists';
      } else {
        await chainsCollection.insertOne({
          chainId,
          chainName,
          chainImage
        });
        
        success = true;
      }
    }
  } catch (err) {
    error = 'Failed to create chain';
    console.error(err);
  }
}
---

<Layout title="Create Chain">
  <div class="max-w-2xl mx-auto">
    <h1 class="text-3xl font-bold mb-6">Create Chain</h1>
    
    {success && (
      <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
        Chain created successfully!
        <a href="/chains" class="ml-2 underline">View all chains</a>
      </div>
    )}
    
    {error && (
      <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
        {error}
      </div>
    )}
    
    <div class="bg-white rounded-lg shadow p-6">
      <form method="POST">
        <div class="mb-4">
          <label class="block text-sm font-medium mb-2" for="chainName">Chain Name</label>
          <input 
            type="text" 
            id="chainName" 
            name="chainName" 
            required
            placeholder="e.g. Ethereum"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
          <p class="text-xs text-gray-500 mt-1">Chain ID will be generated automatically (lowercase)</p>
        </div>
        
        <div class="mb-6">
          <label class="block text-sm font-medium mb-2" for="chainImage">Image URL</label>
          <input 
            type="url" 
            id="chainImage" 
            name="chainImage"
            placeholder="https://example.com/chain-logo.png"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        
        <div class="flex gap-4">
          <button 
            type="submit"
            class="bg-purple-600 text-white py-2 px-4 rounded-lg hover:bg-purple-700"
          >
            Create Chain
          </button>
          <a 
            href="/chains"
            class="bg-gray-200 text-gray-800 py-2 px-4 rounded-lg hover:bg-gray-300"
          >
            Cancel
          </a>
        </div>
      </form>
    </div>
  </div>
</Layout>
```

## 18. src/pages/api/logout.ts (API Route)

```typescript
export async function POST({ cookies, redirect }) {
  cookies.delete('auth-token', { path: '/' });
  return redirect('/login');
}
```

## Setup Instructions

1. **Initialize the project:**
```bash
npm create astro@latest sablier-frontend -- --template minimal
cd sablier-frontend
npm install
```

2. **Install dependencies:**
```bash
npm install mongodb bcryptjs jsonwebtoken nanoid zod @astrojs/node @astrojs/tailwind
npm install -D @types/bcryptjs @types/jsonwebtoken tailwindcss
```

3. **Copy the .env.example to .env:**
```bash
cp .env.example .env
```

4. **Update .env with your MongoDB connection string and credentials**

5. **Run the development server:**
```bash
npm run dev
```

## Features Implemented

✅ **Basic Authentication**: Simple username/password auth with JWT tokens
✅ **Stream Management**: 
  - Create streams with auto-generated unique IDs (XX-N-NNNN format)
  - List all streams
  - Validates uniqueness of stream IDs

✅ **Coin Management**:
  - Create coins with automatic key generation (coin-chain format)
  - Select from available chains
  - Image URL support

✅ **Chain Management**:
  - Create chains with auto-generated chainId (lowercase)
  - Image URL support

✅ **Dashboard**: Shows counts of all entities
✅ **Responsive UI**: Using Tailwind CSS
✅ **Server-side rendering**: Using Astro with Node adapter
✅ **MongoDB Integration**: Direct connection to MongoDB

## Default Credentials
- Username: `admin`
- Password: `admin123`

You can change these in the `.env` file.