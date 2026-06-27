# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# check=skip=InvalidDefaultArgInFrom
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG
FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

ARG ZIG_VERSION
ARG ZLS_VERSION
ARG TARGETARCH
ARG SHELL_COMPLETIONS_COMMIT

USER root

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=bind,source=zig-minisign.pub,target=/tmp/zig-minisign.pub \
    --mount=type=bind,source=zls-minisign.pub,target=/tmp/zls-minisign.pub \
    export DEBIAN_FRONTEND=noninteractive \
        && apt-get update \
        && apt-get --no-install-recommends install -y minisign \
    && case "${TARGETARCH}" in \
        amd64) ZIG_ARCH="x86_64" ;; \
        arm64) ZIG_ARCH="aarch64" ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && ZIG_TMPDIR="$(mktemp -d)" \
    # Install Zig
    && ZIG_TARBALL="zig-${ZIG_ARCH}-linux-${ZIG_VERSION}.tar.xz" \
    && wget -q -P "${ZIG_TMPDIR}" "https://ziglang.org/download/${ZIG_VERSION}/${ZIG_TARBALL}" \
    && wget -q -P "${ZIG_TMPDIR}" "https://ziglang.org/download/${ZIG_VERSION}/${ZIG_TARBALL}.minisig" \
    && minisign -Vm "${ZIG_TMPDIR}/${ZIG_TARBALL}" -p /tmp/zig-minisign.pub \
    && tar xJf "${ZIG_TMPDIR}/${ZIG_TARBALL}" -C "${ZIG_TMPDIR}" \
    && mv "${ZIG_TMPDIR}/zig-${ZIG_ARCH}-linux-${ZIG_VERSION}" /usr/local/zig \
    # Install ZLS
    && ZLS_TARBALL="zls-${ZIG_ARCH}-linux-${ZLS_VERSION}.tar.xz" \
    && wget -q -P "${ZIG_TMPDIR}" "https://builds.zigtools.org/${ZLS_TARBALL}" \
    && wget -q -P "${ZIG_TMPDIR}" "https://builds.zigtools.org/${ZLS_TARBALL}.minisig" \
    && minisign -Vm "${ZIG_TMPDIR}/${ZLS_TARBALL}" -p /tmp/zls-minisign.pub \
    && tar xJf "${ZIG_TMPDIR}/${ZLS_TARBALL}" -C "${ZIG_TMPDIR}" \
    && mv "${ZIG_TMPDIR}/zls" /usr/local/bin/zls \
    # Install shell completions for Zig
    && wget -q -O /usr/share/bash-completion/completions/zig \
        "https://codeberg.org/ziglang/shell-completions/raw/commit/${SHELL_COMPLETIONS_COMMIT}/_zig.bash" \
    && rm -rf "${ZIG_TMPDIR}"

ENV PATH=/usr/local/zig:${PATH}

RUN install -d -o dev -g dev /home/dev/.cache/zig

USER dev
WORKDIR /workspaces
