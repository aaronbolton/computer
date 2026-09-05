#!/bin/bash
# Same as dev.sh, but rebuilds the frontend first.
#
# dev.sh only starts the backend, and the backend serves the prebuilt static
# files in cptr/frontend/build. That directory is gitignored, so a fresh clone
# has no frontend at all, and --reload only restarts Python -- edits to Svelte,
# CSS or TS never show up until the frontend is rebuilt. This script does that
# rebuild, then hands off to the same server invocation dev.sh uses.
#
# While actively working on the UI, prefer the two-terminal loop instead:
#   ./dev.sh                          # backend on :9741
#   cd cptr/frontend && npm run dev   # vite, proxies /api to the backend
# That hot-reloads on save rather than rebuilding each time.

set -e
set -o pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
export CPTR_DATA_DIR="${CPTR_DATA_DIR:-$ROOT/.cptr}"

if ! command -v npm >/dev/null 2>&1; then
	echo "dev2.sh: npm not found; install Node.js to build the frontend" >&2
	exit 1
fi

cd "$ROOT/cptr/frontend"

# Reinstall when the lockfile is newer than what's installed, so switching
# branches picks up dependency changes without a manual npm ci.
if [ ! -d node_modules ] || [ package-lock.json -nt node_modules ]; then
	echo "==> Installing frontend dependencies"
	npm ci
fi

echo "==> Building frontend"
npm run build

cd "$ROOT"
echo "==> Starting cptr"
exec uv run --extra all cptr run --reload --host 0.0.0.0 --port 9741 --headless "$@"
