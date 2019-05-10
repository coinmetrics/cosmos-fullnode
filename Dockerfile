FROM golang:latest as builder

ARG VERSION

RUN set -ex; \
	mkdir -p $GOPATH/src/github.com/cosmos; \
	cd $GOPATH/src/github.com/cosmos; \
	git clone --depth 1 -b v${VERSION} https://github.com/cosmos/cosmos-sdk.git; \
	cd cosmos-sdk; \
	make tools install


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

RUN set -ex; \
	gaiad init coinmetrics; \
	curl -Lo .gaiad/config/genesis.json https://raw.githubusercontent.com/cosmos/launch/master/genesis.json; \
	sed -i -e "s/seeds = \"\"/seeds = \"$SEEDS\"/" .gaiad/config/config.toml; \
	gaiad unsafe-reset-all

ENTRYPOINT ["gaiad"]
