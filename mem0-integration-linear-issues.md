# Linear Issue Breakdown – mem0 Integration for Salthea

| # | Title | Description | Pts | Depends on |
|---|-------|-------------|-----|-----------|
| **INF-1** | Provision Azure AI Search (vector) | Add `azurerm_search_service` with vector & semantic search enabled to Terraform. Expose Key Vault secrets + private endpoint. | 8 | – |
| **INF-2** | Deploy OpenAI embedding model | Terraform deployment for `text-embedding-3-large`, capacity 20.  Add KV secret & app-settings refs. | 5 | INF-1 |
| **INF-3** | Inject mem0 env vars into App Service | Merge new `MEM0_*` settings via `azurerm_app_service_application_settings`. | 3 | INF-1, INF-2 |
| **INF-4** | Role assignments for Search | Grant backend & staging slots **Search Service Contributor**; update Key Vault policies. | 2 | INF-1 |
| **BE-1** | Add mem0 SDK & service layer | `npm i mem0ai @azure/openai`; implement `services/mem0Service.js` with three collections. | 8 | INF-3 |
| **BE-2** | Conversation memory extraction | Implement `extractAndStoreMemory` using GPT-4o; store distilled facts in mem0. | 5 | BE-1 |
| **BE-3** | RAG helper utilities | `performRagSearch` & `formatRagResultsForPrompt`; filters by userId. | 5 | BE-1 |
| **IDX-1** | Nightly FHIR indexing job | New script/Function `indexFhirJob.js`: export & vectorize resources; maintain state file. | 8 | BE-1 |
| **IDX-2** | Wearable data indexing hook | On Terra webhook, chunk metrics & call `mem0Service.indexWearableData`. | 5 | BE-1 |
| **CHAT-1** | Integrate mem0 in anonymous route | Update `/chat/anonymous` to call mem0 RAG for generic memory. | 3 | BE-3 |
| **CHAT-2** | Integrate mem0 in authenticated route | Replace Deep Search; inject formatted RAG context; store conversation memory. | 8 | BE-2, BE-3 |
| **TEST-1** | Unit tests for mem0 service | Jest tests: config loads, add/search returns, mock Search. | 3 | BE-1 |
| **TEST-2** | Integration tests: RAG citations | Seed sample patient; expect FHIR lab value in GPT response. | 5 | CHAT-2, IDX-1 |
| **TEST-3** | Load test mem0 latency | k6 script 50 RPS, assert P95 < 3 s; auto-scale Search. | 5 | CHAT-2 |
| **DOC-1** | Update runbooks & README | Add mem0 ops guide, index rotation, cost controls, env vars. | 2 | INF-3, BE-1 |
| **OPS-1** | Feature flag & rollout plan | Add `MEM0_ENABLED`; create canary config & monitoring dashboard. | 3 | TEST-3 |

### Legend
Pts = Fibonacci complexity estimate (1–13).  
Dependencies reference blocking issues that **must** complete first.  
