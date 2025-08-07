# 🧠 TinyLLaMA Local Setup Guide

This document explains how to set up and run the TinyLLaMA model locally using llama.cpp

## 1. Install 

```bash
brew install cmake git

## 2. Clone and Build llama.cpp

git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
mkdir build && cd build
cmake .. -DLLAMA_METAL=on
cmake --build . --config Release

## 3. Donwload model

tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf

## 4. Run the model

cd llm
./run_local_llm.sh