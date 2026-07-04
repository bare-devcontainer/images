# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG

# ---- Builder stage: download and verify the mise binary in isolation ----
FROM debian:trixie-slim@sha256:28de0877c2189802884ccd20f15ee41c203573bd87bb6b883f5f46362d24c5c2 AS builder

ARG MISE_VERSION
ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3003 # cd only used in subshell
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=bind,source=mise-minisign.pub,target=/tmp/mise-minisign.pub,ro \
    rm -f /etc/apt/apt.conf.d/docker-clean \
        && export DEBIAN_FRONTEND=noninteractive \
        && apt-get update \
        && apt-get --no-install-recommends install -y ca-certificates wget minisign \
    && case "${TARGETARCH}" in \
        amd64) MISE_ARCH="x64" ;; \
        arm64) MISE_ARCH="arm64" ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && MISE_BINARY="mise-v${MISE_VERSION}-linux-${MISE_ARCH}" \
    && MISE_TMPDIR="$(mktemp -d)" \
    && wget -q -T 30 -t 3 -P "${MISE_TMPDIR}" "https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/${MISE_BINARY}" \
    && wget -q -T 30 -t 3 -P "${MISE_TMPDIR}" "https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/SHASUMS256.txt" \
    && wget -q -T 30 -t 3 -P "${MISE_TMPDIR}" "https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/SHASUMS256.txt.minisig" \
    && minisign -Vm "${MISE_TMPDIR}/SHASUMS256.txt" -p /tmp/mise-minisign.pub \
    && (cd "${MISE_TMPDIR}" && grep "  \\./${MISE_BINARY}$" SHASUMS256.txt | sha256sum -c -) \
    && install -m 755 "${MISE_TMPDIR}/${MISE_BINARY}" /usr/local/bin/mise \
    && rm -rf "${MISE_TMPDIR}"

# ---- Final stage: only the verified binary plus runtime dependencies ----
FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

USER root

# build-essential kept as a runtime dependency for tools mise compiles from source.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    export DEBIAN_FRONTEND=noninteractive \
        && apt-get update \
        && apt-get --no-install-recommends install -y build-essential

COPY --from=builder /usr/local/bin/mise /usr/local/bin/mise

ENV PATH=/home/dev/.local/share/mise/shims:${PATH}

USER dev
WORKDIR /workspaces

# hadolint ignore=SC2016 # intentional single quotes
RUN mkdir -p \
      /home/dev/.cache/mise \
      /home/dev/.config/mise \
      /home/dev/.local/share/mise \
      /home/dev/.local/state/mise \
    && mise use -g usage
