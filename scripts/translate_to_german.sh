#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Translate to German
# @raycast.mode silent
# @raycast.icon 📝
# @raycast.packageName Language Tools

# Documentation:
# @raycast.description Translates clipboard text into grammatically correct German
# @raycast.author Roel van der Ven
# @raycast.authorURL https://roelvanderven.com

# Configuration
OPENAI_API_KEY="XXXXX"

# Build config and call workflow handler
CONFIG=$(jq -n \
  --arg api_key "$OPENAI_API_KEY" \
  --arg model "gpt-4o-mini" \
  --arg system_prompt "Translate the text into grammatically correct German. Only output the corrected German text. No comments." \
  --arg spinner_msg "Translating…" \
  --arg success_msg "✅ Translated! German copied" \
  '{
    api_key: $api_key,
    model: $model,
    system_prompt: $system_prompt,
    temperature: 0.3,
    max_tokens: 500,
    spinner_msg: $spinner_msg,
    success_msg: $success_msg,
    notify_mode: "hud"
  }')

exec "$HOME/.raycast/bin/llm-workflow.sh" "$CONFIG"