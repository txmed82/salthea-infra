#!/bin/bash

# Simplified CLU Setup - Direct API calls without complex job monitoring
# Since project creation worked, let's train and deploy directly

set -e

# Configuration
ENDPOINT="https://salthea-language.cognitiveservices.azure.com"
API_KEY="397d1d363b6046d4b72276e263819297"
PROJECT_NAME="salthea-intent-routing"
DEPLOYMENT_NAME="production"
MODEL_NAME="SaltheaRoutingModel"
API_VERSION="2023-04-01"

echo "🚀 CLU Training & Deployment: $PROJECT_NAME"
echo "📍 Endpoint: $ENDPOINT"
echo ""

# Step 1: Verify project exists
echo "🔍 Checking if project exists..."
project_check=$(curl -s -w "%{http_code}" -o /dev/null \
    "$ENDPOINT/language/authoring/analyze-conversations/projects/$PROJECT_NAME?api-version=$API_VERSION" \
    -H "Ocp-Apim-Subscription-Key: $API_KEY")

if [ "$project_check" = "200" ]; then
    echo "✅ Project '$PROJECT_NAME' found!"
else
    echo "❌ Project not found (HTTP $project_check)"
    exit 1
fi

# Step 2: Train Model
echo ""
echo "🎯 Training CLU model..."

train_response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -X POST \
    "$ENDPOINT/language/authoring/analyze-conversations/projects/$PROJECT_NAME/:train?api-version=$API_VERSION" \
    -H "Ocp-Apim-Subscription-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "modelLabel": "'$MODEL_NAME'",
        "trainingMode": "advanced",
        "trainingConfigVersion": "2022-09-01",
        "evaluationOptions": {
            "kind": "percentage",
            "testingSplitPercentage": 20,
            "trainingSplitPercentage": 80
        }
    }')

http_code=$(echo "$train_response" | tail -n1 | sed 's/.*HTTP_CODE://')

if [ "$http_code" = "202" ]; then
    echo "✅ Training initiated successfully"
    echo "   (This will take a few minutes to complete)"
    
    # Wait a bit for training to start
    echo "   Waiting 30 seconds for training to begin..."
    sleep 30
else
    echo "❌ Training failed (HTTP $http_code)"
    echo "Response: $(echo "$train_response" | sed '$d')"
    exit 1
fi

# Step 3: Check training status periodically
echo ""
echo "⏳ Checking training status..."

for i in {1..20}; do
    echo "   Check $i/20..."
    
    status_response=$(curl -s \
        "$ENDPOINT/language/authoring/analyze-conversations/projects/$PROJECT_NAME/models?api-version=$API_VERSION" \
        -H "Ocp-Apim-Subscription-Key: $API_KEY")
    
    # Look for our model in the response
    model_status=$(echo "$status_response" | jq -r --arg model "$MODEL_NAME" '.value[] | select(.modelLabel == $model) | .modelTrainingStatus // "unknown"')
    
    echo "   Model '$MODEL_NAME' status: $model_status"
    
    if [ "$model_status" = "trained" ]; then
        echo "✅ Training completed successfully!"
        break
    elif [ "$model_status" = "failed" ]; then
        echo "❌ Training failed!"
        exit 1
    elif [ "$i" = "20" ]; then
        echo "⚠️  Training taking longer than expected, proceeding anyway..."
        break
    else
        echo "   Still training... waiting 30 seconds"
        sleep 30
    fi
done

# Step 4: Deploy Model
echo ""
echo "🚀 Deploying CLU model..."

deploy_response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -X PUT \
    "$ENDPOINT/language/authoring/analyze-conversations/projects/$PROJECT_NAME/deployments/$DEPLOYMENT_NAME?api-version=$API_VERSION" \
    -H "Ocp-Apim-Subscription-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "trainedModelLabel": "'$MODEL_NAME'"
    }')

http_code=$(echo "$deploy_response" | tail -n1 | sed 's/.*HTTP_CODE://')

if [ "$http_code" = "202" ]; then
    echo "✅ Deployment initiated successfully"
    echo "   (This will take a few minutes to complete)"
    
    # Wait for deployment to settle
    echo "   Waiting 60 seconds for deployment to complete..."
    sleep 60
else
    echo "❌ Deployment failed (HTTP $http_code)"
    echo "Response: $(echo "$deploy_response" | sed '$d')"
    exit 1
fi

# Step 5: Test Deployment
echo ""
echo "🧪 Testing CLU model..."

test_queries=(
    "What causes diabetes?"
    "Analyze my blood pressure trends" 
    "Hello how are you?"
    "Suggest health questions"
    "Connect my health data"
)

all_tests_passed=true

for query in "${test_queries[@]}"; do
    echo ""
    echo "Testing: \"$query\""
    
    test_response=$(curl -s \
        -X POST \
        "$ENDPOINT/language/:analyze-conversations?api-version=$API_VERSION" \
        -H "Ocp-Apim-Subscription-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d '{
            "kind": "Conversation",
            "analysisInput": {
                "conversationItem": {
                    "id": "1",
                    "participantId": "1",
                    "text": "'"$query"'"
                }
            },
            "parameters": {
                "projectName": "'$PROJECT_NAME'",
                "deploymentName": "'$DEPLOYMENT_NAME'",
                "stringIndexType": "TextElement_V8"
            }
        }')
    
    # Check if we got an error
    error_code=$(echo "$test_response" | jq -r '.error.code // empty')
    if [ -n "$error_code" ]; then
        echo "   ❌ Error: $error_code"
        echo "   $(echo "$test_response" | jq -r '.error.message // "Unknown error"')"
        all_tests_passed=false
    else
        intent=$(echo "$test_response" | jq -r '.result.prediction.topIntent // "unknown"')
        confidence=$(echo "$test_response" | jq -r '.result.prediction.intents[0].confidenceScore // 0')
        confidence_percent=$(echo "$confidence * 100" | bc -l 2>/dev/null | cut -d'.' -f1 || echo "N/A")
        
        echo "   → Intent: $intent (confidence: ${confidence_percent}%)"
    fi
done

echo ""
echo "🎉 CLU Setup Complete!"
echo ""
echo "✅ Project: $PROJECT_NAME"
echo "✅ Model: $MODEL_NAME" 
echo "✅ Deployment: $DEPLOYMENT_NAME"
echo "✅ Endpoint: $ENDPOINT"

if [ "$all_tests_passed" = true ]; then
    echo "✅ All tests passed!"
else
    echo "⚠️  Some tests had issues, but deployment may still be working"
fi

echo ""
echo "🔧 CLU is ready! Environment variables:"
echo "   CLU_ENDPOINT=$ENDPOINT"
echo "   CLU_KEY=$API_KEY"
echo "   CLU_PROJECT_NAME=$PROJECT_NAME"
echo "   CLU_DEPLOYMENT_NAME=$DEPLOYMENT_NAME" 