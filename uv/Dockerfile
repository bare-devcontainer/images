# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG} AS builder

ARG UV_VERSION
ARG TARGETARCH

# hadolint ignore=DL3002 # builder stage is a throwaway; never shipped or run
USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# uv's release tarball is verified against a checksum committed to this repo
# (downloaded from https://releases.astral.sh/, kept in sync by
# .github/workflows/update-material.yml and reviewed like any other change)
# instead of one fetched alongside the binary.
RUN --mount=type=bind,source=uv-amd64.sha256,target=/tmp/uv-amd64.sha256,ro \
    --mount=type=bind,source=uv-arm64.sha256,target=/tmp/uv-arm64.sha256,ro \
    case "${TARGETARCH}" in \
        amd64) UV_ARCH="x86_64"; UV_SHA256_FILE="/tmp/uv-amd64.sha256" ;; \
        arm64) UV_ARCH="aarch64"; UV_SHA256_FILE="/tmp/uv-arm64.sha256" ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && TMPDIR="$(mktemp -d)" \
    # Download uv and verify it against the committed checksum
    && UV_TARBALL="uv-${UV_ARCH}-unknown-linux-gnu.tar.gz" \
    && wget -q -T 30 -t 3 -P "${TMPDIR}" "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/${UV_TARBALL}" \
    && env --chdir="${TMPDIR}" sha256sum -c "${UV_SHA256_FILE}" \
    # Install uv
    && tar xzf "${TMPDIR}/${UV_TARBALL}" -C "${TMPDIR}" \
    && mv "${TMPDIR}/uv-${UV_ARCH}-unknown-linux-gnu/uv" "${TMPDIR}/uv-${UV_ARCH}-unknown-linux-gnu/uvx" /usr/local/bin/ \
    && rm -rf "${TMPDIR}"

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

COPY --from=builder /usr/local/bin/uv /usr/local/bin/uvx /usr/local/bin/

ENV PATH=/home/dev/.local/bin:${PATH}
RUN mkdir -p \
      /home/dev/.cache/uv \
      /home/dev/.local/bin \
      /home/dev/.local/share/uv
