# AGENTS.md

## Cursor Cloud specific instructions

### Repository overview

This repo contains three projects:

| Project | Path | Purpose |
|---|---|---|
| **OpenClaw Enterprise OS** | `openclaw-enterprise/` | Multi-agent auditable enterprise system (FastAPI + PostgreSQL + pgvector) |
| **Controller Financiero** | `ControllerFinanciero/` | Financial analysis Excel generator for Colombian SMEs (Python + openpyxl) |
| **SQL learning exercises** | Root `.sql` files | Static educational SQL dumps (no services needed) |

### Running OpenClaw Enterprise (main product)

**Prerequisites:** Docker, PostgreSQL client (`psql`), Python 3.12.

1. **Start PostgreSQL + pgvector** — Docker Compose has cgroup issues in nested containers. Use `docker run` instead:
   ```bash
   docker run -d --name openclaw-postgres --cgroup-parent="" \
     -e POSTGRES_USER=openclaw -e POSTGRES_PASSWORD=openclaw_dev -e POSTGRES_DB=openclaw \
     -p 127.0.0.1:5432:5432 pgvector/pgvector:pg16
   ```
2. **Apply schemas** (idempotent):
   ```bash
   export PGPASSWORD="openclaw_dev"
   psql -h 127.0.0.1 -U openclaw -d openclaw -f openclaw-enterprise/sql/001_memory_schemas.sql
   psql -h 127.0.0.1 -U openclaw -d openclaw -f openclaw-enterprise/sql/002_audit_ledger.sql
   ```
3. **Start the FastAPI runtime API** from `openclaw-enterprise/`:
   ```bash
   export OPENCLAW_DB_URL="postgresql://openclaw:openclaw_dev@127.0.0.1:5432/openclaw"
   cd openclaw-enterprise
   uvicorn scripts.runtime_server:app --host 0.0.0.0 --port 8000
   ```
4. **Smoke test:** see `Makefile` targets `runtime-api-smoke` and `runtime-api-approve`.

### Gotchas and non-obvious caveats

- **Docker Compose cgroup issue:** The `docker-compose.yml` includes hardened security options (`read_only`, `cap_drop`, `tmpfs`) that fail in nested Docker environments (Firecracker VM). Use plain `docker run` as shown above to bypass this.
- **PATH for pip-installed tools:** `ruff`, `bandit`, `pip-audit` install to `~/.local/bin`. Ensure `export PATH="$HOME/.local/bin:$PATH"` is set before running lint commands.
- **OPENCLAW_DB_URL is required:** The FastAPI server and `MemoryStore` both require this env var. If unset, they look for `~/apps/.env.production` which won't exist in cloud VMs.
- **Embedding provider (Ollama) is optional:** Without Ollama, the memory store falls back to text-based `ILIKE` search. The runtime API works fully without it.
- **`scripts/` module import:** The runtime server must be started from `openclaw-enterprise/` directory so that `scripts.runtime_server` resolves correctly as a Python module.

### Lint / Test / Build commands

All commands run from `/workspace`:

| Check | Command |
|---|---|
| Lint (ruff) | `ruff check openclaw-enterprise/scripts` |
| Syntax check | `python3 -m compileall -q openclaw-enterprise/scripts` |
| SAST (bandit) | `bandit -q -r openclaw-enterprise/scripts -lll` |
| Dependency audit | `pip-audit` |
| Runtime import test | `make runtime-test` (from `openclaw-enterprise/`) |

### CI pipeline

See `.github/workflows/ci.yml` — runs ruff, compileall, bandit, pip-audit, and a secret scan on push/PR to main/master.
