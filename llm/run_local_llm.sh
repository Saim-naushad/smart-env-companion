#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Smart Env Companion — Temperature Chat (Llama 3.2 3B Instruct)
#
# Usage:
#   ./llm/run_local_llm.sh --json ./temperature.json
#   ./llm/run_local_llm.sh --json ./temperature.json "Is it comfortable to work now?"
#   ./llm/run_local_llm.sh                          # REPL
#
# Flags:
#   --json <path>       read this file for the latest reading
#   --stale-mins <N>    consider reading stale after N minutes (default 10)
#   --quiet             log llama.cpp banners to llm/llama.log (quieter stdout)
#   --qa                wrap input in Q:/A: format
#
# Env:
#   MODEL_PATH=...      (defaults to models/Llama-3.2-3B-Instruct-Q4_K_M.gguf)
#   LLAMA_BIN=...       (defaults to ./llama.cpp/build/bin/llama-cli)
# ------------------------------------------------------------

MODEL_PATH="${MODEL_PATH:-models/Llama-3.2-3B-Instruct-Q4_K_M.gguf}"
LLAMA_BIN="${LLAMA_BIN:-./llama.cpp/build/bin/llama-cli}"
QUIET=""
QA_MODE=false
JSON_FILE=""
STALE_MINUTES=10
ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --json) JSON_FILE="$2"; shift 2 ;;
    --stale-mins) STALE_MINUTES="$2"; shift 2 ;;
    --quiet) QUIET="--quiet"; shift ;;
    --qa) QA_MODE=true; shift ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

# ---------- System prompt (refined) ----------
SYSTEM_PROMPT="You are Smart Env Companion — a short, practical advisor that bases every answer only on the provided sensor facts.

Rules:
- Answer the user's specific question in 1–2 sentences. Never dump a full report unless the user only greets you.
- Use only metrics present in FACTS. Do not invent AQI, humidity, CO₂, PM2.5, etc. If a metric is asked for but missing, say it was not provided.
- Reference the temperature band when helpful (cold / comfortable / hot) and the °C value if present.
- If reading is stale, note it once (briefly).

Advice mapping by band:
- cold (<18°C): suggest layers/warmth; do NOT recommend fan or AC; exercise: light/indoor warm-up.
- comfortable (18–26°C): normal activities; no AC/fan needed; ventilation only if AQI is provided and good.
- hot (>26°C): recommend hydration, lighter activity, fan/AC as needed; avoid heavy workouts.

Style:
- Be friendly but direct; avoid single-word replies; include a short justification tied to the facts.
- Do not contradict the band (e.g., do not call 25°C ‘hot’).
"

# ---------- Facts from JSON (band + staleness) ----------
have_jq=0; command -v jq >/dev/null 2>&1 && have_jq=1

build_facts_from_json() {
  local file="$1"
  [[ -n "$file" && -f "$file" && $have_jq -eq 1 ]] || { echo ""; return 0; }

  local cel ts
  cel="$(jq -r 'try .celsius // .temperature // .temp_c // empty' "$file")"
  ts="$(jq -r 'try .timestamp // empty' "$file")"

  local band="unknown"
  if [[ -n "${cel:-}" ]]; then
    band="$(awk -v t="$cel" 'BEGIN{ if(t<18)print"cold"; else if(t<=26)print"comfortable"; else print"hot"; }')"
  fi

  local age=""; local now ts_epoch
  if [[ -n "${ts:-}" ]]; then
    now="$(date +%s)"
    ts_epoch="$(date -j -f "%Y-%m-%d %H:%M:%S" "$ts" +%s 2>/dev/null || date -d "$ts" +%s 2>/dev/null || echo "")"
    [[ -n "$ts_epoch" ]] && age=$(( (now - ts_epoch) / 60 ))
  fi

  local stale_note=""
  if [[ -n "${age:-}" && "$age" -gt "$STALE_MINUTES" ]]; then
    stale_note="note: reading may be stale"
  fi

  local facts="band: ${band}"
  [[ -n "${cel:-}" ]] && facts+=$'\n'"temperature_c: ${cel}"
  [[ -n "${ts:-}"  ]] && facts+=$'\n'"timestamp: ${ts}"
  [[ -n "${age:-}" ]] && facts+=$'\n'"reading_age_min: ${age}"
  [[ -n "${stale_note:-}" ]] && facts+=$'\n'"${stale_note}"
  printf "%s" "$facts"
}

FACTS=""
if [[ -n "$JSON_FILE" && -f "$JSON_FILE" ]]; then
  if [[ $have_jq -eq 1 ]]; then
    FACTS="$(build_facts_from_json "$JSON_FILE")"
  else
    FACTS="(raw_json) $(cat "$JSON_FILE")"
  fi
fi

# ---------- LLM call ----------
call_llm() {
  local user_q="$1"
  local prompt_text
  if [[ -n "${FACTS:-}" ]]; then
    prompt_text=$'FACTS:\n'"$FACTS"$'\n\nQUESTION:\n'"$user_q"
  else
    prompt_text=$'QUESTION:\n'"$user_q"
  fi

  "$LLAMA_BIN" \
    --model "$MODEL_PATH" \
    --system-prompt "$SYSTEM_PROMPT" \
    --prompt "$prompt_text" \
    --n-predict 256 \
    --temp 0.5 \
    --seed 7 \
    --color \
    $QUIET
}

# ---------- One-shot or REPL ----------
if [[ ${#ARGS[@]} -gt 0 ]]; then
  INPUT="${ARGS[*]}"
  if $QA_MODE; then
    printf "Q: %s\n\nA: " "$INPUT"
  fi
  call_llm "$INPUT"
  if $QA_MODE; then printf "\n"; fi
else
  while true; do
    printf "> "
    IFS= read -r INPUT || break
    [[ -z "$INPUT" ]] && continue
    if $QA_MODE; then
      printf "\nQ: %s\n\nA: " "$INPUT"
    fi
    call_llm "$INPUT"
    printf "\n"
  done
fi
