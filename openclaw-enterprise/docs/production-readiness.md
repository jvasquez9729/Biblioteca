# Production Readiness Checklist (OpenClaw Enterprise)

## 1) Orquestación y runtime
- Implementar orquestación por grafo de estados con **LangGraph** (recomendado) para asegurar transiciones y reintentos controlados.
- Mantener `state_machine.yaml` como fuente de verdad de estados.
- Enforzar HITL para acciones irreversibles.

## 2) Seguridad
- Secret manager obligatorio (Vault/AWS Secrets Manager/GCP Secret Manager).
- Rotación de credenciales de DB/API.
- Escaneo SAST y dependencias en CI.
- WAF y rate limiting para endpoints públicos.

## 3) Observabilidad
- Logs estructurados (JSON) con `execution_id`.
- Trazas distribuidas (OpenTelemetry).
- Métricas de costo/token/latencia por agente.
- Alertas para fallos de cadena de auditoría.

## 4) Datos y resiliencia
- Backup diario de `mem_finance`, `mem_tech`, `mem_audit`.
- Restore test semanal.
- Migraciones reversibles y verificadas en staging.

## 5) CI/CD
- Gates obligatorios: lint, tests, SAST, secret scan, policy gate.
- Prohibir auto-merge del mismo agente autor.
- Deploy con aprobación humana y ventanas controladas.

## 6) n8n en producción
- Entornos separados (dev/staging/prod).
- Workflows críticos con circuit breaker y dead-letter queue.
- Evidencia de pruebas antes de `execute_n8n_workflow_production`.
