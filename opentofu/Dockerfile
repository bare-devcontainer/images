# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG} AS builder

ARG OPENTOFU_VERSION
ARG TOFU_LS_VERSION
ARG TARGETARCH

# hadolint ignore=DL3002 # builder stage is a throwaway; never shipped or run
USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN --mount=type=bind,source=opentofu-signing-key.asc,target=/tmp/opentofu-signing-key.asc,ro \
    --mount=type=bind,source=tofu-ls-checksums.txt,target=/tmp/tofu-ls-checksums.txt,ro \
    # Import OpenTofu's release signing key into an ephemeral keyring
    GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && gpg --batch --import /tmp/opentofu-signing-key.asc \
    # Download and verify the official OpenTofu release
    && TOFU_URL="https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}" \
    && TOFU_ZIP="tofu_${OPENTOFU_VERSION}_linux_${TARGETARCH}.zip" \
    && TOFU_SUMS="tofu_${OPENTOFU_VERSION}_SHA256SUMS" \
    && TOFU_TMPDIR="$(mktemp -d)" \
    && wget -q -T 30 -t 3 -P "${TOFU_TMPDIR}" "${TOFU_URL}/${TOFU_ZIP}" \
    && wget -q -T 30 -t 3 -P "${TOFU_TMPDIR}" "${TOFU_URL}/${TOFU_SUMS}" \
    && wget -q -T 30 -t 3 -P "${TOFU_TMPDIR}" "${TOFU_URL}/${TOFU_SUMS}.gpgsig" \
    && gpg --batch --verify \
        "${TOFU_TMPDIR}/${TOFU_SUMS}.gpgsig" \
        "${TOFU_TMPDIR}/${TOFU_SUMS}" \
    && grep " ${TOFU_ZIP}\$" "${TOFU_TMPDIR}/${TOFU_SUMS}" | env --chdir="${TOFU_TMPDIR}" sha256sum -c - \
    && gpgconf --kill all \
    # Install tofu. The archive carries its documentation alongside the binary,
    # so the binary is moved out rather than the whole extraction directory.
    && unzip -q "${TOFU_TMPDIR}/${TOFU_ZIP}" -d "${TOFU_TMPDIR}" \
    && mv "${TOFU_TMPDIR}/tofu" /usr/local/bin/tofu \
    && rm -rf "${GNUPGHOME}" "${TOFU_TMPDIR}" \
    # tofu-ls names its archives after `uname` rather than the Go architecture
    && case "${TARGETARCH}" in \
        amd64) TOFU_LS_ARCH="x86_64" ;; \
        arm64) TOFU_LS_ARCH="arm64" ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    # Download tofu-ls and verify it against the committed checksums
    && TOFU_LS_TARBALL="tofu-ls_Linux_${TOFU_LS_ARCH}.tar.gz" \
    && TOFU_LS_TMPDIR="$(mktemp -d)" \
    && wget -q -T 30 -t 3 -P "${TOFU_LS_TMPDIR}" \
        "https://github.com/opentofu/tofu-ls/releases/download/v${TOFU_LS_VERSION}/${TOFU_LS_TARBALL}" \
    && grep "  ${TOFU_LS_TARBALL}\$" /tmp/tofu-ls-checksums.txt | env --chdir="${TOFU_LS_TMPDIR}" sha256sum -c - \
    # Install tofu-ls. The archive records the uid of the account that built it,
    # which tar restores when it runs as root, so install rather than move the
    # binary to keep it owned by root like everything else under /usr/local/bin.
    && tar -xzf "${TOFU_LS_TMPDIR}/${TOFU_LS_TARBALL}" -C "${TOFU_LS_TMPDIR}" \
    && install -m 755 "${TOFU_LS_TMPDIR}/tofu-ls" /usr/local/bin/tofu-ls \
    && rm -rf "${TOFU_LS_TMPDIR}"

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

COPY --from=builder /usr/local/bin/tofu /usr/local/bin/tofu-ls /usr/local/bin/

ENV TF_PLUGIN_CACHE_DIR="/home/dev/.terraform.d/plugin-cache"
RUN mkdir -p "${TF_PLUGIN_CACHE_DIR}"
