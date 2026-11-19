#!/usr/bin/env python3
"""Require human approval for calls that change the cluster.

The approve directive carries `display_target`, so the approval card shows the
real command in its command block (Hermes >= 0.23.2 + our local patch on
request_tool_approval). The Reason field only holds a short why, never the
command: it is capped at ~500 characters and truncates long kubectl/helm lines.

If the receiving Hermes predates the patch the extra key is ignored and the card
falls back to the synthetic `<terminal> (plugin approval rule)` label with the
reason text - which is why the reason stays short and readable either way.

The command is matched at command position (line start, after ; | && || ` ( or
environment assignments), not anywhere in the text: mentioning the tool inside
quotes, a heredoc or a comment must not require approval.
"""
import json
import re
import sys


CMD_START = (
    r"(?:^|[\n;|&(`])\s*"
    r"(?:[A-Za-z_][A-Za-z0-9_]*=\S*\s+)*"
    r"(?:sudo\s+(?:-\S+\s+)*)?"
    r"(?:env\s+(?:\S+=\S*\s+)*)?"
)

MUTATING = re.compile(
    CMD_START
    + r"(?:"
    # kubectl: любой глагол, меняющий состояние кластера
    r"kubectl\s+[^\n;|&]*?\b("
    r"apply|create|delete|replace|patch|edit|scale|autoscale|"
    r"drain|cordon|uncordon|taint|label|annotate|exec|cp|set|expose|"
    r"port-forward|proxy|run|debug"
    r")\b"
    r"|"
    # rollout читает состояние в status/history, а меняет только этими глаголами
    r"kubectl\s+rollout\s+(restart|undo|pause|resume)\b"
    r"|"
    # helm: установка, удаление, откат, тестовые поды
    r"helm\s+(?!(?:list|get|status|history|show|search|version|template|env|repo|lint|dependency|verify)\b)"
    r"[^\n;|&]*?\b(upgrade|install|uninstall|del|rollback|test)\b"
    r"|"
    # обёртки деплоя kapsule: внутри них helm, но в командной строке его не видно
    r"(?:\./)?bin/(upgrade|upgrade_all|deploy|deploy_all)\b"
    r")",
    re.MULTILINE,
)

# ssh отправляет команду на другую машину, и мутирующий глагол оказывается внутри
# кавычек - то есть не в командной позиции. Без этого разбора `ssh box 'kubectl
# scale ...'` проходил мимо гейта.
SSH_INVOCATION = re.compile(
    CMD_START + r"ssh\b(?P<rest>[^\n;|&]*)",
    re.MULTILINE,
)

# Флаги ssh, которые съедают следующий токен как своё значение.
SSH_FLAGS_WITH_ARG = {
    "-b", "-c", "-D", "-E", "-e", "-F", "-I", "-i", "-J", "-L", "-l",
    "-m", "-O", "-o", "-p", "-Q", "-R", "-S", "-W", "-w",
}

QUOTED = re.compile(r"'([^']*)'|\"([^\"]*)\"")


def _unwrap(text: str, depth: int = 3) -> list[str]:
    """Строка плюс всё, что из неё вынимается снятием/раскрытием кавычек.

    Нужно для цепочек вида `ssh box "bash -lc 'kubectl delete ...'"`: снаружи
    команда начинается с bash, а мутирующий глагол лежит на два уровня глубже.
    """
    out = [text]
    stripped = text.strip().strip("'\"").strip()
    if stripped and stripped != text:
        out.append(stripped)
    if depth > 0:
        for single, double in QUOTED.findall(text):
            inner = single or double
            if not inner:
                continue
            for item in _unwrap(inner, depth - 1):
                if item not in out:
                    out.append(item)
    return out


def _ssh_remote_command(rest: str) -> str:
    """Хвост ssh-вызова после «опции + хост» -> строка удалённой команды."""
    tokens = rest.split()
    i = 0
    while i < len(tokens) and tokens[i].startswith("-"):
        flag = tokens[i]
        i += 1
        if flag in SSH_FLAGS_WITH_ARG:
            i += 1
    if i >= len(tokens):
        return ""          # ssh без хоста: это не вызов команды
    i += 1                 # сам хост
    return " ".join(tokens[i:])


def ssh_remote_mutates(command: str) -> bool:
    """Есть ли мутирующий kubectl/helm в удалённой части ssh-вызова."""
    for m in SSH_INVOCATION.finditer(command):
        remote = _ssh_remote_command(m.group("rest"))
        if not remote:
            continue
        if any(MUTATING.search(c) for c in _unwrap(remote) if c):
            return True
    return False


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0

    if payload.get("tool_name") != "terminal":
        return 0

    tool_input = payload.get("tool_input") or payload.get("args") or {}
    command = tool_input.get("command") or tool_input.get("cmd") or ""
    if not isinstance(command, str) or not (MUTATING.search(command) or ssh_remote_mutates(command)):
        return 0

    one_line = " ".join(command.split())
    verbs = one_line.split()
    short = " ".join(verbs[:5]) + ("…" if len(verbs) > 5 else "")
    # Полная команда уходит в слот команды карточки, причина - короткая и читаемая.
    print(json.dumps({
        "action": "approve",
        "message": f"kubectl меняет кластер: {short}",
        "display_target": command,
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
