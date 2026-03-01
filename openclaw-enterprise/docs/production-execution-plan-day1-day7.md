# Plan Operativo Produccion (Dia 1 a Dia 7) — v2

Este plan ejecuta el paso de plantilla a produccion para OpenClaw Enterprise con 2 nodos:
- **Contabo** (217.216.89.61): control plane, OpenClaw Gateway, LangGraph runtime, n8n, PostgreSQL.
- **Oracle Queretaro**: inferencia pesada (Ollama + modelos locales).

## Arquitectura de orquestacion

```
Usuario (Telegram / Web)
       |
OpenClaw Gateway  <-- gestiona dispositivos, WebSocket, canales
       |
LangGraph Runtime  <-- implementa la maquina de 7 estados
       |
Agentes especializados  <-- cada nodo del grafo = un agente con su modelo
       |
PostgreSQL (mem_finance / mem_tech / mem_audit)
```

**LangGraph** es el runtime declarado en `control-plane/openclaw.json` (`"recommended_runtime": "langgraph"`).
Implementa el workflow de 7 estados como un `StateGraph` de Python.
**LangChain** actua como capa de utilidades (wrappers de modelos, prompts, retrievers).
**OpenClaw** maneja el gateway de entrada/salida (no la orquestacion interna).

## Supuestos del estado actual

- Contabo **ya tiene** Docker, OpenClaw Gateway corriendo, PostgreSQL (ai_postgres), Nginx con SSL.
- Oracle **ya tiene** Ollama con modelos instalados.
- Repo local en `C:\OpenClaw\openclaw-enterprise`.
- Acceso SSH desde WSL con clave ed25519 a ambos nodos.

---

## Dia 1 — Auditoria del estado actual + validacion de artefactos

### 1.1 Validar artefactos locales (PowerShell / WSL)

```powershell
wsl -e bash -lc "cd /mnt/c/OpenClaw/openclaw-enterprise && python -m json.tool control-plane/openclaw.json >/dev/null && echo openclaw.json_OK"
wsl -e bash -lc "cd /mnt/c/OpenClaw/openclaw-enterprise && grep -n 'recommended_runtime\|human_in_the_loop_required\|approval_command' control-plane/openclaw.json"
wsl -e bash -lc "cd /mnt/c/OpenClaw/openclaw-enterprise && grep -n 'requires_human_approval_for\|allowed_tools\|denied_tools' policies/agent_capabilities.yaml | head -30"
wsl -e bash -lc "cd /mnt/c/OpenClaw/openclaw-enterprise && grep -n 'workflow_name\|initial_state\|HITL_WAIT\|irreversible_actions' workflows/state_machine.yaml"
```

Resultado esperado: todos los archivos validos, HITL presente, `recommended_runtime: langgraph`.

### 1.2 Auditar estado de Contabo (SSH)

```bash
ssh aiadmin@217.216.89.61 "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
ssh aiadmin@217.216.89.61 "docker network ls"
ssh aiadmin@217.216.89.61 "df -h / /var/lib/docker"
ssh aiadmin@217.216.89.61 "free -h"
```

Documentar: que contenedores corren, cuanto disco y RAM libre quedan.

### 1.3 Auditar estado de Oracle (SSH)

```bash
ssh <user>@<oracle_public_ip> "ollama list"
ssh <user>@<oracle_public_ip> "docker ps --format 'table {{.Names}}\t{{.Status}}'"
ssh <user>@<oracle_public_ip> "free -h && df -h /"
```

Documentar: modelos disponibles en Ollama (estos son los que se usaran como alternativa local).

Resultado esperado: inventario completo de ambos nodos antes de tocar cualquier cosa.

---

## Dia 2 — WireGuard: red privada Contabo <-> Oracle

La red privada es el backbone de seguridad. Ollama en Oracle NUNCA debe estar expuesto a internet.

### 2.1 Instalar WireGuard en Contabo

```bash
ssh aiadmin@217.216.89.61

sudo apt install -y wireguard

# Abrir puerto de WireGuard si UFW esta activo
sudo ufw allow 51820/udp

# Generar claves
wg genkey | sudo tee /etc/wireguard/contabo_private.key | wg pubkey | sudo tee /etc/wireguard/contabo_public.key
sudo chmod 600 /etc/wireguard/contabo_private.key

# Leer clave publica (guardarla, se necesita en Oracle)
sudo cat /etc/wireguard/contabo_public.key
```

### 2.2 Instalar WireGuard en Oracle

```bash
ssh <user>@<oracle_public_ip>

sudo apt install -y wireguard

# Abrir puerto de WireGuard si UFW esta activo
sudo ufw allow 51820/udp

wg genkey | sudo tee /etc/wireguard/oracle_private.key | wg pubkey | sudo tee /etc/wireguard/oracle_public.key
sudo chmod 600 /etc/wireguard/oracle_private.key

# Leer clave publica (guardarla, se necesita en Contabo)
sudo cat /etc/wireguard/oracle_public.key
```

### 2.3 Configurar interfaz WireGuard en Contabo

```bash
# En Contabo (reemplaza ORACLE_PUBLIC_KEY con la clave del paso 2.2)
sudo tee /etc/wireguard/wg0.conf << EOF
[Interface]
Address = 10.10.0.1/24
ListenPort = 51820
PrivateKey = $(sudo cat /etc/wireguard/contabo_private.key)

[Peer]
PublicKey = ORACLE_PUBLIC_KEY
AllowedIPs = 10.10.0.2/32
EOF

sudo chmod 600 /etc/wireguard/wg0.conf
sudo systemctl enable --now wg-quick@wg0
sudo wg show
```

### 2.4 Configurar interfaz WireGuard en Oracle

```bash
# En Oracle (reemplaza CONTABO_PUBLIC_KEY y 217.216.89.61 con datos reales)
sudo tee /etc/wireguard/wg0.conf << EOF
[Interface]
Address = 10.10.0.2/24
PrivateKey = $(sudo cat /etc/wireguard/oracle_private.key)

[Peer]
PublicKey = CONTABO_PUBLIC_KEY
Endpoint = 217.216.89.61:51820
AllowedIPs = 10.10.0.1/32
PersistentKeepalive = 25
EOF

sudo chmod 600 /etc/wireguard/wg0.conf
sudo systemctl enable --now wg-quick@wg0
```

### 2.5 Validar conectividad privada

```bash
# Desde Contabo hacia Oracle
ping -c 4 10.10.0.2

# Verificar que Ollama responde por IP privada
curl http://10.10.0.2:11434/api/tags

# Desde Oracle hacia Contabo
ping -c 4 10.10.0.1
```

### 2.6 Exponer Ollama solo por red privada en Oracle

```bash
# En Oracle: override no interactivo (apto para SSH/script)
sudo mkdir -p /etc/systemd/system/ollama.service.d/
sudo tee /etc/systemd/system/ollama.service.d/override.conf << 'EOF'
[Service]
Environment="OLLAMA_HOST=10.10.0.2:11434"
EOF
sudo systemctl daemon-reload
sudo systemctl restart ollama

# Verificar que NO responde en interfaz publica
curl --connect-timeout 3 http://<oracle_public_ip>:11434/api/tags || echo "OK: no accesible publicamente"

# Verificar que SI responde por privada (desde Contabo)
ssh aiadmin@217.216.89.61 "curl http://10.10.0.2:11434/api/tags"
```

Resultado esperado: ping entre nodos OK, Ollama accesible solo por `10.10.0.2:11434`.

### 2.7 Clonar repo en Contabo (requerido antes de Dia 3.3)

```bash
ssh aiadmin@217.216.89.61
mkdir -p ~/apps

# Opcion A: desde git
# git clone <repo_url> ~/apps/openclaw-enterprise

# Opcion B: copiar desde tu maquina local via scp
# scp -r /mnt/c/OpenClaw/openclaw-enterprise aiadmin@217.216.89.61:~/apps/
```

---

## Dia 3 — Base de datos y esquemas de memoria (Contabo)

### 3.1 Generar password de produccion (NO usar openclaw_dev)

```bash
ssh aiadmin@217.216.89.61

# Generar password seguro
DB_PASS=$(openssl rand -hex 24)
echo "DB_PASS=$DB_PASS"  # Guardar en gestor de passwords (1Password, Bitwarden, etc.)
```

### 3.2 Crear base de datos de produccion para el enterprise stack

El PostgreSQL de `ai_postgres` ya existe en Contabo. Crear una base dedicada:

```bash
# Crear usuario y base de datos enterprise
docker exec -it ai_postgres psql -U aiadmin -c "CREATE USER enterprise_owner WITH PASSWORD '$DB_PASS';"
docker exec -it ai_postgres psql -U aiadmin -c "CREATE DATABASE openclaw_enterprise OWNER enterprise_owner;"
docker exec -it ai_postgres psql -U aiadmin -c "GRANT ALL PRIVILEGES ON DATABASE openclaw_enterprise TO enterprise_owner;"

# Precheck de pgvector en el contenedor existente
docker exec -it ai_postgres psql -U aiadmin -c "SELECT name, default_version, installed_version FROM pg_available_extensions WHERE name = 'vector';"

# Instalar extension pgvector (requerida para memoria vectorial)
docker exec -it ai_postgres psql -U aiadmin -d openclaw_enterprise -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

Si `vector` no aparece en `pg_available_extensions`, ese contenedor no incluye pgvector.
Accion: migrar `ai_postgres` a imagen compatible (`pgvector/pgvector:pg16`) antes de continuar.

### 3.3 Aplicar esquemas de memoria separada

```bash
# Copiar SQLs al contenedor
docker cp ~/apps/openclaw-enterprise/sql/001_memory_schemas.sql ai_postgres:/tmp/
docker cp ~/apps/openclaw-enterprise/sql/002_audit_ledger.sql ai_postgres:/tmp/

# Aplicar (con el usuario enterprise_owner)
docker exec -it ai_postgres psql -U enterprise_owner -d openclaw_enterprise -f /tmp/001_memory_schemas.sql
docker exec -it ai_postgres psql -U enterprise_owner -d openclaw_enterprise -f /tmp/002_audit_ledger.sql
```

### 3.4 Verificar esquemas

```bash
docker exec -it ai_postgres psql -U enterprise_owner -d openclaw_enterprise \
  -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE 'mem_%' ORDER BY 1;"

docker exec -it ai_postgres psql -U enterprise_owner -d openclaw_enterprise \
  -c "\dt mem_audit.*"

docker exec -it ai_postgres psql -U enterprise_owner -d openclaw_enterprise \
  -c "\dt mem_finance.*"
```

Resultado esperado: `mem_finance`, `mem_tech`, `mem_audit` presentes con sus tablas.

### 3.5 Crear archivo de variables de produccion

```bash
mkdir -p ~/apps
cat > ~/apps/.env.production << EOF
# Base de datos enterprise
OPENCLAW_DB_URL=postgresql://enterprise_owner:${DB_PASS}@127.0.0.1:5432/openclaw_enterprise

# APIs de modelos (completar con claves reales)
ANTHROPIC_API_KEY=REPLACE_ME
OPENAI_API_KEY=REPLACE_ME

# Ollama por red privada WireGuard
OLLAMA_BASE_URL=http://10.10.0.2:11434

# n8n (completar cuando se instale en Dia 6)
N8N_BASE_URL=https://n8n.<tu_dominio>
N8N_API_KEY=REPLACE_ME
N8N_RUNTIME_EVENTS_WEBHOOK=https://n8n.<tu_dominio>/webhook/runtime-events

# Alertas
TELEGRAM_TOKEN=REPLACE_ME
TELEGRAM_CHAT_ID=REPLACE_ME
EOF

chmod 600 ~/apps/.env.production
```

### 3.6 Configurar .pgpass para evitar password en crontab

```bash
echo "127.0.0.1:5432:openclaw_enterprise:enterprise_owner:${DB_PASS}" >> ~/.pgpass
chmod 600 ~/.pgpass
```

---

## Dia 4 — LangGraph runtime: implementar la maquina de estados

LangGraph es el runtime declarado en `control-plane/openclaw.json`. Implementa el workflow de
7 estados como un grafo de Python donde cada nodo es un agente especializado.

Orden de ejecucion de este dia: `4.1 -> 4.2 -> 4.3 -> 4.4`.

### 4.1 Verificar repo en Contabo (ya debio quedar listo en Dia 2.7)

```bash
ssh aiadmin@217.216.89.61
mkdir -p ~/apps
test -d ~/apps/openclaw-enterprise && echo "repo_OK" || echo "repo_missing"
```

### 4.2 Instalar Python y dependencias en Contabo

```bash
ssh aiadmin@217.216.89.61

sudo apt install -y python3 python3-pip python3-venv

mkdir -p ~/apps/openclaw-enterprise/runtime
cd ~/apps/openclaw-enterprise/runtime

python3 -m venv .venv
source .venv/bin/activate

pip install \
  langgraph>=0.2 \
  langchain>=0.3 \
  langchain-anthropic \
  langchain-openai \
  langchain-community \
  psycopg2-binary \
  python-dotenv \
  pydantic>=2
```

### 4.3 Crear el StateGraph principal (langgraph_runtime.py)

```bash
cat > ~/apps/openclaw-enterprise/runtime/langgraph_runtime.py << 'PYEOF'
"""
OpenClaw Enterprise - LangGraph Runtime
Implementa el workflow de 7 estados definido en workflows/state_machine.yaml
"""
import os
import hashlib
import uuid
from typing import TypedDict
from dotenv import load_dotenv
from langgraph.graph import StateGraph, END
from langgraph.checkpoint.memory import MemorySaver
from langchain_anthropic import ChatAnthropic
from langchain_openai import ChatOpenAI
import psycopg2

load_dotenv(os.path.join(os.path.dirname(__file__), '..', '..', '.env.production'))


# --- Estado del grafo ---

class EnterpriseState(TypedDict):
    execution_id: str
    task: str
    state: str
    agent_id: str
    model_id: str
    decomposed_tasks: list
    execution_results: list
    audit_findings: list
    consolidated_report: str
    exec_summary: str
    risk_flags: list
    approved: bool
    error: str


# --- Modelos por agente (segun agent_capabilities.yaml) ---

def get_model(model_id: str):
    models = {
        "claude-opus-4-6":   ChatAnthropic(model="claude-opus-4-6"),
        "claude-sonnet-4-5": ChatAnthropic(model="claude-sonnet-4-5"),
        "gpt-4o":            ChatOpenAI(model="gpt-4o"),
    }
    return models.get(model_id, models["claude-sonnet-4-5"])


def compute_hash(content: str) -> str:
    return hashlib.sha256(content.encode()).hexdigest()


def append_ledger_event(
    execution_id: str,
    agent_id: str,
    model_id: str,
    state: str,
    input_payload: str,
    output_payload: str,
    status: str = "approved",
    token_in: int = 0,
    token_out: int = 0,
    cost_usd: float = 0.0,
) -> None:
    db_url = os.getenv("OPENCLAW_DB_URL")
    if not db_url:
        return

    input_hash = compute_hash(input_payload or "")
    output_hash = compute_hash(output_payload or "")
    with psycopg2.connect(db_url) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT event_hash
                FROM mem_audit.execution_ledger
                WHERE execution_id = %s
                ORDER BY event_id DESC
                LIMIT 1
                """,
                (execution_id,),
            )
            row = cur.fetchone()
            prev_event_hash = row[0] if row else None
            prev_for_hash = prev_event_hash or ""
            event_hash = compute_hash(
                f"{execution_id}|{agent_id}|{state}|{output_hash}|{prev_for_hash}"
            )

            cur.execute(
                """
                INSERT INTO mem_audit.execution_ledger
                (execution_id, agent_id, model_id, state, input_hash, output_hash,
                 prev_event_hash, event_hash, token_in, token_out, cost_usd, status)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    execution_id,
                    agent_id,
                    model_id,
                    state,
                    input_hash,
                    output_hash,
                    prev_event_hash,
                    event_hash,
                    token_in,
                    token_out,
                    cost_usd,
                    status,
                ),
            )


# --- Nodos del grafo (uno por estado del workflow) ---

def validation_node(state: EnterpriseState) -> EnterpriseState:
    model = get_model("claude-opus-4-6")
    response = model.invoke(
        f"Valida que esta tarea es coherente y segura para procesar:\n{state['task']}\n"
        "Responde: VALID o INVALID con razon breve."
    )
    content = response.content if hasattr(response, 'content') else str(response)
    valid = "INVALID" not in content.upper()
    return {
        **state,
        "state": "DECOMPOSITION" if valid else "REJECTED",
        "agent_id": "chief_of_staff",
        "model_id": "claude-opus-4-6",
        "risk_flags": [] if valid else [f"Validation failed: {content}"],
        "error": "" if valid else content,
    }


def decomposition_node(state: EnterpriseState) -> EnterpriseState:
    model = get_model("claude-opus-4-6")
    response = model.invoke(
        f"Descompone esta tarea en micro-tareas auditables (max 5):\n{state['task']}\n"
        "Formato: lista numerada, una tarea por linea."
    )
    content = response.content if hasattr(response, 'content') else str(response)
    tasks = [line.strip() for line in content.split('\n') if line.strip()]
    return {
        **state,
        "state": "EXECUTION",
        "agent_id": "chief_of_staff",
        "decomposed_tasks": tasks,
    }


def execution_node(state: EnterpriseState) -> EnterpriseState:
    model = get_model("gpt-4o")
    results = []
    for subtask in state.get("decomposed_tasks", []):
        response = model.invoke(f"Ejecuta esta micro-tarea:\n{subtask}")
        content = response.content if hasattr(response, 'content') else str(response)
        results.append({"task": subtask, "result": content})
    return {
        **state,
        "state": "AUDIT",
        "agent_id": "developer",
        "model_id": "gpt-4o",
        "execution_results": results,
    }


def audit_node(state: EnterpriseState) -> EnterpriseState:
    model = get_model("claude-sonnet-4-5")
    results_text = "\n".join([r["result"] for r in state.get("execution_results", [])])
    response = model.invoke(
        f"Audita estos resultados. Identifica riesgos de seguridad (HIGH/CRITICAL bloquean):\n{results_text}"
    )
    content = response.content if hasattr(response, 'content') else str(response)
    has_critical = any(kw in content.upper() for kw in ["HIGH", "CRITICAL"])
    risk_flags = state.get("risk_flags", [])
    if has_critical:
        risk_flags.append(f"Security gate triggered: {content[:200]}")
    return {
        **state,
        "state": "CONSOLIDATION" if not has_critical else "REJECTED",
        "agent_id": "security_agent",
        "model_id": "claude-sonnet-4-5",
        "audit_findings": [content],
        "risk_flags": risk_flags,
    }


def consolidation_node(state: EnterpriseState) -> EnterpriseState:
    model = get_model("claude-opus-4-6")
    data = {
        "tasks": state.get("decomposed_tasks", []),
        "results": state.get("execution_results", []),
        "audit": state.get("audit_findings", []),
    }
    response = model.invoke(f"Consolida los resultados en un reporte unificado:\n{data}")
    content = response.content if hasattr(response, 'content') else str(response)
    return {
        **state,
        "state": "EXEC_SUMMARY",
        "agent_id": "chief_of_staff",
        "consolidated_report": content,
    }


def exec_summary_node(state: EnterpriseState) -> EnterpriseState:
    model = get_model("claude-opus-4-6")
    response = model.invoke(
        f"Genera resumen ejecutivo con: objetivo, riesgos, costo estimado, decision recomendada.\n"
        f"Reporte:\n{state.get('consolidated_report', '')}"
    )
    content = response.content if hasattr(response, 'content') else str(response)
    return {
        **state,
        "state": "HITL_WAIT",
        "agent_id": "chief_of_staff",
        "exec_summary": content,
    }


def hitl_wait_node(state: EnterpriseState) -> EnterpriseState:
    # En produccion: bloquea hasta recibir /approve por OpenClaw/Telegram
    # Por ahora: requiere aprobacion explicita en el estado
    if state.get("approved", False):
        return {**state, "state": "DONE"}
    return {
        **state,
        "state": "HITL_WAIT",
        "risk_flags": state.get("risk_flags", []) + ["Esperando aprobacion humana (/approve)"],
    }


# --- Routing ---

def route_after_validation(state: EnterpriseState) -> str:
    return "decomposition" if state["state"] == "DECOMPOSITION" else END

def route_after_audit(state: EnterpriseState) -> str:
    return "consolidation" if state["state"] == "CONSOLIDATION" else END

# --- Construccion del grafo ---

def build_enterprise_graph():
    graph = StateGraph(EnterpriseState)

    graph.add_node("validation",    validation_node)
    graph.add_node("decomposition", decomposition_node)
    graph.add_node("execution",     execution_node)
    graph.add_node("audit",         audit_node)
    graph.add_node("consolidation", consolidation_node)
    graph.add_node("exec_summary",  exec_summary_node)
    graph.add_node("hitl_wait",     hitl_wait_node)

    graph.set_entry_point("validation")

    graph.add_conditional_edges("validation", route_after_validation,
                                 {"decomposition": "decomposition", END: END})
    graph.add_edge("decomposition", "execution")
    graph.add_conditional_edges("audit", route_after_audit,
                                 {"consolidation": "consolidation", END: END})
    graph.add_edge("execution",     "audit")
    graph.add_edge("consolidation", "exec_summary")
    graph.add_edge("exec_summary",  "hitl_wait")
    graph.add_edge("hitl_wait", END)

    # HITL real: pausar antes de ejecutar hitl_wait y reanudar con estado aprobado.
    return graph.compile(checkpointer=MemorySaver(), interrupt_before=["hitl_wait"])


# --- Punto de entrada ---

if __name__ == "__main__":
    app = build_enterprise_graph()
    cfg = {"configurable": {"thread_id": f"thread-{uuid.uuid4().hex[:8]}"}}
    initial_state: EnterpriseState = {
        "execution_id": f"exec-{uuid.uuid4().hex[:8]}",
        "task": "Analizar estados financieros Q1 y generar reporte ejecutivo",
        "state": "VALIDATION",
        "agent_id": "chief_of_staff",
        "model_id": "claude-opus-4-6",
        "decomposed_tasks": [],
        "execution_results": [],
        "audit_findings": [],
        "consolidated_report": "",
        "exec_summary": "",
        "risk_flags": [],
        "approved": False,
        "error": "",
    }
    # Fase 1: corre hasta pausa HITL (interrupt_before)
    partial = app.invoke(initial_state, config=cfg)
    print("=== PAUSA HITL ===")
    print("Resumen previo:", partial.get("exec_summary", ""))

    # Fase 2: simula /approve y reanuda
    app.update_state(cfg, {"approved": True})
    result = app.invoke(None, config=cfg)
    append_ledger_event(
        execution_id=result.get("execution_id", initial_state["execution_id"]),
        agent_id=result.get("agent_id", "chief_of_staff"),
        model_id=result.get("model_id", "unknown"),
        state=result.get("state", "UNKNOWN"),
        input_payload=initial_state.get("task", ""),
        output_payload=result.get("exec_summary", "") or str(result),
        status="approved" if result.get("state") in {"HITL_WAIT", "DONE"} else "rejected",
    )
    print("=== RESUMEN EJECUTIVO ===")
    print(result.get("exec_summary", ""))
    print("=== RISK FLAGS ===")
    for flag in result.get("risk_flags", []):
        print(f"  - {flag}")
    print(f"=== ESTADO FINAL: {result.get('state')} ===")
PYEOF
```

### 4.4 Prueba del runtime LangGraph (requiere API keys en .env.production)

```bash
cd ~/apps/openclaw-enterprise/runtime
source .venv/bin/activate
set -a && source ../../.env.production && set +a

# Validar que importa sin errores
python -c "from langgraph_runtime import build_enterprise_graph; g = build_enterprise_graph(); print('LangGraph OK')"

# Prueba completa (demuestra pausa HITL y reanudacion con aprobacion)
python langgraph_runtime.py
```

Resultado esperado:
- `LangGraph OK` sin errores de importacion.
- El script pausa en HITL y luego finaliza en `DONE`.

---

## Dia 5 — Control plane: agentes en OpenClaw + pruebas funcionales

### 5.1 Cargar prompts de agentes en OpenClaw

```bash
ssh aiadmin@217.216.89.61

# Verificar comandos soportados por el CLI real
docker exec openclaw_prod openclaw --help
docker exec openclaw_prod sh -lc "openclaw agents --help || true"

# Solo si existe agents create, usarlo.
if docker exec openclaw_prod sh -lc "openclaw agents create --help >/dev/null 2>&1"; then
  docker exec openclaw_prod openclaw agents list
  docker exec openclaw_prod openclaw agents create \
    --name chief_of_staff \
    --model claude-opus-4-6 \
    --system-prompt "$(cat ~/apps/openclaw-enterprise/prompts/chief_of_staff.md)"
else
  echo "openclaw agents create no disponible en esta version."
  echo "Fallback: configurar agentes por openclaw.json + prompts en volumen."
fi
```

### 5.2 Enlazar LangGraph como runtime de OpenClaw

```bash
# Actualizar openclaw.json del servidor con la ruta del runtime
OPENCLAW_DATA=$(docker inspect openclaw_prod --format '{{range .Mounts}}{{if eq .Destination "/home/node/.openclaw"}}{{.Source}}{{end}}{{end}}')

if [ -z "$OPENCLAW_DATA" ]; then
  echo "Error: no se encontro el mount /home/node/.openclaw en openclaw_prod"
  exit 1
fi

# Copiar config enterprise al volumen de OpenClaw
sudo cp ~/apps/openclaw-enterprise/control-plane/openclaw.json $OPENCLAW_DATA/openclaw.json

# Reiniciar para cargar config
docker restart openclaw_prod
sleep 5
docker logs openclaw_prod --tail 20
```

### 5.3 Prueba de escritura en ledger de auditoria

```bash
docker exec -it ai_postgres psql -U enterprise_owner -d openclaw_enterprise -c "
WITH last_event AS (
  SELECT event_hash
  FROM mem_audit.execution_ledger
  WHERE execution_id = 'exec-smoke-001'
  ORDER BY event_id DESC
  LIMIT 1
),
payload AS (
  SELECT
    'exec-smoke-001'::text AS execution_id,
    'chief_of_staff'::text AS agent_id,
    'claude-opus-4-6'::text AS model_id,
    'VALIDATION'::text AS state,
    md5('input_test')::text AS input_hash,
    md5('output_test')::text AS output_hash,
    (SELECT event_hash FROM last_event) AS prev_event_hash
)
INSERT INTO mem_audit.execution_ledger
  (execution_id, agent_id, model_id, state, input_hash, output_hash,
   prev_event_hash, event_hash, token_in, token_out, cost_usd, status)
SELECT
  p.execution_id,
  p.agent_id,
  p.model_id,
  p.state,
  p.input_hash,
  p.output_hash,
  p.prev_event_hash,
  md5(
    p.execution_id || '|' || p.agent_id || '|' || p.state || '|' ||
    p.output_hash || '|' || COALESCE(p.prev_event_hash, '')
  ),
  100,
  200,
  0.10,
  'approved'
FROM payload p;"

docker exec -it ai_postgres psql -U enterprise_owner -d openclaw_enterprise -c "
SELECT execution_id, agent_id, state, status, created_at
FROM mem_audit.execution_ledger
ORDER BY event_id DESC LIMIT 5;"
```

Resultado esperado: registro insertado y consultado correctamente.

---

## Dia 6 — n8n + backups seguros + observabilidad

### 6.1 Instalar n8n en Contabo

```bash
ssh aiadmin@217.216.89.61

mkdir -p /opt/ai-system/n8n
cat > /opt/ai-system/n8n/docker-compose.yml << 'EOF'
version: '3.9'
services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n_prod
    restart: unless-stopped
    ports:
      - "127.0.0.1:5678:5678"
    environment:
      - N8N_HOST=n8n.<tu_dominio>
      - N8N_PROTOCOL=https
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=REPLACE_WITH_STRONG_PASSWORD
      - EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true
      - N8N_LOG_LEVEL=info
    volumes:
      - n8n_data:/home/node/.n8n
    networks:
      - ai-network

volumes:
  n8n_data:
networks:
  ai-network:
    external: true
EOF

cd /opt/ai-system/n8n
docker network create ai-network >/dev/null 2>&1 || true
docker compose up -d
docker ps | grep n8n

# Publicar n8n via Nginx
sudo tee /etc/nginx/sites-available/n8n.conf << 'EOF'
server {
    listen 80;
    server_name n8n.<tu_dominio>;
    client_max_body_size 20m;

    location / {
        proxy_pass http://127.0.0.1:5678;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

sudo ln -sfn /etc/nginx/sites-available/n8n.conf /etc/nginx/sites-enabled/n8n.conf
sudo nginx -t && sudo systemctl reload nginx

# TLS (Let's Encrypt) - opcional pero recomendado
# sudo certbot --nginx -d n8n.<tu_dominio>
```

### 6.2 Backups automatizados (via docker exec, sin dependencia del host)

```bash
mkdir -p ~/backups/openclaw

# Wrapper con autenticacion desde OPENCLAW_DB_URL
cat > ~/apps/openclaw-enterprise/scripts/backup.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
SCHEMA="${1:?uso: backup.sh <schema>}"
OUT_DIR="${2:-$HOME/backups/openclaw}"
mkdir -p "$OUT_DIR"

DB_URL="$(grep '^OPENCLAW_DB_URL=' ~/apps/.env.production | head -1 | cut -d= -f2-)"
if [ -z "$DB_URL" ]; then
  echo "OPENCLAW_DB_URL no encontrado en ~/apps/.env.production"
  exit 1
fi

# Parse robusto de URL (soporta credenciales con caracteres especiales/percent-encoding)
tmp_env="$(mktemp)"
DB_URL="$DB_URL" python3 - "$tmp_env" << 'PY'
import os
import shlex
import sys
from urllib.parse import urlparse, unquote

db_url = os.environ.get("DB_URL", "")
u = urlparse(db_url)
if not (u.username and u.password and u.path and len(u.path) > 1):
    raise SystemExit("OPENCLAW_DB_URL invalida")

out = sys.argv[1]
with open(out, "w", encoding="utf-8") as f:
    f.write(f"DB_USER={shlex.quote(u.username)}\n")
    f.write(f"DB_PASS={shlex.quote(unquote(u.password))}\n")
    f.write(f"DB_NAME={shlex.quote(u.path.lstrip('/'))}\n")
PY
. "$tmp_env"
rm -f "$tmp_env"

docker exec -e PGPASSWORD="$DB_PASS" ai_postgres \
  pg_dump -U "$DB_USER" -d "$DB_NAME" -n "$SCHEMA" -F c \
  > "$OUT_DIR/${SCHEMA}_$(date +%Y%m%d_%H%M).dump"
EOF

chmod +x ~/apps/openclaw-enterprise/scripts/backup.sh

# Prueba manual inicial
bash ~/apps/openclaw-enterprise/scripts/backup.sh mem_audit

# Cron de backups
crontab -l > /tmp/crontab.enterprise 2>/dev/null || true

cat >> /tmp/crontab.enterprise << 'EOF'
# mem_audit: RPO 15min
*/15 * * * * bash ~/apps/openclaw-enterprise/scripts/backup.sh mem_audit

# mem_finance: RPO 1h
0 * * * * bash ~/apps/openclaw-enterprise/scripts/backup.sh mem_finance

# mem_tech: RPO 2h
0 */2 * * * bash ~/apps/openclaw-enterprise/scripts/backup.sh mem_tech

# Limpieza: conservar solo ultimos 3 dias
0 4 * * * find ~/backups/openclaw -name "*.dump" -mtime +3 -delete
EOF

crontab /tmp/crontab.enterprise
crontab -l
```

### 6.3 Prueba de restore (ejecutar semanalmente)

```bash
DUMP_FILE=$(ls -t ~/backups/openclaw/mem_audit_*.dump | head -1)
docker exec -it ai_postgres psql -U aiadmin -c "CREATE DATABASE openclaw_restore_test OWNER enterprise_owner;" 2>/dev/null || true
docker cp "$DUMP_FILE" ai_postgres:/tmp/restore_test.dump
docker exec -it ai_postgres pg_restore -U enterprise_owner -d openclaw_restore_test /tmp/restore_test.dump
docker exec -it ai_postgres psql -U enterprise_owner -d openclaw_restore_test -c "\dn"
docker exec -it ai_postgres rm -f /tmp/restore_test.dump
docker exec -it ai_postgres psql -U aiadmin -c "DROP DATABASE openclaw_restore_test;"
echo "Restore test OK: $DUMP_FILE"
```

### 6.4 Alertas minimas (via Telegram bot ya configurado)

```bash
# Crear script de health check
cat > ~/apps/openclaw-enterprise/scripts/health_check.sh << 'HEOF'
#!/usr/bin/env bash
set -euo pipefail
source ~/apps/.env.production

TELEGRAM_TOKEN="${TELEGRAM_TOKEN:-}"
CHAT_ID="${TELEGRAM_CHAT_ID:-}"

if [ -z "$TELEGRAM_TOKEN" ] || [ -z "$CHAT_ID" ]; then
  echo "Faltan TELEGRAM_TOKEN o TELEGRAM_CHAT_ID en .env.production"
  exit 1
fi

alert() {
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" -d "text=🚨 ALERTA OpenClaw: $1" >/dev/null
}

# Verificar contenedores criticos
for container in openclaw_prod ai_postgres n8n_prod; do
  STATUS=$(docker inspect --format '{{.State.Status}}' "$container" 2>/dev/null || echo "missing")
  if [ "$STATUS" != "running" ]; then
    alert "$container NO esta corriendo (status: $STATUS)"
  fi
done

# Verificar disco
DISK_USED=$(df / | awk 'NR==2{print $5}' | tr -d '%')
if [ "$DISK_USED" -gt 85 ]; then
  alert "Disco al ${DISK_USED}% en Contabo"
fi
HEOF

chmod +x ~/apps/openclaw-enterprise/scripts/health_check.sh

# Agregar al crontab (cada 10 minutos)
crontab -l > /tmp/crontab.enterprise2
echo "*/10 * * * * bash ~/apps/openclaw-enterprise/scripts/health_check.sh" >> /tmp/crontab.enterprise2
crontab /tmp/crontab.enterprise2
```

Nota de seguridad:
- No guardar tokens reales en este markdown ni en el repositorio.
- Si algun token quedo expuesto antes, rotarlo inmediatamente.

---

## Dia 7 — Go/No-Go y corte a produccion

### 7.1 Verificaciones tecnicas

```bash
ssh aiadmin@217.216.89.61

# Contenedores
docker ps --format 'table {{.Names}}\t{{.Status}}'

# Config valida
python3 -m json.tool ~/apps/openclaw-enterprise/control-plane/openclaw.json >/dev/null && echo "config_OK"

# Esquemas de memoria presentes
docker exec -it ai_postgres psql -U enterprise_owner -d openclaw_enterprise \
  -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE 'mem_%' ORDER BY 1;"

# Ledger tiene eventos
docker exec -it ai_postgres psql -U enterprise_owner -d openclaw_enterprise \
  -c "SELECT COUNT(*) AS ledger_events FROM mem_audit.execution_ledger;"

# WireGuard activo
sudo wg show

# Ollama accesible por red privada
curl http://10.10.0.2:11434/api/tags | python3 -m json.tool | head -20

# LangGraph importa
cd ~/apps/openclaw-enterprise/runtime && source .venv/bin/activate && \
  python -c "from langgraph_runtime import build_enterprise_graph; build_enterprise_graph(); print('LangGraph_OK')"
```

### 7.2 Checklist Go/No-Go

- [ ] WireGuard activo entre Contabo y Oracle (`wg show` muestra peer conectado)
- [ ] Ollama accesible SOLO por IP privada `10.10.0.2:11434`
- [ ] Esquemas `mem_finance`, `mem_tech`, `mem_audit` presentes en BD
- [ ] Ledger de auditoria acepta escrituras
- [ ] LangGraph runtime importa sin errores
- [ ] `.env.production` con passwords reales (no `REPLACE_ME` ni `openclaw_dev`)
- [ ] `.pgpass` configurado (sin passwords en crontab)
- [ ] Backups automatizados corriendo (`crontab -l` los muestra)
- [ ] Restore test ejecutado y documentado
- [ ] n8n corriendo (`docker ps | grep n8n`)
- [ ] Health check via Telegram activo
- [ ] HITL validado: `/approve` bloquea acciones irreversibles
- [ ] Runbook de rollback: `docker compose down` + restore del ultimo dump

### 7.3 Primera corrida controlada (Go-Live)

```bash
cd ~/apps/openclaw-enterprise/runtime
source .venv/bin/activate
source ../../.env.production

# Ejecutar con una tarea financiera de bajo riesgo como primera prueba
python langgraph_runtime.py

# Verificar que se registro en el ledger
docker exec -it ai_postgres psql -U enterprise_owner -d openclaw_enterprise \
  -c "SELECT execution_id, agent_id, state, status, cost_usd, created_at FROM mem_audit.execution_ledger ORDER BY event_id DESC LIMIT 10;"
```

Declarar Go-Live en ventana de cambio: **Lunes–Jueves 09:00–14:00**.
# Version: v5
