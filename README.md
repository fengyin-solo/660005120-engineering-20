# 射频信号频谱分析与调制识别仪

基于Vue 3 + FastAPI的射频信号分析工具，支持IQ数据导入、FFT频谱/瀑布图/星座图三面板可视化、自动调制分类识别。

## 目标用户
业余无线电爱好者、信号工程师、通信专业学生

## 技术栈
- 前端: Vue 3 + TypeScript + Vite + Pinia + Element Plus + ECharts
- 后端: Python FastAPI + NumPy + SciPy

## 核心功能
1. IQ基带数据CSV文件导入，支持采样率/中心频率参数配置
2. FFT频谱图(ECharts)、瀑布图(Canvas)与星座图(Canvas)三面板同步
3. AM/FM/BPSK/QPSK/16QAM五种调制模式自动识别分类
4. 信号参数估算(符号速率、载波频率偏移)
5. 频谱分析结果JSON/PNG导出

## 依赖版本锁定
为保证各环境装出的版本一致，两端依赖均已锁定：
- 前端：`frontend/package-lock.json` 已提交仓库，安装统一用 `npm ci`（不要用 `npm install`，否则会绕过锁文件）
- 后端：`backend/requirements.txt` 固定直接依赖，`backend/requirements-dev.txt` 固定检查工具依赖，`backend/requirements-lock.txt` 冻结全部传递依赖，安装以锁文件为准

升级依赖时：前端改 `package.json` 后运行 `npm install` 重新生成锁文件并提交；后端改 `requirements*.txt` 后在虚拟环境中运行 `pip freeze | sort > requirements-lock.txt` 并提交。

## 统一入口（Make）
```bash
make all              # 完整流程：安装依赖 -> 基本检查 -> 构建
make install          # 只装依赖（前端 npm ci + 后端 venv/pip，按锁文件安装）
make check            # 基本检查（前端类型检查、后端编译/导入检查、API 冒烟测试）
make build            # 构建（前端生产包，输出 frontend/dist）
make clean            # 删除全部生成物（node_modules/dist/.venv/__pycache__）
```
每一步都是独立目标，失败后可单独重跑：`make install-frontend`、`make install-backend`、`make check-frontend`、`make check-backend`、`make smoke-backend`、`make build-frontend`。

每步默认超时 600 秒，超时或失败时日志会标明卡在哪一步；可用 `STEP_TIMEOUT` 调整，例如 `make build STEP_TIMEOUT=1200`。

重复执行安全：npm/pip 缓存与已建好的 `node_modules`/`.venv` 会被复用，所有生成物都在 `.gitignore` 覆盖的标准位置，不留残留。

## 本地启动（原有方式不变）
```bash
# 后端（backend/ 目录下，先激活 .venv）
uvicorn app.main:app --reload        # http://localhost:8000

# 前端（frontend/ 目录下）
npm run dev                          # http://localhost:3000，/api 代理到 8000
```
也可以使用等价的便利入口：`make dev-backend`、`make dev-frontend`。