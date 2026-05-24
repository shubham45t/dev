#!/bin/bash

MODEL="openai/gpt-oss-120b"

export GROQ_API_KEY="xai-NazTnYay9hIvFPjwlqyftWyIJsI7jgsfxwVepRoV0SU1kC3bFSQ4izGKbvF44ttjPUaA3lZzIxhJwEP3"

history='[]'

while true; do
    read -p "You: " prompt

    [[ "$prompt" == "exit" ]] && break

    history=$(echo "$history" | jq --arg p "$prompt" \
        '. + [{"role":"user","content":$p}] | if length > 6 then .[-6:] else . end')

    response=$(curl -s https://api.groq.com/openai/v1/chat/completions \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $GROQ_API_KEY" \
      -d "$(jq -n \
        --arg model "$MODEL" \
        --argjson messages "$history" \
        '{
          model: $model,
          max_tokens: 3000,
          messages: $messages
        }')")

    error=$(echo "$response" | jq -r '.error.message // empty')

    if [[ -n "$error" ]]; then
        echo ""
        echo "ERROR: $error"
        echo ""
        continue
    fi

    reply=$(echo "$response" | jq -r '.choices[0].message.content // empty')

    if [[ -z "$reply" ]]; then
        echo ""
        echo "ERROR: No response content"
        echo "$response" | jq
        echo ""
        continue
    fi

    echo ""
    echo "AI: $reply"
    echo ""

    history=$(echo "$history" | jq --arg r "$reply" \
        '. + [{"role":"assistant","content":$r}] | if length > 6 then .[-6:] else . end')
done
