# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG} AS builder

ARG DENO_VERSION
ARG TARGETARCH

# hadolint ignore=DL3002 # builder stage is a throwaway; never shipped or run
USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# Deno publishes no signature for its release archives, so each archive is
# verified against a checksum file committed to this repository (kept in
# sync by .github/workflows/update-material.yml and reviewed like any other
# change).
RUN --mount=type=bind,source=deno-amd64.sha256,target=/tmp/deno-amd64.sha256,ro \
    --mount=type=bind,source=deno-arm64.sha256,target=/tmp/deno-arm64.sha256,ro \
    case "${TARGETARCH}" in \
        amd64) DENO_ARCH="x86_64"; DENO_SHA256_FILE="/tmp/deno-amd64.sha256" ;; \
        arm64) DENO_ARCH="aarch64"; DENO_SHA256_FILE="/tmp/deno-arm64.sha256" ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && DENO_ZIP="deno-${DENO_ARCH}-unknown-linux-gnu.zip" \
    && DENO_TMPDIR="$(mktemp -d)" \
    && wget -q -T 30 -t 3 -P "${DENO_TMPDIR}" "https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/${DENO_ZIP}" \
    && env --chdir="${DENO_TMPDIR}" sha256sum -c "${DENO_SHA256_FILE}" \
    && unzip -q "${DENO_TMPDIR}/${DENO_ZIP}" -d "${DENO_TMPDIR}" \
    && mv "${DENO_TMPDIR}/deno" /usr/local/bin/deno \
    && rm -rf "${DENO_TMPDIR}" \
    && /usr/local/bin/deno completions bash > /usr/share/bash-completion/completions/deno

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

COPY --from=builder /usr/local/bin/deno /usr/local/bin/
COPY --from=builder /usr/share/bash-completion/completions/deno /usr/share/bash-completion/completions/deno

RUN mkdir -p /home/dev/.cache/deno
