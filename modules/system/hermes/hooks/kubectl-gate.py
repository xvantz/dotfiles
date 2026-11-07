#!/usr/bin/env python3
"""Require human approval for calls that change the cluster.

The approval card in Hermes has two slots: the command block is taken by the
`<terminal> (plugin approval rule)` placeholder, and the Reason field holds 500
characters. Only the command itself goes into Reason. When it does not fit the
budget, the call is blocked with the full text so the human sees it in chat
instead of a truncated line.

The command is matched at command position (line start, after ; | && || ` ( or
environment assignments), not anywhere in the text: mentioning the tool inside
quotes, a heredoc or a comment must not require approval.
"""
import json
import re
import sys

REASON_BUDGET = 460

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


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0

    if payload.get("tool_name") != "terminal":
        return 0

    tool_input = payload.get("tool_input") or payload.get("args") or {}
    command = tool_input.get("command") or tool_input.get("cmd") or ""
    if not isinstance(command, str) or not MUTATING.search(command):
        return 0

    one_line = " ".join(command.split())

    if len(one_line) <= REASON_BUDGET:
        print(json.dumps({"action": "approve", "message": one_line}, ensure_ascii=False))
        return 0

    message = (
        "Требуется подтверждение человека: команда не влезает в поле подтверждения "
        "(лимит 500 символов), поэтому её нельзя показать без обрезки. "
        "Покажи команду в чате код-блоком и дождись явного согласия, прежде чем выполнять:\n\n"
        + command
    )
    print(json.dumps({"action": "block", "message": message}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
