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

## 构建与检查（统一入口）

根目录 `Makefile` 是构建与检查的统一入口，每个步骤开始都会打印带时间戳的步骤名，构建超时时看最后一行即可定位卡在哪一步：

```bash
make              # 依赖安装 + 基本检查 + 构建（默认）
make check        # 基本检查：后端编译+冒烟，前端 vue-tsc 类型检查
make build        # 构建（前端产物在 frontend/dist）
make clean        # 清理构建产物与缓存（保留已装依赖）
make distclean    # 连同 backend/.venv 和 frontend/node_modules 一起删除
```

任何一步失败都可单独重跑：`make deps-backend` / `deps-frontend` / `check-backend` / `check-frontend` / `build-frontend`。依赖按锁文件增量安装，已安装且锁文件未变化时自动跳过，重复执行不留残留。

## 本地启动（原有方式不变）

```bash
# 后端（或 make dev-backend）
cd backend && .venv/bin/uvicorn app.main:app --reload
# 前端（或 make dev-frontend）
cd frontend && npm run dev
```

## 依赖版本管理

- 前端：`package-lock.json` 已纳入版本管理，安装请用 `npm ci`（`make deps-frontend` 即如此）；变更依赖后把更新后的 lock 文件一起提交。
- 后端：`requirements.txt` 只列直接依赖，`requirements-lock.txt` 是含传递依赖的全量锁定，构建以锁定文件为准。变更直接依赖后重新生成并验证：
  ```bash
  cd backend && .venv/bin/pip install -r requirements.txt \
    && .venv/bin/pip freeze --exclude pip --exclude setuptools --exclude wheel > requirements-lock.txt
  make check-backend   # 验证后再提交
  ```