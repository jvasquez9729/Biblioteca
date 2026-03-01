#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT_DIR/github-ci-workflow.yml"
DST_DIR="$ROOT_DIR/.github/workflows"
DST="$DST_DIR/ci.yml"

mkdir -p "$DST_DIR"
cp "$SRC" "$DST"
echo "Workflow instalado en: $DST"

