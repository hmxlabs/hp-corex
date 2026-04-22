#!/usr/bin/env bash

# allows x86_64 containers to be run on arm 
docker run --privileged --rm tonistiigi/binfmt --install all

# Build as x86_64
docker build --platform linux/amd64 -t corex-builder -f Dockerfile .

mkdir -p target

# Spawn a temp container and copy the output file out
docker create --name ore-temp corex-builder
docker cp ore-temp:/target/corex-bin-boost-x86_64.tar.gz ./target/


