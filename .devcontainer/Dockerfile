# syntax=docker/dockerfile:1@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183
# check=error=true

FROM ghcr.io/bare-devcontainer/debian:trixie-20261128@sha256:8635c6ebfa1b141775d58b8499f5fb5c83c1e24ae2c39ed2a87b83a2ab977fc2

USER root

# Enable debian backports for `yq-go`.
COPY ./debian-backports.sources /etc/apt/sources.list.d/

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    export DEBIAN_FRONTEND=noninteractive \
      && apt-get update \
      && apt-get --no-install-recommends install -y skopeo yq-go

USER dev

