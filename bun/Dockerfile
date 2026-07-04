# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG} AS builder

ARG BUN_VERSION
ARG TARGETARCH

# hadolint ignore=DL3002 # builder stage is a throwaway; never shipped or run
USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3003 # cd only used in subshell
RUN --mount=type=bind,source=bun-signing-key.asc,target=/tmp/bun-signing-key.asc,ro \
    case "${TARGETARCH}" in \
        amd64) BUN_ARCH="x64" ;; \
        arm64) BUN_ARCH="aarch64" ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    # Import Bun's release signing key into an ephemeral keyring
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && gpg --batch --import /tmp/bun-signing-key.asc \
    # Download and verify the official Bun release
    && BUN_ZIP="bun-linux-${BUN_ARCH}.zip" \
    && BUN_TMPDIR="$(mktemp -d)" \
    && wget -q -T 30 -t 3 -P "${BUN_TMPDIR}" "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/${BUN_ZIP}" \
    && wget -q -T 30 -t 3 -P "${BUN_TMPDIR}" "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/SHASUMS256.txt.asc" \
    && gpg --batch --verify --output "${BUN_TMPDIR}/SHASUMS256.txt" "${BUN_TMPDIR}/SHASUMS256.txt.asc" \
    && (cd "${BUN_TMPDIR}" && grep " ${BUN_ZIP}\$" SHASUMS256.txt | sha256sum -c -) \
    && gpgconf --kill all \
    # Install bun
    && unzip -q "${BUN_TMPDIR}/${BUN_ZIP}" -d "${BUN_TMPDIR}" \
    && mv "${BUN_TMPDIR}/bun-linux-${BUN_ARCH}/bun" /usr/local/bin/bun \
    && ln -s bun /usr/local/bin/bunx \
    && rm -rf "${GNUPGHOME}" "${BUN_TMPDIR}"

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

COPY --from=builder /usr/local/bin/bun /usr/local/bin/bunx /usr/local/bin/

RUN mkdir -p /home/dev/.bun/install/cache
