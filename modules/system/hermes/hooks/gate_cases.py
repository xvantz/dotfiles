"""Тесты хука kubectl-gate, включая ssh-ветку.

Запуск: python3 gate_cases.py [путь-к-хуку]
В командной строке нет мутирующих глаголов, поэтому сам тест не требует апрува.
"""
import json
import subprocess
import sys

hook = sys.argv[1] if len(sys.argv) > 1 else "/dotfiles/modules/system/hermes/hooks/kubectl-gate.py"

# (label, command, ожидается_ли_апрув)
cases = [
    ("kubectl apply", "kubectl apply -f k8s/deploy.yaml", True),
    ("kubectl read", "kubectl get pods -A", False),
    ("rollout restart", "kubectl rollout restart deploy/api", True),
    ("rollout status", "kubectl rollout status deploy/api", False),
    ("helm install", "helm install api ./chart --wait", True),
    ("helm list", "helm list -A", False),
    ("ssh quoted mutate", "ssh box 'kubectl scale deploy/api --replicas=3'", True),
    ("ssh dquoted mutate", 'ssh box "kubectl delete ns prod"', True),
    ("ssh read", "ssh box 'kubectl get pods'", False),
    ("ssh with flags", "ssh -p 2222 -i ~/.ssh/id_ed25519 box 'helm upgrade api ./chart'", True),
    ("ssh bash -c", "ssh box bash -c 'kubectl apply -f x.yaml'", True),
    ("ssh nested quoting", "ssh box \"bash -lc 'kubectl delete pod api-0'\"", True),
    ("ssh plain ls", "ssh box 'ls -la /tmp'", False),
    ("ssh no command", "ssh box", False),
    ("mention in echo", "echo 'kubectl delete ns prod' > notes.txt", False),
    ("mention in comment", "ls -l  # kubectl delete ns prod", False),
    ("deploy wrapper", "./bin/deploy_all prod", True),
]

fails = 0
for label, cmd, expect in cases:
    p = subprocess.run([sys.executable, hook], text=True, capture_output=True,
                       input=json.dumps({"tool_name": "terminal", "tool_input": {"command": cmd}}))
    out = p.stdout.strip()
    if p.returncode != 0:
        print(f"{label:22} ОШИБКА ХУКА rc={p.returncode} {p.stderr.strip()[:80]}")
        fails += 1
        continue
    got = bool(out)
    if got != expect:
        print(f"{label:22} ПРОВАЛ: ожидался апрув={expect}, получен={got}  cmd={cmd!r}")
        fails += 1
        continue
    if got:
        d = json.loads(out)
        ok_dt = d.get("display_target") == cmd
        if d["action"] != "approve" or not ok_dt:
            print(f"{label:22} ПРОВАЛ: action={d['action']} display_target_ok={ok_dt}")
            fails += 1
            continue
    print(f"{label:22} ok  (апрув={got}{', display_target=команда' if got else ''})")

print()
print("ПРОВАЛОВ:", fails)
sys.exit(1 if fails else 0)
