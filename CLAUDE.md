# CLAUDE.md

Conventions for agents (Claude Code, Pi, etc.) modifying this repo.

## Hard rules

- **Pin everything by digest.** No `:latest` in Dockerfiles or workflows for upstream references. Use `image@sha256:...`. Renovate rotates these.
- **No devcontainer Features.** Most Features assume Debian/Ubuntu apt; Wolfi uses apk. Install via explicit Dockerfile steps.
- **Wolfi is glibc-based** (not musl, despite using apk). Native-binary packages and glibc-compiled binaries work as-is. Use standard linux-x64 / linux-aarch64 release artifacts, NOT musl variants.
- **Non-root by default.** All containers run as UID 1000 (`vscode`). Sudo present for ad-hoc apk installs.
- **Block postinstall scripts.** `bunfig.toml` `trustedDependencies: []`, npm `ignore-scripts=true`, pnpm `strictDepBuilds: true`. Allowlist per-project, not globally.
- **Verify checksums for binary downloads.** Any `curl | sh` or release-tarball install must check SHA-256.

## Image naming

`ghcr.io/ddlaws0n/devcontainer-{base,python,tsjs}`. Tags: `latest`, `YYYY-MM-DD`, `sha-<short>`. Consumers should reference `@sha256:` digests.

## Dependency chain

`base` is the parent of `python` and `tsjs`. Changes to `base` rebuild both children. CI matrix builds in this order.

## Where things live

| Tool | Lives in | Why |
|-|-|-|
| Claude Code, Pi Agent | `base` | Available to every container |
| uv | `python` | Python-specific |
| ruff, pre-commit, pip-audit | `python` (globally via `uv tool install`) | Used across all Python projects |
| ty, basedpyright, pytest | Per-project `[dependency-groups].dev` | Version follows project |
| bun, node | `tsjs` | Language-specific |
| vtsls, biome, tsx | `tsjs` (global) | Editors discover from PATH |
| typescript | Per-project `node_modules` | LSP picks up project version |

## Before merging

1. Image builds clean in CI
2. Trivy reports no new HIGH/CRITICAL CVEs
3. Cosign signatures verifiable
4. SBOM attached
5. Both VSCode and Zed open the example devcontainer cleanly
