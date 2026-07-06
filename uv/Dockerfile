# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG} AS builder

ARG UV_VERSION
ARG GH_VERSION
ARG TARGETARCH

# hadolint ignore=DL3002 # builder stage is a throwaway; never shipped or run
USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3003 # cd only used in subshell
RUN case "${TARGETARCH}" in \
        amd64) UV_ARCH="x86_64"; GH_ARCH="amd64" ;; \
        arm64) UV_ARCH="aarch64"; GH_ARCH="arm64" ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && TMPDIR="$(mktemp -d)" \
    # Download uv and verify its checksum
    && UV_TARBALL="uv-${UV_ARCH}-unknown-linux-gnu.tar.gz" \
    && wget -q -T 30 -t 3 -P "${TMPDIR}" "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/${UV_TARBALL}" \
    && wget -q -T 30 -t 3 -P "${TMPDIR}" "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/${UV_TARBALL}.sha256" \
    && (cd "${TMPDIR}" && sha256sum -c "${UV_TARBALL}.sha256") \
    # Download gh to verify uv's GitHub Artifact Attestation below.
    && GH_TARBALL="gh_${GH_VERSION}_linux_${GH_ARCH}.tar.gz" \
    && wget -q -T 30 -t 3 -P "${TMPDIR}" "https://github.com/cli/cli/releases/download/v${GH_VERSION}/${GH_TARBALL}" \
    && wget -q -T 30 -t 3 -P "${TMPDIR}" "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_checksums.txt" \
    && (cd "${TMPDIR}" && grep " ${GH_TARBALL}\$" "gh_${GH_VERSION}_checksums.txt" | sha256sum -c -) \
    && tar xzf "${TMPDIR}/${GH_TARBALL}" -C "${TMPDIR}" \
    && GH_BIN="${TMPDIR}/gh_${GH_VERSION}_linux_${GH_ARCH}/bin/gh" \
    # Verify uv's release artifact against its GitHub Artifact Attestation.
    && UV_DIGEST="$(sha256sum "${TMPDIR}/${UV_TARBALL}" | awk '{print $1}')" \
    && wget -q -T 30 -t 3 -O "${TMPDIR}/attestations.json" \
        --header="Accept: application/vnd.github+json" \
        "https://api.github.com/repos/astral-sh/uv/attestations/sha256:${UV_DIGEST}" \
    && jq -c '.attestations[].bundle' "${TMPDIR}/attestations.json" > "${TMPDIR}/bundles.jsonl" \
    && [ -s "${TMPDIR}/bundles.jsonl" ] \
    && GH_CONFIG_DIR="${TMPDIR}/gh-config" "${GH_BIN}" attestation verify "${TMPDIR}/${UV_TARBALL}" \
        --bundle "${TMPDIR}/bundles.jsonl" --repo astral-sh/uv \
    # Install uv
    && tar xzf "${TMPDIR}/${UV_TARBALL}" -C "${TMPDIR}" \
    && mv "${TMPDIR}/uv-${UV_ARCH}-unknown-linux-gnu/uv" "${TMPDIR}/uv-${UV_ARCH}-unknown-linux-gnu/uvx" /usr/local/bin/ \
    && rm -rf "${TMPDIR}"

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

COPY --from=builder /usr/local/bin/uv /usr/local/bin/uvx /usr/local/bin/

ENV PATH=/home/dev/.local/bin:${PATH}
RUN mkdir -p \
      /home/dev/.cache/uv \
      /home/dev/.local/bin \
      /home/dev/.local/share/uv
