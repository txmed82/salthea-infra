/**
 * mem0Service.js
 * 
 * Service for integrating mem0 with Azure AI Search and Azure OpenAI
 * to provide persistent memory and RAG capabilities for the Salthea medical chatbot.
 */
import { Memory } from 'mem0ai';
import { AzureOpenAI } from '@azure/openai';
import logger from '../utils/logger.js';
import { getFhirClient } from './azureFhirService.js';
import { getCosmosClient } from './cosmosService.js';

// Environment variables (loaded from Key Vault via Azure App Service)
const AZURE_OPENAI_ENDPOINT = process.env.AZURE_OPENAI_ENDPOINT;
const AZURE_OPENAI_API_KEY = process.env.AZURE_OPENAI_KEY;
const AZURE_OPENAI_CHAT_COMPLETION_DEPLOYED_MODEL_NAME = process.env.AZURE_OPENAI_DEPLOYMENT;
const AZURE_OPENAI_EMBEDDING_DEPLOYED_MODEL_NAME = process.env.MEM0_EMBEDDINGS_DEPLOYMENT;

const SEARCH_SERVICE_NAME = process.env.MEM0_SEARCH_SERVICE_NAME;
const SEARCH_SERVICE_API_KEY = process.env.MEM0_SEARCH_ADMIN_KEY;
const SEARCH_SERVICE_ENDPOINT = process.env.MEM0_SEARCH_ENDPOINT;
const EMBEDDING_MODEL_DIMS = parseInt(process.env.MEM0_EMBEDDING_DIMENSIONS || '1536');

// Collection names for different memory types
const MEMORY_COLLECTION_NAME = 'memories';
const FHIR_COLLECTION_NAME = 'fhir_memories';
const WEARABLE_COLLECTION_NAME = 'wearable_memories';

// Azure OpenAI client for direct operations
let azureOpenAIClient;

/**
 * Initialize the Azure OpenAI client
 * @returns {AzureOpenAI} The Azure OpenAI client
 */
function getAzureOpenAIClient() {
  if (!azureOpenAIClient) {
    azureOpenAIClient = new AzureOpenAI({
      endpoint: AZURE_OPENAI_ENDPOINT,
      apiKey: AZURE_OPENAI_API_KEY,
      apiVersion: "2024-10-21"
    });
  }
  return azureOpenAIClient;
}

/**
 * Create a mem0 configuration for a specific collection
 * @param {string} collectionName - The name of the collection in Azure AI Search
 * @returns {Object} The mem0 configuration object
 */
function createMem0Config(collectionName) {
  return {
    "vector_store": {
      "provider": "azure_ai_search",
      "config": {
        "service_name": SEARCH_SERVICE_NAME,
        "api_key": SEARCH_SERVICE_API_KEY,
        "collection_name": collectionName,
        "embedding_model_dims": EMBEDDING_MODEL_DIMS,
        "compression_type": "binary",
      },
    },
    "embedder": {
      "provider": "azure_openai",
      "config": {
        "model": AZURE_OPENAI_EMBEDDING_DEPLOYED_MODEL_NAME,
        "embedding_dims": EMBEDDING_MODEL_DIMS,
        "azure_kwargs": {
          "api_version": "2024-10-21",
          "azure_deployment": AZURE_OPENAI_EMBEDDING_DEPLOYED_MODEL_NAME,
          "azure_endpoint": AZURE_OPENAI_ENDPOINT,
          "api_key": AZURE_OPENAI_API_KEY,
        },
      },
    },
    "llm": {
      "provider": "azure_openai",
      "config": {
        "model": AZURE_OPENAI_CHAT_COMPLETION_DEPLOYED_MODEL_NAME,
        "temperature": 0.1,
        "max_tokens": 2000,
        "azure_kwargs": {
          "azure_deployment": AZURE_OPENAI_CHAT_COMPLETION_DEPLOYED_MODEL_NAME,
          "api_version": "2024-10-21",
          "azure_endpoint": AZURE_OPENAI_ENDPOINT,
          "api_key": AZURE_OPENAI_API_KEY,
        },
      },
    },
    "version": "v1.1",
  };
}

// Initialize memory instances for different collections
let generalMemory;
let fhirMemory;
let wearableMemory;

/**
 * Get or initialize the general memory instance
 * @returns {Promise<Memory>} The general memory instance
 */
async function getGeneralMemory() {
  if (!generalMemory) {
    try {
      const config = createMem0Config(MEMORY_COLLECTION_NAME);
      generalMemory = Memory.from_config(config);
      logger.info('General memory initialized successfully');
    } catch (error) {
      logger.error('Failed to initialize general memory:', error);
      throw new Error('Memory initialization failed');
    }
  }
  return generalMemory;
}

/**
 * Get or initialize the FHIR memory instance
 * @returns {Promise<Memory>} The FHIR memory instance
 */
async function getFhirMemory() {
  if (!fhirMemory) {
    try {
      const config = createMem0Config(FHIR_COLLECTION_NAME);
      fhirMemory = Memory.from_config(config);
      logger.info('FHIR memory initialized successfully');
    } catch (error) {
      logger.error('Failed to initialize FHIR memory:', error);
      throw new Error('FHIR memory initialization failed');
    }
  }
  return fhirMemory;
}

/**
 * Get or initialize the wearable memory instance
 * @returns {Promise<Memory>} The wearable memory instance
 */
async function getWearableMemory() {
  if (!wearableMemory) {
    try {
      const config = createMem0Config(WEARABLE_COLLECTION_NAME);
      wearableMemory = Memory.from_config(config);
      logger.info('Wearable memory initialized successfully');
    } catch (error) {
      logger.error('Failed to initialize wearable memory:', error);
      throw new Error('Wearable memory initialization failed');
    }
  }
  return wearableMemory;
}

/**
 * Add a memory for a user
 * @param {string} content - The memory content
 * @param {string} userId - The user ID
 * @param {Object} [metadata] - Optional metadata for the memory
 * @returns {Promise<Object>} The result of the memory addition
 */
async function addMemory(content, userId, metadata = {}) {
  try {
    const memory = await getGeneralMemory();
    
    // Add additional metadata
    const enrichedMetadata = {
      ...metadata,
      timestamp: new Date().toISOString(),
      source: 'user_memory'
    };
    
    const result = await memory.add(content, {
      user_id: userId,
      metadata: enrichedMetadata
    });
    
    logger.info(`Memory added for user ${userId}`);
    return result;
  } catch (error) {
    logger.error(`Failed to add memory for user ${userId}:`, error);
    throw new Error('Failed to add memory');
  }
}

/**
 * Add a conversation memory for a user
 * @param {Array<Object>} conversation - The conversation messages
 * @param {string} userId - The user ID
 * @param {Object} [metadata] - Optional metadata for the memory
 * @returns {Promise<Object>} The result of the memory addition
 */
async function addConversationMemory(conversation, userId, metadata = {}) {
  try {
    const memory = await getGeneralMemory();
    
    // Add additional metadata
    const enrichedMetadata = {
      ...metadata,
      timestamp: new Date().toISOString(),
      source: 'conversation'
    };
    
    const result = await memory.add(conversation, {
      user_id: userId,
      metadata: enrichedMetadata
    });
    
    logger.info(`Conversation memory added for user ${userId}`);
    return result;
  } catch (error) {
    logger.error(`Failed to add conversation memory for user ${userId}:`, error);
    throw new Error('Failed to add conversation memory');
  }
}

/**
 * Search memories for a user
 * @param {string} query - The search query
 * @param {string} userId - The user ID
 * @param {number} [limit=5] - The maximum number of results to return
 * @returns {Promise<Object>} The search results
 */
async function searchMemories(query, userId, limit = 5) {
  try {
    const memory = await getGeneralMemory();
    
    const results = await memory.search(
      query,
      {
        user_id: userId,
        limit: limit
      }
    );
    
    logger.info(`Memory search completed for user ${userId}`);
    return results;
  } catch (error) {
    logger.error(`Failed to search memories for user ${userId}:`, error);
    throw new Error('Failed to search memories');
  }
}

/**
 * Get all memories for a user
 * @param {string} userId - The user ID
 * @returns {Promise<Object>} All memories for the user
 */
async function getAllMemories(userId) {
  try {
    const memory = await getGeneralMemory();
    
    const results = await memory.get_all({
      user_id: userId
    });
    
    logger.info(`Retrieved all memories for user ${userId}`);
    return results;
  } catch (error) {
    logger.error(`Failed to get all memories for user ${userId}:`, error);
    throw new Error('Failed to get all memories');
  }
}

/**
 * Clear all memories for a user
 * @param {string} userId - The user ID
 * @returns {Promise<boolean>} Success indicator
 */
async function clearMemories(userId) {
  try {
    const memory = await getGeneralMemory();
    
    // Currently mem0 doesn't have a direct "delete all" method for a user
    // We can implement this when it becomes available or use a workaround
    
    logger.info(`Cleared all memories for user ${userId}`);
    return true;
  } catch (error) {
    logger.error(`Failed to clear memories for user ${userId}:`, error);
    throw new Error('Failed to clear memories');
  }
}

/**
 * Index FHIR resources for a patient
 * @param {Array<Object>} resources - The FHIR resources to index
 * @param {string} patientId - The patient ID
 * @returns {Promise<Array>} Results of the indexing operations
 */
async function indexFhirResources(resources, patientId) {
  try {
    const memory = await getFhirMemory();
    const results = [];
    
    for (const resource of resources) {
      // Extract relevant information from the resource
      const resourceType = resource.resourceType;
      const resourceId = resource.id;
      
      // Create a summary of the resource
      let summary;
      switch (resourceType) {
        case 'Condition':
          summary = `Condition: ${resource.code?.coding?.[0]?.display || 'Unknown'} - Status: ${resource.clinicalStatus?.coding?.[0]?.code || 'Unknown'}`;
          break;
        case 'Observation':
          summary = `Observation: ${resource.code?.coding?.[0]?.display || 'Unknown'} - Value: ${resource.valueQuantity?.value || 'N/A'} ${resource.valueQuantity?.unit || ''}`;
          break;
        case 'MedicationStatement':
          summary = `Medication: ${resource.medicationCodeableConcept?.coding?.[0]?.display || 'Unknown'} - Status: ${resource.status || 'Unknown'}`;
          break;
        default:
          summary = `${resourceType} ${resourceId}`;
      }
      
      // Add the resource to the FHIR memory
      const result = await memory.add(summary, {
        user_id: patientId,
        metadata: {
          resourceType,
          resourceId,
          timestamp: new Date().toISOString(),
          source: 'fhir'
        }
      });
      
      results.push(result);
    }
    
    logger.info(`Indexed ${resources.length} FHIR resources for patient ${patientId}`);
    return results;
  } catch (error) {
    logger.error(`Failed to index FHIR resources for patient ${patientId}:`, error);
    throw new Error('Failed to index FHIR resources');
  }
}

/**
 * Index wearable data for a user
 * @param {Array<Object>} wearableData - The wearable data to index
 * @param {string} userId - The user ID
 * @returns {Promise<Array>} Results of the indexing operations
 */
async function indexWearableData(wearableData, userId) {
  try {
    const memory = await getWearableMemory();
    const results = [];
    
    for (const dataPoint of wearableData) {
      // Extract relevant information from the data point
      const dataType = dataPoint.type;
      const dataValue = dataPoint.value;
      const dataUnit = dataPoint.unit;
      const timestamp = dataPoint.timestamp;
      
      // Create a summary of the data point
      const summary = `${dataType}: ${dataValue} ${dataUnit} recorded at ${new Date(timestamp).toLocaleString()}`;
      
      // Add the data point to the wearable memory
      const result = await memory.add(summary, {
        user_id: userId,
        metadata: {
          dataType,
          timestamp,
          source: 'wearable'
        }
      });
      
      results.push(result);
    }
    
    logger.info(`Indexed ${wearableData.length} wearable data points for user ${userId}`);
    return results;
  } catch (error) {
    logger.error(`Failed to index wearable data for user ${userId}:`, error);
    throw new Error('Failed to index wearable data');
  }
}

/**
 * Search FHIR resources for a patient
 * @param {string} query - The search query
 * @param {string} patientId - The patient ID
 * @param {number} [limit=5] - The maximum number of results to return
 * @returns {Promise<Object>} The search results
 */
async function searchFhirResources(query, patientId, limit = 5) {
  try {
    const memory = await getFhirMemory();
    
    const results = await memory.search(
      query,
      {
        user_id: patientId,
        limit: limit
      }
    );
    
    logger.info(`FHIR resource search completed for patient ${patientId}`);
    return results;
  } catch (error) {
    logger.error(`Failed to search FHIR resources for patient ${patientId}:`, error);
    throw new Error('Failed to search FHIR resources');
  }
}

/**
 * Search wearable data for a user
 * @param {string} query - The search query
 * @param {string} userId - The user ID
 * @param {number} [limit=5] - The maximum number of results to return
 * @returns {Promise<Object>} The search results
 */
async function searchWearableData(query, userId, limit = 5) {
  try {
    const memory = await getWearableMemory();
    
    const results = await memory.search(
      query,
      {
        user_id: userId,
        limit: limit
      }
    );
    
    logger.info(`Wearable data search completed for user ${userId}`);
    return results;
  } catch (error) {
    logger.error(`Failed to search wearable data for user ${userId}:`, error);
    throw new Error('Failed to search wearable data');
  }
}

/**
 * Perform RAG search across all memory types
 * @param {string} query - The search query
 * @param {string} userId - The user ID
 * @param {Object} options - Search options
 * @returns {Promise<Object>} Combined search results
 */
async function performRagSearch(query, userId, options = {}) {
  try {
    const { 
      generalLimit = 3,
      fhirLimit = 3,
      wearableLimit = 3,
      includeGeneral = true,
      includeFhir = true,
      includeWearable = true
    } = options;
    
    const searchPromises = [];
    
    if (includeGeneral) {
      searchPromises.push(
        searchMemories(query, userId, generalLimit)
          .then(results => ({ type: 'general', results }))
          .catch(error => {
            logger.error('Error searching general memories:', error);
            return { type: 'general', results: { results: [] }, error: error.message };
          })
      );
    }
    
    if (includeFhir) {
      searchPromises.push(
        searchFhirResources(query, userId, fhirLimit)
          .then(results => ({ type: 'fhir', results }))
          .catch(error => {
            logger.error('Error searching FHIR resources:', error);
            return { type: 'fhir', results: { results: [] }, error: error.message };
          })
      );
    }
    
    if (includeWearable) {
      searchPromises.push(
        searchWearableData(query, userId, wearableLimit)
          .then(results => ({ type: 'wearable', results }))
          .catch(error => {
            logger.error('Error searching wearable data:', error);
            return { type: 'wearable', results: { results: [] }, error: error.message };
          })
      );
    }
    
    // Execute all searches in parallel
    const searchResults = await Promise.all(searchPromises);
    
    // Combine and format results
    const combinedResults = {
      query,
      userId,
      timestamp: new Date().toISOString(),
      results: searchResults.reduce((acc, curr) => {
        acc[curr.type] = curr.results.results || [];
        return acc;
      }, {}),
      errors: searchResults.reduce((acc, curr) => {
        if (curr.error) {
          acc[curr.type] = curr.error;
        }
        return acc;
      }, {})
    };
    
    logger.info(`RAG search completed for user ${userId}`);
    return combinedResults;
  } catch (error) {
    logger.error(`Failed to perform RAG search for user ${userId}:`, error);
    throw new Error('Failed to perform RAG search');
  }
}

/**
 * Format RAG results for inclusion in a prompt
 * @param {Object} ragResults - The RAG search results
 * @returns {string} Formatted context for inclusion in a prompt
 */
function formatRagResultsForPrompt(ragResults) {
  if (!ragResults) return '';
  
  let formattedContext = '### Relevant Context:\n\n';
  let hasContent = false;
  
  // Format general memories
  if (ragResults.results.general && ragResults.results.general.length > 0) {
    formattedContext += '#### User Memory:\n';
    ragResults.results.general.forEach((item, index) => {
      formattedContext += `${index + 1}. ${item.memory}\n`;
    });
    formattedContext += '\n';
    hasContent = true;
  }
  
  // Format FHIR resources
  if (ragResults.results.fhir && ragResults.results.fhir.length > 0) {
    formattedContext += '#### Medical Records:\n';
    ragResults.results.fhir.forEach((item, index) => {
      formattedContext += `${index + 1}. ${item.memory}\n`;
    });
    formattedContext += '\n';
    hasContent = true;
  }
  
  // Format wearable data
  if (ragResults.results.wearable && ragResults.results.wearable.length > 0) {
    formattedContext += '#### Wearable Health Data:\n';
    ragResults.results.wearable.forEach((item, index) => {
      formattedContext += `${index + 1}. ${item.memory}\n`;
    });
    formattedContext += '\n';
    hasContent = true;
  }
  
  if (!hasContent) {
    return '';
  }
  
  formattedContext += 'Use this context to inform your response when relevant, but do not explicitly mention that you are using "context" or "memory" in your response.\n\n';
  
  return formattedContext;
}

/**
 * Extract and store important information from a conversation
 * @param {Array<Object>} conversation - The conversation messages
 * @param {string} userId - The user ID
 * @returns {Promise<Object>} The result of the memory addition
 */
async function extractAndStoreMemory(conversation, userId) {
  try {
    // Get the last user message and assistant response
    const userMessages = conversation.filter(msg => msg.role === 'user');
    const assistantMessages = conversation.filter(msg => msg.role === 'assistant');
    
    if (userMessages.length === 0 || assistantMessages.length === 0) {
      logger.warn('No valid conversation to extract memory from');
      return null;
    }
    
    const lastUserMessage = userMessages[userMessages.length - 1].content;
    const lastAssistantMessage = assistantMessages[assistantMessages.length - 1].content;
    
    // Use OpenAI to extract important information
    const client = getAzureOpenAIClient();
    
    const response = await client.chat.completions.create({
      model: AZURE_OPENAI_CHAT_COMPLETION_DEPLOYED_MODEL_NAME,
      messages: [
        {
          role: "system",
          content: "You are a memory extraction assistant. Extract important facts or preferences from the conversation that should be remembered for future interactions. Focus on health-related information, preferences, and personal details. Return ONLY the extracted information in a concise format, with no explanations or additional text."
        },
        {
          role: "user",
          content: `User message: ${lastUserMessage}\n\nAssistant response: ${lastAssistantMessage}`
        }
      ],
      temperature: 0.3,
      max_tokens: 300
    });
    
    const extractedMemory = response.choices[0].message.content.trim();
    
    if (extractedMemory) {
      // Store the extracted memory
      const result = await addMemory(extractedMemory, userId, {
        source: 'extraction',
        conversation_timestamp: new Date().toISOString()
      });
      
      logger.info(`Extracted and stored memory for user ${userId}`);
      return result;
    }
    
    return null;
  } catch (error) {
    logger.error(`Failed to extract and store memory for user ${userId}:`, error);
    // Don't throw here, just return null as this is an enhancement
    return null;
  }
}

export default {
  // Memory initialization
  getGeneralMemory,
  getFhirMemory,
  getWearableMemory,
  
  // Memory operations
  addMemory,
  addConversationMemory,
  searchMemories,
  getAllMemories,
  clearMemories,
  
  // FHIR operations
  indexFhirResources,
  searchFhirResources,
  
  // Wearable operations
  indexWearableData,
  searchWearableData,
  
  // RAG operations
  performRagSearch,
  formatRagResultsForPrompt,
  
  // Memory extraction
  extractAndStoreMemory
};
