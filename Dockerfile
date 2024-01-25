# Build Image
#  $ docker build -t clivern/prober:0.12.8 .
#
# Run Probe
#
#  $ docker run -d --rm \
#     --network host \
#     -v $PWD/cloudprober.cfg:/etc/cloudprober.cfg \
#     --name prober \
#     clivern/prober:0.12.8
#
#  http://127.0.0.1:9313/metrics
#  http://127.0.0.1:9313/status

FROM golang:1.21.6 as builder

ENV GO111MODULE=on

ARG CLOUD_PROBER_VERSION=v0.12.8

RUN mkdir -p $GOPATH/src/cloudprober/cloudprober

RUN git clone -b master https://github.com/cloudprober/cloudprober.git $GOPATH/src/github.com/cloudprober/cloudprober

WORKDIR $GOPATH/src/github.com/cloudprober/cloudprober

RUN git checkout tags/$CLOUD_PROBER_VERSION

RUN go mod download

RUN CGO_ENABLED=0 GOOS=linux go build -o cloudprober -ldflags "-X main.version=$CLOUD_PROBER_VERSION -extldflags -static" 
./cmd/cloudprober.go

RUN ./cloudprober -version

FROM alpine:3.19.0

RUN mkdir -p /app/bin

COPY --from=builder /go/src/github.com/cloudprober/cloudprober/cloudprober /app/bin/cloudprober

WORKDIR /app/bin

RUN ./cloudprober -version

CMD ["./cloudprober", "--logtostderr"]

