#!/usr/bin/env bash
# 步骤执行器：给每一步加上开始/结束日志和超时控制。
# 超时或失败时能明确看到卡在哪一步；每一步对应 Makefile 里的同名目标，可单独重跑。
#
# 用法: scripts/step.sh <步骤名> <超时秒数> <命令...>
set -u

name="$1"; shift
timeout_s="$1"; shift

echo "==> [$name] 开始 $(date '+%H:%M:%S')"
start=$(date +%s)

timeout "$timeout_s" "$@"
code=$?

elapsed=$(( $(date +%s) - start ))
if [ "$code" -eq 124 ]; then
  echo "==> [$name] 超时（>${timeout_s}s），卡住的就是这一步"
  exit 124
fi
if [ "$code" -ne 0 ]; then
  echo "==> [$name] 失败（退出码 $code，耗时 ${elapsed}s）"
  exit "$code"
fi
echo "==> [$name] 完成（耗时 ${elapsed}s）"
