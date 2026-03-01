.PHONY: help preflight runtime-test backup-test verify-audit deploy chaos-test runtime-api runtime-api-smoke runtime-api-approve install-ci

help:
	@echo "Targets disponibles:"
	@echo "  make preflight    - Validaciones previas de entorno"
	@echo "  make runtime-test - Prueba basica del runtime LangGraph"
	@echo "  make backup-test  - Prueba de backup (mem_audit)"
	@echo "  make verify-audit - Verifica hash chain del ledger"
	@echo "  make deploy       - Levanta stack enterprise"
	@echo "  make chaos-test   - Simulacion controlada de resiliencia"
	@echo "  make runtime-api  - Levanta API HTTP del runtime (FastAPI)"
	@echo "  make runtime-api-smoke - Prueba execute/approve"
	@echo "  make runtime-api-approve - Aprueba ejecucion por ID (EXEC_ID=...)"
	@echo "  make install-ci   - Instala workflow de GitHub Actions en .github/workflows/ci.yml"

preflight:
	bash scripts/preflight.sh

runtime-test:
	@if [ ! -f scripts/runtime_server.py ]; then \
		echo "scripts/runtime_server.py no existe"; \
		exit 1; \
	fi
	python3 -c "import scripts.runtime_server as s; print('runtime_server import OK', s.app.title)"

backup-test:
	@if [ ! -f scripts/backup.sh ]; then \
		echo "scripts/backup.sh no existe"; \
		exit 1; \
	fi
	bash scripts/backup.sh mem_audit

verify-audit:
	bash scripts/verify_audit_chain.sh

deploy:
	bash scripts/run_enterprise_stack.sh

chaos-test:
	bash scripts/chaos_test.sh --dry-run

runtime-api:
	uvicorn scripts.runtime_server:app --host 0.0.0.0 --port 8000

runtime-api-smoke:
	curl -s -X POST http://127.0.0.1:8000/runtime/execute -H "Content-Type: application/json" -d "{\"task\":\"smoke test\",\"domain\":\"mem_finance\",\"agent_id\":\"chief_of_staff\",\"budget_key\":\"finance_analysis\"}"

runtime-api-approve:
	@test -n "$(EXEC_ID)" || (echo "Uso: make runtime-api-approve EXEC_ID=exec-xxxx"; exit 1)
	curl -s -X POST http://127.0.0.1:8000/runtime/approve -H "Content-Type: application/json" -d "{\"execution_id\":\"$(EXEC_ID)\",\"approved\":true}"

install-ci:
	bash scripts/install_github_workflow.sh
