# Salthea – mem0 Integration Plan

## 1  Executive Summary  
Salthea’s medical chatbot currently stores a short‐term chat history in Cosmos DB and enriches answers with Deep Search. This limits personalization and prevents retrieval-augmented generation (RAG) over longitudinal clinical data. Azure’s new first-party integration with **mem0** (vector memory layer) unlocks persistent user memory plus hybrid RAG across Azure AI Search, FHIR, Cosmos DB and OpenAI.

This plan details the architectural changes, Terraform additions, backend refactors, and validation steps required to:

* Persist long-term conversation and user facts in mem0  
* Index & retrieve FHIR clinical resources and wearable-metrics vectors via Azure AI Search  
* Replace brittle Deep Search calls with mem0-powered RAG  
* Maintain HIPAA-grade security and predictable performance

Target milestone: production pilot in 4 weeks with staged rollout behind feature flag.

---

## 2  Current Architecture Overview  

| Layer | Technology | Notes |
|-------|------------|-------|
| Frontend | Next.js (salthea-frontend) | Uses Axios hooks (`useChat`, `memoryApi`) |
| API | Express.js (salthea-backend) | Chat & memory routes; PHI sanitizer; RAG = Deep Search |
| Data | Azure Cosmos DB (Mongo API) | Users, Conversations, Memory (text) |
| Clinical Data | Azure API for FHIR | HL7 FHIR resources |
| Wearables | Cosmos DB collections + Blob Storage | Terra ingests |
| AI | Azure OpenAI GPT-4o | Chat completions & embeddings |
| IaC | Terraform (salthea-infra) | No AI Search / mem0 resources today |

Limitations  
– Memory is plain text, low recall & no semantic search  
– No vector index of FHIR or wearable data  
– Deep Search not optimized for patient-specific retrieval  
– Chat prompts grow unbounded, impacting latency & cost  

---

## 3  Proposed Changes to Implement mem0  

### 3.1 Terraform Additions  

1. **Azure AI Search (Vector Store)**
   * `azurerm_search_service.mem0_search`
   * SKU: `standard` with vector capabilities enabled
   * Private network + managed identity

2. **OpenAI Embedding Deployment**
   * New `azurerm_cognitive_deployment.mem0_embeddings`
   * Model: `text-embedding-3-large` (1536 dims)

3. **Key Vault Secrets**  
   * Search admin key, endpoint URI  
   * Embedding deployment name

4. **Role Assignments**  
   * Grant backend App Service “Search Service Contributor”  
   * Allow Search to read FHIR blobs if hybrid search (optional)

5. **Outputs**  
   * Search endpoint & name for backend config

### 3.2 Backend (salthea-backend) Changes  

* `services/mem0Service.js`
  * Instantiate `Memory.from_config` using env vars populated from Key Vault.
  * Composite vector store: Azure AI Search; embedder & LLM: Azure OpenAI.
* Replace Cosmos `Memory` model with thin shim that forwards to mem0.
* Extend chat route:
  1. Retrieve top-K relevant memories via `mem0.search(query, userId)`.
  2. Retrieve relevant FHIR & wearable embeddings with tag filters (`patientId`).
  3. Inject results into system prompt (RAG chunk + citations).
  4. Store conversation & distilled memory via `mem0.add(...)`.

### 3.3 RAG over FHIR & Wearable Data  

* **FHIR pipeline**
  * Nightly batch job extracts relevant resources (Conditions, Observations, Medications) into JSON lines.
  * Each line sent through mem0’s `add` with `metadata: {type:'fhir', patientId}`.

* **Wearables pipeline**
  * When Terra sync completes, new metrics chunked & sent to mem0 with `metadata: {type:'wearable', patientId}`.

* Tag strategy allows `mem0.search` with filter `"patientId = $uid"` to keep retrieval scoped.

---

## 4  Detailed Implementation Steps  

| # | Task | Owner | Week |
|---|------|-------|------|
| 1 | Terraform module draft for AI Search & embedding deployment | Infra | W1 |
| 2 | Apply to staging, run `az search admin-key` rotation | Infra | W1 |
| 3 | Add env vars & KV references to `compute-improved.tf` (backend slot) | Infra | W1 |
| 4 | `npm i mem0ai` + create `mem0Service.js` (config per blog) | Backend | W2 |
| 5 | Refactor `Memory` model to proxy mem0 | Backend | W2 |
| 6 | Update `chatRoutes.js` to: retrieve memories → build prompt → store new memory | Backend | W2 |
| 7 | Build ETL lambda `jobs/indexFhir.js` to export & push FHIR data nightly | Backend | W3 |
| 8 | Hook Terra webhook to push new wearable vectors | Backend | W3 |
| 9 | Frontend update: show “🔄 Using your history” banner, fallback logic | Frontend | W3 |
|10 | Integration tests & load tests, security review | QA | W4 |
|11 | Feature flag & canary rollout | DevOps | W4 |

---

## 5  Testing & Validation Plan  

1. **Unit tests**  
   * mem0 config loads with mock Search endpoint  
   * Memory add / search returns expected vector matches

2. **Integration tests**  
   * Seed sample FHIR & wearable docs; verify RAG citations appear in GPT response  
   * Regression suite: anonymous chat unchanged

3. **Load & latency**  
   * k6 script: 50 RPS chat requests, measure P95 latency (<3 s)  
   * Search index warm-up script before test

4. **User acceptance (clinical)**  
   * Clinician confirms responses reflect latest lab value & medication list

5. **Security validation**  
   * PHI sanitizer outputs redacted text before mem0 store  
   * Network scan: Search endpoint private, Key Vault RBAC enforced

---

## 6  Security Considerations  

* All vectors include only de-identified content; PHI sanitizer runs first.  
* mem0 configured to store metadata containing patientId (GUID) but **no name/DOB**.  
* Azure AI Search deployed with private endpoint; access limited to backend managed identity.  
* Key Vault references used for all secrets; no plain-text keys in app settings.  
* Enable diagnostic logs & role-based auditing for Search and OpenAI.  
* Review HIPAA BAA coverage for mem0 service (within Azure boundary).

---

## 7  Performance Considerations  

* **Index design**: use 1536-dim vector dims; hybrid field for term filters → fast filter + vector scoring.  
* **Cold start**: keep Azure Functions (ETL) warm via timer trigger.  
* **Memory growth**: implement importance score, rotate / compress vectors older than 1 year.  
* **Chat latency**: parallelize mem0.search (K=5) with FHIR/wearable fetch; impose 1-second budget.  
* **Cost control**: auto-scale Search replicas 1→3 on CPU>60%; monitor OpenAI token usage.  

---

_Revision 1 – 2025-06-13_
