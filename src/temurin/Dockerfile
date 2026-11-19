# syntax=docker/dockerfile:1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG
FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

ARG TEMURIN_VERSION_AMD64
ARG TEMURIN_VERSION_ARM64
ARG TARGETARCH

USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# The apt repository stays configured, so a Dockerfile built on this image can
# install another Temurin release from the same verified source.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=bind,source=adoptium-signing-key.asc,target=/tmp/adoptium-signing-key.asc,ro \
    export DEBIAN_FRONTEND=noninteractive \
    # A tag names one update release for both architectures, so the build args
    # may differ in the respin and build number only.
    && if [ "$(cut -d. -f1-3 <<< "${TEMURIN_VERSION_AMD64}")" != "$(cut -d. -f1-3 <<< "${TEMURIN_VERSION_ARM64}")" ]; then \
         echo "TEMURIN_VERSION_AMD64 (${TEMURIN_VERSION_AMD64}) and TEMURIN_VERSION_ARM64 (${TEMURIN_VERSION_ARM64}) name different update releases" >&2; \
         exit 1; \
       fi \
    && case "${TARGETARCH}" in \
         amd64) TEMURIN_VERSION="${TEMURIN_VERSION_AMD64}" ;; \
         arm64) TEMURIN_VERSION="${TEMURIN_VERSION_ARM64}" ;; \
         *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
       esac \
    && install -D -m 0644 /tmp/adoptium-signing-key.asc /etc/apt/keyrings/adoptium.asc \
    && . /etc/os-release \
    && printf 'Types: deb\nURIs: https://packages.adoptium.net/artifactory/deb\nSuites: %s\nComponents: main\nSigned-By: /etc/apt/keyrings/adoptium.asc\n' \
        "${VERSION_CODENAME}" > /etc/apt/sources.list.d/adoptium.sources \
    && apt-get update \
    # TEMURIN_VERSION carries no Debian revision; the glob takes the newest one
    # the repository has for this architecture.
    && apt-get --no-install-recommends install -y "temurin-${TEMURIN_VERSION%%.*}-jdk=${TEMURIN_VERSION}-*" \
    # The package installs under a directory naming the feature release and the
    # architecture. The symlink gives every variant of this image the same
    # JAVA_HOME, so a devcontainer.json can point a Java extension at the JDK
    # without knowing which tag it is running; smoke-test.sh asserts the path.
    && ln -s "temurin-${TEMURIN_VERSION%%.*}-jdk-${TARGETARCH}" /usr/lib/jvm/temurin \
    && test -x /usr/lib/jvm/temurin/bin/java

ENV JAVA_HOME=/usr/lib/jvm/temurin

USER dev

RUN mkdir -p \
      /home/dev/.m2/repository \
      /home/dev/.gradle
