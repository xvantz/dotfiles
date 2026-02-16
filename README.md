# NixOS Dotfiles (Flake + Home Manager)

## Goal

This repository is my **declarative system base** designed to be reproducible quickly and predictably on a new machine.

Core idea:

- all OS and user-environment configuration is defined in `nix`;
- builds are pinned via `flake.lock`;
- the setup is split into small modules for easier maintenance and evolution.

---

## Main Build Components

### 1) Entry point: `flake.nix`

`flake.nix` defines:

- inputs (`nixpkgs`, `home-manager`, `niri`, `anyrun`, `dms`, `zen-browser`, etc.);
- `nixosConfigurations.nixos`;
- `specialArgs` wiring (including `pkgs-unstable` and `customPkgs`);
- Home Manager integration as a NixOS module.

### 2) System layer: `configuration.nix` + `modules/system/*`

`configuration.nix` imports:

- `hardware-configuration.nix` (auto-generated hardware/disk config);
- system module aggregator `modules/system/default.nix`.

`modules/system/*` is organized by domain:

- boot/kernel/memory (`boot.nix`, `power.nix`),
- networking and DNS (`network.nix`),
- graphics/display (`display.nix`, `portals.nix`),
- audio/Bluetooth (`audio.nix`, `bluetooth.nix`),
- Nix settings and services (`nix-settings.nix`, `services.nix`),
- system packages and virtualization (`packages.nix`, `virtualization.nix`).

### 3) User layer: `home.nix` + `modules/home/*`

`home.nix` imports the aggregator `modules/home/default.nix`.

Home modules include:

- shell/tooling (`shell.nix`, `packages.nix`, `starship.nix`, `tmux.nix`, `yazi.nix`),
- desktop/UI (`desktop.nix`, `theme.nix`, `ghostty.nix`),
- daily apps (`anyrun.nix`, `dms.nix`, `neovim.nix`).

### 4) Custom packages: `customPkgs/*`

Local derivations are exposed through `customPkgs/default.nix`:

- `customPkgs/codex/codex.nix` — pinned Codex CLI package with fixed version/hash;
- `customPkgs/gemini/gemini.nix` — Gemini CLI package with wrapper and behavior patching.

### 5) External config assets

- `config/hypr/*` — Hyprlock assets and theme,
- `config/niri/config.kdl` — config included by DMS/Niri,
- `config/nvim` — git submodule with a separate Neovim setup.

---

## Custom Flakes / Inputs

In addition to base `nixpkgs` + `home-manager`, this setup uses:

- `zen-browser`;
- `dms` (DankMaterialShell) + `dgop`;
- `niri`;
- `anyrun`.

This creates a hybrid model: **stable base + targeted external components**.

---

## Repository Structure

```text
.
├── flake.nix
├── flake.lock
├── configuration.nix
├── home.nix
├── hardware-configuration.nix   (local, ignored)
├── customPkgs/
│   ├── default.nix
│   ├── codex/codex.nix
│   └── gemini/gemini.nix
├── modules/
│   ├── system/
│   └── home/
└── config/
    ├── hypr/
    ├── niri/
    └── nvim/   (submodule)
```

---

## Privacy Notes

- `hardware-configuration.nix` is intentionally git-ignored (machine-specific, generated per host).
- Runtime logs like `config/hypr/*.log` are git-ignored.

---

## How to Apply

From the repository root:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

Update flake inputs:

```bash
nix flake update
```

Validate that the flake evaluates correctly:

```bash
nix flake check
```

---

## Reproducibility Principles

- pinned dependencies in `flake.lock`;
- explicit modular layout;
- custom tools (Codex/Gemini) built declaratively;
- minimal manual post-setup steps outside Nix.

When migrating to another machine, you usually need to adjust:

- `hardware-configuration.nix`;
- username and home paths in `home.nix`/home modules;
- device-specific parameters (GPU, kernel modules, power tweaks).
