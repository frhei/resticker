#
# Builder image
#
FROM golang:alpine AS builder

RUN apk add --update --no-cache curl git

ARG RESTIC_VERSION=0.9.1
ARG RESTIC_SHA256=359d3b8e555a9952f2b98c81ee3dbec8dc441e12789c436ca564762aaacec095
ARG GO_CRON_VERSION=0.0.2
ARG GO_CRON_SHA256=ca2acebf00d61cede248b6ffa8dcb1ef5bb92e7921acff3f9d6f232f0b6cf67a

RUN curl -sL -o go-cron.tar.gz https://github.com/michaloo/go-cron/archive/v${GO_CRON_VERSION}.tar.gz \
 && echo "${GO_CRON_SHA256}  go-cron.tar.gz" | sha256sum -c - \
 && tar xzf go-cron.tar.gz \
 && cd go-cron-${GO_CRON_VERSION} \
 && export GOBIN=$GOPATH/bin \
 && go get \
 && go build \
 && mv $GOPATH/bin/go-cron-${GO_CRON_VERSION} /usr/local/bin/go-cron \
 && cd .. \
 && rm go-cron.tar.gz go-cron-${GO_CRON_VERSION} -fR

RUN curl -sL -o restic.tar.gz https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic-${RESTIC_VERSION}.tar.gz \
 && echo "${RESTIC_SHA256}  restic.tar.gz" | sha256sum -c - \
 && tar xzf restic.tar.gz \
 && cd restic-${RESTIC_VERSION} \
 && go run build.go \
 && mv restic /usr/local/bin/restic \
 && cd .. \
 && rm restic.tar.gz restic-${RESTIC_VERSION} -fR

#
# Final image
#
FROM arm32v6/alpine:latest

RUN apk add --update --no-cache ca-certificates fuse nfs-utils openssh

ENV RESTIC_REPOSITORY /mnt/restic

RUN apk add tzdata \
 && cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime \
 && echo "Europe/Berlin" >  /etc/timezone \
 && apk del tzdata

COPY --from=builder /usr/local/bin/* /usr/local/bin/
COPY backup /usr/local/bin/
COPY entrypoint /

ENTRYPOINT ["/entrypoint"]
