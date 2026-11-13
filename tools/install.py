"""Собирает мод и кладёт его в папку mods игры, убрав старые zip этого же мода.
Не ставит, если игра запущена (замена zip в запущенной игре ломает загрузку).
Запуск: python tools/install.py [--mods-dir ПАПКА]  (по умолчанию %APPDATA%\\Factorio\\mods)"""
import argparse, hashlib, os, pathlib, shutil, subprocess, sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from build import build


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()[:12]


def game_running():
    # вывод tasklist на русской Windows не utf-8: читаем байты и ищем имя процесса. Если проверить не удалось,
    # считаем, что игра МОЖЕТ быть запущена (безопаснее не копировать)
    try:
        out = subprocess.run(["tasklist", "/FI", "IMAGENAME eq factorio.exe"], capture_output=True, check=True).stdout
        return b"factorio.exe" in out.lower()
    except Exception:
        return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mods-dir", default=os.path.join(os.environ.get("APPDATA", ""), "Factorio", "mods"))
    ap.add_argument("--force-running", action="store_true", help="только для тестов")
    a = ap.parse_args()
    mods = pathlib.Path(a.mods_dir)
    if not mods.is_dir():
        sys.exit(f"Нет папки модов: {mods}")
    if game_running() and not a.force_running:
        sys.exit("Игра запущена: ничего не копирую. Закрой Factorio и запусти снова.")
    name, ver, zipfile_ = build()
    for old in mods.glob(f"{name}_*.zip"):
        old.unlink()
        print("удалён старый:", old.name)
    dst = mods / zipfile_.name
    shutil.copy2(zipfile_, dst)
    ok = sha(zipfile_) == sha(dst)
    print(("установлено: " if ok else "ОШИБКА КОПИРОВАНИЯ: ") + str(dst), sha(dst))
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
