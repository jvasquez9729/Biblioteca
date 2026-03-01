# P1 - DB Down (ai_postgres)

## Severidad
- P1 (servicio degradado o caido).

## Deteccion
- Alertas de health check.
- Fallos en runtime al escribir/leer en `mem_audit`, `mem_finance`, `mem_tech`.

## Diagnostico rapido
```bash
docker ps --filter "name=ai_postgres"
docker logs ai_postgres --tail 200
docker exec -it ai_postgres psql -U aiadmin -c "SELECT 1;"
df -h
```

## Mitigacion inmediata
```bash
docker restart ai_postgres
sleep 10
docker exec -it ai_postgres psql -U aiadmin -c "SELECT 1;"
```

## Recuperacion (si no levanta)
1. Identificar ultimo dump valido en `~/backups/openclaw`.
2. Crear DB temporal y ejecutar restore test.
3. Restaurar DB principal segun runbook de backup/restore.

## Criterio de cierre
- `SELECT 1` estable.
- Runtime vuelve a registrar eventos en ledger.
- Alertas vuelven a verde por 15 min.

## Postmortem
- Causa raiz.
- Tiempo de deteccion/mitigacion.
- Acciones preventivas.

