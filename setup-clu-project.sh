#!/bin/bash

# Azure Language Service CLU Project Setup Script
# This script creates a CLU project, defines intents, trains and deploys the model

set -e

# Configuration
ENDPOINT="https://salthea-language.cognitiveservices.azure.com/"
API_KEY="397d1d363b6046d4b72276e263819297"
PROJECT_NAME="salthea-intent-routing"
DEPLOYMENT_NAME="production"
API_VERSION="2023-04-01"

echo "🚀 Setting up CLU project: $PROJECT_NAME"
echo "📍 Endpoint: $ENDPOINT"

# Step 1: Create CLU Project
echo ""
echo "📝 Step 1: Creating CLU project..."

curl -X PUT \
  "${ENDPOINT}language/authoring/analyze-conversations/projects/${PROJECT_NAME}?api-version=${API_VERSION}" \
  -H "Ocp-Apim-Subscription-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "projectFileVersion": "2022-05-01",
    "stringIndexType": "Utf16CodeUnit",
    "metadata": {
      "projectName": "'${PROJECT_NAME}'",
      "projectKind": "Conversation",
      "description": "Intent classification for Salthea health chat routing",
      "language": "en-us",
      "multilingual": false,
      "settings": {}
    }
  }'

echo ""
echo "✅ Project created successfully"

# Step 2: Import Project with Intents and Utterances
echo ""
echo "📚 Step 2: Importing intents and training data..."

curl -X POST \
  "${ENDPOINT}language/authoring/analyze-conversations/projects/${PROJECT_NAME}/:import?api-version=${API_VERSION}" \
  -H "Ocp-Apim-Subscription-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "projectFileVersion": "2022-05-01",
    "stringIndexType": "Utf16CodeUnit",
    "metadata": {
      "projectName": "'${PROJECT_NAME}'",
      "projectKind": "Conversation",
      "description": "Intent classification for Salthea health chat routing",
      "language": "en-us",
      "multilingual": false,
      "settings": {}
    },
    "assets": {
      "projectKind": "Conversation",
      "intents": [
        {
          "category": "search_medical"
        },
        {
          "category": "memory_personal"
        },
        {
          "category": "meta_request"
        },
        {
          "category": "conversation"
        },
        {
          "category": "system_query"
        }
      ],
      "utterances": [
        {
          "text": "What causes diabetes?",
          "intent": "search_medical",
          "language": "en-us"
        },
        {
          "text": "How is hypertension treated?",
          "intent": "search_medical",
          "language": "en-us"
        },
        {
          "text": "What are the symptoms of COVID-19?",
          "intent": "search_medical",
          "language": "en-us"
        },
        {
          "text": "Explain the mechanism of insulin resistance",
          "intent": "search_medical",
          "language": "en-us"
        },
        {
          "text": "What medications are used for depression?",
          "intent": "search_medical",
          "language": "en-us"
        },
        {
          "text": "How does chemotherapy work?",
          "intent": "search_medical",
          "language": "en-us"
        },
        {
          "text": "What is the prognosis for heart disease?",
          "intent": "search_medical",
          "language": "en-us"
        },
        {
          "text": "Tell me about cancer treatment options",
          "intent": "search_medical",
          "language": "en-us"
        },
        {
          "text": "How do vaccines work?",
          "intent": "search_medical",
          "language": "en-us"
        },
        {
          "text": "What are the side effects of statins?",
          "intent": "search_medical",
          "language": "en-us"
        },
        {
          "text": "What does my blood pressure data show?",
          "intent": "memory_personal",
          "language": "en-us"
        },
        {
          "text": "Analyze my recent health trends",
          "intent": "memory_personal",
          "language": "en-us"
        },
        {
          "text": "What patterns do you see in my glucose levels?",
          "intent": "memory_personal",
          "language": "en-us"
        },
        {
          "text": "Based on my records, what should I monitor?",
          "intent": "memory_personal",
          "language": "en-us"
        },
        {
          "text": "How has my weight changed over time?",
          "intent": "memory_personal",
          "language": "en-us"
        },
        {
          "text": "Review my lab results from last month",
          "intent": "memory_personal",
          "language": "en-us"
        },
        {
          "text": "What do my sleep patterns show?",
          "intent": "memory_personal",
          "language": "en-us"
        },
        {
          "text": "Summarize my health data",
          "intent": "memory_personal",
          "language": "en-us"
        },
        {
          "text": "Suggest some health questions I could ask",
          "intent": "meta_request",
          "language": "en-us"
        },
        {
          "text": "What kinds of questions can you answer?",
          "intent": "meta_request",
          "language": "en-us"
        },
        {
          "text": "Give me ideas for health-related queries",
          "intent": "meta_request",
          "language": "en-us"
        },
        {
          "text": "Help me think of questions to ask",
          "intent": "meta_request",
          "language": "en-us"
        },
        {
          "text": "What should I ask about my health?",
          "intent": "meta_request",
          "language": "en-us"
        },
        {
          "text": "Can you suggest some topics to discuss?",
          "intent": "meta_request",
          "language": "en-us"
        },
        {
          "text": "Hello",
          "intent": "conversation",
          "language": "en-us"
        },
        {
          "text": "Hi there",
          "intent": "conversation",
          "language": "en-us"
        },
        {
          "text": "Thank you",
          "intent": "conversation",
          "language": "en-us"
        },
        {
          "text": "That is helpful",
          "intent": "conversation",
          "language": "en-us"
        },
        {
          "text": "Good morning",
          "intent": "conversation",
          "language": "en-us"
        },
        {
          "text": "I appreciate your help",
          "intent": "conversation",
          "language": "en-us"
        },
        {
          "text": "Thanks for the information",
          "intent": "conversation",
          "language": "en-us"
        },
        {
          "text": "Have a good day",
          "intent": "conversation",
          "language": "en-us"
        },
        {
          "text": "Connect my health data",
          "intent": "system_query",
          "language": "en-us"
        },
        {
          "text": "Show my account status",
          "intent": "system_query",
          "language": "en-us"
        },
        {
          "text": "Update my profile",
          "intent": "system_query",
          "language": "en-us"
        },
        {
          "text": "Check my subscription",
          "intent": "system_query",
          "language": "en-us"
        },
        {
          "text": "Link my medical records",
          "intent": "system_query",
          "language": "en-us"
        },
        {
          "text": "Manage my account",
          "intent": "system_query",
          "language": "en-us"
        }
      ]
    }
  }'

echo ""
echo "✅ Training data imported successfully"

# Step 3: Start Training Job
echo ""
echo "🏋️  Step 3: Starting training job..."

TRAINING_JOB_ID="training-$(date +%s)"

curl -X POST \
  "${ENDPOINT}language/authoring/analyze-conversations/projects/${PROJECT_NAME}/:train?api-version=${API_VERSION}" \
  -H "Ocp-Apim-Subscription-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "modelLabel": "'${TRAINING_JOB_ID}'",
    "trainingConfigVersion": "latest"
  }'

echo ""
echo "⏳ Training started with job ID: $TRAINING_JOB_ID"
echo "⏳ Waiting for training to complete (this may take 5-10 minutes)..."

# Wait for training to complete
sleep 30
TRAINING_STATUS="running"
ATTEMPTS=0
MAX_ATTEMPTS=20

while [ "$TRAINING_STATUS" != "succeeded" ] && [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
  echo "⏳ Checking training status... (attempt $((ATTEMPTS + 1))/$MAX_ATTEMPTS)"
  
  RESPONSE=$(curl -s \
    "${ENDPOINT}language/authoring/analyze-conversations/projects/${PROJECT_NAME}/train/jobs/${TRAINING_JOB_ID}?api-version=${API_VERSION}" \
    -H "Ocp-Apim-Subscription-Key: ${API_KEY}")
  
  TRAINING_STATUS=$(echo $RESPONSE | jq -r '.status // "unknown"')
  
  if [ "$TRAINING_STATUS" = "succeeded" ]; then
    echo "✅ Training completed successfully!"
    break
  elif [ "$TRAINING_STATUS" = "failed" ]; then
    echo "❌ Training failed!"
    echo "Response: $RESPONSE"
    exit 1
  else
    echo "   Status: $TRAINING_STATUS"
    sleep 30
    ATTEMPTS=$((ATTEMPTS + 1))
  fi
done

if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
  echo "❌ Training timeout - please check manually in Language Studio"
  exit 1
fi

# Step 4: Deploy the Model
echo ""
echo "🚀 Step 4: Deploying trained model to production..."

curl -X PUT \
  "${ENDPOINT}language/authoring/analyze-conversations/projects/${PROJECT_NAME}/deployments/${DEPLOYMENT_NAME}?api-version=${API_VERSION}" \
  -H "Ocp-Apim-Subscription-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "trainedModelLabel": "'${TRAINING_JOB_ID}'"
  }'

echo ""
echo "⏳ Waiting for deployment to complete..."
sleep 20

# Check deployment status
DEPLOYMENT_STATUS="running"
ATTEMPTS=0
MAX_ATTEMPTS=10

while [ "$DEPLOYMENT_STATUS" != "succeeded" ] && [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
  echo "⏳ Checking deployment status... (attempt $((ATTEMPTS + 1))/$MAX_ATTEMPTS)"
  
  RESPONSE=$(curl -s \
    "${ENDPOINT}language/authoring/analyze-conversations/projects/${PROJECT_NAME}/deployments/${DEPLOYMENT_NAME}?api-version=${API_VERSION}" \
    -H "Ocp-Apim-Subscription-Key: ${API_KEY}")
  
  DEPLOYMENT_STATUS=$(echo $RESPONSE | jq -r '.deploymentStatus // "unknown"')
  
  if [ "$DEPLOYMENT_STATUS" = "succeeded" ]; then
    echo "✅ Deployment completed successfully!"
    break
  elif [ "$DEPLOYMENT_STATUS" = "failed" ]; then
    echo "❌ Deployment failed!"
    echo "Response: $RESPONSE"
    exit 1
  else
    echo "   Status: $DEPLOYMENT_STATUS"
    sleep 15
    ATTEMPTS=$((ATTEMPTS + 1))
  fi
done

if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
  echo "❌ Deployment timeout - please check manually in Language Studio"
  exit 1
fi

echo ""
echo "🎉 CLU Project Setup Complete!"
echo ""
echo "📋 Summary:"
echo "   Project Name: $PROJECT_NAME"
echo "   Deployment Name: $DEPLOYMENT_NAME"
echo "   Endpoint: $ENDPOINT"
echo "   Intents: search_medical, memory_personal, meta_request, conversation, system_query"
echo ""
echo "🧪 Test your CLU project:"
echo "   1. Go to Language Studio: https://language.cognitive.microsoft.com/"
echo "   2. Open your project: $PROJECT_NAME"
echo "   3. Test utterances in the 'Test' section"
echo ""
echo "🔧 Backend Integration:"
echo "   The CLU credentials are already stored in Key Vault and configured in your backend!"
echo "   Your azureIntentService.js will now use CLU instead of heuristics." 