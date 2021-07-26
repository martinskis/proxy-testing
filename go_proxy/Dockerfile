FROM golang:latest

WORKDIR /go/src
COPY proxy.go /go/src/
COPY server.pem /go/src/
COPY server.key /go/src/

RUN go build proxy.go
