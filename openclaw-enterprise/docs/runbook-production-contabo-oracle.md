# Runbook de Producción (Contabo + Oracle Querétaro)

Este runbook es para desplegar tu sistema multi‑agente en 2 nodos:
- **Contabo**: control plane (OpenClaw, API, n8n, observabilidad)
- **Oracle (Querétaro)**: inferencia pesada/modelos locales (Ollama/DeepSeek)

## 0) Prerrequisitos
- Ubuntu 22.04 en ambos servidores.
- Usuario con sudo (no root) en ambos.
- Dominio con DNS gestionable.
- Repositorio clonado en ambos nodos.

## 1) Topología recomendada
- Red privada WireGuard entre Contabo y Oracle.
- Puertos públicos solo para:
  - reverse proxy (80/443)
  - endpoint API público (detrás de WAF)
- PostgreSQL y servicios internos solo por red privada.

## 2) Bootstrap base en ambos nodos
```bash
sudo apt update && sudo apt -y upgrade
sudo apt -y install git curl jq ca-certificates gnupg ufw

# Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```

## 3) Variables de entorno mínimas (ejemplo)
Crear archivo `.env.production` (NO commitear):
```bash
OPENCLAW_DB_URL=postgresql://USER:PASS@DB_HOST:5432/DB_NAME
OPENAI_API_KEY=***
ANTHROPIC_API_KEY=***
KIMI_API_KEY=***
DEEPSEEK_API_KEY=***
OLLAMA_BASE_URL=http://oracle-private-ip:11434
N8N_BASE_URL=https://n8n-prod.tudominio.com
N8N_API_KEY=***
```

## 4) Secret Manager (recomendación operativa)
- Fase 1 (rápida): 1Password Secrets Automation.
- Fase 2 (enterprise): Vault.

Regla: ningún secreto hardcodeado en código o compose.

## 5) Base de datos y memoria separada
En la instancia PostgreSQL objetivo:
```bash
psql -h DB_HOST -U DB_USER -d DB_NAME -f openclaw-enterprise/sql/001_memory_schemas.sql
psql -h DB_HOST -U DB_USER -d DB_NAME -f openclaw-enterprise/sql/002_audit_ledger.sql
```

Validar:
```bash
psql -h DB_HOST -U DB_USER -d DB_NAME -c "select schema_name from information_schema.schemata where schema_name like 'mem_%' order by 1;"
psql -h DB_HOST -U DB_USER -d DB_NAME -c "\dt mem_audit.*"
```

## 6) Política de backups (operativa)
- `mem_audit`: RPO 5m, RTO 30m
- `mem_finance`: RPO 15m, RTO 1h
- `mem_tech`: RPO 1h, RTO 2h

Restore test semanal (documentado en acta).

## 7) Despliegue de control plane en Contabo
```bash
cd /ruta/Biblioteca
export OPENCLAW_DB_URL="postgresql://USER:PASS@DB_HOST:5432/DB_NAME"
bash openclaw-enterprise/scripts/bootstrap.sh
bash openclaw-enterprise/scripts/run_enterprise_stack.sh
```

## 8) Nodo Oracle para inferencia pesada
- Instalar Ollama y modelos necesarios.
- Exponer Ollama solo por red privada WireGuard.
- Probar conectividad desde Contabo al `OLLAMA_BASE_URL`.

## 9) n8n producción
- Separar entornos: dev/stg/prod.
- Activar auth fuerte (OIDC/API key rotada).
- Workflows financieros críticos requieren HITL.

## 10) CI/CD mínimo obligatorio
Gates:
- lint
- tests
- SAST
- dependency scan
- secret scan
- policy gate

Bloquear auto-merge del mismo agente autor.

## 11) Observabilidad
- Logs JSON con `execution_id`.
- Trazas OpenTelemetry.
- Métricas de costo/token/latencia.
- Alertas a Slack + Email:
  - p95 latencia > 2.5s por 5m
  - error rate > 2% por 10m
  - costo diario > 120% promedio semanal
  - fallo en cadena de auditoría (crítico)

## 12) Ventanas de cambio
- Lunes-Jueves: 09:00–14:00
- Viernes: solo hotfix
- Fines de semana: solo incidentes P1

## 13) Go/No-Go checklist final
- [ ] Secret manager activo
- [ ] DB separada + backups + restore test
- [ ] HITL validado (`/approve`) para acciones críticas
- [ ] n8n prod aislado + política de workflows críticos
- [ ] CI/CD con gates bloqueantes
- [ ] Observabilidad y alertas activas
- [ ] Runbook de rollback probado

---

## 14) Hardening de red en Contabo (hallazgos pendientes)

> Ejecutar los siguientes pasos con SSH desde tu máquina local.
> Servidor: `aiadmin@217.216.89.61`

### 14.1 Verificar exposición actual de ai_postgres y ai_postgres_pgvector

```bash
ssh aiadmin@217.216.89.61 "docker ps --format 'table {{.Names}}\t{{.Ports}}'"
```

Si ves `0.0.0.0:5432->5432/tcp` o `0.0.0.0:5433->5433/tcp`, los puertos están expuestos a toda la red. Continúa con el fix.

### 14.2 Encontrar el docker-compose que define ai_postgres en Contabo

```bash
ssh aiadmin@217.216.89.61 "grep -rl 'ai_postgres\|container_name' ~/apps/ /opt/ /home/ 2>/dev/null | grep -i compose | head -10"
```

Edita ese archivo y cambia los `ports:` de los contenedores afectados:

```yaml
# ANTES (inseguro):
ports:
  - "5432:5432"
  - "5433:5433"

# DESPUÉS (seguro — solo loopback):
ports:
  - "127.0.0.1:5432:5432"
  - "127.0.0.1:5433:5433"
```

Luego recrea los contenedores:

```bash
ssh aiadmin@217.216.89.61 "cd ~/apps && docker compose up -d --force-recreate ai_postgres ai_postgres_pgvector"
```

Verificar que ya no están en 0.0.0.0:

```bash
ssh aiadmin@217.216.89.61 "docker inspect ai_postgres | grep -A2 'HostIp'"
# Debe mostrar: "HostIp": "127.0.0.1"
```

### 14.3 Limpiar symlinks dangling bajo /oc/skills/

```bash
# Listar todos los symlinks rotos bajo /oc/skills/
ssh aiadmin@217.216.89.61 "find /oc/skills/ -maxdepth 2 -type l ! -e 2>/dev/null"

# Ver cuáles apuntan a destinos inexistentes
ssh aiadmin@217.216.89.61 "find /oc/skills/ -maxdepth 2 -xtype l 2>/dev/null"

# Eliminar symlinks dangling (revisar la lista primero antes de borrar)
ssh aiadmin@217.216.89.61 "find /oc/skills/ -maxdepth 2 -xtype l -delete 2>/dev/null && echo 'Symlinks dangling eliminados'"
```

### 14.4 Crear /oc/skills.disabled/ para control de skills en runtime

El directorio `/oc/skills.disabled/` permite deshabilitar skills individualmente en el runtime de OpenClaw sin desinstalarlos. Un skill cuyo nombre aparece en este directorio es ignorado por el runtime.

```bash
# Crear el directorio si no existe
ssh aiadmin@217.216.89.61 "sudo mkdir -p /oc/skills.disabled && sudo chown aiadmin:aiadmin /oc/skills.disabled && echo 'Directorio creado'"

# Para deshabilitar un skill específico (ejemplo: mcporter):
ssh aiadmin@217.216.89.61 "touch /oc/skills.disabled/mcporter && echo 'mcporter deshabilitado'"

# Para listar skills deshabilitados:
ssh aiadmin@217.216.89.61 "ls /oc/skills.disabled/"

# Para rehabilitar un skill:
ssh aiadmin@217.216.89.61 "rm /oc/skills.disabled/mcporter && echo 'mcporter rehabilitado'"
```

### 14.5 Verificación final de red en Contabo

```bash
# Ningún puerto PostgreSQL debe aparecer en 0.0.0.0
ssh aiadmin@217.216.89.61 "ss -tlnp | grep '5432\|5433'"
# Resultado esperado: solo 127.0.0.1:5432 y 127.0.0.1:5433

# Confirmar que el runtime sigue accesible
ssh aiadmin@217.216.89.61 "curl -fsS http://127.0.0.1:8000/health || echo 'Sin endpoint /health'"

# Confirmar que openclaw_prod responde
ssh aiadmin@217.216.89.61 "curl -fsS http://127.0.0.1:3000 -o /dev/null -w '%{http_code}'"
```
