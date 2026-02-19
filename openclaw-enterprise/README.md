# OpenClaw Enterprise OS (Plantilla Inicial)

Esta carpeta contiene una **base de arquitectura** para un Sistema Multi‑Agente Auditado con separación estricta de memoria (financiera/técnica/auditoría), HITL obligatorio y pipeline de validación.

## Objetivo
Implementar 3 bloques:
1. **Financial Intelligence System**.
2. **Software Factory** con review cruzada y seguridad.
3. **Control Plane + Auditoría** con trazabilidad completa.

## Estructura
- `control-plane/openclaw.json`: configuración base del orquestador y políticas globales.
- `policies/agent_capabilities.yaml`: permisos por agente (RBAC + tool allowlist).
- `workflows/state_machine.yaml`: ciclo de 7 estados con transición formal.
- `prompts/*.md`: prompts iniciales por agente.
- `sql/*.sql`: esquemas de memoria separada y ledger auditable.
- `infra/docker-compose.yml`: PostgreSQL + pgvector para memoria persistente.
- `docs/architecture.md`: arquitectura de referencia y flujo operativo.
- `docs/skills-roadmap.md`: skills recomendadas para usar/crear en tu sistema.
- `docs/execution-and-ssh.md`: cómo ejecutar el sistema y cómo operarlo por SSH.
- `scripts/bootstrap.sh`: guía automatizable para primeros pasos.

## Principios no negociables
- Ningún agente hace merge/deploy sin `HITL_APPROVAL`.
- El agente que desarrolla no puede autoaprobar su PR.
- Toda acción se registra con hash de entrada/salida y costo.
- Memoria financiera y técnica aisladas por esquema + rol DB.


## Quickstart de comandos
Para ejecutar todo en orden, sigue `docs/quickstart-commands.md`.
