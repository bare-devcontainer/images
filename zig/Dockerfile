# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG
FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

ARG ZIG_VERSION
ARG ZLS_VERSION
ARG TARGETARCH
ARG SHELL_COMPLETIONS_COMMIT

USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
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
    && ZIG_MIRRORS="$(wget -q -T 30 -O - https://ziglang.org/download/community-mirrors.txt | shuf)" \
    && for mirror in ${ZIG_MIRRORS} "https://ziglang.org/download/${ZIG_VERSION}"; do \
           if wget -q -T 30 -t 1 -P "${ZIG_TMPDIR}" "${mirror}/${ZIG_TARBALL}" \
               && wget -q -T 30 -t 1 -P "${ZIG_TMPDIR}" "${mirror}/${ZIG_TARBALL}.minisig"; then \
               break; \
           fi; \
           rm -f "${ZIG_TMPDIR}/${ZIG_TARBALL}" "${ZIG_TMPDIR}/${ZIG_TARBALL}.minisig"; \
       done \
    && test -f "${ZIG_TMPDIR}/${ZIG_TARBALL}" \
    && ZIG_TRUSTED_COMMENT="$(minisign -Vm "${ZIG_TMPDIR}/${ZIG_TARBALL}" -p /tmp/zig-minisign.pub -Q)" \
    && case "${ZIG_TRUSTED_COMMENT}" in \
        *"file:${ZIG_TARBALL}"*) ;; \
        *) echo "Trusted comment does not match requested file" >&2; exit 1 ;; \
       esac \
    && tar xJf "${ZIG_TMPDIR}/${ZIG_TARBALL}" -C "${ZIG_TMPDIR}" \
    && mv "${ZIG_TMPDIR}/zig-${ZIG_ARCH}-linux-${ZIG_VERSION}" /usr/local/zig \
    # Install ZLS
    && ZLS_TARBALL="zls-${ZIG_ARCH}-linux-${ZLS_VERSION}.tar.xz" \
    && wget -q -T 30 -t 3 -P "${ZIG_TMPDIR}" "https://builds.zigtools.org/${ZLS_TARBALL}" \
    && wget -q -T 30 -t 3 -P "${ZIG_TMPDIR}" "https://builds.zigtools.org/${ZLS_TARBALL}.minisig" \
    && ZLS_TRUSTED_COMMENT="$(minisign -Vm "${ZIG_TMPDIR}/${ZLS_TARBALL}" -p /tmp/zls-minisign.pub -Q)" \
    && case "${ZLS_TRUSTED_COMMENT}" in \
        *"file:${ZLS_TARBALL}"*) ;; \
        *) echo "Trusted comment does not match requested file" >&2; exit 1 ;; \
       esac \
    && tar xJf "${ZIG_TMPDIR}/${ZLS_TARBALL}" -C "${ZIG_TMPDIR}" \
    && mv "${ZIG_TMPDIR}/zls" /usr/local/bin/zls \
    # Install shell completions for Zig
    && wget -q -T 30 -t 3 -O /usr/share/bash-completion/completions/zig \
        "https://codeberg.org/ziglang/shell-completions/raw/commit/${SHELL_COMPLETIONS_COMMIT}/_zig.bash" \
    && rm -rf "${ZIG_TMPDIR}"

ENV PATH=/usr/local/zig:${PATH}

USER dev
WORKDIR /workspaces

RUN mkdir -p /home/dev/.cache/zig
