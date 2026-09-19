"""后端基本冒烟检查：导入应用并直接调用生成接口，无需启动服务。

用法: .venv/bin/python smoke_check.py
"""
from app.main import app, GenerateRequest, generate_and_analyze

MODULATIONS = ("AM", "FM", "BPSK", "QPSK", "16QAM")


def main() -> None:
    paths = {route.path for route in app.routes}
    assert "/api/generate" in paths, "缺少 /api/generate 路由"

    for mod in MODULATIONS:
        req = GenerateRequest(modulation=mod, samples=2048, snr=20.0)
        result = generate_and_analyze(req)
        spectrum = result["spectrum"]
        assert len(spectrum["frequencies"]) == len(spectrum["magnitudes"]) == 2048
        assert result["waterfall"], f"{mod}: 瀑布图数据为空"
        assert result["constellation"], f"{mod}: 星座图数据为空"
        assert result["modulation"]["type"] in MODULATIONS

    print("smoke check ok: 路由注册正常，5 种调制的生成/频谱/瀑布图/星座图/识别接口均正常")


if __name__ == "__main__":
    main()
