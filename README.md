# pb-gen
docker image for protobuf go code generation

fork from  https://github.com/jaegertracing/docker-protobuf and https://github.com/eldad87/go-boilerplate


## Supported languages
- Go

## Usage
```

docker run -it --rm -v"${PWD}":/workdir achuala.in/pb-gen  --proto_path=/workdir/proto --go_out="module=${PACKAGE}:/workdir" --validate_out="module=${PACKAGE},lang=go:/workdir" api.proto
