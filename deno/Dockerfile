# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG} AS builder

ARG DENO_VERSION
ARG GH_VERSION
ARG TARGETARCH

# hadolint ignore=DL3002 # builder stage is a throwaway; never shipped or run
USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# Install gh from GitHub's official apt repository to verify deno's GitHub
# Artifact Attestation below. The repository keyring is committed to this
# repo and kept in sync via the `materials` declarations in build.yaml.
RUN --mount=type=bind,source=githubcli-archive-keyring.gpg,target=/etc/apt/keyrings/githubcli-archive-keyring.gpg,readonly \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get --no-install-recommends install -y "gh=${GH_VERSION}"

# Deno publishes no signature for its release archives, so its checksum is
# verified below.
# hadolint ignore=DL3003 # cd only used in subshell
RUN case "${TARGETARCH}" in \
        amd64) DENO_ARCH="x86_64" ;; \
        arm64) DENO_ARCH="aarch64" ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && DENO_ZIP="deno-${DENO_ARCH}-unknown-linux-gnu.zip" \
    && DENO_TMPDIR="$(mktemp -d)" \
    # Download deno and verify its checksum
    && wget -q -T 30 -t 3 -P "${DENO_TMPDIR}" "https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/${DENO_ZIP}" \
    && wget -q -T 30 -t 3 -P "${DENO_TMPDIR}" "https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/${DENO_ZIP}.sha256sum" \
    && (cd "${DENO_TMPDIR}" && sha256sum -c "${DENO_ZIP}.sha256sum") \
    # Verify deno's release artifact against its GitHub Artifact Attestation.
    && DENO_DIGEST="$(sha256sum "${DENO_TMPDIR}/${DENO_ZIP}" | awk '{print $1}')" \
    && wget -q -T 30 -t 3 -O "${DENO_TMPDIR}/attestations.json" \
        --header="Accept: application/vnd.github+json" \
        "https://api.github.com/repos/denoland/deno/attestations/sha256:${DENO_DIGEST}" \
    && jq -c '.attestations[].bundle' "${DENO_TMPDIR}/attestations.json" > "${DENO_TMPDIR}/bundles.jsonl" \
    && [ -s "${DENO_TMPDIR}/bundles.jsonl" ] \
    && echo "DIAGNOSTIC predicate types: $(jq -r '.attestations[].bundle.dsseEnvelope.payload | @base64d | fromjson.predicateType' "${DENO_TMPDIR}/attestations.json" | paste -sd ',')" \
    && GH_CONFIG_DIR="${DENO_TMPDIR}/gh-config" gh attestation verify "${DENO_TMPDIR}/${DENO_ZIP}" \
        --bundle "${DENO_TMPDIR}/bundles.jsonl" --repo denoland/deno \
    # Install deno
    && unzip -q "${DENO_TMPDIR}/${DENO_ZIP}" -d "${DENO_TMPDIR}" \
    && mv "${DENO_TMPDIR}/deno" /usr/local/bin/deno \
    && rm -rf "${DENO_TMPDIR}" \
    && /usr/local/bin/deno completions bash > /usr/share/bash-completion/completions/deno

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

COPY --from=builder /usr/local/bin/deno /usr/local/bin/
COPY --from=builder /usr/share/bash-completion/completions/deno /usr/share/bash-completion/completions/deno

RUN mkdir -p /home/dev/.cache/deno
