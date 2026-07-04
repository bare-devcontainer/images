# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG} AS builder

ARG TERRAFORM_VERSION
ARG TERRAFORM_LS_VERSION
ARG TARGETARCH

# hadolint ignore=DL3002 # builder stage is a throwaway; never shipped or run
USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3003 # cd only used in subshell
RUN --mount=type=bind,source=hashicorp-signing-key.asc,target=/tmp/hashicorp-signing-key.asc,ro \
    # Import HashiCorp's release signing key into an ephemeral keyring
    GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && gpg --batch --import /tmp/hashicorp-signing-key.asc \
    # Download and verify the official Terraform release
    && TF_ZIP="terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip" \
    && TF_TMPDIR="$(mktemp -d)" \
    && wget -q -T 30 -t 3 -P "${TF_TMPDIR}" "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TF_ZIP}" \
    && wget -q -T 30 -t 3 -P "${TF_TMPDIR}" "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" \
    && wget -q -T 30 -t 3 -P "${TF_TMPDIR}" "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig" \
    && gpg --batch --verify \
        "${TF_TMPDIR}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig" \
        "${TF_TMPDIR}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" \
    && (cd "${TF_TMPDIR}" && grep " ${TF_ZIP}\$" "terraform_${TERRAFORM_VERSION}_SHA256SUMS" | sha256sum -c -) \
    && gpgconf --kill all \
    # Install terraform
    && unzip -q "${TF_TMPDIR}/${TF_ZIP}" -d "${TF_TMPDIR}" \
    && mv "${TF_TMPDIR}/terraform" /usr/local/bin/terraform \
    && rm -rf "${GNUPGHOME}" "${TF_TMPDIR}" \
    # Import HashiCorp's release signing key into an ephemeral keyring
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && gpg --batch --import /tmp/hashicorp-signing-key.asc \
    # Download and verify the official terraform-ls release
    && TFLS_ZIP="terraform-ls_${TERRAFORM_LS_VERSION}_linux_${TARGETARCH}.zip" \
    && TFLS_TMPDIR="$(mktemp -d)" \
    && wget -q -T 30 -t 3 -P "${TFLS_TMPDIR}" "https://releases.hashicorp.com/terraform-ls/${TERRAFORM_LS_VERSION}/${TFLS_ZIP}" \
    && wget -q -T 30 -t 3 -P "${TFLS_TMPDIR}" "https://releases.hashicorp.com/terraform-ls/${TERRAFORM_LS_VERSION}/terraform-ls_${TERRAFORM_LS_VERSION}_SHA256SUMS" \
    && wget -q -T 30 -t 3 -P "${TFLS_TMPDIR}" "https://releases.hashicorp.com/terraform-ls/${TERRAFORM_LS_VERSION}/terraform-ls_${TERRAFORM_LS_VERSION}_SHA256SUMS.sig" \
    && gpg --batch --verify \
        "${TFLS_TMPDIR}/terraform-ls_${TERRAFORM_LS_VERSION}_SHA256SUMS.sig" \
        "${TFLS_TMPDIR}/terraform-ls_${TERRAFORM_LS_VERSION}_SHA256SUMS" \
    && (cd "${TFLS_TMPDIR}" && grep " ${TFLS_ZIP}\$" "terraform-ls_${TERRAFORM_LS_VERSION}_SHA256SUMS" | sha256sum -c -) \
    && gpgconf --kill all \
    # Install terraform-ls
    && unzip -q "${TFLS_TMPDIR}/${TFLS_ZIP}" -d "${TFLS_TMPDIR}" \
    && mv "${TFLS_TMPDIR}/terraform-ls" /usr/local/bin/terraform-ls \
    && rm -rf "${GNUPGHOME}" "${TFLS_TMPDIR}"

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

COPY --from=builder /usr/local/bin/terraform /usr/local/bin/terraform-ls /usr/local/bin/
