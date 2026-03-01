# P2 - n8n Queue Stuck

## Severidad
- P2 (degradacion parcial, sin caida total del sistema).

## Deteccion
- Workflows pendientes sin progreso.
- Retrasos en notificaciones o automatizaciones.

## Diagnostico rapido
```bash
docker ps --filter "name=n8n_prod"
docker logs n8n_prod --tail 200
curl -I http://127.0.0.1:5678
```

## Mitigacion inmediata
```bash
docker restart n8n_prod
sleep 10
docker logs n8n_prod --tail 100
```

## Verificaciones posteriores
1. Validar autenticacion (`N8N_BASIC_AUTH_*` o OIDC).
2. Validar conectividad con runtime/webhooks.
3. Reintentar workflow critico en entorno controlado.

## Criterio de cierre
- Workflows criticos vuelven a ejecutarse.
- Cola sin crecimiento anormal por 30 min.
- No hay errores repetitivos en logs.

