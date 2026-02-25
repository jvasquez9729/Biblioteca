# Arquitectura Empresarial Multi‑Agente (MVP+)

## 1. Bloques
- **Control Plane**: orquestación, políticas, workflow, presupuesto.
- **Financial Intelligence**: parsing + análisis + narrativa ejecutiva.
- **Software Factory**: build/review/security con gates obligatorios.
- **Engineering Specialists**: frontend, backend, database, n8n automation.
- **Memory Plane**: `mem_finance`, `mem_tech`, `mem_audit`.
- **Audit Plane**: ledger hash-encadenado + PR checks + eventos de estado.

## 2. Flujo operativo
1. VALIDATION (integridad input)
2. DECOMPOSITION (micro-tareas)
3. EXECUTION (agentes especializados)
4. AUDIT (review + security)
5. CONSOLIDATION (unificar resultados)
6. EXEC_SUMMARY (reporte ejecutivo)
7. HITL_WAIT (espera `/approve`)

## 3. Mecanismos de seguridad
- Principio de mínimo privilegio por rol.
- Separación de memoria por esquema y credenciales.
- Denegación explícita de acciones irreversibles sin HITL.
- Gate de seguridad bloqueante para severidad HIGH/CRITICAL.

## 4. Stack de orquestación recomendado (LangChain vs LangGraph)
- **Recomendación principal: LangGraph** para producción multi-agente.
- Usar **LangChain** como capa de utilidades (prompts, retrievers, tool wrappers).

### ¿Por qué LangGraph primero?
- Control explícito de estados/transiciones.
- Reintentos y recuperación de errores por nodo.
- Mejor trazabilidad para auditoría y compliance.
- Encaja naturalmente con tu ciclo de 7 pasos + HITL.

## 5. Métricas mínimas por release
- Tiempo promedio de ciclo de tarea (TCT).
- Costo por ejecución.
- Porcentaje de PR rechazadas por seguridad.
- Precisión de extracción financiera validada.
- Tasa de éxito de workflows n8n en staging vs producción.
