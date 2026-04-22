FROM ubuntu:24.04

# install dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    build-essential \
    g++ \
    python3-dev \
    autotools-dev \
    libicu-dev \
    libbz2-dev \
    cmake \
    git \
    doxygen \
    graphviz \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# build boost
RUN mkdir -p boost/root && \
    cd boost && \
    wget https://archives.boost.io/release/1.81.0/source/boost_1_81_0.tar.gz && \
    tar -xf boost_1_81_0.tar.gz && \
    cd boost_1_81_0 && \
    ./bootstrap.sh --prefix=/build/boost/root > bootstrap.log 2>&1 || (cat bootstrap.log && exit 1) && \
    ./b2 install > b2-install.log 2>&1 || (cat b2-install.log && exit 1)

# clone and checkout corex-bin
RUN git clone --recurse-submodules https://github.com/hmxlabs/corex-bin.git && \
    cd corex-bin && \
    git checkout tags/v1.8.8.0

# apply float-conversion warning fix
RUN echo 'add_compiler_flag("-Wno-error=float-conversion" supportsNoFloatConversion)' \
    >> /build/corex-bin/cmake/commonSettings.cmake

# cmake configure
RUN cd /build/corex-bin && \
    cmake \
        -DBOOST_ROOT=/build/boost/root \
        -DBOOST_LIBRARYDIR=/build/boost/root/lib \
        . > cmake.log 2>&1 || (cat cmake.log && exit 1)

# build
RUN cd /build/corex-bin && \
    make -j$(nproc) 



# package into tarball
RUN mkdir -p /build/bin && mkdir -p /target && \
    cp /build/corex-bin/App/ore                                 /build/bin/ && \
    cp /build/corex-bin/OREAnalytics/orea/libOREAnalytics.so    /build/bin/ && \
    cp /build/corex-bin/QuantExt/qle/libQuantExt.so             /build/bin/ && \
    cp /build/corex-bin/OREData/ored/libOREData.so              /build/bin/ && \
    cp /build/corex-bin/QuantLib/ql/libQuantLib.so              /build/bin/ && \
    cp /build/corex-bin/QuantLib/ql/libQuantLib.so.1            /build/bin/ && \
    cp /build/corex-bin/license.txt                             /build/bin/ore-license.txt && \
    cp -r /build/boost/root/lib/*                                  /build/bin/ && \
    ldd /build/bin/ore | grep "=> /" | awk '{print $3}' | xargs -I{} cp {} /build/bin/ && \
    cd /build/bin && \
    tar -czf /target/corex-bin-boost-x86_64.tar.gz *

# VOLUME /target
