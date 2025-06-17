# 🧠 Complete CLU Setup Guide

## ✅ Infrastructure Ready

Your Azure Language Service is deployed and configured:

- **Endpoint**: `https://salthea-language.cognitiveservices.azure.com/`
- **Region**: East US (CLU supported)
- **API Key**: Stored in Key Vault as `CLUKey`
- **Project Name**: `salthea-intent-routing` (stored as `CLUProjectName`)
- **Deployment**: `production` (stored as `CLUDeploymentName`)

## 🎯 Manual CLU Project Setup

Since the REST API approach failed, follow these steps in Language Studio:

### Step 1: Open Language Studio
1. Go to **https://language.cognitive.microsoft.com/**
2. Sign in with your Azure account 
3. Make sure you're in the correct subscription/tenant

### Step 2: Create CLU Project
1. Click **"Conversational Language Understanding"**
2. Click **"Create new project"**
3. Fill in project details:
   - **Project Name**: `salthea-intent-routing`
   - **Text Primary Language**: `English (en-us)`
   - **Description**: `Intent classification for Salthea health chat routing`
   - **Enable multiple languages**: `No`

### Step 3: Connect Azure Resource
1. Select your **Language resource**: `salthea-language`
2. This should auto-detect your East US resource
3. Click **"Next"** → **"Create project"**

### Step 4: Add Intents
Add these 5 intents with their descriptions:

#### Intent: `search_medical`
**Description**: Medical questions that need external knowledge from Valyu
**Examples**: (Add 10-15 of these)
```
What causes diabetes?
How is hypertension treated?
What are the symptoms of COVID-19?
Explain the mechanism of insulin resistance
What medications are used for depression?
How does chemotherapy work?
What is the prognosis for heart disease?
What are the side effects of metformin?
How is pneumonia diagnosed?
What causes high cholesterol?
Explain how vaccines work
What is the treatment for anxiety?
How does the thyroid gland function?
What causes migraines?
How is sleep apnea treated?
```

#### Intent: `memory_personal` 
**Description**: Personal health data queries that need mem0 user memory
**Examples**:
```
What does my blood pressure data show?
Analyze my recent health trends
What patterns do you see in my glucose levels?
Summarize my health data from last month
Based on my records, what should I monitor?
How has my weight changed over time?
What do my lab results indicate?
Show me my heart rate patterns
Analyze my sleep data
What trends do you see in my health metrics?
Based on my history, what are my risk factors?
How have my symptoms progressed?
What does my medication adherence look like?
Compare my current health to last year
What insights can you give about my health journey?
```

#### Intent: `meta_request`
**Description**: Requests for suggestions or questions about what to ask
**Examples**:
```
Suggest some health questions I could ask
What kinds of questions can you answer?
Give me ideas for health-related queries
What should I ask about my health?
Help me think of questions to ask
What topics can we discuss?
Give me some conversation starters
What are good health questions to explore?
Suggest questions about wellness
What could I learn about my health?
Give me ideas for health discussions
What health topics should I be curious about?
Help me brainstorm health questions
What are important health topics to ask about?
Suggest personalized health questions
```

#### Intent: `conversation`
**Description**: General conversation, greetings, thanks, social interaction
**Examples**:
```
Hello
How are you?
Thank you
That's helpful
Good morning
I appreciate your help
Thanks for the information
This is really useful
You're very helpful
Good afternoon
Hi there
Great, thanks
Perfect, thank you
That makes sense
I understand now
Okay, got it
Awesome
Cool
Nice
Wonderful
```

#### Intent: `system_query`
**Description**: Account, subscription, connection, or system-related requests
**Examples**:
```
Connect my health data
Show my account status
Update my profile
Check my subscription
Link my medical records
How do I connect my data?
What's my account information?
Can you access my health records?
How do I sync my data?
What data do you have access to?
Show me my connection status
How do I link my EHR?
What health apps can I connect?
How do I grant data access?
Check my data connections
```

### Step 5: Train the Model
1. Click **"Training jobs"** in the left menu
2. Click **"Start a training job"**
3. **Training mode**: `Standard training`
4. **Model name**: `salthea-routing-model`
5. Click **"Train"**
6. ⏳ **Wait 5-10 minutes** for training to complete

### Step 6: Deploy the Model
1. Go to **"Deploying a model"** 
2. Click **"Add deployment"**
3. **Deployment name**: `production` 
4. **Model**: Select your trained `salthea-routing-model`
5. Click **"Deploy"**
6. ⏳ **Wait 2-3 minutes** for deployment

### Step 7: Test the Deployment
1. Go to **"Testing deployments"**
2. Select **Deployment**: `production`
3. Test with sample queries:
   - `"What causes diabetes?"` → Should predict `search_medical` 
   - `"Analyze my health trends"` → Should predict `memory_personal`
   - `"Suggest health questions"` → Should predict `meta_request`
   - `"Hello"` → Should predict `conversation`

## 🔧 Backend Integration

### Environment Variables Already Configured
Your backend is already configured to use these Key Vault secrets:
- `CLU_ENDPOINT` → `CLUEndpoint`
- `CLU_KEY` → `CLUKey` 
- `CLU_PROJECT_NAME` → `CLUProjectName`
- `CLU_DEPLOYMENT_NAME` → `CLUDeploymentName`

### Code Status
- ✅ **azureIntentService.js**: Ready to use CLU
- ✅ **chatRoutes.js**: Integrated with CLU routing
- ✅ **Fallback system**: Enhanced heuristics as backup
- ✅ **Test script**: `test-clu-routing.js` available

## 🚀 Verification

### Test CLU Integration
Once your CLU model is deployed, run:
```bash
cd salthea-backend
node test-clu-routing.js
```

You should see output like:
```
🧠 CLU Routing:
  Intent: search_medical (87% confidence)
  Reasoning: High confidence medical question  
  shouldUseValyu: true
```

### Check Application Logs
Monitor your application logs for:
- `✅ Azure Intent Service initialized` 
- `🧠 Classifying intent with Azure CLU`
- `🎯 CLU Result: search_medical (87% confidence)`

## 🎯 Expected Performance Impact

### Before CLU
- ❌ "Suggest questions" triggered Valyu (slow)
- ❌ Some false positives in routing
- ⚡ ~3-5 second response times

### After CLU  
- ✅ "Suggest questions" stays in direct chat (fast)
- ✅ More accurate intent detection
- ⚡ ~1-2 second response times for non-search queries

## 🔍 Troubleshooting

### If CLU Fails
- System automatically falls back to enhanced heuristics
- Check logs for `🔄 CLU not configured, falling back to heuristics`
- Verify Key Vault secrets are accessible

### Common Issues
1. **Training fails**: Make sure you have 10+ examples per intent
2. **Low accuracy**: Add more diverse training examples
3. **Wrong predictions**: Review and retrain with corrected examples

## 📋 Training Data
Complete training examples are available in `clu-training-data.json` for reference.

---

**Status**: Ready for CLU project creation in Language Studio
**Next Step**: Follow Step 1 above to create the CLU project
**Estimated Time**: 20-30 minutes total (including training) 