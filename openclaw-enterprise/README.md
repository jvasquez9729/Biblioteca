# OpenClaw Enterprise OS (Plantilla Inicial)

Esta carpeta contiene una **base de arquitectura** para un Sistema Multi‑Agente Auditado con separación estricta de memoria (financiera/técnica/auditoría), HITL obligatorio y pipeline de validación.

## Objetivo
Implementar 4 bloques:
1. **Financial Intelligence System**.
2. **Software Factory** con review cruzada y seguridad.
3. **Engineering Specialists** (frontend, backend, database, n8n).
4. **Control Plane + Auditoría** con trazabilidad completa.

## Estructura
- `control-plane/openclaw.json`: configuración base del orquestador y políticas globales.
- `policies/agent_capabilities.yaml`: permisos por agente (RBAC + tool allowlist + routing).
- `workflows/state_machine.yaml`: ciclo de 7 estados con transición formal.
- `prompts/*.md`: prompts iniciales por agente (finanzas, dev, reviewer, seguridad y especialistas).
- `sql/*.sql`: esquemas de memoria separada y ledger auditable.
- `infra/docker-compose.yml`: PostgreSQL + pgvector para memoria persistente.
- `docs/architecture.md`: arquitectura de referencia y stack recomendado (LangGraph + LangChain).
- `docs/production-readiness.md`: checklist de endurecimiento para producción.
- `docs/runbook-production-contabo-oracle.md`: runbook detallado para pasar a producción (Contabo + Oracle).
- `docs/production-files-included.md`: índice de archivos del paquete de producción.
- `docs/skills-roadmap.md`: skills recomendadas para usar/crear en tu sistema.
- `docs/execution-and-ssh.md`: cómo ejecutar el sistema y cómo operarlo por SSH.
- `scripts/bootstrap.sh`: guía automatizable para primeros pasos.
- `scripts/package_production_bundle.sh`: empaqueta los artefactos para compartir/desplegar.

## Principios no negociables
- Ningún agente hace merge/deploy sin `HITL_APPROVAL`.
- El agente que desarrolla no puede autoaprobar su PR.
- Toda acción se registra con hash de entrada/salida y costo.
- Memoria financiera y técnica aisladas por esquema + rol DB.
- Cambios de automatización crítica (n8n productivo) requieren aprobación humana.

## Quickstart de comandos
Para ejecutar todo en orden, sigue `docs/quickstart-commands.md`.
