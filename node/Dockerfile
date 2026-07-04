# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG} AS builder

ARG NODE_VERSION
ARG COREPACK_VERSION
ARG TARGETARCH

# hadolint ignore=DL3002 # builder stage is a throwaway; never shipped or run
USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=bind,source=node-keyring.kbx,target=/tmp/node-keyring.kbx,ro \
    export DEBIAN_FRONTEND=noninteractive \
        && apt-get update \
        && apt-get --no-install-recommends install -y gpgv build-essential \
    && case "${TARGETARCH}" in \
        amd64) NODE_ARCH="x64" ;; \
        arm64) NODE_ARCH="arm64" ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && NODE_TARBALL="node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" \
    && NODE_TMPDIR="$(mktemp -d)" \
    && wget -q -T 30 -t 3 -P "${NODE_TMPDIR}" "https://nodejs.org/dist/v${NODE_VERSION}/${NODE_TARBALL}" \
    && wget -q -T 30 -t 3 -P "${NODE_TMPDIR}" "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt.asc" \
    && gpgv --keyring=/tmp/node-keyring.kbx --output "${NODE_TMPDIR}/SHASUMS256.txt" < "${NODE_TMPDIR}/SHASUMS256.txt.asc" \
    && grep "  ${NODE_TARBALL}$" "${NODE_TMPDIR}/SHASUMS256.txt" | sed "s|  ${NODE_TARBALL}\$|  ${NODE_TMPDIR}/${NODE_TARBALL}|" | sha256sum -c - \
    && tar xJf "${NODE_TMPDIR}/${NODE_TARBALL}" -C /usr/local --strip-components=1 \
    && rm -rf "${NODE_TMPDIR}" \
    && npm install -g "corepack@${COREPACK_VERSION}" \
    && rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

USER root

# node-gyp dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    export DEBIAN_FRONTEND=noninteractive \
        && apt-get update \
        && apt-get --no-install-recommends install -y build-essential python3

COPY --from=builder /usr/local /usr/local

USER dev
WORKDIR /workspaces
