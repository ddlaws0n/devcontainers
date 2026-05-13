# devcontainers

Hardened, signed devcontainer images for local development. Built on Chainguard Wolfi for a near-zero CVE baseline; published to GHCR; signed keylessly via Cosign + GitHub OIDC.

## Images

| Image | Purpose | Includes |
|-|-|-|
| `ghcr.io/ddlaws0n/devcontainer-base` | General-purpose shell + agents | zsh, starship, gh, git, delta, rg, fd, bat, fzf, Node 24 LTS, Claude Code, Pi Agent |
| `ghcr.io/ddlaws0n/devcontainer-python` | Python development | base + uv-managed CPython 3.13 + 3.14, ruff, pre-commit, pip-audit |
| `ghcr.io/ddlaws0n/devcontainer-tsjs` | TypeScript/JavaScript development | base + bun 1.3, pnpm, yarn, Biome v2, vtsls, tsx |

All three run as the non-root `vscode` user (UID 1000) with passwordless sudo.

## Tagging

| Tag | Meaning |
|-|-|
| `:latest` | Most recent build from `main` |
| `:YYYY-MM-DD` | Date-stamped |
| `:sha-<short>` | Git commit |
| `@sha256:<digest>` | Immutable. Use in production. Renovate pins this. |

## Verify before pulling

Every image is signed via Cosign keyless OIDC and carries a GitHub build-provenance attestation.

```sh
./scripts/verify-image.sh ghcr.io/ddlaws0n/devcontainer-base:latest
```

The script runs both `cosign verify` (against the workflow identity) and `gh attestation verify` (build provenance).

## Using an image in a project

Each image ships a `.devcontainer/` template you can copy into your project:

```sh
# Python project
cp -r path/to/devcontainers/python/templates/.devcontainer .devcontainer
cp -r path/to/devcontainers/python/templates/.zed .zed
cp path/to/devcontainers/python/templates/pyproject.toml ./   # if starting fresh

# TS/JS project
cp -r path/to/devcontainers/tsjs/templates/.devcontainer .devcontainer
cp -r path/to/devcontainers/tsjs/templates/.zed .zed
cp path/to/devcontainers/tsjs/templates/biome.json ./
```

Then open the folder in **VSCode** (it prompts "Reopen in Container") or **Zed** (CMD-Shift-P → Dev Containers).

### Zed-specific note

Zed's devcontainer support is functional but immature (May 2026):
- No auto-rebuild when `devcontainer.json` changes — manually stop and reopen
- `customizations.vscode` is ignored — VSCode-only extensions don't load
- Extensions installed in Zed must be configured per-user via Zed's extension panel; they can't be auto-installed by `devcontainer.json` yet

The `.zed/settings.json` template in each container handles LSP wiring (basedpyright + ruff for Python; vtsls + Biome for TS/JS).

## Tailscale (optional, per-device)

Both the Python and TS/JS templates support an opt-in Tailscale sidecar. The opt-in is a single file copy per device:

```sh
# On a personal device that should join your tailnet:
cd .devcontainer
cp compose.override.yaml.example compose.override.yaml
# Set TS_AUTHKEY (ephemeral, tagged) in .devcontainer/.env
```

`compose.override.yaml` is gitignored at the template level. `docker compose` automatically merges it when present, with no other config changes required.

Generate an ephemeral, tagged Tailscale auth key at https://login.tailscale.com/admin/settings/keys.

## Supply-chain hardening

What we enforce:

- Wolfi base image pinned by `@sha256:` digest (Renovate-managed)
- All apk, npm, and PyPI packages installed with explicit pinned versions
- Postinstall scripts blocked by default (bun `trustedDependencies: []`, npm `ignore-scripts=true`, pnpm `strictDepBuilds: true`)
- `uv` lockfiles include SHA-256 per package, enforced via `uv sync --frozen`
- `bunfig.toml` template sets `minimumReleaseAge = "3 days"` against typosquats
- `pyproject.toml` template sets `exclude-newer = "7 days"`
- bun release binaries verified against `SHASUMS256.txt` at install
- Cosign keyless signatures + SLSA build provenance on every published image
- Trivy CVE scan in CI; HIGH/CRITICAL blocks signature
- SBOM produced by buildkit, attached as OCI artifact to each image
- Renovate auto-PRs for digest rotation; major bumps require manual review
- Coding-agent package upgrades always require manual review (`agent-update` label)

What you should still do:

- Always reference images by `@sha256:` digest in your project's `devcontainer.json`
- Run `scripts/verify-image.sh` before pulling a new digest into a project
- Don't add packages to `trustedDependencies` without auditing their postinstall script
- Keep Tailscale auth keys ephemeral, tagged, and short-lived

## Building locally

```sh
# Build base first (children depend on it)
docker build -t ghcr.io/ddlaws0n/devcontainer-base:local base/

# Children reference the local base via build-arg
docker build -t ghcr.io/ddlaws0n/devcontainer-python:local \
  --build-arg BASE_IMAGE=ghcr.io/ddlaws0n/devcontainer-base:local \
  python/

docker build -t ghcr.io/ddlaws0n/devcontainer-tsjs:local \
  --build-arg BASE_IMAGE=ghcr.io/ddlaws0n/devcontainer-base:local \
  tsjs/
```

Multi-arch local builds need `docker buildx` with the `--platform linux/amd64,linux/arm64` flag and a builder configured for emulation.

## Updating versions

Renovate runs weekly and opens grouped PRs for:

- Wolfi base image digest
- GitHub Actions SHAs (initially tags — Renovate pins on first run)
- Astral tools (uv, ruff)
- JS toolchain (bun, biome, vtsls, tsx, pnpm, yarn)
- Coding agents (always requires manual review)

Patch and minor updates for first-party tooling auto-merge after CI passes. Major bumps and coding-agent updates always require manual review.

## Repo layout

```text
base/                              Base image source
  Dockerfile, home/.zshrc, home/.config/starship.toml
  templates/.devcontainer/         Example consumer config
python/                            Python image source
  Dockerfile
  templates/.devcontainer/         Example consumer config (devcontainer.json + compose)
  templates/.zed/                  Zed LSP wiring
  templates/pyproject.toml         Example project config with ruff + uv exclude-newer
  templates/.pre-commit-config.yaml
tsjs/                              TS/JS image source
  Dockerfile
  templates/.devcontainer/
  templates/.zed/
  templates/bunfig.toml            minimumReleaseAge + trustedDependencies
  templates/.npmrc                 ignore-scripts=true
  templates/biome.json
  templates/tsconfig.json
  templates/package.json
.github/workflows/build.yml        CI: build, scan, sign, attest
renovate.json                      Auto-update config
scripts/verify-image.sh            Cosign + gh attestation verification
CLAUDE.md                          Conventions for agents modifying this repo
```

## Conventions

See [CLAUDE.md](./CLAUDE.md) for the rules agents must follow when modifying this repo (digest pinning, no Features, etc.).
