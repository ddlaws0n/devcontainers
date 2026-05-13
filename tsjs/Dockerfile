# syntax=docker/dockerfile:1.7
#
# TypeScript / JavaScript devcontainer image
# - Extends devcontainer-base (Wolfi, has nodejs-24 + npm)
# - Adds bun, pnpm, yarn (classic), vtsls, biome, tsx
# - tsgo (TypeScript native preview) stays per-project in [devDependencies]
#
# Versions are pinned and Renovate-managed.

ARG BASE_IMAGE=ghcr.io/ddlaws0n/devcontainer-base:latest
FROM ${BASE_IMAGE} AS tsjs

# renovate: datasource=github-releases depName=oven-sh/bun
ARG BUN_VERSION=1.3.13
# renovate: datasource=npm depName=@biomejs/biome
ARG BIOME_VERSION=2.4.15
# renovate: datasource=npm depName=@vtsls/language-server
ARG VTSLS_VERSION=0.3.0
# renovate: datasource=npm depName=tsx
ARG TSX_VERSION=4.21.0
# renovate: datasource=npm depName=pnpm
ARG PNPM_VERSION=11.1.1
# renovate: datasource=npm depName=yarn
ARG YARN_VERSION=1.22.22

USER root

# Install bun from the official GitHub release, verifying SHA-256 against
# the upstream SHASUMS256.txt for the same release tag.
RUN set -eux; \
    ARCH=$(uname -m); \
    case "$ARCH" in \
      x86_64)  BUN_ARCH=x64 ;; \
      aarch64) BUN_ARCH=aarch64 ;; \
      *) echo "Unsupported arch: $ARCH"; exit 1 ;; \
    esac; \
    BUN_REL="bun-v${BUN_VERSION}"; \
    BUN_FILE="bun-linux-${BUN_ARCH}.zip"; \
    BASE_URL="https://github.com/oven-sh/bun/releases/download/${BUN_REL}"; \
    curl -fsSL "${BASE_URL}/${BUN_FILE}" -o /tmp/bun.zip; \
    curl -fsSL "${BASE_URL}/SHASUMS256.txt" -o /tmp/SHASUMS256.txt; \
    EXPECTED=$(grep " ${BUN_FILE}$" /tmp/SHASUMS256.txt | awk '{print $1}'); \
    test -n "$EXPECTED" || { echo "no checksum for ${BUN_FILE}"; exit 1; }; \
    echo "${EXPECTED}  /tmp/bun.zip" | sha256sum -c -; \
    unzip -q /tmp/bun.zip -d /tmp/bun-extract; \
    install -m 0755 /tmp/bun-extract/*/bun /usr/local/bin/bun; \
    ln -s /usr/local/bin/bun /usr/local/bin/bunx; \
    rm -rf /tmp/bun.zip /tmp/SHASUMS256.txt /tmp/bun-extract

# Global JS tooling installed via npm with explicit pins.
# --ignore-scripts blocks postinstall code execution; we don't need it for these.
ENV npm_config_fund=false \
    npm_config_audit=false \
    npm_config_ignore_scripts=true
RUN --mount=type=cache,target=/root/.npm,sharing=locked \
    npm install -g --omit=optional \
      "@biomejs/biome@${BIOME_VERSION}" \
      "@vtsls/language-server@${VTSLS_VERSION}" \
      "tsx@${TSX_VERSION}" \
      "pnpm@${PNPM_VERSION}" \
      "yarn@${YARN_VERSION}"

# bun stores its own cache and config under $HOME — pre-create for vscode user.
RUN install -d -o vscode -g vscode \
      /home/vscode/.bun \
      /home/vscode/.bun/install/cache

USER vscode
WORKDIR /home/vscode

ENV PATH=/home/vscode/.bun/bin:${PATH} \
    BUN_INSTALL=/home/vscode/.bun

# Smoke test
RUN node --version \
 && npm --version \
 && bun --version \
 && pnpm --version \
 && yarn --version \
 && biome --version \
 && tsx --version

CMD ["/bin/zsh", "-l"]
