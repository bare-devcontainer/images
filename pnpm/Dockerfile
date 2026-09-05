# syntax=docker/dockerfile:1@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG} AS builder

ARG PNPM_VERSION
ARG TARGETARCH

# hadolint ignore=DL3002 # builder stage is a throwaway; never shipped or run
USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN --mount=type=bind,source=pnpm-amd64.sha256,target=/tmp/pnpm-amd64.sha256,ro \
    --mount=type=bind,source=pnpm-arm64.sha256,target=/tmp/pnpm-arm64.sha256,ro \
    case "${TARGETARCH}" in \
        amd64) PNPM_ARCH="x64"; PNPM_SHA256_FILE="/tmp/pnpm-amd64.sha256" ;; \
        arm64) PNPM_ARCH="arm64"; PNPM_SHA256_FILE="/tmp/pnpm-arm64.sha256" ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && PNPM_TARBALL="pnpm-linux-${PNPM_ARCH}.tar.gz" \
    && PNPM_TMPDIR="$(mktemp -d)" \
    && wget -q -T 30 -t 3 -P "${PNPM_TMPDIR}" "https://github.com/pnpm/pnpm/releases/download/v${PNPM_VERSION}/${PNPM_TARBALL}" \
    && env --chdir="${PNPM_TMPDIR}" sha256sum -c "${PNPM_SHA256_FILE}" \
    && mkdir -p /opt/pnpm \
    && tar --no-same-owner -xzf "${PNPM_TMPDIR}/${PNPM_TARBALL}" -C /opt/pnpm \
    && rm -rf "${PNPM_TMPDIR}" \
    && test "$(/opt/pnpm/pnpm --version)" = "${PNPM_VERSION}" \
    && /opt/pnpm/pnpm completion bash > /usr/share/bash-completion/completions/pnpm

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

COPY --from=builder /opt/pnpm /opt/pnpm
COPY --from=builder /usr/share/bash-completion/completions/pnpm /usr/share/bash-completion/completions/pnpm

USER root

RUN ln -s /opt/pnpm/pnpm /usr/local/bin/pnpm

ENV PNPM_HOME=/home/dev/.local/share/pnpm
ENV PATH=${PNPM_HOME}/bin:${PATH}

USER dev

RUN mkdir -p \
    /home/dev/.cache/pnpm \
    "${PNPM_HOME}/bin"
