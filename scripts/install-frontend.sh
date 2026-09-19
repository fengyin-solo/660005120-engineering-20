#!/usr/bin/env bash
# 前端依赖安装：严格按 package-lock.json 安装（npm ci，不用 npm install）。
# 在 overlayfs 等文件系统上，npm ci 清理 node_modules 时可能偶发 ENOTEMPTY，
# 失败后清掉残留重试一次即可；锁文件本身的问题（如与 package.json 不一致）重试后仍会如实报错。
set -u
cd "$(dirname "$0")/../frontend"

for attempt in 1 2; do
  if npm ci --no-audit --no-fund; then
    exit 0
  fi
  echo "npm ci 第 $attempt 次失败，清理 node_modules 后重试"
  rm -rf node_modules 2>/dev/null || rm -rf node_modules
done

echo "npm ci 重试后仍失败"
exit 1
