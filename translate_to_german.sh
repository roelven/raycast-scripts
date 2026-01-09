#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Translate to German
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📝
# @raycast.packageName Language Tools

# Documentation:
# @raycast.description Translates clipboard text into grammatically correct German using GPT-4 and copies it back to clipboard.
# @raycast.author Roel van der Ven
# @raycast.authorURL https://roelvanderven.com

# CONFIGURATION
OPENAI_API_KEY="XXXXXXX"
LOGGING_ENABLED=false
LOGFILE="/tmp/translate_log.txt"

# Read clipboard
INPUT=$(pbpaste)

# Validate input: skip if one word or hash-like
if [[ "$INPUT" =~ ^[[:alnum:]]+$ ]]; then
  echo "❌ Skipped: single word detected"
  exit 0
fi

if [[ "$INPUT" =~ ^[a-f0-9]{4,}-[a-f0-9]{4,}-[a-f0-9]{4,}$ ]]; then
  echo "❌ Skipped: hash-like pattern detected"
  exit 0
fi

# Show immediate feedback
echo "Translating... ⏳" 

if [ "$LOGGING_ENABLED" = true ]; then
  echo "--- $(date) ---" >> $LOGFILE
  echo "Clipboard:" >> $LOGFILE
  echo "$INPUT" >> $LOGFILE
fi

# Escape input safely for JSON
ESCAPED_INPUT=$(echo "$INPUT" | jq -Rs .)

# Start timing
START_TIME=$(date +%s.%N)

# API request
RESPONSE=$(curl -s --max-time 10 https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"gpt-4-turbo\",
    \"messages\": [
      {\"role\": \"system\", \"content\": \"Translate the text into grammatically correct German. Only output the corrected German text. No comments.\"},
      {\"role\": \"user\", \"content\": $ESCAPED_INPUT}
    ],
    \"temperature\": 0.2,
    \"max_tokens\": 1024
}")

if [ "$LOGGING_ENABLED" = true ]; then
  echo "Response:" >> $LOGFILE
  echo "$RESPONSE" >> $LOGFILE
fi

# Check for API error
if echo "$RESPONSE" | grep -q '"error"'; then
  ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message')
  if [ "$LOGGING_ENABLED" = true ]; then
    echo "API error: $ERROR_MSG" >> $LOGFILE
  fi
  echo "⚠️ Translation failed. \"API Error: $ERROR_MSG\" with title \"OpenAI Error\""
  exit 1
fi

# Extract translation
TRANSLATED=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')

# Calculate API latency
END_TIME=$(date +%s.%N)
LATENCY=$(echo "$END_TIME - $START_TIME" | bc)

if [ "$LOGGING_ENABLED" = true ]; then
  echo "Parsed result:" >> $LOGFILE
  echo "$TRANSLATED" >> $LOGFILE
  echo "API latency: ${LATENCY}s" >> $LOGFILE
fi

# Append latency to stats file for analysis
echo "$(date +"%Y-%m-%d %H:%M:%S"),${LATENCY}" >> "/tmp/translate_latency_stats.csv"

# Handle null output
if [ "$TRANSLATED" == "null" ]; then
  echo "Translation output was null"
  exit 1
fi

# Copy to clipboard and notify
echo "$TRANSLATED" | pbcopy
echo "Translated! Corrected German copied ☑️"

