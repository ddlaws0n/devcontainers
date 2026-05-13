# Security Policy

## Supported versions

Only the most recent published image digest on `main` receives security updates. Pull and pin by `@sha256:` digest, and let Renovate rotate it.

## Reporting a vulnerability

If you've found a vulnerability in these images, build configs, or the verification scripts, **please do not open a public issue**.

Use GitHub's private vulnerability reporting:

1. Go to the [Security tab](https://github.com/ddlaws0n/devcontainers/security) of this repo.
2. Click **Report a vulnerability**.
3. Include: affected image (and `@sha256:` digest if you have it), reproduction steps, and impact.

You can also email **ddiranlawson@gmail.com** with the subject `[devcontainers security]` if you can't use GitHub's reporter.

I aim to acknowledge reports within 72 hours and to ship a fix or mitigation within 14 days for HIGH/CRITICAL issues. Lower-severity reports are batched into the regular Renovate cadence.

## Scope

In scope:

- The `base`, `python`, and `tsjs` Dockerfiles and their installed packages
- The CI workflow (`.github/workflows/build.yml`) — secrets handling, signing, attestation
- `scripts/verify-image.sh` — anything that could cause it to pass a tampered image
- The devcontainer templates under `*/templates/` that ship with the images

Out of scope:

- Vulnerabilities in upstream packages already pinned by digest (report those to the upstream project; Renovate will pull the fix)
- Issues that require a malicious user already inside the dev container
- Anything in a fork or downstream copy

## What I do to keep these images safe

- Wolfi base pinned by `@sha256:` digest (near-zero CVE baseline)
- Cosign keyless signatures + SLSA build provenance on every published image
- Trivy HIGH/CRITICAL scan in CI; failures block signing
- SBOM published as an OCI artifact per image
- Postinstall scripts blocked by default (bun `trustedDependencies: []`, npm `ignore-scripts=true`, pnpm `strictDepBuilds: true`)
- `uv` lockfiles enforce SHA-256 per package via `uv sync --frozen`
- All GitHub Actions pinned by commit SHA, rotated by Renovate

See [README.md](./README.md#supply-chain-hardening) for the full hardening list.
