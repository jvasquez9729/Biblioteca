#!/usr/bin/env bash
set -euo pipefail

python3 "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/verify_audit_chain.py"

