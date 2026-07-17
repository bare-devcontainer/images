# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG
FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

ARG RUSTUP_VERSION
ARG TARGETARCH

USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    export DEBIAN_FRONTEND=noninteractive \
        && apt-get update \
        && apt-get --no-install-recommends install -y build-essential

ENV PATH=/home/dev/.cargo/bin:${PATH}

USER dev

# rustup publishes no signature for rustup-init, so verify it against a
# checksum file committed to this repository (kept in sync by
# .github/workflows/update-material.yml and reviewed like any other change)
# instead of one fetched from the same server as the binary.
RUN --mount=type=bind,source=rustup-init-amd64.sha256,target=/tmp/rustup-init-amd64.sha256,ro \
    --mount=type=bind,source=rustup-init-arm64.sha256,target=/tmp/rustup-init-arm64.sha256,ro \
    case "${TARGETARCH}" in \
        amd64) RUST_ARCH="x86_64"; RUSTUP_SHA256_FILE="/tmp/rustup-init-amd64.sha256" ;; \
        arm64) RUST_ARCH="aarch64"; RUSTUP_SHA256_FILE="/tmp/rustup-init-arm64.sha256" ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && RUSTUP_TMPDIR="$(mktemp -d)" \
    && wget -q -T 30 -t 3 -P "${RUSTUP_TMPDIR}" \
        "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${RUST_ARCH}-unknown-linux-gnu/rustup-init" \
    && env --chdir="${RUSTUP_TMPDIR}" sha256sum -c "${RUSTUP_SHA256_FILE}" \
    && chmod +x "${RUSTUP_TMPDIR}/rustup-init" \
    && "${RUSTUP_TMPDIR}/rustup-init" -y --no-modify-path --default-toolchain none \
    && rm -rf "${RUSTUP_TMPDIR}" \
    && mkdir -p \
        /home/dev/.cargo/registry \
        /home/dev/.cargo/git
