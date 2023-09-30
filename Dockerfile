FROM golang:1.21 AS builder

ENV GIT_REF=master

# Get Kubo
RUN git clone https://github.com/ipfs/kubo /kubo && \
	cd /kubo && \
	git checkout $GIT_REF

WORKDIR /kubo

# Pull in the datastore plugin (you can specify a version other than latest if you'd like).
RUN go get github.com/ipfs/go-ds-s3/plugin@latest

# Add the plugin to the preload list.
RUN echo "\ns3ds github.com/ipfs/go-ds-s3/plugin 0" >> plugin/loader/preload_list

# ( this first pass will fail ) Try to build kubo with the plugin
RUN make build; exit 0

# Update the deptree
RUN go mod tidy

# Now rebuild kubo with the plugin
RUN make build

FROM debian:stable-slim

COPY --from=builder /kubo/cmd/ipfs/ipfs /usr/local/bin/

VOLUME [ "/data" ]

ENV IPFS_PATH=/data

ENTRYPOINT ["ipfs", "daemon" ]