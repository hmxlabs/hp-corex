#!/usr/bin/env bash

# This script attempts to ensure the boost libraries and ore binaries are built and ready to be uploaded to the azure blob storage

install_ore_deps () {

    sudo apt update
    sudo apt upgrade -y
    sudo apt install \
        build-essential g++ python3-dev autotools-dev \
        libicu-dev libbz2-dev cmake git doxygen graphviz -y
}



build_ore () {

    # Ensure that we don't pick up any other boost libraries
    export LD_LIBRARY_PATH=

    echo "Treating current directory as root dirctory for build: $ROOT_DIR"
    mkdir --parents boost/root
    mkdir bin
    cd boost
    wget https://archives.boost.io/release/1.81.0/source/boost_1_81_0.tar.gz
    tar -xf boost_1_81_0.tar.gz
    cd boost_1_81_0
    ./bootstrap.sh --prefix=$ROOT_DIR/boost/root > bootstrap.log 2>&1
    if [ $? -ne 0 ]; then
        echo "Bootstrap  of boost libraries failed"
        exit 1
    fi

    ./b2 install > b2-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo "Build of boost libraries failed"
        exit 1
    fi
    echo "Build of boost libraries succeeded"

    cd $ROOT_DIR
    git clone --recurse-submodules https://github.com/hmxlabs/corex-bin.git
    if [ $? -ne 0 ]; then
        echo "Failed to clone corex-bin repository"
        exit 1
    fi
    cd corex-bin
    git checkout tags/v1.8.8.0
    if [ $? -ne 0 ]; then
        echo "Failed to checkout tag v1.8.8.0 of corex-bin repository for build"
        exit 1
    fi


    # TODO: add this warning surpression to the corex-bin repository rather than adding it here
    echo 'add_compiler_flag("-Wno-error=float-conversion" supportsNoFloatConversion)' >> cmake/commonSettings.cmake                                            

    cmake -DBOOST_ROOT=$ROOT_DIR/boost/root -DBOOST_LIBRARYDIR=$ROOT_DIR/boost/root/lib > cmake.log 2>&1
    if [ $? -ne 0 ]; then
        echo "Failed to configure cmake for build"
        exit 1
    fi

    CPU_COUNT=`lscpu | grep "^CPU(s):" | awk '{print $2}'`
    make -j$CPU_COUNT > make.log 2>&1
    if [ $? -ne 0 ]; then
        echo "Failed to build ORE binaries"
        exit 1
    fi
    echo "Build of ORE binaries succeeded"

}




package_ore () {
    if [ -z "$ROOT_DIR" ]; then
        ROOT_DIR=`pwd`
    fi 
    
    cd $ROOT_DIR

    if [ ! -d bin ]; then
        echo "Creating bin directory"
        mkdir --parents $ROOT_DIR/bin
    fi

    echo "Copying ORE binaries to bin directory"
    cp $ROOT_DIR/corex-bin/App/ore $ROOT_DIR/bin
    cp $ROOT_DIR/corex-bin/OREAnalytics/orea/libOREAnalytics.so $ROOT_DIR/bin
    cp $ROOT_DIR/corex-bin/QuantExt/qle/libQuantExt.so $ROOT_DIR/bin
    cp $ROOT_DIR/corex-bin/OREData/ored/libOREData.so $ROOT_DIR/bin
    cp $ROOT_DIR/corex-bin/QuantLib/ql/libQuantLib.so $ROOT_DIR/bin
    cp $ROOT_DIR/corex-bin/QuantLib/ql/libQuantLib.so.1 $ROOT_DIR/bin
    cp $ROOT_DIR/corex-bin/license.txt $ROOT_DIR/bin/ore-license.txt

    echo "Copying boost libraries to bin directory"
    cp $ROOT_DIR/boost/root/lib/* $ROOT_DIR/bin

    echo "Copying other dependencies"
    ldd $ROOT_DIR/bin | grep "=> /" | awk '{print $3}' | xargs -I{} cp {} $ROOT_DIR/bin


    echo "Creating tarball of ORE binaries"
    cd $ROOT_DIR/bin
    tar -czf corex-bin-boost.tar.gz *
    cd $ROOT_DIR
    mv $ROOT_DIR/bin/corex-bin-boost.tar.gz $ROOT_DIR/..
    echo "Packaging of ORE binaries complete"

}





# main 

if [ -d build ]; then 
    echo "WARNING: Build artifacts may be present, proceeding to delete build artifacts in 3s"
    sleep 3s
    clean
fi


mkdir target 

mkdir build 
pushd build

ROOT_DIR=$(pwd)

install_ore_deps
build_ore
package_ore

popd 

rm -rf ./build

mv corex-bin-boost.tar.gz target/corex-bin-boost-$(uname -m).tar.gz










