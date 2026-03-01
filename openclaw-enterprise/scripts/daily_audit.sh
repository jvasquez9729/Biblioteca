#!/usr/bin/env bash
# daily_audit.sh — Verificación diaria de integridad de la cadena de auditoría
# Iniciativa 5.10: verificaciones automáticas diarias obligatorias
#
# Uso: bash scripts/daily_audit.sh
#
# CRONTAB (ejecutar como aiadmin en el servidor):
#   0 6 * * * /home/aiadmin/apps/openclaw-enterprise/scripts/daily_audit.sh
# Para instalar: crontab -e

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${OPENCLAW_LOG_DIR:-/var/log/openclaw}"
LOG_FILE="$LOG_DIR/audit-$(date +%Y%m%d).log"
TIMESTAMP="$(date -Iseconds)"

# Crear directorio de logs si no existe
mkdir -p "$LOG_DIR"

echo "[$TIMESTAMP] =====================================" | tee -a "$LOG_FILE"
echo "[$TIMESTAMP] Iniciando verificación diaria de cadena de auditoría..." | tee -a "$LOG_FILE"

# Ejecutar verificador de cadena
if bash "$SCRIPT_DIR/verify_audit_chain.sh" >> "$LOG_FILE" 2>&1; then
  echo "[$(date -Iseconds)] ✅ Cadena de auditoría íntegra." | tee -a "$LOG_FILE"
  echo "[$(date -Iseconds)] Log: $LOG_FILE" | tee -a "$LOG_FILE"
  exit 0
else
  EXIT_CODE=$?
  echo "[$(date -Iseconds)] ❌ FALLO en verificación de auditoría (exit $EXIT_CODE)." | tee -a "$LOG_FILE"
  echo "[$(date -Iseconds)] Revisar log completo: $LOG_FILE" | tee -a "$LOG_FILE"

  # Extensión futura: enviar alerta vía webhook
  # SLACK_WEBHOOK="${SLACK_AUDIT_WEBHOOK:-}"
  # if [ -n "$SLACK_WEBHOOK" ]; then
  #   curl -s -X POST "$SLACK_WEBHOOK" \
  #     -H 'Content-type: application/json' \
  #     --data "{\"text\":\"❌ openclaw-enterprise: fallo en auditoría diaria. Revisar $LOG_FILE\"}"
  # fi

  exit 1
fi
