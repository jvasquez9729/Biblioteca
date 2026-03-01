#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$HOME/apps/.env.production"
FAIL=0

ok() { echo "[ok] $*"; }
warn() { echo "[warn] $*"; }
err() { echo "[err] $*"; FAIL=1; }

check_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "comando disponible: $cmd"
  else
    err "falta comando: $cmd"
  fi
}

check_file() {
  local f="$1"
  if [ -f "$f" ]; then
    ok "archivo presente: $f"
  else
    err "archivo faltante: $f"
  fi
}

echo "== Preflight OpenClaw Enterprise =="

check_cmd docker
check_cmd python3
check_cmd curl

check_file "$ROOT_DIR/control-plane/openclaw.json"
check_file "$ROOT_DIR/policies/agent_capabilities.yaml"
check_file "$ROOT_DIR/workflows/state_machine.yaml"
check_file "$ROOT_DIR/sql/001_memory_schemas.sql"
check_file "$ROOT_DIR/sql/002_audit_ledger.sql"

if [ -f "$ENV_FILE" ]; then
  ok "env de produccion encontrado: $ENV_FILE"
else
  warn "env no encontrado en $ENV_FILE"
fi

if docker ps --format '{{.Names}}' | grep -qx "ai_postgres"; then
  ok "contenedor ai_postgres en ejecucion"
  if docker exec ai_postgres psql -U aiadmin -tAc "SELECT 1" >/dev/null 2>&1; then
    ok "conexion a PostgreSQL OK"
  else
    warn "no se pudo validar conexion SQL con usuario aiadmin"
  fi
else
  warn "ai_postgres no esta corriendo"
fi

if docker ps --format '{{.Names}}' | grep -qx "openclaw_prod"; then
  MOUNT_PATH="$(docker inspect openclaw_prod --format '{{range .Mounts}}{{if eq .Destination "/home/node/.openclaw"}}{{.Source}}{{end}}{{end}}')"
  if [ -n "$MOUNT_PATH" ]; then
    ok "mount OpenClaw detectado: $MOUNT_PATH"
  else
    warn "no se detecto mount /home/node/.openclaw en openclaw_prod"
  fi
else
  warn "openclaw_prod no esta corriendo"
fi

if [ -f "$ENV_FILE" ]; then
  OLLAMA_URL="$(grep '^OLLAMA_BASE_URL=' "$ENV_FILE" | head -1 | cut -d= -f2- || true)"
  if [ -n "$OLLAMA_URL" ]; then
    if curl -fsS --max-time 3 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
      ok "OLLAMA_BASE_URL responde: $OLLAMA_URL"
    else
      warn "OLLAMA_BASE_URL no responde: $OLLAMA_URL"
    fi
  else
    warn "OLLAMA_BASE_URL no definido en $ENV_FILE"
  fi
fi

if [ "$FAIL" -ne 0 ]; then
  echo "Preflight: FAILED"
  exit 1
fi

echo "Preflight: OK"

