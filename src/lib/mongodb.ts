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