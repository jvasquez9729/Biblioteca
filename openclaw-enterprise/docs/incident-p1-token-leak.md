# P1 - Token Leak / Secret Exposure

## Severidad
- P1 (compromiso de credenciales).

## Deteccion
- Secret detectado en logs, commits, chat o alertas de secret scan.

## Acciones inmediatas (primeros 15 min)
1. Revocar y rotar el secreto comprometido.
2. Invalidar sesiones/tokens activos asociados.
3. Cortar integraciones afectadas temporalmente si aplica.

## Checklist de contencion
```bash
# Buscar rastros en repo local
rg -n "API_KEY|TOKEN|SECRET|PASSWORD" .

# Ver ultimos commits por exposicion accidental
git log --oneline -n 20
```

## Rotacion minima
- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `N8N_API_KEY`
- `TELEGRAM_TOKEN`
- password de DB (`enterprise_owner`)

## Recuperacion
1. Actualizar secret manager con valores nuevos.
2. Reiniciar servicios que cachean secretos.
3. Verificar conectividad y jobs criticos.

## Criterio de cierre
- Secretos comprometidos revocados y rotados.
- Confirmacion de funcionamiento de runtime/n8n.
- Hallazgo documentado y lecciones aprendidas.

