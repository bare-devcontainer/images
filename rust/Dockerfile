# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG
FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

ARG RUSTUP_VERSION
ARG TARGETARCH

USER root

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
        && export DEBIAN_FRONTEND=noninteractive \
        && apt-get update \
        && apt-get --no-install-recommends install -y build-essential

ENV PATH=/home/dev/.cargo/bin:${PATH}

USER dev
WORKDIR /workspaces

# hadolint ignore=DL3003 # cd only used in subshell
RUN case "${TARGETARCH}" in \
        amd64) RUST_ARCH="x86_64" ;; \
        arm64) RUST_ARCH="aarch64" ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && RUSTUP_TMPDIR="$(mktemp -d)" \
    && RUSTUP_URL="https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${RUST_ARCH}-unknown-linux-gnu" \
    && wget -q -T 30 -t 3 -P "${RUSTUP_TMPDIR}" "${RUSTUP_URL}/rustup-init" \
    && wget -q -T 30 -t 3 -P "${RUSTUP_TMPDIR}" "${RUSTUP_URL}/rustup-init.sha256" \
    && (cd "${RUSTUP_TMPDIR}" && sha256sum -c rustup-init.sha256) \
    && chmod +x "${RUSTUP_TMPDIR}/rustup-init" \
    && "${RUSTUP_TMPDIR}/rustup-init" -y --no-modify-path --default-toolchain none \
    && rm -rf "${RUSTUP_TMPDIR}" \
    && mkdir -p \
        /home/dev/.cargo/registry \
        /home/dev/.cargo/git
