#!/usr/bin/env bash

mkdir target 

git clone https://github.com/hmxlabs/corex.git && pushd corex ; 

./build.sh

popd && cp corex/corex.tar.gz target
