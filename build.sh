#!/bin/bash

# refer to:
# https://hub.docker.com/r/alexandreoda/vlc
# docker pull alexandreoda/vlc

set -e
#set -x

. ./libShell/echo_color.lib
. ./libShell/time.lib


usage_func()
{
    echoY "Usage:"
    echoY "./build.sh -c <cmd> -a <cpu arch> -r <build root dir> -l <libs list>"
    echo 'eg: ./build.sh -c download -a aarch64 -r tmpBuildRoot -l "LIBEV,SODIUM,MBEDTLS,PCRE,CARES"'
    
    echo ""
    echoY "Supported cmd:"
    echo "[ download, build ]"
    echo ""
    echoY "Supported cpu arch:"
    echo "[ x86_64, aarch64 ]"
    echo ""
    echoY "Supported libs:"
    echo "[ LIBEV, SODIUM, MBEDTLS, PCRE, CARES ]"
}


EXEC_CMD=""
EXEC_CPU_ARCH=""
EXEC_BUILD_ROOT_DIR=""
EXEC_LIBS_LIST=""


no_args="true"
while getopts "c:a:r:l:" opts
do
    case $opts in
        c)
              # execute command
              EXEC_CMD=$OPTARG
              ;;
        a)
              # cpu architecture
              EXEC_CPU_ARCH=$OPTARG
              ;;
        r)
              # build root dir
              EXEC_BUILD_ROOT_DIR=$OPTARG
              ;;
        l)
              # libs list
              EXEC_LIBS_LIST=$OPTARG
              ;;
        :)
            echo "The option -$OPTARG requires an argument."
            exit 1
            ;;
        ?)
            echo "Invalid option: -$OPTARG"
            usage_func
            exit 2
            ;;
        *)    #unknown error?
              echoR "unkonw error."
              usage_func
              exit 1
              ;;
    esac
    no_args="false"
done

[[ "$no_args" == "true" ]] && { usage_func; exit 1; }

case ${EXEC_CMD} in
    download) echoY "Downloading packages:${EXEC_LIBS_LIST} ..."
        ./static.sh ${EXEC_CMD} ${EXEC_CPU_ARCH} ${EXEC_BUILD_ROOT_DIR} ${EXEC_LIBS_LIST}
        ;;
    build) echoY "Building packages:${EXEC_LIBS_LIST} ..."
        export PATH=$PATH:/opt/zlg/m1808-sdk-v1.3.1-ga/host/bin/
        ./static.sh ${EXEC_CMD} ${EXEC_CPU_ARCH} ${EXEC_BUILD_ROOT_DIR} ${EXEC_LIBS_LIST}
        ;;
esac

exit 0

