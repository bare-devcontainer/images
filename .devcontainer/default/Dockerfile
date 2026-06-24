FROM ghcr.io/bare-devcontainer/debian:trixie-20260624@sha256:3127c0d46c375eda6fac9dce68f2a5051b83f2d772e0e9e663ead5c6353fbc11

USER root

# Enable debian backports for `yq-go`.
COPY ./debian-backports.sources /etc/apt/sources.list.d/

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    export DEBIAN_FRONTEND=noninteractive \
      && apt-get update \
      && apt-get --no-install-recommends install -y skopeo yq-go

USER dev
