ARG DEBIAN_TAG

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

ARG ZIG_VERSION
ARG TARGETARCH
ARG SHELL_COMPLETIONS_COMMIT

USER root

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=bind,source=zig-minisign.pub,target=/tmp/zig-minisign.pub \
    export DEBIAN_FRONTEND=noninteractive \
        && apt-get update \
        && apt-get --no-install-recommends install -y minisign \
    && case "${TARGETARCH}" in \
        amd64) ZIG_ARCH="x86_64" ;; \
        arm64) ZIG_ARCH="aarch64" ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && ZIG_TARBALL="zig-${ZIG_ARCH}-linux-${ZIG_VERSION}.tar.xz" \
    && ZIG_TMPDIR="$(mktemp -d)" \
    && wget -q -P "${ZIG_TMPDIR}" "https://ziglang.org/download/${ZIG_VERSION}/${ZIG_TARBALL}" \
    && wget -q -P "${ZIG_TMPDIR}" "https://ziglang.org/download/${ZIG_VERSION}/${ZIG_TARBALL}.minisig" \
    && minisign -Vm "${ZIG_TMPDIR}/${ZIG_TARBALL}" -p /tmp/zig-minisign.pub \
    && tar xJf "${ZIG_TMPDIR}/${ZIG_TARBALL}" -C "${ZIG_TMPDIR}" \
    && mv "${ZIG_TMPDIR}/zig-${ZIG_ARCH}-linux-${ZIG_VERSION}" /usr/local/zig \
    && rm -rf "${ZIG_TMPDIR}" \
    && wget -q -O /usr/share/bash-completion/completions/zig \
        "https://codeberg.org/ziglang/shell-completions/raw/commit/${SHELL_COMPLETIONS_COMMIT}/_zig.bash"

ENV PATH=/usr/local/zig:${PATH}

USER dev
WORKDIR /workspaces
