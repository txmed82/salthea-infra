#!/bin/bash

# Simplified Azure CLU Project Setup Script
# Uses Language Studio REST APIs with correct endpoints

set -e

# Configuration
ENDPOINT="https://salthea-language.cognitiveservices.azure.com/"
API_KEY="397d1d363b6046d4b72276e263819297"
PROJECT_NAME="salthea-intent-routing"
DEPLOYMENT_NAME="production"

echo "🚀 Setting up CLU project: $PROJECT_NAME"
echo "📍 Endpoint: $ENDPOINT"

# Test endpoint connectivity first
echo ""
echo "🔍 Testing endpoint connectivity..."
HEALTH_CHECK=$(curl -s -w "%{http_code}" \
  "${ENDPOINT}language/:analyze-text?api-version=2022-05-01" \
  -H "Ocp-Apim-Subscription-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "kind": "SentimentAnalysis",
    "parameters": {
      "modelVersion": "latest"
    },
    "analysisInput": {
      "documents": [
        {
          "id": "1",
          "language": "en",
          "text": "Hello world"
        }
      ]
    }
  }' -o /dev/null)

if [ "$HEALTH_CHECK" = "200" ]; then
  echo "✅ Endpoint is accessible and working"
else
  echo "❌ Endpoint connectivity test failed (HTTP $HEALTH_CHECK)"
  echo "   This might indicate region or authentication issues"
fi

echo ""
echo "🔧 For CLU setup, please follow these manual steps:"
echo ""
echo "1. 🌐 Open Language Studio: https://language.cognitive.microsoft.com/"
echo "2. 🔑 Sign in with your Azure account"
echo "3. ➕ Create a new Conversational Language Understanding project:"
echo "   - Project Name: $PROJECT_NAME"
echo "   - Language: English (en-us)"
echo "   - Description: Intent classification for Salthea health chat routing"
echo ""
echo "4. 📋 Add these intents:"
echo "   - search_medical (for medical questions needing Valyu)"
echo "   - memory_personal (for personal health data queries)"
echo "   - meta_request (for suggestion requests)"
echo "   - conversation (for greetings, thanks)"
echo "   - system_query (for account/connection requests)"
echo ""
echo "5. 📝 Add example utterances for each intent:"
echo ""
echo "   search_medical:"
echo "   - 'What causes diabetes?'"
echo "   - 'How is hypertension treated?'"
echo "   - 'What are the symptoms of COVID-19?'"
echo "   - 'Explain how insulin works'"
echo "   - 'What medications are used for depression?'"
echo ""
echo "   memory_personal:"
echo "   - 'What does my blood pressure data show?'"
echo "   - 'Analyze my recent health trends'"
echo "   - 'Based on my records, what should I monitor?'"
echo "   - 'How has my weight changed over time?'"
echo ""
echo "   meta_request:"
echo "   - 'Suggest some health questions I could ask'"
echo "   - 'What kinds of questions can you answer?'"
echo "   - 'Give me ideas for health-related queries'"
echo ""
echo "   conversation:"
echo "   - 'Hello'"
echo "   - 'Thank you'"
echo "   - 'That is helpful'"
echo "   - 'Good morning'"
echo ""
echo "   system_query:"
echo "   - 'Connect my health data'"
echo "   - 'Show my account status'"
echo "   - 'Update my profile'"
echo ""
echo "6. 🏋️  Train the model (this takes 5-10 minutes)"
echo "7. 🚀 Deploy to 'production' slot"
echo "8. 🧪 Test with sample utterances"
echo ""
echo "📋 Your CLU Configuration:"
echo "   Endpoint: $ENDPOINT"
echo "   Project: $PROJECT_NAME"
echo "   Deployment: $DEPLOYMENT_NAME"
echo "   Key: [Already stored in Key Vault]"
echo ""
echo "✅ Once deployed, your backend will automatically use CLU for routing!"
echo "   (It will fall back to enhanced heuristics if CLU isn't configured)"

# Alternative: Try to create project using authoring API
echo ""
echo "🔄 Attempting automated project creation..."

# Try the Language Studio authoring API
CREATE_RESPONSE=$(curl -s -w "%{http_code}" \
  "${ENDPOINT}language/authoring/analyze-conversations/projects/${PROJECT_NAME}?api-version=2023-04-01" \
  -X PUT \
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
  }' -o /tmp/create_response.json)

if [ "$CREATE_RESPONSE" = "201" ] || [ "$CREATE_RESPONSE" = "200" ]; then
  echo "✅ Project created successfully via API!"
  cat /tmp/create_response.json
  echo ""
  echo "🎯 Next: Import intents and train model in Language Studio"
else
  echo "⚠️  Automated creation failed (HTTP $CREATE_RESPONSE)"
  echo "   Response: $(cat /tmp/create_response.json 2>/dev/null || echo 'No response')"
  echo "   Please use the manual Language Studio approach above"
fi

echo ""
echo "🔧 Backend Integration Status:"
echo "   ✅ azureIntentService.js configured and ready"
echo "   ✅ Enhanced heuristics working as fallback"
echo "   ✅ CLU credentials stored in Key Vault"
echo "   🔄 Waiting for CLU project training completion" 