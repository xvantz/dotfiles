# LOCAL-NOTES (окружение Ivan/Hermes)

Заметки по запуску сканера в этой среде (не часть апстрим-скилла).

## Запуск сканера

Сканер работает на системном python3 контейнера. Зависимости (razdel, pymorphy3,
dawg2, dicts-ru, dicts-uk) приходят через PYTHONPATH, который задан в
`services.hermes-agent.container.extraOptions` (см. /dotfiles/modules/system/hermes/hermes.nix):

```nix
"--env"
"PYTHONPATH=${pkgs.lib.makeSearchPath pkgs.python312.sitePackages (pkgs.python312.pkgs.requiredPythonModules (with pkgs.python312Packages; [ razdel pymorphy3 ]))}"
```

Команда: `python3 <папка скилла>/scripts/scan.py файл.txt`

## Важно: extraPythonPackages НЕ работает (баг v2026.8.3)

`services.hermes-agent.extraPythonPackages` игнорируется: override пакета не
попадает в активируемый systemd unit (effectivePackage остаётся старым),
поэтому razdel/pymorphy3 никогда не собираются в closure. Обход — PYTHONPATH
через container.extraOptions (см. выше). НЕ использовать extraPythonPackages.

## Прочее

- venv /data/.hermes/venvs/humanizer-ru удалён (больше не нужен)
- /tmp сбрасывается при пересоздании контейнера (writable layer)
