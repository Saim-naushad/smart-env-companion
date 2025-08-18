# 🧠 TinyLLaMA Local Setup Guide

This document explains how to set up and run the TinyLLaMA model on Pi using llama.cpp

## 1. Install 

`brew install cmake git`

## 2. Clone and Build llama.cpp

`git clone https://github.com/ggerganov/llama.cpp.git`

`cd llama.cpp`

`mkdir build && cd build`

`cmake .. -DLLAMA_METAL=on`

`cmake --build . --config Release`

## 3. Donwload model

~/models/Llama-3.2-3B-Instruct-Q4_K_M.gguf

## 4. Run the model

`export LLAMA_BIN=~/llama.cpp/build/bin/llama-cli`

`export LLAMA_BIN=~/llama.cpp/build/bin/llama-cli`

`./llm/run_local_llm.sh --json ./temperature.json`
