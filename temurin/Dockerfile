# syntax=docker/dockerfile:1@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG
FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

ARG TEMURIN_VERSION
ARG TARGETARCH

USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# The apt repository stays configured, so a Dockerfile built on this image can
# install another Temurin release from the same verified source.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=bind,source=adoptium-signing-key.asc,target=/tmp/adoptium-signing-key.asc,ro \
    export DEBIAN_FRONTEND=noninteractive \
    && install -D -m 0644 /tmp/adoptium-signing-key.asc /etc/apt/keyrings/adoptium.asc \
    && . /etc/os-release \
    && printf 'Types: deb\nURIs: https://packages.adoptium.net/artifactory/deb\nSuites: %s\nComponents: main\nSigned-By: /etc/apt/keyrings/adoptium.asc\n' \
        "${VERSION_CODENAME}" > /etc/apt/sources.list.d/adoptium.sources \
    && apt-get update \
    && apt-cache madison "temurin-${TEMURIN_VERSION%%.*}-jdk" \
    && apt-get --no-install-recommends install -y "temurin-${TEMURIN_VERSION%%.*}-jdk=${TEMURIN_VERSION}" \
    # The package installs under this path, which ENV JAVA_HOME below repeats.
    && test -x "/usr/lib/jvm/temurin-${TEMURIN_VERSION%%.*}-jdk-${TARGETARCH}/bin/java"

ENV JAVA_HOME=/usr/lib/jvm/temurin-${TEMURIN_VERSION%%.*}-jdk-${TARGETARCH}

USER dev

RUN mkdir -p \
      /home/dev/.m2/repository \
      /home/dev/.gradle
