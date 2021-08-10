# Arguments to Env variables
ARG GO_VERSION=1.16.7
ARG UBUNTU_VERSION=20.04
ARG PROTOBUF_RELEASE_TAG=3.17.3
ARG GRPC_GATEWAY_VERSION=2.5.0
ARG UPX_VERSION=3.96
ARG GRPC_VERSION=1.39.0
ARG PROTOC_GEN_VALIDATE_VERSION=0.6.1

FROM golang:${GO_VERSION} as go_builder

ENV PATH=$PATH:/out/usr/bin

ARG PROTOBUF_RELEASE_TAG
ARG PROTOC_GEN_VALIDATE_VERSION

# Protobuf
RUN mkdir -p /out/usr/bin && \
    mkdir -p /out/usr/include && \
    apt-get update && \
    apt-get -y install unzip

RUN curl -OL "https://github.com/google/protobuf/releases/download/v${PROTOBUF_RELEASE_TAG}/protoc-${PROTOBUF_RELEASE_TAG}-linux-x86_64.zip" && \
    unzip "protoc-${PROTOBUF_RELEASE_TAG}-linux-x86_64.zip" -d protoc3 && \
    mv protoc3/bin/* /out/usr/bin/ && \
    mv protoc3/include/* /out/usr/include/ && \
    rm -rf protoc3 && \
    rm protoc-${PROTOBUF_RELEASE_TAG}-linux-x86_64.zip

RUN go get -u google.golang.org/protobuf/cmd/protoc-gen-go && \
    install -Ds /go/bin/protoc-gen-go /out/usr/bin/

RUN go get -u github.com/srikrsna/protoc-gen-gotag && \
    install -Ds /go/bin/protoc-gen-gotag /out/usr/bin/

#RUN go get -d github.com/envoyproxy/protoc-gen-validate && make build -C /go/pkg/mod/github.com/envoyproxy/protoc-gen-validate/
RUN set -e && \ 
    go get -u github.com/envoyproxy/protoc-gen-validate@v${PROTOC_GEN_VALIDATE_VERSION} && \
    cd /go/pkg/mod/github.com/envoyproxy/protoc-gen-validate@v${PROTOC_GEN_VALIDATE_VERSION} && \
    make build && \
    install -Ds /go/bin/protoc-gen-validate /out/usr/bin/ && \
    mkdir -p /out/usr/include/github.com/envoyproxy/protoc-gen-validate/validate && \
    install -D ./validate/validate.proto /out/usr/include/github.com/envoyproxy/protoc-gen-validate/validate 

FROM ubuntu:${UBUNTU_VERSION} as packer

RUN apt-get update && \
    apt-get -y install curl xz-utils

ARG UPX_VERSION
RUN mkdir -p /upx && curl -sSL https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-amd64_linux.tar.xz | tar xJ --strip 1 -C /upx && \
    install -D /upx/upx /usr/bin/upx

# Use all output including headers and protoc from protoc_builder
# Integrate all output from go_builder
COPY --from=go_builder /out/ /out/

RUN upx --lzma $(find /out/usr/bin/ \
        -type f -name 'grpc_*' \
        -or -name 'protoc-gen-*' \
    )

RUN find /out -name "*.a" -delete -or -name "*.la" -delete



# Final assembly

FROM ubuntu:${UBUNTU_VERSION}

COPY --from=packer /out/ /

LABEL maintainer="Karthik Raman"
COPY protoc-wrapper /usr/bin/protoc-wrapper
ENTRYPOINT ["protoc-wrapper", "-I/usr/include"]

