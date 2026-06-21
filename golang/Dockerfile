ARG DEBIAN_TAG=trixie@sha256:22c67997e90d119b37cdf6fce4f170a75eed3dc970e0b80bfb30f0fee9e7755b

FROM golang:1.24.13-trixie@sha256:5835f052b784aa39f2fe9070def3568605c8bc3fcd810f10402066348b61e716 AS golang

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

USER root

COPY --from=golang /usr/local/go /usr/local/go

ENV GOPATH=/home/dev/go
ENV PATH=/usr/local/go/bin:${GOPATH}/bin:${PATH}

RUN install -d -o dev -g dev ${GOPATH}

USER dev
WORKDIR /workspace
