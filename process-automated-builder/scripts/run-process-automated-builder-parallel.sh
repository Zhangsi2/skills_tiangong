#!/usr/bin/env bash
set -euo pipefail

# Safer parallel wrapper for batch flow processing.
# Fixes prior issues where xargs child shells lost env vars and wrote logs to /<file>.log.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
SKILL_DIR="$(cd -- "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
RUNNER="${SCRIPT_DIR}/run-process-automated-builder.sh"

FLOW_DIR=""
OUT_DIR=""
WORKERS=3
OPERATION="produce"
PYTHON_BIN="${PAB_PYTHON_BIN:-python3}"
MAX_ATTEMPTS=3

usage() {
  cat <<'USAGE'
Usage: run-process-automated-builder-parallel.sh --flow-dir <dir> --out-dir <dir> [options]

Options:
  --flow-dir <dir>       Directory containing *.json flow files (required)
  --out-dir <dir>        Output directory for logs/summary/state (required)
  --workers <n>          Concurrent workers (default: 3)
  --operation <mode>     produce|treat (default: produce)
  --python-bin <path>    Python executable for child scripts
  --max-attempts <n>     Max attempts per flow (default: 3)
  -h, --help             Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --flow-dir)
      FLOW_DIR="$2"; shift 2 ;;
    --out-dir)
      OUT_DIR="$2"; shift 2 ;;
    --workers)
      WORKERS="$2"; shift 2 ;;
    --operation)
      OPERATION="$2"; shift 2 ;;
    --python-bin)
      PYTHON_BIN="$2"; shift 2 ;;
    --max-attempts)
      MAX_ATTEMPTS="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 2 ;;
  esac
done

[[ -n "${FLOW_DIR}" ]] || { echo "Missing --flow-dir" >&2; exit 2; }
[[ -n "${OUT_DIR}" ]] || { echo "Missing --out-dir" >&2; exit 2; }
[[ -d "${FLOW_DIR}" ]] || { echo "Flow dir not found: ${FLOW_DIR}" >&2; exit 2; }

mkdir -p "${OUT_DIR}"
STATE_PATH="${OUT_DIR}/batch_state.json"
LOG_DIR="${OUT_DIR}/batch_logs"

exec "${PYTHON_BIN}" "${SKILL_DIR}/scripts/origin/process_from_flow_batch_runner.py" \
  --flow-dir "${FLOW_DIR}" \
  --state "${STATE_PATH}" \
  --log-dir "${LOG_DIR}" \
  --workers "${WORKERS}" \
  --operation "${OPERATION}" \
  --max-attempts "${MAX_ATTEMPTS}" \
  --python-bin "${PYTHON_BIN}"
