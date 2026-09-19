"""后端冒烟测试：不启动真实服务器，直接用 TestClient 打一遍核心接口。

运行方式：
    make smoke-backend            # 推荐，仓库根目录下
    或在 backend/ 目录下： PYTHONPATH=. .venv/bin/python tests/smoke_test.py
"""
from fastapi.testclient import TestClient

from app.main import app, MODULATION_TYPES


def main() -> None:
    client = TestClient(app)

    for mod in MODULATION_TYPES:
        resp = client.post(
            "/api/generate",
            json={"modulation": mod, "samples": 512, "snr": 20.0},
        )
        assert resp.status_code == 200, f"{mod}: HTTP {resp.status_code}: {resp.text}"
        data = resp.json()

        spectrum = data["spectrum"]
        assert len(spectrum["frequencies"]) == 512, f"{mod}: 频谱点数异常"
        assert len(spectrum["magnitudes"]) == 512, f"{mod}: 频谱幅度点数异常"

        assert data["waterfall"], f"{mod}: 瀑布图数据为空"
        assert data["constellation"], f"{mod}: 星座图数据为空"

        modulation = data["modulation"]
        assert modulation["type"] in MODULATION_TYPES, f"{mod}: 识别结果非法"
        assert 0.0 <= modulation["confidence"] <= 1.0, f"{mod}: 置信度越界"

    print(f"smoke OK: /api/generate x {len(MODULATION_TYPES)} 种调制方式全部通过")


if __name__ == "__main__":
    main()
