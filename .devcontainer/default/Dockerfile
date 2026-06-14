FROM ghcr.io/bare-devcontainer/debian:trixie@sha256:22c67997e90d119b37cdf6fce4f170a75eed3dc970e0b80bfb30f0fee9e7755b

USER root

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    export DEBIAN_FRONTEND=noninteractive \
      && apt-get --no-install-recommends install -y skopeo

USER dev
