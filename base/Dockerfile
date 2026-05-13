# syntax=docker/dockerfile:1.7
#
# Base devcontainer image
# - Chainguard Wolfi for a near-zero CVE baseline
# - Non-root vscode user (UID 1000) with sudo
# - zsh + starship, modern CLI tools
# - Claude Code + Pi Agent (pinned versions)
#
# Build:
#   docker build -t devcontainer-base .
#
# All upstream digests and tool versions are managed by Renovate.

ARG WOLFI_BASE_REF=cgr.dev/chainguard/wolfi-base:latest

FROM ${WOLFI_BASE_REF} AS base

# renovate-friendly tool versions. Update these via Renovate or by hand.
ARG NODE_PACKAGE=nodejs-24
# renovate: datasource=npm depName=@anthropic-ai/claude-code
ARG CLAUDE_CODE_VERSION=2.1.140
# renovate: datasource=npm depName=@earendil-works/pi-coding-agent
ARG PI_AGENT_VERSION=0.74.0

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

USER root

# Core apk packages. Wolfi is glibc-based (not musl) — no compat shim needed.
# shadow → useradd/groupadd
# sudo   → passwordless sudo for vscode user
# tar, gzip, less are provided by busybox; install gnu-equivalents only if needed.
RUN apk add --no-cache \
      bash zsh \
      shadow sudo \
      git gh delta openssh-client \
      curl wget ca-certificates \
      ripgrep fd bat fzf jq unzip xz \
      starship \
      tzdata \
      ${NODE_PACKAGE} npm

# Non-root user with passwordless sudo
RUN groupadd --gid ${USER_GID} ${USERNAME} \
 && useradd --uid ${USER_UID} --gid ${USER_GID} --create-home --shell /bin/zsh ${USERNAME} \
 && install -d -o ${USERNAME} -g ${USERNAME} /home/${USERNAME}/.claude \
 && install -d -o ${USERNAME} -g ${USERNAME} /home/${USERNAME}/.config \
 && echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USERNAME} \
 && chmod 0440 /etc/sudoers.d/${USERNAME}

# Coding agents. DISABLE_AUTOUPDATER keeps Claude Code at the pinned version.
ENV DISABLE_AUTOUPDATER=1 \
    npm_config_fund=false \
    npm_config_audit=false
RUN --mount=type=cache,target=/root/.npm,sharing=locked \
    npm install -g --omit=optional \
      "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
      "@earendil-works/pi-coding-agent@${PI_AGENT_VERSION}"

# Shell config for the vscode user
COPY --chown=${USERNAME}:${USERNAME} home/.zshrc /home/${USERNAME}/.zshrc
COPY --chown=${USERNAME}:${USERNAME} home/.config/starship.toml /home/${USERNAME}/.config/starship.toml

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    SHELL=/bin/zsh \
    EDITOR=vi \
    CLAUDE_CONFIG_DIR=/home/${USERNAME}/.claude \
    PATH=/home/${USERNAME}/.local/bin:/home/${USERNAME}/bin:/usr/local/bin:/usr/bin:/sbin:/bin

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Verify the agents are reachable and Node is the expected major
RUN node --version \
 && npm --version \
 && claude --version \
 && pi --version

CMD ["/bin/zsh", "-l"]
