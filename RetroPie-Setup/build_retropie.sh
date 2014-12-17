#!/bin/bash

#DEFAULT COMPILER: HOST_CC=default ./build_retropie.sh -b -name=?
#BUILD WIN64: HOST_CC=x86_64-w64-mingw32 ./build_retropie.sh -b -name=?
#CROSS COMPILATION ARM: HOST_CC=arm-linux-gnueabihf ./build_retropie.sh -b -name=?
#UBUNTU FOR CROSS COMPILATION INSTALL: apt-get install gcc-arm-linux-gnueabihf && apt-get install g++-arm-linux-gnueabihf

#LIBRETRO SAMPLE: ARCH=x86_64 platform=win HOST_CC=x86_64-w64-mingw32 ./libretro-build.sh
#LIBRETRO SAMPLE: make -f Makefile platform=win CC="x86_64-w64-mingw32-gcc" CXX="x86_64-w64-mingw32-g++" -j7

# INIT COMPILER FLAGS
__default_cflags="-O2 -pipe -mfpu=vfp -march=armv6j -mfloat-abi=hard"
__default_asflags=""
__default_makeflags=""
__default_gcc_version="4.7"

if [ "$HOST_CC" ]; then
   #[ "$HOST_CC" = "arm-unknown-linux-gnueabi" ] && PATH_CC=/opt/cross/x-tools/arm-unknown-linux-gnueabi/bin && export PATH=$PATH_CC:$PATH

   [ "$HOST_CC" != "default" ] && export CC="\"${HOST_CC}-gcc\""
   [ "$HOST_CC" != "default" ] && export CXX="\"${HOST_CC}-g++\""
   #[ "$HOST_CC" != "default" ] && export STRIP=x86_64-w64-mingw32-strip
   [ "$HOST_CC" != "default" ] && export COMPILER="CC=${CC} CXX=${CXX}"

   [ "$HOST_CC" = "x86_64-w64-mingw32" ] && FORMAT_COMPILER_TARGET="win"

   if [ "$HOST_CC" = "arm-unknown-linux-gnueabi" ] || [ "$HOST_CC" = "arm-linux-gnueabihf" ]; then
       #echo "--- CROSS COMPILATION ---"
       FORMAT_COMPILER_TARGET="armv6j-hardfloat"

       #[ "$HOST_CC" = "arm-unknown-linux-gnueabi" ] && __default_cflags+=" -I/opt/cross/x-tools/arm-unknown-linux-gnueabi/arm-unknown-linux-gnueabi/sysroot/usr/include "
       #/opt/cross/x-tools/arm-unknown-linux-gnueabi/arm-unknown-linux-gnueabi/sysroot/usr/lib
       #which gcc-arm-linux-gnueabi

       #export RANLIB=/opt/cross/x-tools/arm-unknown-linux-gnueabi/bin/arm-unknown-linux-gnueabi-ranlib
       #export STRIP=/opt/cross/x-tools/arm-unknown-linux-gnueabi/bin/arm-unknown-linux-gnueabi-strip
       #export CFLAGS="-I/opt/cross/x-tools/arm-unknown-linux-gnueabi/include"
       #export LDFLAGS="-L/opt/cross/x-tools/arm-unknown-linux-gnueabi/lib"

       #arm-unknown-linux-gnueabi-g++ --version
       #echo "--- $? ---"
   fi
else
   # default raspberry compilation
   FORMAT_COMPILER_TARGET="armv6j-hardfloat"
fi

so_filter='*libretro*.so'
[ "$HOST_CC" = "x86_64-w64-mingw32" ] && so_filter='*libretro*.dll'

[ "$FORMAT_COMPILER_TARGET" = "armv6j-hardfloat" ] && [[ -z "${CFLAGS}" ]] && export CFLAGS="${__default_cflags}"
[ "$FORMAT_COMPILER_TARGET" = "armv6j-hardfloat" ] && [[ -z "${CXXFLAGS}" ]] && export CXXFLAGS="${__default_cflags}"
[ "$FORMAT_COMPILER_TARGET" = "armv6j-hardfloat" ] && [[ -z "${ASFLAGS}" ]] && export ASFLAGS="${__default_asflags}"
[ "$FORMAT_COMPILER_TARGET" = "armv6j-hardfloat" ] && [[ -z "${MAKEFLAGS}" ]] && export MAKEFLAGS="${__default_makeflags}"
# END INIT COMPILER FLAGS

# FUNCTIONS
__mod_idx=()
__mod_id=()
__mod_desc=()
__mod_menus=()
__doPackages=0

# function from: https://github.com/petrockblog/RetroPie-Setup/blob/master/scriptmodules/packages.sh
function rp_registerFunction() {
    __mod_idx+=($1)
    __mod_id[$1]=$2
    __mod_desc[$1]=$3
    __mod_menus[$1]=$4
}

# function from: https://github.com/petrockblog/RetroPie-Setup/blob/master/scriptmodules/packages.sh
function registerModule() {
    local module_idx="$1"
    local module_path="$2"
    local rp_module_id=""
    local rp_module_desc=""
    local rp_module_menus=""
    local var
    local error=0
    source $module_path
    for var in rp_module_id rp_module_desc rp_module_menus; do
        if [[ "${!var}" == "" ]]; then
            echo "Module $module_path is missing valid $var"
            error=1
        fi
    done
    [[ $error -eq 1 ]] && exit 1

    rp_registerFunction "$module_idx" "$rp_module_id" "$rp_module_desc" "$rp_module_menus"
}

# function from: https://github.com/petrockblog/RetroPie-Setup/blob/master/scriptmodules/packages.sh
function registerModuleDir() {
    local module_idx="$1"
    local module_dir="$2"
    for module in `find "$scriptdir/scriptmodules/$2" -maxdepth 1 -name "*.sh" | sort`; do
        registerModule $module_idx "$module"
        ((module_idx++))
    done
}

# function from: https://github.com/petrockblog/RetroPie-Setup/blob/master/scriptmodules/packages.sh
function registerAllModules() {
    registerModuleDir 100 "emulators" 
    registerModuleDir 200 "libretrocores" 
    registerModuleDir 300 "supplementary"
}

function showModules() {
    local module_idx=$1
    while [ "${__mod_id[$module_idx]}" != "" ]; do
        logger 0 "Register Module: [$module_idx] ${__mod_id[$module_idx]}"

        ((module_idx++))
    done
}

function showModuleFunctions() {
    local mod_id=$1

    if [ "$mod_id" != '' ]; then
        local funcDepends="depends_${mod_id}"
        local funcSrc="sources_${mod_id}"
        local funcBuild="build_${mod_id}"
        local funcInstall="install_${mod_id}"
        local funcConfigure="configure_${mod_id}"
        local functions=""

        fn_exists $funcDepends && functions+="$funcDepends "
        fn_exists $funcSrc && functions+="$funcSrc "
        fn_exists $funcBuild && functions+="$funcBuild "
        fn_exists $funcInstall && functions+="$funcInstall "
        fn_exists $funcConfigure && functions+="$funcConfigure "

        logger 1 "MOD: [$mod_id] [ $functions ]"
    fi
}

function execModule() {
    # exit if no module idx
    [ "$1" = "" ] && return
    
    local mod_id=$1

    #func="${func}_${mod_id}"
    local funcDepends="depends_${mod_id}"
    local funcSrc="sources_${mod_id}"
    local funcBuild="build_${mod_id}"
    local funcInstall="install_${mod_id}"
    local funcConfigure="configure_${mod_id}"
    local funcCopy="copy_${mod_id}"

    if [ $opt_build -eq 1 ]; then
        # echo "Checking, if function ${!__function} exists"
        fn_exists $funcSrc || logger 0 "WARN: function -> $funcSrc not found" # __ERRMSGS="function -> $funcSrc not found"
        fn_exists $funcBuild || logger 0 "WARN: function -> $funcBuild not found" # __ERRMSGS="function -> $funcBuild not found"
        #[ -z "$__ERRMSGS" ] || return
    fi

    # echo "Printing function name"
    #logger "$desc ${__mod_desc[$idx]}"

    # echo "Executing function"
    if fn_exists $funcDepends; then
        logger 1 "EXEC: [$mod_id] function -> $funcDepends"
        $funcDepends
    fi
    if [ $opt_build -eq 1 ] && fn_exists $funcSrc; then
        logger 1 "EXEC: [$mod_id] function -> $funcSrc"
        $funcSrc
    fi
    if [ $opt_build -eq 1 ] && fn_exists $funcBuild; then
        logger 1 "EXEC: [$mod_id] function -> $funcBuild"
        $funcBuild

        # check compilation errors
        [ -z "$__ERRMSGS" ] || return
    fi

    if [ $opt_install -eq 1 ] && fn_exists $funcInstall; then
        logger 1 "EXEC: [$mod_id] function -> $funcInstall"
        $funcInstall
    fi

    if [ $opt_configure -eq 1 ] && fn_exists $funcConfigure; then
        logger 1 "EXEC: [$mod_id] function -> $funcConfigure"
        $funcConfigure
    fi

    if [ $opt_build -eq 1 ] && fn_exists $funcCopy; then
        logger 1 "EXEC: [$mod_id] function -> $funcCopy"
        $funcCopy
    fi
}

function execAllModules() {
    local module_idx=$1
    while [ "${__mod_id[$module_idx]}" != "" ]; do
        #echo [$module_idx]
        execModule ${__mod_id[$module_idx]}

        # check errors
        [ -z "$__ERRMSGS" ] || logger 1 "ERROR: $__ERRMSGS"

        ((module_idx++))
    done
}

function updateModules() {
    [ -d temporary ] && rm -R ./tmp/*
    [ -f master.zip ] && rm master.zip

    logger 1 "WGET: ES_RetroPie to .tmp"
    wget https://github.com/frthery/ES_RetroPie/archive/master.zip
    unzip master.zip -d "./tmp"

    logger 1 "COPY: ES_RetroPie Modules"
    cp -R ./tmp/ES_RetroPie-master/RetroPie-Setup/scriptmodules/ ./
    cp -R ./tmp/ES_RetroPie-master/RetroPie-Setup/supplementary/ ./

    # clean
    logger 1 "CLEAN: ES_RetroPie ./tmp"
    rm -R ./tmp/*
}

function showCompilerFlags() {
    # SHOW COMPILER FLAGS
    logger 1 "--- COMPILER OPTIONS --------------------------------------"
    echo "FORMAT_COMPILER_TARGET: [$FORMAT_COMPILER_TARGET]"
    echo "HOST_CC:   [$HOST_CC]"
    echo "COMPILER:  [$COMPILER]"
    #echo "CC:        [$CC]"
    #echo "CXX:       [$CXX]"
    echo "CFLAGS:    [$CFLAGS]"
    echo "CXXFLAGS:  [$CXXFLAGS]"
    echo "ASFLAGS:   [$ASFLAGS]"
    echo "MAKEFLAGS: [$MAKEFLAGS]"
    #echo "PATH: [$PATH]"
}

function logger() {
    [ $1 == 1 ] && echo -e "\n-----------------------------------------------------------\n$2\n-----------------------------------------------------------"
    [ $1 == 1 ] || echo $2
}

function usage() {
    echo "build_libretro.sh [-u|update] [-l|--list] [-a|--all] [-b|--build] [-i|--install] [-c|--configure] -name=[idx]"
}
# END FUNCTIONS

# GLOBAL VARIABLES
default_rootdir='/opt/retropie/'

scriptdir=$(pwd)
rootdir=$scriptdir/build
romdir='/home/pi/RetroPie/roms'

__swapdir="$scriptdir/tmp/"
[ -f free ] && __memory=$(free -t -m | awk '/^Total:/{print $2}')

opt_update=0
opt_build=0
opt_install=0
opt_configure=0
opt_all=0
opt_list=0
# END GLOBAL VARIABLES

# MAIN
# no arguments error
if [ "$1" = "" ]; then
    logger 0 "ERROR: no arguments found!"
    usage
    exit 1
fi

logger 1 "--- INITIALIZE --------------------------------------------"
source $scriptdir/scriptmodules/helpers.sh
logger 0 "LOADED: ./scriptmodules/helpers.sh"

#rps_checkNeededPackages git dialog gcc-4.7 g++-4.7
# set default gcc version
#gcc_version $__default_gcc_version

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        -l | --list)
            opt_list=1
            ;;
        -u | --update)
            opt_update=1
            ;;
        -a | --all)
            opt_build=1
            opt_install=1
            opt_configure=1
            rootdir=$default_rootdir
            ;;
        -b | --build)
            opt_build=1
            ;;
        -i | --install)
            opt_install=1
            rootdir=$default_rootdir
            ;;
        -c | --configure)
            opt_configure=1
            ;;
        -name)
            [ $VALUE = 'all' ] && opt_all=1
            mod_id=$VALUE
            ;;
        -f | --filter)
            so_filter=$VALUE
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

#VERBOSE
logger 0 "OPTIONS: -update[$opt_update],-build[$opt_build],-install[$opt_install],-config[$opt_configure],-all[$opt_all] filter:[$so_filter]"
logger 0 "DIR: scriptdir=[$scriptdir]"
logger 0 "DIR: rootdir=[$rootdir]"
logger 0 "DIR: swapdir=[$__swapdir]"
logger 0 "DIR: romdir=[$romdir]"

[ $opt_update -eq 1 ] && updateModules

registerModuleDir 100 "emulators" 
registerModuleDir 200 "libretrocores" 

#exit on --list option
if [ $opt_list -eq 1 ]; then
    logger 1 "--- EMULATORS ---------------------------------------------"
    showModules 100
    logger 1 "--- LIBRETROCORES -----------------------------------------"
    showModules 200

    showModuleFunctions $mod_id
    exit
fi

showModuleFunctions $mod_id
[ $opt_build -eq 1 ] && showCompilerFlags

# init folders
[ ! -d $rootdir ] && mkdir $rootdir
[ ! -d $scriptdir/bin ] && mkdir $scriptdir/bin
[ ! -d $rootdir/emulatorcores ] && mkdir $sdir/emulatorcores
[ ! -d $rootdir/emulators ] && mkdir $rootdir/emulators

if [ $opt_all -eq 1 ]; then
    # EXEC ALL LIBRETRO MODULES
    #execAllModules 100
    execAllModules 200
else
    # EXEC SPECIFIC MODULE
    execModule $mod_id

    # check errors
    [ -z "$__ERRMSGS" ] || logger 1 "ERROR: $__ERRMSGS"
fi

logger 1 "--- EXIT --------------------------------------------------"
exit 0
# END MAIN
