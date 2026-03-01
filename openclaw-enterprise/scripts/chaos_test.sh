#!/usr/bin/env bash
set -euo pipefail

MODE="dry-run"
if [ "${1:-}" = "--execute" ]; then
  MODE="execute"
fi
if [ "${1:-}" = "--dry-run" ]; then
  MODE="dry-run"
fi

run() {
  if [ "$MODE" = "execute" ]; then
    echo "[run] $*"
    eval "$@"
  else
    echo "[dry-run] $*"
  fi
}

echo "== Chaos Test ($MODE) =="

if ! docker ps --format '{{.Names}}' | grep -qx "ai_postgres"; then
  echo "[err] ai_postgres no esta corriendo"
  exit 1
fi

echo "Escenario 1: caida temporal de DB (2 min) y recuperacion"
run "docker stop ai_postgres"
run "sleep 120"
run "docker start ai_postgres"
run "docker inspect --format '{{.State.Status}}' ai_postgres"

echo "Escenario 2: validacion de conectividad Ollama"
ENV_FILE="$HOME/apps/.env.production"
if [ -f "$ENV_FILE" ]; then
  OLLAMA_URL="$(grep '^OLLAMA_BASE_URL=' "$ENV_FILE" | head -1 | cut -d= -f2- || true)"
  if [ -n "$OLLAMA_URL" ]; then
    run "curl -fsS --max-time 3 $OLLAMA_URL/api/tags >/dev/null"
  else
    echo "[warn] OLLAMA_BASE_URL no definido en $ENV_FILE"
  fi
else
  echo "[warn] no existe $ENV_FILE"
fi

echo "Chaos test completado ($MODE)."
if [ "$MODE" = "dry-run" ]; then
  echo "Para ejecutar realmente: bash scripts/chaos_test.sh --execute"
fi

