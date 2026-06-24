FROM ghcr.io/bare-devcontainer/debian:trixie-20260622@sha256:06086f7fef2b18505e936d0b47bece0513cf790a16d6e5aa03c7fecd109a34e1

USER root

# Enable debian backports for `yq-go`.
COPY ./debian-backports.sources /etc/apt/sources.list.d/

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    export DEBIAN_FRONTEND=noninteractive \
      && apt-get update \
      && apt-get --no-install-recommends install -y skopeo yq-go

USER dev
