# Plan de Implementacion (< 1 semana)

Objetivo: cerrar 6 gaps reales en **5 dias habiles** con alcance MVP de produccion.

## Por que antes dije 2 semanas
- 2 semanas era una estimacion conservadora en modo secuencial.
- Para bajarlo a 5 dias, hay que ejecutar en paralelo y limitar alcance a MVP verificable.

## Alcance MVP (obligatorio en 5 dias)
1. Vector memory conectada (write + retrieval basico).
2. RBAC aplicado en runtime antes de tool calls.
3. Cost guard por ejecucion y por agente.
4. Verificacion de hash chain diaria con alerta.
5. Integracion minima n8n <-> LangGraph (entrada y salida).
6. Metricas minimas exportadas a Prometheus.

## Decisiones de arquitectura (explicitadas)
- Runtime pasa de script CLI a **servidor HTTP FastAPI**.
- Endpoints minimos:
  - `POST /runtime/execute`
  - `POST /runtime/approve`
  - `POST /runtime/events` (opcional, solo para ingesta interna de eventos)
  - `GET /metrics`
  - `GET /runtime/status/{execution_id}`
- Formula canonica de `event_hash`:
  - `hash(execution_id|agent_id|state|output_hash|prev_event_hash)`
- Embeddings (MVP):
  - Default: `EMBEDDING_PROVIDER=ollama`, modelo `nomic-embed-text`.
  - Alternativo: `EMBEDDING_PROVIDER=openai`, modelo `text-embedding-3-small`.
- RBAC scope en runtime:
  - `external_call`, `db_write`, `workflow_action`, `code_action`.
  - Cada accion/tool pasa por `policy_enforcer.check_tool_allowed(...)`.

## Pasos faltantes agregados (lo que no estaba cubierto)
7. Task runner unico (`Makefile`) para operacion repetible.
8. Preflight automatico antes de deploy.
9. Secret manager real + rotacion de credenciales.
10. CI/CD ejecutable con gates bloqueantes.
11. Pruebas de resiliencia (chaos basico).
12. Runbooks de incidentes P1/P2.
13. Entorno staging con paridad de arquitectura.

## Plan de 5 dias

### Dia 1 - Runtime hardening base (RBAC + Budget)
- Crear `scripts/runtime_server.py` (FastAPI) y mover entrada principal a HTTP.
- Crear `scripts/runtime_policy_enforcer.py`:
  - Carga `policies/agent_capabilities.yaml`.
  - Expone `check_tool_allowed(agent_id, tool_name)`.
- Integrar middleware en `scripts/runtime_server.py`:
  - Validar permisos antes de cada tool call.
  - Bloquear y registrar evento `policy_denied`.
- Crear `scripts/runtime_budget_guard.py`:
  - Carga budgets desde `control-plane/openclaw.json`.
  - Acumula costo estimado por ejecucion/agent.
  - Aborta flujo al exceder presupuesto.
- Crear `Makefile` minimo:
  - `make preflight`, `make runtime-test`, `make backup-test`, `make verify-audit`, `make deploy`.
- Crear `scripts/preflight.sh`:
  - valida `.env`, Docker, mounts `openclaw_prod`, conectividad `OLLAMA_BASE_URL`, extension `vector`.

Entregable:
- Runtime rechaza tools no permitidas y corta por budget.
- Operacion estandarizada por comandos de un solo paso.
- API HTTP arriba con `/runtime/execute` y `/runtime/approve`.

### Dia 2 - Vector memory (MVP)
- Crear `scripts/runtime_memory_store.py`:
  - PGVector store (`mem_finance` y `mem_tech`).
  - `save_execution_artifact(...)` al cerrar nodos clave.
  - `retrieve_context(task, domain, k=5)` al iniciar nodos.
- Definir proveedor de embeddings en `.env.production`:
  - `EMBEDDING_PROVIDER=ollama` (default).
  - `OLLAMA_EMBEDDING_MODEL=nomic-embed-text`.
  - (opcional) `OPENAI_EMBEDDING_MODEL=text-embedding-3-small`.
- Integrar en `validation`, `decomposition` y `execution`.
- Guardar `execution_id`, `agent_id`, `domain`, `timestamp` en metadata.

Entregable:
- Cada corrida guarda memoria y recupera contexto relevante.

### Dia 3 - Auditoria verificable (hash chain verifier)
- Crear script `scripts/verify_audit_chain.py`:
  - Recorre `mem_audit.execution_ledger` por `event_id`.
  - Verifica continuidad `prev_event_hash -> event_hash`.
  - Recalcula y valida la formula canonica:
    - `hash(execution_id|agent_id|state|output_hash|prev_event_hash)`
  - Reporta primer quiebre y retorna exit code no-cero.
- Crear wrapper `scripts/verify_audit_chain.sh`.
- Agregar cron diario + alerta Telegram/Slack si falla.

Entregable:
- Cadena de auditoria verificada automaticamente cada dia.

### Dia 4 - Integracion n8n <-> LangGraph
- Entrada:
  - Webhook n8n `POST /runtime/execute` con payload de tarea.
  - Endpoint en runtime que inicia ejecucion y retorna `execution_id`.
- Aprobacion HITL:
  - n8n/Telegram llama `POST /runtime/approve` con `execution_id`.
  - Runtime hace `update_state(... approved=True)` y reanuda.
- Salida:
  - Al estado `DONE/REJECTED`, runtime llama webhook de n8n
    (ejemplo: `POST https://n8n.<tu_dominio>/webhook/runtime-events`).
  - Nota: esto NO es el endpoint interno opcional `POST /runtime/events` del runtime.
- Crear 2 workflows n8n minimos:
  - `finance-trigger-to-runtime`.
  - `runtime-status-notify` (Slack/Email/Telegram).

Entregable:
- Flujo extremo a extremo automatizado funcionando.

### Dia 5 - Observabilidad + pruebas de aceptacion
- Exponer metricas en `scripts/runtime_server.py` (Prometheus):
  - `node_latency_seconds` (histogram por nodo).
  - `tokens_total` (counter por agente).
  - `cost_usd_total` (counter por agente).
  - `execution_rejections_total` (counter por motivo).
- Exponer endpoint `/metrics`.
- Pruebas de aceptacion (smoke):
  - RBAC deny test.
  - Budget exceed test.
  - Vector recall test.
  - Hash chain verify test.
  - n8n trigger + callback test.
- Crear pipeline CI/CD MVP (GitHub Actions o equivalente):
  - Jobs: lint, tests, sast, dependency scan, secret scan, policy gate.
  - Regla: merge bloqueado si falla cualquier gate.
  - Archivo base en repo: `github-ci-workflow.yml`.
  - Instalacion en ruta final: `bash scripts/install_github_workflow.sh`.

Entregable:
- Dashboard basico visible y checklist de validacion completado.
- CI/CD bloqueante activo.

## Dia 6-7 (inmediato post-MVP, aun dentro de 1 semana calendario)

### Dia 6 - Secret manager + runbooks de incidentes
- Migrar secretos desde `.env` a secret manager (Vault/1Password SA).
- Rotar: DB password, API keys, token Telegram.
- Crear runbooks en `docs/incidents/`:
  - `p1-db-down.md`
  - `p1-ollama-unreachable.md`
  - `p1-token-leak.md`
  - `p2-n8n-queue-stuck.md`
- Simulacro rapido de incidente P1 (tabletop de 30 min).

Entregable:
- Secretos fuera de archivos locales y playbooks de incidente listos.

### Dia 7 - Resiliencia + staging parity
- Crear `scripts/chaos_test.sh`:
  - detener `ai_postgres` 2 min y validar recuperacion.
  - bloquear temporalmente acceso a Ollama y validar fallback/alerta.
- Definir y levantar staging minimo:
  - mismo diagrama (control plane + runtime + DB + n8n + nodo inference).
  - configurar mismos checks de preflight y monitoreo.
- Ejecutar suite smoke completa en staging antes de prod.

Entregable:
- Evidencia de recuperacion ante fallos.
- Staging funcional con paridad suficiente para pruebas de release.

## Criterio de Done (fin de semana 1)
- [ ] RBAC bloquea tool prohibida y registra evento.
- [ ] Budget cap detiene ejecucion al exceder umbral.
- [ ] Memoria vectorial guarda y recupera contexto.
- [ ] Verificador hash chain corre diario con alertas.
- [ ] n8n inicia ejecucion y recibe callback final.
- [ ] Metricas de latencia/tokens/costo/rechazos visibles en Prometheus.
- [ ] `make preflight` y `make deploy` operativos.
- [ ] CI/CD bloquea merges al fallar gates.
- [ ] Secretos migrados a gestor y credenciales rotadas.
- [ ] Runbooks P1/P2 disponibles y validados en tabletop.
- [ ] Chaos test basico ejecutado con evidencia.
- [ ] Staging operativo antes de siguiente release.

## Riesgos para cumplir en 5 dias
- Dependencias de OpenClaw CLI/API no documentadas.
- Inestabilidad de credenciales/model providers.
- Ajustes de red/reverse proxy para webhooks.

Mitigacion:
- Priorizar endpoints internos simples y wrappers.
- Feature flags para activar por etapas.
- Pruebas de humo al cierre de cada dia (no esperar al dia 5).
