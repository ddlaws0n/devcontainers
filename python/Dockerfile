# syntax=docker/dockerfile:1.7
#
# Python devcontainer image
# - Extends devcontainer-base (Wolfi)
# - uv-managed CPython 3.13 + 3.14
# - ruff, pre-commit, pip-audit installed globally
# - basedpyright + ty live in per-project [dependency-groups].dev (NOT baked here)
#
# Versions are pinned and Renovate-managed.

# Global ARGs (resolvable in FROM lines). They must be re-declared inside each
# stage that uses them.
ARG BASE_IMAGE=ghcr.io/ddlaws0n/devcontainer-base:latest
# renovate: datasource=github-releases depName=astral-sh/uv
ARG UV_VERSION=0.11.14

# Pin uv via its official image as a named stage — sidesteps the buildkit
# limitation that ARG substitution in `COPY --from=` only works for stage names.
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv-bin

FROM ${BASE_IMAGE} AS python

# renovate: datasource=pypi depName=ruff
ARG RUFF_VERSION=0.15.12
# renovate: datasource=pypi depName=pre-commit
ARG PRECOMMIT_VERSION=4.6.0
# renovate: datasource=pypi depName=pip-audit
ARG PIPAUDIT_VERSION=2.10.0

ARG PYTHON_VERSION=3.14
ARG PYTHON_FALLBACK_VERSION=3.13

# uv is distributed as a static binary in its own image — copy it in.
COPY --from=uv-bin /uv /uvx /usr/local/bin/

USER root

# Wolfi packages required by some sdists when uv falls back to source builds.
# Most projects use wheels; these are insurance for edge cases.
RUN apk add --no-cache build-base linux-headers

# Pre-create uv state dirs owned by the vscode user
RUN install -d -o vscode -g vscode \
      /home/vscode/.cache/uv \
      /home/vscode/.local/share/uv \
      /home/vscode/.local/bin

USER vscode
WORKDIR /home/vscode

ENV UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    UV_PYTHON_PREFERENCE=only-managed \
    UV_TOOL_BIN_DIR=/home/vscode/.local/bin \
    UV_NO_PROGRESS=1

# Install managed Python builds + global dev tools in one cached layer.
# uv's tool installs are pinned; Renovate updates them.
RUN --mount=type=cache,target=/home/vscode/.cache/uv,uid=1000,gid=1000 \
    uv python install ${PYTHON_FALLBACK_VERSION} ${PYTHON_VERSION} \
 && uv tool install "ruff==${RUFF_VERSION}" \
 && uv tool install "pre-commit==${PRECOMMIT_VERSION}" \
 && uv tool install "pip-audit==${PIPAUDIT_VERSION}"

# Smoke test
RUN uv --version \
 && uv python list --only-installed \
 && ruff --version \
 && pre-commit --version \
 && pip-audit --version

CMD ["/bin/zsh", "-l"]
