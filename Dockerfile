FROM golang:1.17-alpine3.14 AS builder

ARG VERSION

# Set up dependencies
# Ref : https://github.com/cosmos/gaia/blob/main/contrib/Dockerfile.test
ENV PACKAGES curl make git libc-dev bash gcc linux-headers eudev-dev python3

RUN set -ex; \
	apk add --no-cache $PACKAGES

RUN git clone --depth 1 -b v${VERSION} https://github.com/cosmos/gaia.git /opt/gaia
WORKDIR /opt/gaia
RUN make install

FROM alpine:3.14

RUN set -ex; \
	apk add --update ca-certificates

COPY --from=builder /go/bin/gaiad /usr/bin/gaiad

RUN adduser -D -u 1000 cosmos
RUN chown -R 1000:1000 /opt
USER cosmos
WORKDIR /opt

# gRPC port
EXPOSE 9090
# RestAPi port
EXPOSE 1317
# Protmetheus port
EXPOSE 26600
# P2P port
EXPOSE 26656
# Tendermint ABCI port
EXPOSE 26657
# Rosetta port
EXPOSE 8080

ENTRYPOINT ["gaiad"]
