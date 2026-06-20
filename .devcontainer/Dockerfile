FROM ghcr.io/bare-devcontainer/debian:trixie-20260518@sha256:67780c51960cf5154f6188362882a72228e0409618f96f63e4b96efcafee927d

USER root

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    export DEBIAN_FRONTEND=noninteractive \
      && apt-get --no-install-recommends install -y skopeo

USER dev
