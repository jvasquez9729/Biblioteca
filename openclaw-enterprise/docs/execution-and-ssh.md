# Ejecución: quién lo corre y cómo (incluyendo SSH)

## ¿Quién debe ejecutarlo?
- **Normalmente tú / tu equipo** en tu máquina o servidor.
- Yo (agente) puedo preparar archivos, scripts y comandos dentro de este entorno de trabajo, pero **no puedo abrir una sesión SSH interactiva a tus servidores privados** por mi cuenta.

## Opciones reales de ejecución

### Opción A — Local (rápida)
```bash
cd /workspace/Biblioteca
bash openclaw-enterprise/scripts/run_enterprise_stack.sh
```

### Opción B — En servidor por SSH (recomendada para operación continua)
Desde tu terminal local:
```bash
ssh usuario@tu-servidor
cd /ruta/del/repo/Biblioteca
bash openclaw-enterprise/scripts/run_enterprise_stack.sh
```

### Opción C — Servicio gestionado
- Docker + systemd/PM2 para dejarlo corriendo.
- Cron para heartbeat y jobs periódicos.

## ¿Cómo “decirle a OpenClaw” que ejecute?
Con una invocación del runtime apuntando al config del control-plane:
```bash
openclaw run --config openclaw-enterprise/control-plane/openclaw.json --task "Procesar estados financieros Q1"
```

Si tu versión de OpenClaw usa otra sintaxis CLI, conserva la misma idea:
1) cargar `openclaw.json`,
2) definir tarea,
3) respetar HITL (`/approve`) antes de acciones irreversibles.

## Seguridad mínima antes de ejecutar en servidor
- Usar usuario no-root para el proceso.
- Guardar credenciales vía variables de entorno/secret manager.
- Restringir acceso de red al puerto de base de datos.
- Respaldos de `mem_finance`, `mem_tech`, `mem_audit`.


## Antes de producción
Revisa y completa `docs/production-readiness.md` para endurecer seguridad, observabilidad y CI/CD.
