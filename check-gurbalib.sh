#!/bin/bash
# Quick preflight checks before ./bin/startmud
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

echo "Checking gurbalib install in: $ROOT"
echo

fail=0
warn() { echo "WARN: $*"; }
err() { echo "ERROR: $*"; fail=1; }

[ -x bin/dgd ] || err "bin/dgd missing or not executable (build DGD with: make -C src/dgd/src CXX=g++)"
[ -f mud.dgd ] || err "mud.dgd missing (cp mud.dgd.examp mud.dgd)"
[ -d tmp ] || err "tmp/ missing (run: perl scripts/create_data_dirs)"
[ -d lib/logs ] || err "lib/logs/ missing (run: perl scripts/create_data_dirs)"
[ -f lib/kernel/include/local_config.h ] || err "local_config.h missing (cp lib/kernel/include/local_config.h.default lib/kernel/include/local_config.h)"

if [ -f mud.dgd ]; then
  libdir="$(awk -F'"' '/^[[:space:]]*directory/ { print $2; exit }' mud.dgd)"
  if [ -z "$libdir" ]; then
    err "could not read directory= from mud.dgd"
  elif [ ! -d "$libdir" ]; then
    err "mud.dgd directory does not exist: $libdir"
  elif [[ "$libdir" != /* ]]; then
    err "mud.dgd directory must be an absolute path, got: $libdir"
  elif [ "$libdir" != "$ROOT/lib/" ] && [ "$libdir" != "$ROOT/lib" ]; then
    warn "mud.dgd directory is $libdir (expected $ROOT/lib/)"
  fi
fi

if command -v ss >/dev/null 2>&1; then
  if ss -tln | grep -q ':4000 '; then
    warn "port 4000 is already in use (stop old mud: pkill -f 'bin/dgd')"
  fi
fi

if [ -f dump ]; then
  warn "dump file exists; startmud will restore from it (remove with: rm -f dump)"
fi

if [ -f lib/logs/gurba-driver.log ]; then
  fatal="$(grep -m1 'Fatal error:' lib/logs/gurba-driver.log || true)"
  if [ -n "$fatal" ]; then
    echo
    echo "Last fatal error from log:"
    echo "  $fatal"
  fi
fi

echo
if [ "$fail" -ne 0 ]; then
  echo "Fix the errors above, then run ./bin/startmud again."
  exit 1
fi

echo "Looks good. Start with: ./bin/startmud"
echo "Then check: tail -f lib/logs/gurba-driver.log"
