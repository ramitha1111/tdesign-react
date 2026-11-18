#!/usr/bin/env bash

# 启动或复用当前仓库的 pnpm dev 服务

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
SITE_DIR="${ROOT}/packages/tdesign-react/site"

get_dev_info() {
  local pids
  pids="$(lsof -t -a -c node -d cwd -- "${SITE_DIR}" 2>/dev/null | paste -sd, - || true)"
  if [[ -z "${pids}" ]]; then
    return 0
  fi
  lsof -nP -a -iTCP -sTCP:LISTEN -Fpn -p "${pids}" 2>/dev/null | awk '
    /^p/ { pid = substr($0, 2) }
    /^n.*:/ {
      sub(/^n.*:/, "", $0)
      if (pid != "" && $0 != "") {
        print pid " " $0
        exit
      }
    }
  ' || true
}

INFO="$(get_dev_info)"
if [[ -n "${INFO}" ]]; then
  PID="${INFO%% *}"
  PORT="${INFO##* }"
  # 已有运行中的服务，直接复用
  echo "${PORT}"
  exit 0
fi

# 启动
exec BROWSER=none pnpm --dir "${ROOT}" dev
