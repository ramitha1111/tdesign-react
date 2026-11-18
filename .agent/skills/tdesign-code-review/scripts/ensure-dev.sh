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

# 后台启动并等待端口就绪
LOG_FILE="/tmp/tdesign-dev-${$}.log"
nohup env BROWSER=none pnpm --dir "${ROOT}" dev >"${LOG_FILE}" 2>&1 </dev/null &
DEV_PID=$!

for _ in $(seq 1 60); do
  INFO="$(get_dev_info)"
  if [[ -n "${INFO}" ]]; then
    PORT="${INFO##* }"
    echo "${PORT}"
    exit 0
  fi
  if ! kill -0 "${DEV_PID}" 2>/dev/null; then
    echo "[ensure-dev] dev 服务启动失败，日志如下：" >&2
    tail -n 30 "${LOG_FILE}" >&2 || true
    exit 1
  fi
  sleep 1
done

echo "[ensure-dev] 等待 dev 服务端口超时，日志路径：${LOG_FILE}" >&2
exit 1
