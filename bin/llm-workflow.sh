#!/bin/bash
# LLM Workflow Handler - called by Raycast scripts
# Usage: llm-workflow.sh <config_json>

set -euo pipefail

# Parse config from JSON argument
CONFIG="$1"
MODEL=$(echo "$CONFIG" | jq -r '.model')
SYSTEM_PROMPT=$(echo "$CONFIG" | jq -r '.system_prompt')
USER_TRANSFORM=$(echo "$CONFIG" | jq -r '.user_transform // "none"')
TEMPERATURE=$(echo "$CONFIG" | jq -r '.temperature // 1')
MAX_TOKENS=$(echo "$CONFIG" | jq -r '.max_tokens // "null"')
SPINNER_MSG=$(echo "$CONFIG" | jq -r '.spinner_msg')
SUCCESS_MSG=$(echo "$CONFIG" | jq -r '.success_msg')
OPENAI_API_KEY=$(echo "$CONFIG" | jq -r '.api_key')
NOTIFY_MODE=$(echo "$CONFIG" | jq -r '.notify_mode // "hud"')
SKIP_VALIDATION=$(echo "$CONFIG" | jq -r '.skip_validation // false')

# Spinner state
SPINNER_FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
SPINNER_PID=""
SPINNER_RUNNING=0

notify() {
  [ "$NOTIFY_MODE" = "none" ] && return
  local args_json=$(jq -n --arg title "$1" '{title: $title}')
  local encoded=$(printf "%s" "$args_json" | jq -r @uri)
  open -g "raycast://extensions/maxnyby/raycast-notification/index?launchType=background&arguments=$encoded" 2>/dev/null || true
}

start_spinner() {
  SPINNER_RUNNING=1
  (
    local i=0
    while [ "$SPINNER_RUNNING" -eq 1 ]; do
      notify "${SPINNER_FRAMES[$(( i % ${#SPINNER_FRAMES[@]} ))]} $1"
      sleep 1
      i=$((i+1))
    done
  ) &
  SPINNER_PID=$!
}

stop_spinner() {
  if [ -n "$SPINNER_PID" ]; then
    SPINNER_RUNNING=0
    kill "$SPINNER_PID" 2>/dev/null || true
    wait "$SPINNER_PID" 2>/dev/null || true
    SPINNER_PID=""
  fi
}

trap stop_spinner EXIT

# Read clipboard
INPUT=$(pbpaste)

# Validate unless skipped
if [ "$SKIP_VALIDATION" != "true" ]; then
  # Check if empty (including whitespace-only)
  if [[ -z "${INPUT// /}" ]]; then
    echo "❌ Empty clipboard"
    exit 0
  fi
  
  # Check if single word (alphanumeric only, no spaces/punctuation)
  if [[ "$INPUT" =~ ^[[:alnum:]]+$ ]]; then
    echo "❌ Single word detected"
    exit 0
  fi
  
  # Check if hash-like pattern
  if [[ "$INPUT" =~ ^[a-f0-9]{4,}-[a-f0-9]{4,}-[a-f0-9]{4,}$ ]]; then
    echo "❌ Hash-like pattern detected"
    exit 0
  fi
fi

# Apply user transform if specified
case "$USER_TRANSFORM" in
  wrap_prompt_tags)
    USER_INPUT=$(printf "<HUMAN_PROMPT>\n%s\n</HUMAN_PROMPT>" "$INPUT")
    ;;
  *)
    USER_INPUT="$INPUT"
    ;;
esac

# Build request body
if [ "$MAX_TOKENS" = "null" ]; then
  BODY=$(jq -n \
    --arg model "$MODEL" \
    --arg sys "$SYSTEM_PROMPT" \
    --arg user "$USER_INPUT" \
    --argjson temp "$TEMPERATURE" \
    '{
      model: $model,
      messages: [{role: "system", content: $sys}, {role: "user", content: $user}],
      temperature: $temp
    }')
else
  BODY=$(jq -n \
    --arg model "$MODEL" \
    --arg sys "$SYSTEM_PROMPT" \
    --arg user "$USER_INPUT" \
    --argjson temp "$TEMPERATURE" \
    --argjson max "$MAX_TOKENS" \
    '{
      model: $model,
      messages: [{role: "system", content: $sys}, {role: "user", content: $user}],
      temperature: $temp,
      max_tokens: $max
    }')
fi

# Call API with spinner
start_spinner "$SPINNER_MSG"

RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$BODY")

stop_spinner

# Handle errors
if echo "$RESPONSE" | grep -q '"error"'; then
  ERROR=$(echo "$RESPONSE" | jq -r '.error.message')
  notify "⚠️ Failed: $ERROR"
  echo "⚠️ Failed: $ERROR"
  exit 1
fi

# Extract result
RESULT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')

if [ "$RESULT" = "null" ] || [ -z "$RESULT" ]; then
  notify "❌ No output"
  echo "❌ No output produced"
  exit 1
fi

# Copy and notify
printf "%s" "$RESULT" | pbcopy
notify "$SUCCESS_MSG"
echo "$SUCCESS_MSG ☑️"