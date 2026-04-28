
import importlib
from pathlib import Path

def test_backend_modules_import_with_test_fakes(fake_db):
    backend_dir = Path(__file__).resolve().parents[3]
    skipped = {"app.py", "config.py"}
    modules = []

    for path in backend_dir.rglob("*.py"):
        relative = path.relative_to(backend_dir)
        if relative.parts[0] == "tests" or relative.as_posix() in skipped:
            continue
        modules.append(".".join(relative.with_suffix("").parts))

    failures = {}
    for module_name in sorted(modules):
        try:
            importlib.import_module(module_name)
        except Exception as exc:
            failures[module_name] = f"{type(exc).__name__}: {exc}"

    assert failures == {}
