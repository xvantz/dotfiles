#!/usr/bin/env python3
"""Тесты обёртки ocr-review. Ни сети, ни ключа: ocr подменяется заглушкой."""
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

SKILL = Path(__file__).resolve().parents[2]
TOOL = SKILL / "scripts" / "ocr-review"
FAILED = []


def sh(cmd, cwd=None, env=None):
    e = dict(os.environ)
    e.update(env or {})
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, env=e)


def check(name, cond, detail=""):
    print(("  ok   " if cond else "  FAIL ") + name + ("" if cond else f"  {detail}"))
    if not cond:
        FAILED.append(name)


def make_repo(path: Path, kind="nestjs"):
    path.mkdir(parents=True, exist_ok=True)
    subprocess.run(["git", "init", "-q"], cwd=path, check=True)
    subprocess.run(["git", "config", "user.email", "t@t"], cwd=path, check=True)
    subprocess.run(["git", "config", "user.name", "t"], cwd=path, check=True)
    if kind == "nestjs":
        (path / "package.json").write_text(json.dumps({"name": "x", "dependencies": {"@nestjs/core": "1"}}))
        src = path / "apps/api/src/Domain"
        src.mkdir(parents=True, exist_ok=True)
        (src / "Service.ts").write_text("export const x = 1;\n")
        (src / "Service.spec.ts").write_text("it('x', () => {});\n")
    else:
        (path / "go.mod").write_text("module x\n")
        (path / "main.go").write_text("package main\n")
    subprocess.run(["git", "add", "-A"], cwd=path, check=True)
    subprocess.run(["git", "commit", "-qm", "init"], cwd=path, check=True)
    return path


FAKE_OK = """#!/usr/bin/env python3
import json, sys
args = sys.argv[1:]
out = args[args.index("--output") + 1] if "--output" in args else None
doc = {"status": "success",
 "summary": {"files_reviewed": 2, "comments": 2, "total_tokens": 1000, "elapsed": "9s"},
 "comments": [
   {"path": "apps/api/src/Domain/Service.ts", "content": "Сумма на number.",
    "start_line": 7, "end_line": 9, "severity": "high", "suggestion_code": "amount.add(x)"},
   {"path": "apps/api/src/Domain/Service.ts", "content": "Опечатка.", "start_line": 20, "severity": "low"}],
 "session_id": "ses_test"}
if out:
    open(out, "w").write(json.dumps(doc))
print("stub ok")
"""

FAKE_BUDGET = """#!/usr/bin/env python3
import json, sys
args = sys.argv[1:]
out = args[args.index("--output") + 1] if "--output" in args else None
doc = {"status": "partial",
 "summary": {"files_reviewed": 3, "comments": 0, "total_tokens": 900000, "budget_exceeded": True},
 "comments": [],
 "warnings": [{"file": "a.ts,b.ts", "message": "reached the aggregate token budget", "type": "review_limit_reached"}]}
if out:
    open(out, "w").write(json.dumps(doc))
print("stub ok")
"""

FAKE_WRITES = """#!/usr/bin/env python3
import pathlib
pathlib.Path("apps/api/src/Domain/Service.ts").write_text("HACKED")
print("stub wrote")
"""


def stub(path: Path, body: str) -> Path:
    path.write_text(body)
    path.chmod(0o755)
    return path


def main() -> int:
    tmp = Path(tempfile.mkdtemp(prefix="ocr-review-tests-"))
    private = tmp / "private"
    (private / "projects").mkdir(parents=True)
    (private / "projects" / "demo.json").write_text(json.dumps({
        "rules": [{"path": "apps/api/**/*.ts", "rule": "Демо-правило проекта.", "merge_system_rule": False}]}))
    stubs = tmp / "stubs"
    stubs.mkdir()
    ok_bin = stub(stubs / "fake-ok", FAKE_OK)
    writes_bin = stub(stubs / "fake-writes", FAKE_WRITES)

    env = {"OCR_REVIEW_PRIVATE": str(private), "OCR_REVIEW_HOME": str(tmp / "cache")}
    repo = make_repo(tmp / "nestjs-repo")
    go_repo = make_repo(tmp / "go-repo", kind="go")

    print("1. стек, профиль, слои правил")
    r = sh([str(TOOL), "--repo", str(repo), "--rules-only"], cwd=repo, env=env)
    check("exit 0", r.returncode == 0, r.stderr)
    check("стек nestjs", "typescript/nest-typeorm" in r.stdout, r.stdout)
    check("common в слоях", "common" in r.stdout, r.stdout)

    (private / "repos.json").write_text(json.dumps({"repos": {str(repo): {"project": "demo"}}}))
    r = sh([str(TOOL), "--repo", str(repo), "--rules-only"], cwd=repo, env=env)
    check("профиль из repos.json подхвачен", "project:demo (private)" in r.stdout, r.stdout)

    r = sh([str(TOOL), "--repo", str(repo), "--doctor"], cwd=repo, env=env)
    check("doctor exit 0 без leak-terms", r.returncode == 0, r.stdout + r.stderr)
    check("doctor показывает приватный каталог", str(private) in r.stdout, r.stdout)

    r = sh([str(TOOL), "--repo", str(go_repo), "--rules-only"], cwd=go_repo, env=env)
    check("стек go", "go/base" in r.stdout, r.stdout)

    print("1b. правило про тесты не съедается широким правилом проекта")
    composed = json.loads(sorted((tmp / "cache").glob("composed-*.json"))[0].read_text())
    first_path = composed["rules"][0]["path"]
    check("первым идёт тестовое правило", "spec" in first_path or "test" in first_path, first_path)

    r = sh([str(TOOL), "--repo", str(repo), "--project", "nope", "--rules-only"], cwd=repo, env=env)
    check("отсутствующий набор = предупреждение, не падение", r.returncode == 0
          and "не найден" in r.stderr, r.stderr)

    print("1c. provider.env из приватного каталога доходит до ocr")
    (private / "provider.env").write_text("OCR_LLM_TOKEN=abc123\nOCR_LLM_MODEL=demo-model\n")
    env_stub = stub(stubs / "fake-env", """#!/usr/bin/env python3
import os
open(os.environ["OUT"], "w").write(os.environ.get("OCR_LLM_TOKEN", "missing")
                                   + "|" + os.environ.get("OCR_LLM_MODEL", "missing"))
print("ok")
""")
    token_out = tmp / "token.txt"
    sh([str(TOOL), "--repo", str(repo)], cwd=repo,
       env={**env, "OCR_REVIEW_OCR_BIN": str(env_stub), "OUT": str(token_out),
            "OCR_LLM_TOKEN": "", "OCR_LLM_MODEL": ""})
    got = token_out.read_text() if token_out.is_file() else "file-missing"
    check("токен и модель из provider.env", got == "abc123|demo-model", got)
    (private / "provider.env").unlink()

    print("2. findings, gate")
    r = sh([str(TOOL), "--repo", str(repo), "--mode", "fix"], cwd=repo,
           env={**env, "OCR_REVIEW_OCR_BIN": str(ok_bin)})
    check("exit 0", r.returncode == 0, r.stderr)
    check("файл:строки", "Service.ts:7-9" in r.stdout, r.stdout)
    check("severity", "[high]" in r.stdout, r.stdout)
    check("suggestion", "amount.add(x)" in r.stdout, r.stdout)
    check("session", "ses_test" in r.stdout, r.stdout)

    r = sh([str(TOOL), "--repo", str(repo), "--gate"], cwd=repo,
           env={**env, "OCR_REVIEW_OCR_BIN": str(ok_bin)})
    check("gate ловит high (rc=1)", r.returncode == 1, f"rc={r.returncode}")
    r = sh([str(TOOL), "--repo", str(repo), "--gate", "--gate-severity", "critical"], cwd=repo,
           env={**env, "OCR_REVIEW_OCR_BIN": str(ok_bin)})
    check("gate пропускает ниже critical (rc=0)", r.returncode == 0, f"rc={r.returncode}")

    print("2b. исчерпанный бюджет виден в выводе")
    budget_bin = stub(stubs / "fake-budget", FAKE_BUDGET)
    r = sh([str(TOOL), "--repo", str(repo), "--mode", "fix"], cwd=repo,
           env={**env, "OCR_REVIEW_OCR_BIN": str(budget_bin)})
    check("предупреждение про бюджет", "бюджет исчерпан" in r.stderr, r.stderr)
    check("warning как dict печатается", "aggregate token budget" in r.stderr, r.stderr)

    print("3. audit-режим запрещает правки")
    r = sh([str(TOOL), "--repo", str(repo), "--mode", "audit"], cwd=repo,
           env={**env, "OCR_REVIEW_OCR_BIN": str(writes_bin)})
    check("audit violation (rc=3)", r.returncode == 3, f"rc={r.returncode}")
    check("сообщение AUDIT VIOLATION", "AUDIT VIOLATION" in r.stdout + r.stderr, r.stdout)
    subprocess.run(["git", "checkout", "--", "."], cwd=repo, check=True)
    r = sh([str(TOOL), "--repo", str(repo), "--mode", "fix"], cwd=repo,
           env={**env, "OCR_REVIEW_OCR_BIN": str(writes_bin)})
    check("fix не считает правку нарушением (rc=0)", r.returncode == 0, f"rc={r.returncode}")

    print("4. проверка утечек в публичном дереве")
    # термины собираем из кусков: иначе сам тест станет утечкой в своём же дереве
    leak_term = "secret" + "name"
    probe_term = "zzz-" + "internal-" + "alpha"
    (private / "leak-terms.txt").write_text(f"{leak_term}\n{probe_term}\n")
    r = sh([str(TOOL), "--repo", str(repo), "--doctor"], cwd=repo, env=env)
    check("чистое дерево -> rc=0", r.returncode == 0, r.stdout)

    marker = SKILL / "assets" / "rules" / "zz-leak-probe.json"
    marker.write_text(json.dumps({"rules": [{"path": "**/*", "rule": leak_term.capitalize() + " внутри"}]}))
    try:
        r = sh([str(TOOL), "--repo", str(repo), "--doctor"], cwd=repo, env=env)
        check("утечка найдена (rc=4)", r.returncode == 4, f"rc={r.returncode} {r.stdout}")
        check("утечка названа", "zz-leak-probe.json" in r.stdout, r.stdout)
    finally:
        marker.unlink()

    print("5. проверка утечек покрывает весь каталог скилла, не только правила")
    probe = SKILL / "scripts" / "zz-leak-probe.md"
    probe.write_text(f"внутри {probe_term}\n")
    try:
        r = sh([str(TOOL), "--repo", str(repo), "--doctor"], cwd=repo, env=env)
        check("утечка вне assets/rules найдена", r.returncode == 4, f"rc={r.returncode}")
        check("файл-провокатор назван", "zz-leak-probe.md" in r.stdout, r.stdout)
    finally:
        probe.unlink()

    print("6. leakscan: публичная поверхность")
    scan = SKILL / "scripts" / "leakscan"
    leak_repo = tmp / "leak-repo"
    leak_repo.mkdir()
    subprocess.run(["git", "init", "-q"], cwd=leak_repo, check=True)
    subprocess.run(["git", "config", "user.email", "t@t"], cwd=leak_repo, check=True)
    subprocess.run(["git", "config", "user.name", "t"], cwd=leak_repo, check=True)
    (leak_repo / "readme.md").write_text("нейтральный текст\n")
    subprocess.run(["git", "add", "-A"], cwd=leak_repo, check=True)
    subprocess.run(["git", "commit", "-qm", "init"], cwd=leak_repo, check=True)

    scan_env = {**env, "OCR_REVIEW_PRIVATE": str(private)}
    r = sh([str(scan), "--staged"], cwd=leak_repo, env=scan_env)
    check("чистый индекс -> rc=0", r.returncode == 0, r.stderr)

    (leak_repo / "notes.md").write_text(f"тут {leak_term} и всё\n")
    subprocess.run(["git", "add", "-A"], cwd=leak_repo, check=True)
    r = sh([str(scan), "--staged"], cwd=leak_repo, env=scan_env)
    check("термин в индексе -> rc=4", r.returncode == 4, f"rc={r.returncode} {r.stdout}")
    check("термин в выводе замаскирован", leak_term not in (r.stdout + r.stderr), r.stderr)

    (leak_repo / "notes.md").unlink()
    subprocess.run(["git", "add", "-A"], cwd=leak_repo, check=True)
    subprocess.run(["git", "commit", "--allow-empty", "-qm", f"fix: {leak_term} в сообщении"],
                   cwd=leak_repo, check=True)
    r = sh([str(scan), "--range", "HEAD~1..HEAD"], cwd=leak_repo, env=scan_env)
    check("термин в коммит-сообщении -> rc=4", r.returncode == 4, f"rc={r.returncode}")

    r = subprocess.run([str(scan), "--text", "-"], cwd=leak_repo, capture_output=True, text=True,
                       env=scan_env, input=f"тело PR упоминает {probe_term}")
    check("термин в теле PR -> rc=4", r.returncode == 4, f"rc={r.returncode}")

    short_term = "q" + "7"
    (private / "leak-terms.txt").write_text(f"{leak_term}\n{probe_term}\n{short_term}\n")
    r = subprocess.run([str(scan), "--text", "-"], cwd=leak_repo, capture_output=True, text=True,
                       env=scan_env, input="строка aq7b не должна считаться совпадением")
    check("короткий термин не ловит подстроку", r.returncode == 0, r.stderr)
    r = subprocess.run([str(scan), "--text", "-"], cwd=leak_repo, capture_output=True, text=True,
                       env=scan_env, input=f"а тут {short_term} отдельным словом")
    check("короткий термин по границе ловится", r.returncode == 4, r.stderr)

    empty_private = tmp / "empty-private"
    empty_private.mkdir()
    r = sh([str(scan), "--staged", "--require-terms"], cwd=leak_repo,
           env={**env, "OCR_REVIEW_PRIVATE": str(empty_private)})
    check("без терминов fail-closed -> rc=5", r.returncode == 5, f"rc={r.returncode}")

    shutil.rmtree(tmp, ignore_errors=True)
    print()
    if FAILED:
        print(f"ПРОВАЛЕНО {len(FAILED)}: {FAILED}")
        return 1
    print("все тесты прошли")
    return 0


if __name__ == "__main__":
    sys.exit(main())
