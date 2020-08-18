#!/bin/bash

set -e
#set -x

. ./libShell/echo_color.lib


EXEC_CMD=$1
ARCH=$2
BUILD_ROOT_DIR=$3
PKGS=$4

BASE="${PWD}/${BUILD_ROOT_DIR}"
PREFIX="$BASE/stage"
SRC="$BASE/src"
DIST="$BASE/dist"

# gtest
GTEST_VER=1.10.0
GTEST_NAME=googletest-release-${GTEST_VER}
GTEST_URL=https://codeload.github.com/google/googletest/tar.gz/release-${GTEST_VER}

# glog
GLOG_VER=0.4.0
GLOG_NAME=glog-${GLOG_VER}
GLOG_URL=https://codeload.github.com/google/glog/tar.gz/v${GLOG_VER}

# log4c
LOG4C_VER=1.2.4
LOG4C_NAME=log4c-${LOG4C_VER}
LOG4C_URL=https://pilotfiber.dl.sourceforge.net/project/log4c/log4c/${LOG4C_VER}/${LOG4C_NAME}.tar.gz

# libev
LIBEV_VER=4.33
LIBEV_NAME=libev-${LIBEV_VER}
LIBEV_URL=http://dist.schmorp.de/libev/${LIBEV_NAME}.tar.gz

## mbedTLS
MBEDTLS_VER=2.16.6
#MBEDTLS_VER=2.9.0
MBEDTLS_NAME=mbedtls-${MBEDTLS_VER}
MBEDTLS_URL=https://tls.mbed.org/download/${MBEDTLS_NAME}-apache.tgz

## Sodium
SODIUM_VER=1.0.18
#SODIUM_VER=1.0.16
SODIUM_NAME=libsodium-${SODIUM_VER}
SODIUM_URL=https://download.libsodium.org/libsodium/releases/${SODIUM_NAME}.tar.gz

## PCRE
PCRE_VER=8.44
#PCRE_VER=8.42
PCRE_NAME=pcre-${PCRE_VER}
PCRE_URL=https://ftp.pcre.org/pub/pcre/${PCRE_NAME}.tar.gz

#PCRE_VER=10.33
#PCRE_NAME=pcre2-${PCRE_VER}
#PCRE_URL=https://ftp.pcre.org/pub/pcre/${PCRE_NAME}.tar.gz

## c-ares
CARES_VER=1.14.0
CARES_NAME=c-ares-${CARES_VER}
CARES_URL=https://c-ares.haxx.se/download/${CARES_NAME}.tar.gz

#shadowsocks-libev
SHADOWSOCKS_VER=3.3.4
#SHADOWSOCKS_VER=3.2.0
SHADOWSOCKS_NAME=shadowsocks-libev-${SHADOWSOCKS_VER}
SHADOWSOCKS_URL=https://github.com/shadowsocks/shadowsocks-libev/releases/download/v${SHADOWSOCKS_VER}/${SHADOWSOCKS_NAME}.tar.gz

#apt-get update -y
#apt-get install --no-install-recommends -y build-essential gcc-aarch64-linux-gnu g++-aarch64-linux-gnu automake autoconf libtool aria2


# download source
download_sources_func()
{
    DOWN="aria2c --file-allocation=trunc -s10 -x10 -j10 -c"
    
    pushd "${SRC}"

    PKGS_NUM=`echo ${PKGS}|awk -F"," '{print NF}'`
    for ((i=1;i<=${PKGS_NUM};i++)); do
        eval pkg='`echo ${PKGS}|awk -F, "{ print $"$i" }"`'
        name=${pkg}_NAME
        url=${pkg}_URL
        filename="${!name}".tar.gz
        $DOWN ${!url} -o "${filename}"
    done

    popd
}

# extract source
extract_sources_func()
{
    pushd "${SRC}"
    pwd
    mkdir -p ${ARCH}

    PKGS_NUM=`echo ${PKGS}|awk -F"," '{print NF}'`
    for ((i=1;i<=${PKGS_NUM};i++)); do
        eval pkg='`echo ${PKGS}|awk -F, "{ print $"$i" }"`'
        name=${pkg}_NAME
        url=${pkg}_URL
        filename="${!name}".tar.gz
        echoY "Extracting: ${filename}..."
        tar xf ${filename} -C ${ARCH}
    done


    popd
}

# build pkg
build_pkg_func()
{
    PKG=$1

#    echoC "pkg: ${PKG}"

    # static compile arguments
    host=$ARCH-linux-gnu
    prefix=${PREFIX}/$ARCH
#    args="--host=${host} --prefix=${prefix} --disable-shared --enable-static"
#    args="--host=${host} --prefix=${prefix} --disable-shared --enable-static CC=${host}-gcc"
    args="--host=${host} --prefix=${prefix} --enable-static CC=${host}-gcc"

    case $PKG in
        $GTEST_NAME)
            # gtest

            echoY "EXEC_TOOLCHAIN_ROOT_PATH=${EXEC_TOOLCHAIN_ROOT_PATH}"
            echoY "EXEC_CMAKE_CXX_COMPILER=${EXEC_CMAKE_CXX_COMPILER}"
            echoY "EXEC_CMAKE_C_COMPILER=${EXEC_CMAKE_C_COMPILER}"
            echoY "EXEC_CMAKE_FIND_ROOT_PATH=${EXEC_CMAKE_FIND_ROOT_PATH}"
            echoY "EXEC_THREADS_PTHREAD_ARG=${EXEC_THREADS_PTHREAD_ARG}"

            pushd "$SRC/${ARCH}/$GTEST_NAME"
            mkdir build
            if [ $(arch) != ${ARCH} ]
            then
                #echoY "Cross compiling..."

                rm -rf toolchain-${ARCH}.cmake

                echo "set(CMAKE_SYSTEM_NAME Linux)" >> toolchain-${ARCH}.cmake
                echo "set(CMAKE_CROSSCOMPILING TRUE)" >> toolchain-${ARCH}.cmake
                echo "set(CMAKE_CXX_COMPILER ${EXEC_CMAKE_CXX_COMPILER})" >> toolchain-${ARCH}.cmake
                echo "set(CMAKE_C_COMPILER ${EXEC_CMAKE_C_COMPILER})" >> toolchain-${ARCH}.cmake
                echo "set(CMAKE_FIND_ROOT_PATH ${EXEC_CMAKE_FIND_ROOT_PATH})" >> toolchain-${ARCH}.cmake
                echo "set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)" >> toolchain-${ARCH}.cmake
                echo "set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)" >> toolchain-${ARCH}.cmake
                echo "set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)" >> toolchain-${ARCH}.cmake
                echo "set(THREADS_PTHREAD_ARG ${EXEC_THREADS_PTHREAD_ARG})" >> toolchain-${ARCH}.cmake

                cat toolchain-${ARCH}.cmake
                pushd build
                cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=../toolchain-${ARCH}.cmake
                make -j 18
                make install
                popd
            else
                echoY "Native building..."
                pushd build
                cmake .. -DCMAKE_INSTALL_PREFIX=${prefix}
                make -j 18
                #make install DESTDIR=${prefix}
                make install
                popd
            fi
            popd
            ;;
        $GLOG_NAME)
            # glog
            pushd "$SRC/${ARCH}/$GLOG_NAME"
            ./autogen.sh
            ./configure $args
            make clean
            make -j 18
            make install
            popd
            ;;
        $LOG4C_NAME)
            # libev
            pushd "$SRC/${ARCH}/$LOG4C_NAME"
            ./configure $args
            make clean
            make -j 18
            make install
            popd
            ;;
        $LIBEV_NAME)
            # libev
            pushd "$SRC/${ARCH}/$LIBEV_NAME"
            ./configure $args
            make clean
            make -j 18
            make install
            popd
            ;;
        $MBEDTLS_NAME)
            # mbedtls
            pushd "$SRC/${ARCH}/$MBEDTLS_NAME"
            make clean
            # make DESTDIR="${prefix}" CC="${host}-gcc" AR="${host}-ar" LD="${host}-ld" LDFLAGS=-static install -j8
            #export SHARED=1 && make DESTDIR="${prefix}" CC="${host}-gcc" AR="${host}-ar" LD="${host}-ld" LDFLAGS=-static install -j 18
            export SHARED=1 && make DESTDIR="${prefix}" CC="${host}-gcc" AR="${host}-ar" LD="${host}-ld" install -j 18
            unset DESTDIR
            popd
            ;;
        $SODIUM_NAME)
            # sodium
            pushd "$SRC/${ARCH}/$SODIUM_NAME"
            ./configure $args
            make clean
            make -j 18
            make install
            popd
            ;;
        $PCRE_NAME)
            # pcre
            pushd "$SRC/${ARCH}/$PCRE_NAME"
            ./configure $args \
              --enable-unicode-properties --enable-utf8
            make clean
            make -j 18
            make install
            popd
            ;;
        $CARES_NAME)
            # c-ares
            pushd "$SRC/${ARCH}/$CARES_NAME"
            ./configure $args
            make clean
            make -j 18
            make install
            popd
            ;;
    esac

}

# build packages
build_pkgs() {
    PKGS_NUM=`echo ${PKGS}|awk -F"," '{print NF}'`
    for ((i=1;i<=${PKGS_NUM};i++)); do
        eval pkg='`echo ${PKGS}|awk -F, "{ print $"$i" }"`'
        name=${pkg}_NAME
        echoY "Building: ${filename}..."
        build_pkg_func ${!name}
    done
}

build_proj() {
    ARCH=$1
    host=$ARCH-linux-gnu
    prefix=${DIST}/$ARCH
    dep=${PREFIX}/$ARCH 

    pushd "$SRC/${ARCH}/$SHADOWSOCKS_NAME"
    ./configure LIBS="-lpthread -lm" \
        LDFLAGS="-Wl,-static -static -static-libgcc -L$dep/lib" \
        CFLAGS="-I$dep/include" \
        --host=${host} \
        --prefix=${prefix} \
        --disable-ssp \
        --disable-documentation \
        --with-mbedtls="$dep" \
        --with-pcre="$dep" \
        --with-sodium="$dep" \
        --with-cares="$dep"
    make clean
    make install-strip -j8
#    cp ./debian/shadowsocks-libev-*.service ${prefix}/bin/
    popd
    #cp ./setup/srv/* ${prefix}/bin/
}

archClean() 
{
    rm -rf ${PREFIX}/${ARCH} ${SRC}/${ARCH} ${DIST}/${ARCH}
}

mkdir -p ${PREFIX} 
mkdir -p ${SRC} 
mkdir -p ${DIST}


case ${EXEC_CMD} in
    "download")
        download_sources_func
        ;;
    "build")
        archClean
        extract_sources_func
        build_pkgs
        echoG "Building static libs: ${PKGS} finished."
        ;;
esac

exit 0

case $1 in
    "x86_64"|"armv7l") echo "Building static SS for $1..."
        archClean $1
        extract_sources_func $1
        build_deps $1
        build_proj $1
        echo "Building static SS for $1 finished."
        ;;
    "aarch64") echo "Building static SS for aarch64..."
        archClean aarch64
        extract_sources_func aarch64
        build_deps aarch64
        build_proj aarch64
        echo "Building static SS for aarch64 finished."
        ;;
    "all") echo "Building static SS for all platform..."
        dk_clean
        dk_extract_sourcess
        dk_deps
        dk_build
        echo "Building static SS for all platform finished."
        ;;
    *) echo "Unsupported cmd."
        exit 1
esac


exit 0

