# P1 - Ollama Unreachable

## Severidad
- P1 (inferencia local no disponible).

## Deteccion
- Timeout o error 5xx en llamadas a `OLLAMA_BASE_URL`.
- Alerta de health check.

## Diagnostico rapido
```bash
grep '^OLLAMA_BASE_URL=' ~/apps/.env.production
curl -v --max-time 5 http://10.10.0.2:11434/api/tags
ssh <oracle_user>@<oracle_public_ip> "systemctl status ollama --no-pager"
ssh <oracle_user>@<oracle_public_ip> "sudo wg show"
```

## Mitigacion inmediata
```bash
ssh <oracle_user>@<oracle_public_ip> "sudo systemctl restart ollama"
ssh <oracle_user>@<oracle_public_ip> "sudo systemctl status ollama --no-pager"
curl --max-time 5 http://10.10.0.2:11434/api/tags
```

## Recuperacion adicional
1. Validar WireGuard entre nodos (`wg show` en ambos).
2. Validar reglas firewall/ufw puerto `51820/udp`.
3. Confirmar bind de Ollama a IP privada (`OLLAMA_HOST=10.10.0.2:11434`).

## Criterio de cierre
- `OLLAMA_BASE_URL` responde estable por 15 min.
- Runtime vuelve a completar ejecuciones.

