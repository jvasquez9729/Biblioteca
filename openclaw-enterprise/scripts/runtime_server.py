#!/usr/bin/env python3
from __future__ import annotations

import os
import uuid
import json
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path
from time import perf_counter
from typing import Literal

import psycopg2
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest
from starlette.responses import Response

try:
    from scripts.runtime_budget_guard import BudgetExceededError, BudgetGuard
    from scripts.runtime_hash_chain import canonical_event_hash
    from scripts.runtime_memory_store import MemoryStore
    from scripts.runtime_policy_enforcer import PolicyEnforcer, ToolCall
except ModuleNotFoundError:
    from runtime_budget_guard import BudgetExceededError, BudgetGuard
    from runtime_hash_chain import canonical_event_hash
    from runtime_memory_store import MemoryStore
    from runtime_policy_enforcer import PolicyEnforcer, ToolCall


class ExecuteRequest(BaseModel):
    task: str
    domain: Literal["mem_finance", "mem_tech"] = "mem_finance"
    agent_id: str = "chief_of_staff"
    budget_key: str = "finance_analysis"


class ApproveRequest(BaseModel):
    execution_id: str
    approved: bool = True


@dataclass
class ExecutionState:
    execution_id: str
    task: str
    agent_id: str
    budget_key: str
    domain: str
    status: str = "HITL_WAIT"
    summary: str = ""
    approved: bool = False
    cost_usd: float = 0.0
    token_in: int = 0
    token_out: int = 0
    events: list[str] = field(default_factory=list)


NODE_LATENCY = Histogram("node_latency_seconds", "Latencia por nodo", ["node"])
TOKENS_TOTAL = Counter("tokens_total", "Tokens consumidos", ["agent_id", "direction"])
COST_TOTAL = Counter("cost_usd_total", "Costo acumulado", ["agent_id"])
REJECTIONS_TOTAL = Counter("execution_rejections_total", "Ejecuciones rechazadas", ["reason"])

app = FastAPI(title="OpenClaw Runtime API", version="0.1.0")
states: dict[str, ExecutionState] = {}
budget_guard = BudgetGuard()
policy = PolicyEnforcer()
memory = MemoryStore()


def _db_url() -> str:
    url = os.getenv("OPENCLAW_DB_URL", "").strip()
    if url:
        return url
    env_file = Path.home() / "apps" / ".env.production"
    if env_file.exists():
        for line in env_file.read_text(encoding="utf-8").splitlines():
            if line.startswith("OPENCLAW_DB_URL="):
                return line.split("=", 1)[1].strip()
    raise RuntimeError("OPENCLAW_DB_URL no configurado")


def _append_ledger_event(state: ExecutionState, node: str, status: str) -> None:
    db_url = _db_url()
    output_hash = canonical_event_hash(
        state.execution_id, state.agent_id, node, state.summary or state.task, None, "sha256"
    )
    with psycopg2.connect(db_url) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT event_hash FROM mem_audit.execution_ledger
                WHERE execution_id = %s
                ORDER BY event_id DESC
                LIMIT 1
                """,
                (state.execution_id,),
            )
            row = cur.fetchone()
            prev_hash = row[0] if row else None
            event_hash = canonical_event_hash(
                state.execution_id, state.agent_id, node, output_hash, prev_hash, "sha256"
            )
            cur.execute(
                """
                INSERT INTO mem_audit.execution_ledger
                (execution_id, agent_id, model_id, state, input_hash, output_hash,
                 prev_event_hash, event_hash, token_in, token_out, cost_usd, status)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                """,
                (
                    state.execution_id,
                    state.agent_id,
                    "runtime-http-mvp",
                    node,
                    canonical_event_hash(state.execution_id, state.agent_id, "input", state.task, None),
                    output_hash,
                    prev_hash,
                    event_hash,
                    state.token_in,
                    state.token_out,
                    state.cost_usd,
                    status,
                ),
            )


def _notify_n8n(event_type: str, state: ExecutionState) -> None:
    """Notifica estado al webhook de n8n, si esta configurado."""
    url = os.getenv("N8N_RUNTIME_EVENTS_WEBHOOK", "").strip()
    if not url:
        return
    payload = {
        "event_type": event_type,
        "execution_id": state.execution_id,
        "status": state.status,
        "agent_id": state.agent_id,
        "domain": state.domain,
        "summary": state.summary,
        "cost_usd": state.cost_usd,
        "token_in": state.token_in,
        "token_out": state.token_out,
    }
    try:
        req = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=10):
            pass
    except Exception:
        # No bloquear flujo principal por fallo de notificacion.
        return


def _run_execution(state: ExecutionState) -> ExecutionState:
    t0 = perf_counter()
    # RBAC scope explicito: external_call/tool style.
    policy.check_tool_allowed(ToolCall(agent_id=state.agent_id, tool_name="decompose_task", scope="workflow_action"))
    NODE_LATENCY.labels("decomposition").observe(perf_counter() - t0)

    # Simulacion de costo/token + budget guard.
    est_cost = 0.05
    est_token_in = 300
    est_token_out = 700
    state.cost_usd = budget_guard.add_cost(state.execution_id, state.budget_key, est_cost)
    state.token_in += est_token_in
    state.token_out += est_token_out
    TOKENS_TOTAL.labels(state.agent_id, "in").inc(est_token_in)
    TOKENS_TOTAL.labels(state.agent_id, "out").inc(est_token_out)
    COST_TOTAL.labels(state.agent_id).inc(est_cost)

    ctx = memory.retrieve_context(state.domain, state.task, k=5)
    state.summary = f"MVP summary for task='{state.task}' context_items={len(ctx)}"
    memory.save_execution_artifact(
        domain=state.domain,
        text=state.summary,
        metadata={"execution_id": state.execution_id, "agent_id": state.agent_id},
    )
    state.status = "HITL_WAIT"
    _append_ledger_event(state, node="EXEC_SUMMARY", status="pending_approval")
    _notify_n8n("execution.waiting_approval", state)
    return state


@app.post("/runtime/execute")
def runtime_execute(req: ExecuteRequest):
    execution_id = f"exec-{uuid.uuid4().hex[:10]}"
    state = ExecutionState(
        execution_id=execution_id,
        task=req.task,
        agent_id=req.agent_id,
        budget_key=req.budget_key,
        domain=req.domain,
    )
    try:
        states[execution_id] = _run_execution(state)
        return {"execution_id": execution_id, "status": states[execution_id].status}
    except PermissionError as e:
        REJECTIONS_TOTAL.labels("policy_denied").inc()
        raise HTTPException(status_code=403, detail=str(e))
    except BudgetExceededError as e:
        REJECTIONS_TOTAL.labels("budget_exceeded").inc()
        raise HTTPException(status_code=402, detail=str(e))
    except Exception as e:
        REJECTIONS_TOTAL.labels("runtime_error").inc()
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/runtime/approve")
def runtime_approve(req: ApproveRequest):
    state = states.get(req.execution_id)
    if not state:
        raise HTTPException(status_code=404, detail="execution_id no encontrado")
    if not req.approved:
        state.status = "REJECTED"
        _append_ledger_event(state, node="HITL_WAIT", status="rejected")
        _notify_n8n("execution.rejected", state)
        return {"execution_id": state.execution_id, "status": state.status}

    state.approved = True
    state.status = "DONE"
    _append_ledger_event(state, node="HITL_WAIT", status="approved")
    _notify_n8n("execution.done", state)
    return {"execution_id": state.execution_id, "status": state.status}


@app.post("/runtime/events")
def runtime_events(payload: dict):
    execution_id = payload.get("execution_id", "")
    if execution_id and execution_id in states:
        states[execution_id].events.append(str(payload))
    return {"ok": True}


@app.get("/runtime/status/{execution_id}")
def runtime_status(execution_id: str):
    state = states.get(execution_id)
    if not state:
        raise HTTPException(status_code=404, detail="execution_id no encontrado")
    return {
        "execution_id": state.execution_id,
        "status": state.status,
        "approved": state.approved,
        "cost_usd": state.cost_usd,
        "token_in": state.token_in,
        "token_out": state.token_out,
    }


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
