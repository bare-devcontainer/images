# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG GOLANG_TAG
ARG DEBIAN_TAG
FROM golang:${GOLANG_TAG} AS golang
FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

ARG GOPLS_VERSION

USER root

COPY --from=golang /usr/local/go /usr/local/go

RUN --mount=type=cache,target=/root/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    GOBIN=/usr/local/bin /usr/local/go/bin/go install -v -x "golang.org/x/tools/gopls@${GOPLS_VERSION}"

ENV GOPATH=/home/dev/go
ENV PATH=/usr/local/go/bin:${GOPATH}/bin:${PATH}

USER dev
WORKDIR /workspaces

RUN mkdir -p \
    "${GOPATH}/pkg/mod" \
    /home/dev/.cache/go-build
