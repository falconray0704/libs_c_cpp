#!/bin/bash

set -e
set -x

. ./libShell/echo_color.lib


EXEC_CMD=$1
ARCH=$2
BUILD_ROOT_DIR=$3
PKGS=$4

BASE="${PWD}/${BUILD_ROOT_DIR}"
PREFIX="$BASE/stage"
SRC="$BASE/src"
DIST="$BASE/dist"

# boost
BOOST_VER=1.74.0
BOOST_NAME=boost_1_74_0
#BOOST_VER=1.64.0
#BOOST_NAME=boost_1_64_0
BOOST_URL=https://master.dl.sourceforge.net/project/boost/boost/${BOOST_VER}/${BOOST_NAME}.tar.gz
BOOST_URL_TYPE=TARGZ_URL
BOOST_BUILD_TYPE=PRIVATE_BUILD

# libyuv
LIBYUV_VER=
LIBYUV_NAME=libyuv
LIBYUV_URL=https://chromium.googlesource.com/libyuv/libyuv
LIBYUV_URL_TYPE=GIT_URL
LIBYUV_BUILD_TYPE=CMAKE_BUILD

# gtest
GTEST_VER=1.10.0
GTEST_NAME=googletest-release-${GTEST_VER}
GTEST_URL=https://codeload.github.com/google/googletest/tar.gz/release-${GTEST_VER}
GTEST_URL_TYPE=TARGZ_URL
GTEST_BUILD_TYPE=CMAKE_BUILD

# glog
GLOG_VER=0.4.0
GLOG_NAME=glog-${GLOG_VER}
GLOG_URL=https://codeload.github.com/google/glog/tar.gz/v${GLOG_VER}
GLOG_URL_TYPE=TARGZ_URL
GLOG_BUILD_TYPE=MAKE_BUILD

# log4c
LOG4C_VER=1.2.4
LOG4C_NAME=log4c-${LOG4C_VER}
LOG4C_URL=https://pilotfiber.dl.sourceforge.net/project/log4c/log4c/${LOG4C_VER}/${LOG4C_NAME}.tar.gz
LOG4C_URL_TYPE=TARGZ_URL
LOG4C_BUILD_TYPE=MAKE_BUILD

# libev
LIBEV_VER=4.33
LIBEV_NAME=libev-${LIBEV_VER}
LIBEV_URL=http://dist.schmorp.de/libev/${LIBEV_NAME}.tar.gz
LIBEV_URL_TYPE=TARGZ_URL
LIBEV_BUILD_TYPE=MAKE_BUILD

## mbedTLS
MBEDTLS_VER=2.16.6
#MBEDTLS_VER=2.9.0
MBEDTLS_NAME=mbedtls-${MBEDTLS_VER}
MBEDTLS_URL=https://tls.mbed.org/download/${MBEDTLS_NAME}-apache.tgz
MBEDTLS_URL_TYPE=TARGZ_URL
MBEDTLS_BUILD_TYPE=MAKE_BUILD

## Sodium
SODIUM_VER=1.0.18
#SODIUM_VER=1.0.16
SODIUM_NAME=libsodium-${SODIUM_VER}
SODIUM_URL=https://download.libsodium.org/libsodium/releases/${SODIUM_NAME}.tar.gz
SODIUM_URL_TYPE=TARGZ_URL
SODIUM_BUILD_TYPE=MAKE_BUILD

## PCRE
PCRE_VER=8.44
#PCRE_VER=8.42
PCRE_NAME=pcre-${PCRE_VER}
PCRE_URL=https://ftp.pcre.org/pub/pcre/${PCRE_NAME}.tar.gz
PCRE_URL_TYPE=TARGZ_URL
PCRE_BUILD_TYPE=MAKE_BUILD

#PCRE_VER=10.33
#PCRE_NAME=pcre2-${PCRE_VER}
#PCRE_URL=https://ftp.pcre.org/pub/pcre/${PCRE_NAME}.tar.gz

## c-ares
CARES_VER=1.14.0
CARES_NAME=c-ares-${CARES_VER}
CARES_URL=https://c-ares.haxx.se/download/${CARES_NAME}.tar.gz
CARES_URL_TYPE=TARGZ_URL
CARES_BUILD_TYPE=MAKE_BUILD

#shadowsocks-libev
SHADOWSOCKS_VER=3.3.4
#SHADOWSOCKS_VER=3.2.0
SHADOWSOCKS_NAME=shadowsocks-libev-${SHADOWSOCKS_VER}
SHADOWSOCKS_URL=https://github.com/shadowsocks/shadowsocks-libev/releases/download/v${SHADOWSOCKS_VER}/${SHADOWSOCKS_NAME}.tar.gz
SHADOWSOCKS_URL_TYPE=TARGZ_URL
SHADOWSOCKS_BUILD_TYPE=MAKE_BUILD

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
        url_type=${pkg}_URL_TYPE
        name=${pkg}_NAME
        url=${pkg}_URL
        filename="${!name}".tar.gz
        if [ ${!url_type} == TARGZ_URL ]
        then
            echoC "Downloading ${!url}..."
            $DOWN ${!url} -o "${filename}"
        elif [ ${!url_type} == GIT_URL ]
        then
            if [ ! -x ${!name} ]
            then
                echoC "git cloning  ${!url}..."
                git clone --depth=1 ${!url} ${!name}
            else
                echoC "git updating  ${!url}..."
                pushd ${!name}
                git pull
                popd
            fi

            pushd ${!name}
            git pull
            git submodule init
            git submodule update
            popd
        else
            echoR "Unknown url type: ${!url_type} for ${pkg}"
        fi
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
        url_type=${pkg}_URL_TYPE
        name=${pkg}_NAME
        url=${pkg}_URL

        if [ ${!url_type} == TARGZ_URL ]
        then
            filename="${!name}".tar.gz
            echoY "Extracting: ${filename}..."
            tar xf ${filename} -C ${ARCH}
        elif [ ${!url_type} == GIT_URL ]
        then
            cp -a ${!name} ${ARCH}/
        else
            echoR "Unknown url type: ${!url_type} for ${pkg}"
        fi
    done

    popd
}

cmake_build()
{
    PKG=$1

    echoR "PKG:${PKG}"

    # static compile arguments
    host=$ARCH-linux-gnu
    prefix=${PREFIX}/$ARCH

    echoY "EXEC_TOOLCHAIN_ROOT_PATH=${EXEC_TOOLCHAIN_ROOT_PATH}"
    echoY "EXEC_CMAKE_CXX_COMPILER=${EXEC_CMAKE_CXX_COMPILER}"
    echoY "EXEC_CMAKE_C_COMPILER=${EXEC_CMAKE_C_COMPILER}"
    echoY "EXEC_CMAKE_FIND_ROOT_PATH=${EXEC_CMAKE_FIND_ROOT_PATH}"
    echoY "EXEC_THREADS_PTHREAD_ARG=${EXEC_THREADS_PTHREAD_ARG}"

    src_name=${pkg}_NAME
    pushd "$SRC/${ARCH}/${!src_name}"
    mkdir build
    if [ $(arch) != ${ARCH} ]
    then
        echoY "Cross compiling..."
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

}

configure_build()
{
    PKG=$1
    extract_args=$2
    # static compile arguments
    host=$ARCH-linux-gnu
    prefix=${PREFIX}/$ARCH
#    args="--host=${host} --prefix=${prefix} --disable-shared --enable-static"
#    args="--host=${host} --prefix=${prefix} --disable-shared --enable-static CC=${host}-gcc"
    args="--host=${host} --prefix=${prefix} --enable-static CC=${host}-gcc"

    src_name=${pkg}_NAME
    pushd "$SRC/${ARCH}/${!src_name}"
    ./configure $args $extract_args
    make clean
    make -j 18
    make install
    popd
}

autogen_configure_build()
{
    PKG=$1
    extract_args=$2
    # static compile arguments
    host=$ARCH-linux-gnu
    prefix=${PREFIX}/$ARCH
#    args="--host=${host} --prefix=${prefix} --disable-shared --enable-static"
#    args="--host=${host} --prefix=${prefix} --disable-shared --enable-static CC=${host}-gcc"
    args="--host=${host} --prefix=${prefix} --enable-static CC=${host}-gcc"

    src_name=${pkg}_NAME
    pushd "$SRC/${ARCH}/${!src_name}"
    ./autogen.sh
    ./configure $args $extract_args
    make clean
    make -j 18
    make install
    popd
}

# build libyuv
build_LIBYUV()
{
    cmake_build $1
}

# build gtest
build_GTEST()
{
    cmake_build $1
}

# glog
build_GLOG()
{
    autogen_configure_build $1 ""
}

# log4c
build_LOG4C()
{
    configure_build $1 ""
}

# libev
build_LIBEV()
{
    configure_build $1 ""
}

# mbedtls
build_MBEDTLS()
{
    # mbedtls
    prefix=${PREFIX}/$ARCH
    pushd "$SRC/${ARCH}/$MBEDTLS_NAME"
    make clean
    # make DESTDIR="${prefix}" CC="${host}-gcc" AR="${host}-ar" LD="${host}-ld" LDFLAGS=-static install -j8
    #export SHARED=1 && make DESTDIR="${prefix}" CC="${host}-gcc" AR="${host}-ar" LD="${host}-ld" LDFLAGS=-static install -j 18
    export SHARED=1 && make DESTDIR="${prefix}" CC="${host}-gcc" AR="${host}-ar" LD="${host}-ld" install -j 18
    unset DESTDIR
    popd

}

# sodium
build_SODIUM()
{
    configure_build $1 ""
}

# pcre
build_PCRE()
{
    configure_build $1 "--enable-unicode-properties --enable-utf8"
}


# c-ares
build_CARES()
{
    configure_build $1 ""
}

# boost
build_BOOST()
{
    host=$ARCH-linux-gnu
    prefix=${PREFIX}/$ARCH
    
    local nCPU=$(nproc --all) 

    pushd "$SRC/${ARCH}/$BOOST_NAME"

    if [ $(arch) != ${ARCH} ]
    then
        echoY "Cross compiling..."
        ./bootstrap.sh --prefix=${prefix} --with-python-root=${EXEC_TOOLCHAIN_ROOT_PATH}
    #    echo "using gcc : arm : ${ARCH}-linux-gnu-g++ ;" >> user-config.jam
        sed -i "s/using gcc/using gcc \: aarch64 \: aarch64-linux-gnu-g++ \: -std=c++11 /" ./project-config.jam
    #    echo "using gcc : aarch64 : aarch64-linux-gnu-g++ ;" > project-config.jam
    #    ./b2 -a toolset=gcc-arm abi=aapcs address-model=64 --prefix=${prefix} --with=all -j${nCPU} 
        ./b2 --build-type=complete --layout=versioned abi=aapcs address-model=64 cxxflags="-std=c++11" --with=all -j${nCPU} install
    else
        echoY "Native building..."
        ./bootstrap.sh --prefix=${prefix}
        ./b2 --build-type=complete --layout=versioned --with=all -j${nCPU} install
    fi
    popd
}

# build packages
build_pkgs() {
    PKGS_NUM=`echo ${PKGS}|awk -F"," '{print NF}'`
    for ((i=1;i<=${PKGS_NUM};i++)); do
        eval pkg='`echo ${PKGS}|awk -F, "{ print $"$i" }"`'
        name=${pkg}_NAME
        build_func=${pkg}_build
        echoY "Building: ${filename}..."
#        build_pkg_func ${!name}
        build_${pkg} ${pkg}
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

