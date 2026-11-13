"""Собирает zip мода: dist/for-<версия игры>/<имя>_<версия>.zip (внутри папка <имя>_<версия>/).
Запуск: python tools/build.py"""
import json, pathlib, zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent


def build():
    mods = [p for p in (ROOT / "src").iterdir() if (p / "info.json").is_file()]
    if len(mods) != 1:
        raise SystemExit(f"В src ожидается ровно один мод, найдено: {len(mods)}")
    src = mods[0]
    info = json.loads((src / "info.json").read_text(encoding="utf-8"))
    name, ver, game = info["name"], info["version"], info["factorio_version"]
    out_dir = ROOT / "dist" / f"for-{game}"
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / f"{name}_{ver}.zip"
    if out.exists():
        out.unlink()
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for p in sorted(src.rglob("*")):
            if p.is_file():
                z.write(p, f"{name}_{ver}/{p.relative_to(src).as_posix()}")
    return name, ver, out


if __name__ == "__main__":
    print(build()[2])
