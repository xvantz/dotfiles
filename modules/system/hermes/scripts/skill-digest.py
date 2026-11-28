#!/usr/bin/env python3
"""skill-digest - еженедельный разбор библиотеки скиллов.

Читает две библиотеки и показывает расхождение между ними:

  дом   /data/.hermes/skills  - сюда агент пишет через skill_manage
  репо  /projects/skills      - xvantz/skills, source of truth, уезжает на хост через flake

Что показывает:
  новое      - скиллы в доме, которых не было в снимке прошлого разбора
  изменено   - скиллы в доме, у которых поменялись файлы с прошлого разбора
  ждут       - есть в доме, нет в репо: кандидаты на промоушен (ветка + PR)
  расходятся - имя есть в обеих, содержимое разное: копия в доме перекрывает репо
  выросло    - файлы в репо, подросшие с прошлого разбора (сигнал «снежный ком»)

Ничего не пишет в скиллы: только SNapshot в state.json. Никаких коммитов, PR и удалений.

Запуск:  skill-digest  |  skill-digest --json
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import time
from pathlib import Path

HOME = Path(os.environ.get("HERMES_SKILLS_HOME", "/data/.hermes/skills"))
REPO = Path(os.environ.get("SKILLS_REPO", "/projects/skills"))
STATE = Path(os.environ.get("HERMES_SKILLS_STATE", "/data/.hermes/skill-digest/state.json"))
SKIP = {".archive", ".curator_backups", ".hub", ".locks", "node_modules", ".git"}
GROWTH_LINES = 40       # прирост строк, при котором файл считается разросшимся
GROWTH_RATIO = 1.15     # или прирост больше 15%


def fingerprint(skill_dir: Path) -> tuple[str, int, float, bool]:
    """sha256 по всем .md внутри скилла + число строк SKILL.md + mtime + признак read-only."""
    h = hashlib.sha256()
    newest = 0.0
    for md in sorted(skill_dir.rglob("*.md")):
        rel = str(md.relative_to(skill_dir))
        try:
            data = md.read_bytes()
            mtime = md.stat().st_mtime
            if mtime > 1_600_000_000:  # epoch 0 = остаток из nix store, возраст неизвестен
                newest = max(newest, mtime)
        except OSError:
            continue
        h.update(rel.encode())
        h.update(data)
    skill_md = skill_dir / "SKILL.md"
    lines = len(skill_md.read_text(encoding="utf-8", errors="replace").splitlines()) if skill_md.exists() else 0
    return h.hexdigest()[:16], lines, newest, not os.access(skill_dir, os.W_OK)


def skill_name(skill_dir: Path) -> str:
    """Имя скилла: frontmatter `name:`, иначе имя каталога."""
    skill_md = skill_dir / "SKILL.md"
    try:
        text = skill_md.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return skill_dir.name
    if text.startswith("---"):
        end = text.find("\n---", 3)
        if end > 0:
            for line in text[3:end].splitlines():
                if line.lower().startswith("name:"):
                    value = line.split(":", 1)[1].strip().strip("\"'")
                    if value:
                        return value
    return skill_dir.name


def index_home() -> dict[str, dict]:
    out: dict[str, dict] = {}
    if not HOME.is_dir():
        return out
    for skill_md in sorted(HOME.rglob("SKILL.md")):
        rel_parts = skill_md.relative_to(HOME).parts
        if any(part in SKIP for part in rel_parts):
            continue
        skill_dir = skill_md.parent
        sha, lines, newest, readonly = fingerprint(skill_dir)
        out[str(skill_dir.relative_to(HOME))] = {
            "name": skill_name(skill_dir),
            "dir": skill_dir.name,
            "sha": sha,
            "lines": lines,
            "age_days": int((time.time() - newest) // 86400) if newest else None,
            "readonly": readonly,
            "path": str(skill_dir),
        }
    return out


def index_repo() -> tuple[dict[str, dict], dict[str, int]]:
    by_name: dict[str, dict] = {}
    lines: dict[str, int] = {}
    root = REPO / "skills"
    if not root.is_dir():
        return by_name, lines
    for skill_md in sorted(root.rglob("SKILL.md")):
        if any(part in SKIP for part in skill_md.relative_to(root).parts):
            continue
        skill_dir = skill_md.parent
        sha, n_lines, _, _ = fingerprint(skill_dir)
        entry = {"sha": sha, "lines": n_lines, "path": str(skill_dir)}
        by_name[skill_dir.name] = entry
        by_name.setdefault(skill_name(skill_dir), entry)
        for md in skill_dir.rglob("*.md"):
            rel = str(md.relative_to(REPO))
            lines[rel] = len(md.read_text(encoding="utf-8", errors="replace").splitlines())
    return by_name, lines


def load_state() -> dict:
    try:
        return json.loads(STATE.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def digest(top: int) -> dict:
    home = index_home()
    repo, repo_lines = index_repo()
    prev = load_state()
    prev_home = prev.get("home") or {}
    prev_repo_lines = prev.get("repo_lines") or {}

    new, changed, pending, drift = [], [], [], []
    for rel, item in home.items():
        repo_match = repo.get(item["name"])
        base = {
            "name": item["name"],
            "rel": rel,
            "lines": item["lines"],
            "age_days": item["age_days"],
            "readonly": item["readonly"],
        }
        if repo_match is None:
            pending.append(base)
        elif repo_match["sha"] != item["sha"]:
            drift.append({**base, "repo_lines": repo_match["lines"]})
        if rel not in prev_home:
            if prev_home:  # не первый разбор
                new.append({**base, "in_repo": repo_match is not None})
        elif prev_home[rel] != item["sha"]:
            changed.append({**base, "in_repo": repo_match is not None})

    pending.sort(key=lambda i: (-(i["age_days"] or 0), i["name"]))
    new.sort(key=lambda i: i["name"])
    changed.sort(key=lambda i: i["name"])

    oversized = []
    for rel, n_lines in repo_lines.items():
        before = prev_repo_lines.get(rel)
        if before is None:
            continue
        if n_lines > before and (n_lines - before >= GROWTH_LINES or n_lines > before * GROWTH_RATIO):
            oversized.append({"file": rel, "lines": n_lines, "before": before, "growth": n_lines - before})
    oversized.sort(key=lambda i: -i["growth"])

    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(
        json.dumps(
            {
                "updated": time.strftime("%Y-%m-%d"),
                "home": {rel: item["sha"] for rel, item in home.items()},
                "repo_lines": repo_lines,
            },
            ensure_ascii=False,
            indent=0,
        ),
        encoding="utf-8",
    )

    return {
        "date": time.strftime("%Y-%m-%d"),
        "home_skills": len(home),
        "repo_skills": len({e["path"] for e in repo.values()}),
        "baseline": not prev_home,
        "new": new,
        "changed": changed,
        "pending": pending[:max(top, 10)],
        "pending_total": len(pending),
        "drift": drift,
        "oversized": oversized[:top],
    }


def render(r: dict) -> str:
    out = [f"# Скиллы - разбор {r['date']}", ""]
    out.append(f"дом {r['home_skills']} · репо {r['repo_skills']} · только в доме {r['pending_total']}")
    out.append("")
    if r["baseline"]:
        out.append("Первый разбор: базовая линия зафиксирована, «новое» и «изменено» пойдут со следующей недели.")
        out.append("")

    if r["new"]:
        out.append(f"## Новое с прошлого разбора ({len(r['new'])})")
        for i in r["new"]:
            where = "уже в репо" if i["in_repo"] else "в репо нет"
            out.append(f"- {i['name']} · {i['lines']} стр. · {where}")
        out.append("")

    if r["changed"]:
        out.append(f"## Изменено с прошлого разбора ({len(r['changed'])})")
        for i in r["changed"]:
            where = "уже в репо" if i["in_repo"] else "в репо нет"
            out.append(f"- {i['name']} · {i['lines']} стр. · {where}")
        out.append("")

    if r["drift"]:
        out.append(f"## Расходятся дом/репо ({len(r['drift'])}) - копия в доме перекрывает репо")
        for i in r["drift"]:
            out.append(f"- {i['name']} · дом {i['lines']} стр. против репо {i['repo_lines']} стр.")
        out.append("")

    if r["pending"]:
        shown = r["pending"]
        out.append(f"## Только в доме ({r['pending_total']}) - в репо нет")
        out.append("Дом - рабочая библиотека: в репо переезжает по мере надобности, это инвентарь, а не бэклог.")
        for i in shown:
            age = f"{i['age_days']} дн." if i["age_days"] is not None else "возраст ?"
            extra = " · read-only остаток, только копией" if i.get("readonly") else ""
            out.append(f"- {i['name']} · {i['lines']} стр. · {age}{extra}")
        if r["pending_total"] > len(shown):
            out.append(f"- ... ещё {r['pending_total'] - len(shown)}")
        out.append("")

    if r["oversized"]:
        out.append(f"## Выросло в репо ({len(r['oversized'])}) - кандидат на сжатие")
        for i in r["oversized"]:
            out.append(f"- {i['file']} · {i['before']} -> {i['lines']} стр. (+{i['growth']})")
        out.append("")

    if not (r["new"] or r["changed"] or r["drift"] or r["oversized"] or r["pending"]):
        out.append("Разбирать нечего: дом и репо не расходятся.")
        out.append("")
    out.append("Это список, а не решение. Промоушен - по потребности: ветка + PR в xvantz/skills после явного «да» по конкретным именам.")
    return "\n".join(out)


def main() -> int:
    p = argparse.ArgumentParser(prog="skill-digest", description="Разбор библиотеки скиллов: дом против репо")
    p.add_argument("--json", action="store_true")
    p.add_argument("--top", type=int, default=10, help="сколько строк показывать в длинных секциях")
    args = p.parse_args()
    r = digest(args.top)
    print(json.dumps(r, ensure_ascii=False, indent=2) if args.json else render(r))
    return 0


if __name__ == "__main__":
    sys.exit(main())
