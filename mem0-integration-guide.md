# mem0-Integration Guide for Salthea

_Last updated: 2025-06-13_

---

## 1 Executive Summary  

Salthea’s medical chatbot currently stores short-term chat history in Cosmos DB and performs context enrichment with Deep Search. This limits personalization and prevents robust retrieval-augmented generation (RAG) over longitudinal clinical data.  
Microsoft’s new **mem0** service—available as a first-party integration with Azure AI Search and Azure OpenAI—adds a persistent, vector-based memory layer. By adopting mem0 we can:

* Remember user facts and preferences across sessions (long-term memory).  
* Retrieve relevant snippets from Azure FHIR and wearable data stored in Cosmos DB.  
* Ground GPT-4o answers in the patient’s own data with citations.  

This guide walks you through infrastructure changes, backend code additions, and validation steps needed to roll the feature into production.

---

## 2 Architecture Overview  

| Layer | Current | Proposed (with mem0) |
|-------|---------|----------------------|
| **Vector Store** | none (Deep Search) | Azure AI Search (vector enabled) |
| **Memory Layer** | Plain-text Cosmos collection (`memory`) | mem0 SDK + AI Search index (`memories`, `fhir_memories`, `wearable_memories`) |
| **Embedding Model** | GPT-4o embeddings ad-hoc | Dedicated `text-embedding-3-large` deployment |
| **Chat RAG** | Simple Deep Search injection | mem0 RAG across user memory + FHIR + wearables |
| **IaC** | Terraform sets OpenAI, Cosmos, FHIR | + Search service, embedding deployment, Key Vault secrets, role assignments |

Diagram (high-level):

```
User → Frontend (Next.js) → Backend (Express)
     ↘                                ↘
      Azure OpenAI GPT-4o      mem0 SDK
               ↑                  ↑
               └── Embeddings ← AI Search (vector indexes)
                              ↖︎            ↗︎
                       FHIR export     Wearable ETL
```

---

## 3 Step-by-Step Implementation  

### 3.1 Terraform Changes  

1. **Add Azure AI Search (vector enabled)**  
   ```hcl
   resource "azurerm_search_service" "mem0_search" { … semantic_search_sku = "standard" }
   ```
2. **Deploy embedding model** (`text-embedding-3-large`)  
   ```hcl
   resource "azurerm_cognitive_deployment" "mem0_embeddings" { … }
   ```
3. **Key Vault Secrets**  
   * `Mem0SearchEndpoint`, `Mem0SearchAdminKey`, `Mem0EmbeddingsDeploymentName`
4. **App Service Settings (merged)**  
   ```
   MEM0_SEARCH_SERVICE_NAME
   MEM0_SEARCH_ADMIN_KEY
   MEM0_SEARCH_ENDPOINT
   MEM0_EMBEDDINGS_DEPLOYMENT
   MEM0_EMBEDDING_DIMENSIONS=1536
   ```
5. **Role assignments** – give backend & staging slots **Search Service Contributor**.

> Apply to staging first, validate, then prod.

### 3.2 Backend Service Implementation  

1. `npm i mem0ai @azure/openai`  
2. **Create `services/mem0Service.js`** (see sample earlier):  
   * `Memory.from_config` with three collections:
     * `memories` – general user memory  
     * `fhir_memories` – indexed clinical resources  
     * `wearable_memories` – indexed Terra metrics  
3. **Utility functions provided**  
   * `addMemory`, `searchMemories`, `performRagSearch`, `formatRagResultsForPrompt`, etc.  
4. **Conversation extraction**: after each assistant reply call `extractAndStoreMemory` to distill facts.

### 3.3 FHIR & Wearable Data Indexing  

| Data source | How to index | Frequency |
|-------------|-------------|-----------|
| FHIR | `jobs/indexFhirJob.js` (timer trigger or GitHub Action) – exports `Patient`, `Condition`, `Observation`, … → `mem0Service.indexFhirResources()` | Nightly full; 15-min incremental |
| Wearables | Terra webhook → store to Cosmos → after insert call `mem0Service.indexWearableData()` | Near real-time |

Practical tips  
* Store **patientId** metadata so queries can filter `user_id`.  
* Use concise text summaries (<1 kB) to control token count.

### 3.4 Chat Routes Integration  

1. **Anonymous endpoint**  
   * If `shouldUseRag()` true, call  
     ```js
     const rag = await mem0Service.performRagSearch(query,'anonymous',{includeGeneral:true});
     ```
2. **Authenticated endpoint**  
   * Before prompt generation retrieve memories:  
     ```js
     const memoryBlob = (await mem0Service.getAllMemories(uid)).map(m=>m.memory).join('\n');
     ```
   * Perform full RAG (general+fhir+wearable).  
   * Append `formatRagResultsForPrompt(rag)` to system message.  
   * After streaming response:  
     * `mem0Service.addConversationMemory(...)`  
     * `mem0Service.extractAndStoreMemory(...)`

---

## 4 Testing & Validation Plan  

| Stage | Goal | Tools / Scripts |
|-------|------|-----------------|
| Unit   | mem0 config loads; add/search returns | Jest + dotenv-mock |
| Integration | End-to-end chat returns citations incl. FHIR value | Supertest; seed test patient |
| Load | P95 latency < 3 s @ 50 RPS | k6 `scripts/chat-load.js` |
| Security | PHI sanitizer prevents identifiers entering mem0 | automated regex + Azure PII test |
| Acceptance | Clinician checks that new migraine note remembered next day | manual |

---

## 5 Performance Considerations  

* **Vector index sizing** – 1 replica/1 partition fine ≤ 1 M vectors; auto-scale to 3 replicas >5 M.  
* **Embedding cost** – batch FHIR exports; reuse embeddings if resource `hash` unchanged.  
* **Chat latency** – run mem0 searches in parallel; set 1 s timeout.  
* **Memory growth** – nightly job down-ranks vectors >1 year old or low-importance.

---

## 6 Security Considerations  

* mem0 runs inside Azure boundary; covered by existing BAA.  
* All vectors de-identified **before** `memory.add` (PHI sanitizer).  
* AI Search deployed with Private Endpoint; firewall denies public traffic.  
* Secrets only via Key Vault references; no plain keys checked into code.  
* Enable diagnostic logs & managed identity RBAC for Search, OpenAI, Key Vault.

---

## 7 Reference Documentation  

* Azure AI Foundry blog – _Integrating Mem0 with Azure AI Search_  
  https://devblogs.microsoft.com/foundry/azure-ai-mem0-integration/  
* Terraform `azurerm_search_service` resource  
  https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/search_service  
* mem0 SDK docs  
  https://aka.ms/mem0/docs  
* Azure OpenAI embeddings  
  https://learn.microsoft.com/azure/ai-services/openai/concepts/embeddings  
* Salthea backend repo reference (`src/routes/chatRoutes.js`, `services/mem0Service.js`)  

---

### Next Steps Checklist

- [ ] Apply Terraform in staging subscription  
- [ ] Populate sample patient FHIR data and wearable metrics  
- [ ] Run load & unit tests  
- [ ] Enable feature flag `MEM0_ENABLED=true` in prod  
- [ ] Monitor latency, Azure Search bill, and chat quality KPIs for two weeks  

