# syntax=docker/dockerfile:1@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32
# check=error=true

FROM ghcr.io/bare-devcontainer/debian:trixie-20260821@sha256:134cb0d7ebe988217c1fc96596fa37d5fe7d7f37ac4a27c1e0bf1eef8d54dca3

USER root

# Enable debian backports for `yq-go`.
COPY ./debian-backports.sources /etc/apt/sources.list.d/

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    export DEBIAN_FRONTEND=noninteractive \
      && apt-get update \
      && apt-get --no-install-recommends install -y skopeo yq-go

USER dev

