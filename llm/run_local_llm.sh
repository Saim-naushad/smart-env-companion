#!/bin/bash

# Path to your model (adjust if different)
MODEL_PATH="../models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"

# Simple user prompt 
PROMPT="What is the air quality today?"

# Run using llama.cpp with ChatML auto-formatting
../llama.cpp/build/bin/llama-cli \
  -m "$MODEL_PATH" \
  --chat-template chatml \
  -p "$PROMPT" \
  --color \
  --interactive \
  -n 128
