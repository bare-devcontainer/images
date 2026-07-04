# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG

# ---- Builder stage: download, verify, and build the toolchain in isolation ----
FROM debian:trixie-slim@sha256:28de0877c2189802884ccd20f15ee41c203573bd87bb6b883f5f46362d24c5c2 AS builder

ARG GOLANG_VERSION
ARG GOPLS_VERSION
ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=bind,source=google-linux-signing-key.asc,target=/tmp/google-linux-signing-key.asc,ro \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get --no-install-recommends install -y ca-certificates wget gnupg git \
    # Import Google's Linux Packages signing key into an ephemeral keyring
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && gpg --batch --import /tmp/google-linux-signing-key.asc \
    # Download and verify the official Go toolchain
    && GO_TARBALL="go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz" \
    && GO_TMPDIR="$(mktemp -d)" \
    && wget -q -T 30 -t 3 -P "${GO_TMPDIR}" "https://go.dev/dl/${GO_TARBALL}" \
    && wget -q -T 30 -t 3 -P "${GO_TMPDIR}" "https://go.dev/dl/${GO_TARBALL}.asc" \
    && gpg --batch --verify "${GO_TMPDIR}/${GO_TARBALL}.asc" "${GO_TMPDIR}/${GO_TARBALL}" \
    && gpgconf --kill all \
    && tar xzf "${GO_TMPDIR}/${GO_TARBALL}" -C /usr/local \
    && rm -rf "${GNUPGHOME}" "${GO_TMPDIR}"

RUN --mount=type=cache,target=/root/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    GOBIN=/usr/local/bin /usr/local/go/bin/go install "golang.org/x/tools/gopls@${GOPLS_VERSION}"

# ---- Final stage: only the verified binaries plus runtime dependencies ----
FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

ARG TARGETARCH

USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# cgo dependencies kept as runtime dependencies.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    export DEBIAN_FRONTEND=noninteractive \
        && apt-get update \
        && apt-get --no-install-recommends install -y \
            build-essential pkg-config \
    # Go's external linker needs the gold linker on arm64
    # https://github.com/golang/go/issues/22040
    && if [ "${TARGETARCH}" = "arm64" ]; then \
           apt-get --no-install-recommends install -y binutils-gold; \
       fi

COPY --from=builder /usr/local/go /usr/local/go
COPY --from=builder /usr/local/bin/gopls /usr/local/bin/gopls

ENV GOPATH=/home/dev/go
ENV PATH=/usr/local/go/bin:${GOPATH}/bin:${PATH}

USER dev
WORKDIR /workspaces

RUN mkdir -p \
    "${GOPATH}/pkg/mod" \
    /home/dev/.cache/go-build
