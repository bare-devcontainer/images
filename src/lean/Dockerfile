# syntax=docker/dockerfile:1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG
FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

ARG ELAN_VERSION
ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

LABEL devcontainer.metadata='[{ \
  "remoteUser": "dev", \
  "containerUser": "dev", \
  "remoteEnv": { \
    "HISTFILE": "/home/dev/.local/state/bash/history", \
    "PATH": "/home/dev/.elan/bin:${containerEnv:PATH}" \
  } \
}]'

# elan's release tarball is verified against a checksum committed to this
# repository, which checksum.sh derives and
# .github/workflows/update-material.yml keeps in sync with ELAN_VERSION.
RUN --mount=type=bind,source=elan-amd64.sha256,target=/tmp/elan-amd64.sha256,ro \
    --mount=type=bind,source=elan-arm64.sha256,target=/tmp/elan-arm64.sha256,ro \
    case "${TARGETARCH}" in \
        amd64) ELAN_ARCH="x86_64"; ELAN_SHA256_FILE="/tmp/elan-amd64.sha256" ;; \
        arm64) ELAN_ARCH="aarch64"; ELAN_SHA256_FILE="/tmp/elan-arm64.sha256" ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && ELAN_TMPDIR="$(mktemp -d)" \
    && ELAN_TARBALL="elan-${ELAN_ARCH}-unknown-linux-gnu.tar.gz" \
    && wget -q -T 30 -t 3 -P "${ELAN_TMPDIR}" \
        "https://github.com/leanprover/elan/releases/download/v${ELAN_VERSION}/${ELAN_TARBALL}" \
    && env --chdir="${ELAN_TMPDIR}" sha256sum -c "${ELAN_SHA256_FILE}" \
    && tar --no-same-owner -xzf "${ELAN_TMPDIR}/${ELAN_TARBALL}" -C "${ELAN_TMPDIR}" \
    && "${ELAN_TMPDIR}/elan-init" -y --no-modify-path --default-toolchain none \
    && rm -rf "${ELAN_TMPDIR}" \
    && mkdir -p \
        /home/dev/.elan/toolchains \
        /home/dev/.cache/mathlib
