# 统一构建与检查入口
#
# 每个步骤开始时都会打印带时间戳的步骤名，构建超时时看最后一行即可定位卡在哪一步。
# 依赖安装按锁文件增量执行（锁文件未变化时自动跳过），重复执行不产生残留。
#
# 常用：
#   make            # 依赖安装 + 基本检查 + 构建（默认）
#   make check      # 只跑基本检查（后端编译+冒烟，前端类型检查）
#   make build      # 只构建
#   make clean      # 清理构建产物与缓存（保留已装依赖）
#   make distclean  # 连 .venv 和 node_modules 一起删掉
#
# 单步重跑：make deps-backend / deps-frontend / check-backend / check-frontend / build-frontend
# 本地启动：make dev-backend / dev-frontend（等价于原有的 uvicorn / npm run dev 手动启动）

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

BACKEND        := $(CURDIR)/backend
FRONTEND       := $(CURDIR)/frontend
VENV           := $(BACKEND)/.venv
VENV_PY        := $(VENV)/bin/python
NODE_MODULES   := $(FRONTEND)/node_modules

# 安装完成标记：放在 .venv / node_modules 内部，随 distclean 一起清除
BACKEND_STAMP  := $(VENV)/.deps.stamp
FRONTEND_STAMP := $(NODE_MODULES)/.deps.stamp

.DEFAULT_GOAL := all
.PHONY: all deps check build clean distclean help \
        deps-backend deps-frontend check-backend check-frontend \
        build-backend build-frontend dev-backend dev-frontend

# 步骤横幅：时间戳 + 步骤名
define STEP
	@echo "==> [$$(date +%H:%M:%S)] $(1)"
endef

all: check build ## 依赖安装 + 基本检查 + 构建（默认目标）

deps: deps-backend deps-frontend ## 安装两端依赖（按锁文件，增量）

check: check-backend check-frontend ## 基本检查

build: build-backend build-frontend ## 构建

# ---------------- 依赖 ----------------

deps-backend: $(BACKEND_STAMP) ## 安装后端依赖（requirements-lock.txt 全量锁定）

$(BACKEND_STAMP): $(BACKEND)/requirements-lock.txt
	$(STEP) "deps-backend: 准备 Python 虚拟环境 ($(VENV))"
	@if [ -d $(VENV) ] && ! $(VENV_PY) --version >/dev/null 2>&1; then \
		echo "    已有 .venv 无法运行（可能来自其他系统），自动重建"; \
		rm -rf $(VENV); \
	fi
	@if [ ! -x $(VENV_PY) ]; then \
		python3 -m venv $(VENV) || { \
			echo "    ensurepip 不可用，改用 get-pip 引导"; \
			rm -rf $(VENV); \
			python3 -m venv --without-pip $(VENV); \
			tmp=$$(mktemp); \
			curl -fsSL https://bootstrap.pypa.io/get-pip.py -o $$tmp; \
			$(VENV_PY) $$tmp --quiet; \
			rm -f $$tmp; \
		}; \
	fi
	$(STEP) "deps-backend: 按 requirements-lock.txt 安装"
	@$(VENV_PY) -m pip install --quiet -r $(BACKEND)/requirements-lock.txt
	@touch $@

deps-frontend: $(FRONTEND_STAMP) ## 安装前端依赖（npm ci 严格按 package-lock.json）

$(FRONTEND_STAMP): $(FRONTEND)/package-lock.json
	$(STEP) "deps-frontend: npm ci（严格按 package-lock 安装）"
	@cd $(FRONTEND) && npm ci --no-audit --no-fund
	@touch $@

# ---------------- 检查 ----------------

check-backend: deps-backend ## 后端检查：编译 + 冒烟
	$(STEP) "check-backend: 编译检查 (compileall)"
	@cd $(BACKEND) && $(VENV)/bin/python -m compileall -q app smoke_check.py
	$(STEP) "check-backend: 冒烟检查 (smoke_check.py)"
	@cd $(BACKEND) && $(VENV)/bin/python smoke_check.py

check-frontend: deps-frontend ## 前端检查：vue-tsc 类型检查
	$(STEP) "check-frontend: vue-tsc 类型检查"
	@cd $(FRONTEND) && npm run typecheck

# ---------------- 构建 ----------------

build-backend: deps-backend ## 后端构建（字节码编译）
	$(STEP) "build-backend: 字节码编译"
	@cd $(BACKEND) && $(VENV)/bin/python -m compileall -q app

build-frontend: deps-frontend ## 前端构建（产物在 frontend/dist）
	$(STEP) "build-frontend: vite build"
	@cd $(FRONTEND) && npm run build

# ---------------- 本地启动（原有方式的等价封装） ----------------

dev-backend: deps-backend ## 启动后端开发服务（等价于 .venv/bin/uvicorn app.main:app --reload）
	$(STEP) "dev-backend: uvicorn :8000"
	@cd $(BACKEND) && $(VENV)/bin/uvicorn app.main:app --reload --port 8000

dev-frontend: deps-frontend ## 启动前端开发服务（等价于 npm run dev）
	$(STEP) "dev-frontend: vite :3000"
	@cd $(FRONTEND) && npm run dev

# ---------------- 清理 ----------------

clean: ## 清理构建产物与缓存（保留 .venv / node_modules）
	$(STEP) "clean: 删除 dist / __pycache__ / tsbuildinfo"
	@rm -rf $(FRONTEND)/dist
	@find $(BACKEND) -path $(VENV) -prune -o -type d -name __pycache__ -exec rm -rf {} +
	@find $(FRONTEND) -path $(NODE_MODULES) -prune -o -name '*.tsbuildinfo' -exec rm -f {} +

distclean: clean ## 连同 .venv 和 node_modules 一起删除
	$(STEP) "distclean: 删除 $(VENV) 与 $(NODE_MODULES)"
	@rm -rf $(VENV) $(NODE_MODULES)

help: ## 显示本帮助
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-16s %s\n", $$1, $$2}'
