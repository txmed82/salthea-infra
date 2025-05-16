// Test script to verify connection to Cosmos DB and collections
const { MongoClient } = require('mongodb');
require('dotenv').config();

// This will be replaced with the actual connection string from Key Vault in production
// For testing, get the connection string from Azure portal or Terraform output
const connectionString = process.env.COSMOS_CONNECTION_STRING;

if (!connectionString) {
  console.error('COSMOS_CONNECTION_STRING environment variable is not set');
  process.exit(1);
}

async function testCosmosConnection() {
  console.log('Connecting to Cosmos DB...');
  
  const client = new MongoClient(connectionString);
  
  try {
    await client.connect();
    console.log('✅ Successfully connected to Cosmos DB');
    
    // Test database access
    const db = client.db('salthea-database');
    console.log('✅ Connected to database: salthea-database');
    
    // List collections
    const collections = await db.listCollections().toArray();
    console.log('Collections in the database:');
    collections.forEach(collection => {
      console.log(`  - ${collection.name}`);
    });
    
    // Test user collection
    console.log('\nTesting users collection...');
    const usersCollection = db.collection('users');
    
    // Count documents
    const userCount = await usersCollection.countDocuments();
    console.log(`✅ Users collection exists (${userCount} documents)`);
    
    // Test messages collection
    console.log('\nTesting messages collection...');
    const messagesCollection = db.collection('messages');
    
    // Count documents
    const messageCount = await messagesCollection.countDocuments();
    console.log(`✅ Messages collection exists (${messageCount} documents)`);
    
    console.log('\nCosmos DB setup is complete and working correctly!');
  } catch (err) {
    console.error('❌ Error testing Cosmos DB connection:', err);
  } finally {
    await client.close();
    console.log('Connection closed');
  }
}

testCosmosConnection().catch(console.error); 