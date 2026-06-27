FROM ghcr.io/bare-devcontainer/debian:trixie-20260627@sha256:25f65b9548a12b79221933b84ffcd8c83b0a7dc3af3001aa6b42e5119cf9e0cb

USER root

# Enable debian backports for `yq-go`.
COPY ./debian-backports.sources /etc/apt/sources.list.d/

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    export DEBIAN_FRONTEND=noninteractive \
      && apt-get update \
      && apt-get --no-install-recommends install -y skopeo yq-go

USER dev
