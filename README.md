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

- inputs (`nixpkgs`, `home-manager`, `niri`, `dms`, `zen-browser`, `sops-nix`, `nixvim`, self-hosted `coolcontrol`/`pm`/`sync-agent`, etc.);
- `nixosConfigurations.nixos`;
- `specialArgs` wiring (including `selfPath` and `customPkgs`);
- standalone `homeConfigurations.xvantz` (Home Manager as a separate config, not a NixOS module).

### 2) System layer: `configuration.nix` + `modules/system/*`

`configuration.nix` imports:

- `hardware-configuration.nix` (generated hardware/disk config, tracked);
- `modules/system/default.nix` aggregator plus external modules (`dank-greeter`, `sops-nix`, `coolcontrol`, `sync-agent`, `hermes-agent`, `pm`, `navidrome-collector`).

`modules/system/*` is organized by domain:

- boot/kernel/memory (`boot.nix`, `power.nix`, `hardware.nix`),
- networking and DNS (`network.nix`, `adguard.nix`, `caddy.nix`),
- graphics/display (`display.nix`, `portals.nix`, `fonts.nix`, `i18n.nix`),
- audio/Bluetooth (`audio.nix`, `bluetooth.nix`),
- Nix settings and helpers (`nix-settings.nix`, `nh.nix`, `fix-podman.nix`),
- services and self-hosting (`services.nix`, `forgejo.nix`, `searx.nix`, `redis.nix`, `syncthing.nix`, `crw.nix`, `dozzle.nix`, `driftty.nix`, `containers.nix`, `k3s/`, `music.nix`, `hindsight.nix`, `hermes/`),
- system packages and virtualization (`packages.nix`, `virtualization.nix`).

### 3) User layer: `home.nix` + `modules/home/*`

`home.nix` imports the aggregator `modules/home/default.nix`.

Home modules include:

- shell/tooling (`shell.nix`, `packages.nix`, `starship.nix`, `tmux.nix`, `yazi.nix`, `opencode.nix`, `mutagen.nix`),
- desktop/UI (`desktop.nix`, `theme.nix`, `ghostty.nix`, `dms.nix`, `browser.nix`, `keepassxc.nix`),
- editor (`neovim/` directory with `core.nix`, `keymaps.nix`, `autocmds.nix`, `plugins/`).

### 4) Custom packages: `customPkgs/*`

Local derivations are exposed through `customPkgs/default.nix`:

- `codex/` - pinned Codex CLI package with fixed version/hash;
- `gemini/` - Gemini CLI package with wrapper and behavior patching;
- `agent-lsp/`, `biome/`, `pi-coding-agent/` - agent tooling and linters.

### 5) External config assets

- `config/niri/config.kdl` - config included by DMS/Niri,
- `config/virtual/ssdt1.dat` - ACPI table for the Windows VM passthrough.

---

## Custom Flakes / Inputs

In addition to base `nixpkgs` + `home-manager`, this setup uses:

- `zen-browser`;
- `dms` (DankMaterialShell) + `dgop` + `dank-greeter`;
- `niri` (via sodiboo flake);
- `nixvim`;
- `sops-nix`;
- self-hosted on git.827482.xyz: `coolcontrol`, `pm`, `navidrome-collector`, `sync-agent`;
- `hermes-agent` (NousResearch).

This creates a hybrid model: **stable base + targeted external components**.

---

## Repository Structure

```text
.
├── flake.nix
├── flake.lock
├── configuration.nix
├── home.nix
├── hardware-configuration.nix   (generated, tracked)
├── secrets.yaml                 (sops-encrypted)
├── customPkgs/
│   ├── default.nix
│   ├── agent-lsp/
│   ├── biome/
│   ├── codex/
│   ├── gemini/
│   └── pi-coding-agent/
├── modules/
│   ├── system/   (see default.nix for the full list)
│   │   ├── hermes/
│   │   └── k3s/
│   └── home/
│       └── neovim/
└── config/
    ├── niri/
    └── virtual/
```

---

## Privacy Notes

- `hardware-configuration.nix` is tracked (contains partition UUIDs, regenerate per host when migrating).
- `secrets.yaml` is tracked but sops-encrypted; the age key (`sops-keys.txt`) is git-ignored and backed up in KeePassXC.
- Runtime logs like `config/hypr/*.log` are git-ignored (legacy pattern, no hypr config in tree).

---

## How to Apply

From the repository root:

```bash
nh os switch
```

or plain:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

Update home separately:

```bash
nh home switch
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
