# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG
FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

USER root

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
        && export DEBIAN_FRONTEND=noninteractive \
        && apt-get update \
        && apt-get --no-install-recommends install -y build-essential rustup

ENV PATH=/home/dev/.cargo/bin:${PATH}

USER dev
WORKDIR /workspaces

RUN mkdir -p \
      /home/dev/.cargo/registry \
      /home/dev/.cargo/git
