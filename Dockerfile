FROM golang:latest as builder

ARG VERSION

RUN set -ex; \
	mkdir -p $GOPATH/src/github.com/cosmos; \
	git clone --depth 1 -b v${VERSION} https://github.com/cosmos/gaia.git $GOPATH/src/github.com/cosmos/gaia; \
	cd $GOPATH/src/github.com/cosmos/gaia; \
	make install


FROM debian:stretch

RUN set -ex; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		netbase \
		ca-certificates \
		curl \
	; \
	rm -rf /var/lib/apt/lists/*

COPY --from=builder /go/bin/* /usr/bin/

RUN useradd -m -u 1000 -s /bin/bash runner
USER runner
WORKDIR /home/runner

ARG SEEDS

RUN gaiad init coinmetrics

COPY genesis.json /home/runner/.gaiad/config/genesis.json

RUN set -ex; \
	sed -i -e "s/seeds = \"\"/seeds = \"$SEEDS\"/" -e 's?laddr = "tcp://127.0.0.1:26657"?laddr = "tcp://0.0.0.0:26657"?' .gaiad/config/config.toml; \
	gaiad unsafe-reset-all

ENTRYPOINT ["gaiad"]
