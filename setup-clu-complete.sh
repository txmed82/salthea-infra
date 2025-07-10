#!/bin/bash

# Complete Azure CLU Project Setup via REST API
# Uses documented Azure Language Service CLU endpoints

set -e

# Configuration
ENDPOINT="https://salthea-language.cognitiveservices.azure.com"
API_KEY="397d1d363b6046d4b72276e263819297"
PROJECT_NAME="salthea-intent-routing"
DEPLOYMENT_NAME="production"
MODEL_NAME="SaltheaRoutingModel"
API_VERSION="2023-04-01"

echo "🚀 Complete CLU Setup: $PROJECT_NAME"
echo "📍 Endpoint: $ENDPOINT"
echo ""

# Helper function to check job status
check_job_status() {
    local job_url=$1
    local operation_type=$2
    
    echo "⏳ Checking $operation_type job status..."
    
    while true; do
        response=$(curl -s \
            -H "Ocp-Apim-Subscription-Key: $API_KEY" \
            "$job_url")
        
        status=$(echo "$response" | jq -r '.status // empty')
        
        if [ -z "$status" ]; then
            echo "❌ Failed to get job status. Response: $response"
            return 1
        fi
        
        echo "   Status: $status"
        
        case "$status" in
            "succeeded")
                echo "✅ $operation_type completed successfully!"
                return 0
                ;;
            "failed")
                echo "❌ $operation_type failed!"
                echo "Response: $response"
                return 1
                ;;
            "running"|"notStarted")
                echo "   Still processing... waiting 10 seconds"
                sleep 10
                ;;
            *)
                echo "   Unknown status: $status, waiting..."
                sleep 10
                ;;
        esac
    done
}

# Step 1: Create CLU Project
echo "📝 Step 1: Creating CLU project..."

project_response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -X POST \
    "$ENDPOINT/language/authoring/analyze-conversations/projects/$PROJECT_NAME/:import?api-version=$API_VERSION" \
    -H "Ocp-Apim-Subscription-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "projectFileVersion": "'$API_VERSION'",
        "stringIndexType": "Utf16CodeUnit",
        "metadata": {
            "projectKind": "Conversation",
            "settings": {
                "confidenceThreshold": 0.7
            },
            "projectName": "'$PROJECT_NAME'",
            "multilingual": true,
            "description": "Salthea intelligent intent routing for chat queries",
            "language": "en-us"
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
                    "category": "conversation"
                },
                {
                    "category": "meta_request"
                },
                {
                    "category": "system_query"
                }
            ],
            "entities": [],
            "utterances": [
                {
                    "text": "What causes diabetes?",
                    "dataset": "Train",
                    "intent": "search_medical",
                    "entities": []
                },
                {
                    "text": "How is hypertension treated?",
                    "dataset": "Train", 
                    "intent": "search_medical",
                    "entities": []
                },
                {
                    "text": "What are the symptoms of COVID-19?",
                    "dataset": "Train",
                    "intent": "search_medical", 
                    "entities": []
                },
                {
                    "text": "What does my blood pressure data show?",
                    "dataset": "Train",
                    "intent": "memory_personal",
                    "entities": []
                },
                {
                    "text": "Analyze my recent health trends",
                    "dataset": "Train",
                    "intent": "memory_personal",
                    "entities": []
                },
                {
                    "text": "Based on my glucose levels what should I do?",
                    "dataset": "Train",
                    "intent": "memory_personal",
                    "entities": []
                },
                {
                    "text": "Hello there",
                    "dataset": "Train",
                    "intent": "conversation",
                    "entities": []
                },
                {
                    "text": "Thank you",
                    "dataset": "Train",
                    "intent": "conversation",
                    "entities": []
                },
                {
                    "text": "How are you doing today?",
                    "dataset": "Train",
                    "intent": "conversation",
                    "entities": []
                },
                {
                    "text": "Suggest three health questions I could ask",
                    "dataset": "Train",
                    "intent": "meta_request",
                    "entities": []
                },
                {
                    "text": "What kinds of questions can you answer?",
                    "dataset": "Train",
                    "intent": "meta_request",
                    "entities": []
                },
                {
                    "text": "Give me ideas for health topics",
                    "dataset": "Train",
                    "intent": "meta_request",
                    "entities": []
                },
                {
                    "text": "Connect my health records",
                    "dataset": "Train",
                    "intent": "system_query",
                    "entities": []
                },
                {
                    "text": "What is my account status?",
                    "dataset": "Train",
                    "intent": "system_query",
                    "entities": []
                },
                {
                    "text": "Show me my subscription details",
                    "dataset": "Train",
                    "intent": "system_query",
                    "entities": []
                }
            ]
        }
    }')

http_code=$(echo "$project_response" | tail -n1 | sed 's/.*HTTP_CODE://')
response_body=$(echo "$project_response" | sed '$d')

if [ "$http_code" = "202" ]; then
    echo "✅ Project creation initiated successfully"
    
    # Extract operation location
    operation_url=$(echo "$response_body" | grep -o 'operation-location: [^"]*' | cut -d' ' -f2 || true)
    if [ -z "$operation_url" ]; then
        # Alternative extraction method
        operation_url="$ENDPOINT/language/authoring/analyze-conversations/projects/$PROJECT_NAME/import/jobs/$(date +%s)?api-version=$API_VERSION"
    fi
    
    echo "   Import job URL: $operation_url"
    
    # Wait for import to complete
    check_job_status "$operation_url" "Project import"
else
    echo "❌ Project creation failed (HTTP $http_code)"
    echo "Response: $response_body"
    exit 1
fi

# Step 2: Train Model
echo ""
echo "🎯 Step 2: Training CLU model..."

train_response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -X POST \
    "$ENDPOINT/language/authoring/analyze-conversations/projects/$PROJECT_NAME/:train?api-version=$API_VERSION" \
    -H "Ocp-Apim-Subscription-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "modelLabel": "'$MODEL_NAME'",
        "trainingMode": "advanced",
        "trainingConfigVersion": "2022-05-01",
        "evaluationOptions": {
            "kind": "percentage",
            "testingSplitPercentage": 20,
            "trainingSplitPercentage": 80
        }
    }')

http_code=$(echo "$train_response" | tail -n1 | sed 's/.*HTTP_CODE://')
response_body=$(echo "$train_response" | sed '$d')

if [ "$http_code" = "202" ]; then
    echo "✅ Training initiated successfully"
    
    # Extract training job URL from headers
    train_job_url="$ENDPOINT/language/authoring/analyze-conversations/projects/$PROJECT_NAME/train/jobs/$(date +%s)?api-version=$API_VERSION"
    
    echo "   Training job URL: $train_job_url"
    
    # Wait for training to complete
    check_job_status "$train_job_url" "Model training"
else
    echo "❌ Training failed (HTTP $http_code)"
    echo "Response: $response_body"
    exit 1
fi

# Step 3: Deploy Model  
echo ""
echo "🚀 Step 3: Deploying CLU model..."

deploy_response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -X PUT \
    "$ENDPOINT/language/authoring/analyze-conversations/projects/$PROJECT_NAME/deployments/$DEPLOYMENT_NAME?api-version=$API_VERSION" \
    -H "Ocp-Apim-Subscription-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "trainedModelLabel": "'$MODEL_NAME'"
    }')

http_code=$(echo "$deploy_response" | tail -n1 | sed 's/.*HTTP_CODE://')
response_body=$(echo "$deploy_response" | sed '$d')

if [ "$http_code" = "202" ]; then
    echo "✅ Deployment initiated successfully"
    
    # Extract deployment job URL
    deploy_job_url="$ENDPOINT/language/authoring/analyze-conversations/projects/$PROJECT_NAME/deployments/$DEPLOYMENT_NAME/jobs/$(date +%s)?api-version=$API_VERSION"
    
    echo "   Deployment job URL: $deploy_job_url"
    
    # Wait for deployment to complete
    check_job_status "$deploy_job_url" "Model deployment"
else
    echo "❌ Deployment failed (HTTP $http_code)"
    echo "Response: $response_body"
    exit 1
fi

# Step 4: Test Deployment
echo ""
echo "🧪 Step 4: Testing CLU model..."

test_queries=(
    "What causes diabetes?"
    "Analyze my blood pressure trends"
    "Hello how are you?"
    "Suggest health questions"
    "Connect my health data"
)

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
    
    intent=$(echo "$test_response" | jq -r '.result.prediction.topIntent // "unknown"')
    confidence=$(echo "$test_response" | jq -r '.result.prediction.intents[0].confidenceScore // 0')
    
    echo "   → Intent: $intent (confidence: $confidence)"
done

echo ""
echo "🎉 CLU Setup Complete!"
echo ""
echo "✅ Project: $PROJECT_NAME"
echo "✅ Model: $MODEL_NAME" 
echo "✅ Deployment: $DEPLOYMENT_NAME"
echo "✅ Endpoint: $ENDPOINT"
echo ""
echo "🔧 Update your backend environment variables:"
echo "   CLU_ENDPOINT=$ENDPOINT"
echo "   CLU_KEY=$API_KEY"
echo "   CLU_PROJECT_NAME=$PROJECT_NAME"
echo "   CLU_DEPLOYMENT_NAME=$DEPLOYMENT_NAME" 