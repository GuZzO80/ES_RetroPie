rp_module_id="a_ppsspplibretro"
rp_module_desc="PSP LibretroCore PPSSPP (Additional)"
rp_module_menus="2+"

function sources_a_ppsspplibretro() {
    gitPullOrClone "$rootdir/emulatorcores/libretro-ppsspp" git://github.com/libretro/libretro-ppsspp.git
    
    pushd "$rootdir/emulatorcores/libretro-ppsspp"
    git submodule init && git submodule update
    popd
}

function build_a_ppsspplibretro() {
    pushd "$rootdir/emulatorcores/libretro-ppsspp/libretro"

    [ -z "${NOCLEAN}" ] && make -f Makefile clean
    if [[ ${FORMAT_COMPILER_TARGET} =~ "armv6" ]]; then
        make -f Makefile platform=rpi ${COMPILER} 2>&1 | tee makefile.log
    elif [[ ${FORMAT_COMPILER_TARGET} =~ "armv7" ]]; then
        make -f Makefile platform=rpi2 ${COMPILER} 2>&1 | tee makefile.log
    else
        make -f Makefile ${COMPILER} 2>&1 | tee makefile.log
    fi
    
    [ ${PIPESTATUS[0]} -ne 0 ] && __ERRMSGS="Could not successfully compile PSP LibretroCore PPSSPP!"
    [ -f makefile.log ] && cp makefile.log $outputdir/_log.makefile.ppsspplibretro

    popd
}

function configure_a_ppsspplibretro() {
    mkdir -p $romdir/psp

    #rps_retronet_prepareConfig
    #setESSystem "Sega SATURN" "saturn" "~/RetroPie/roms/saturn" ".img .IMG .7z .7Z .pbp .PBP .bin .BIN .cue .CUE" "$rootdir/supplementary/runcommand/runcommand.sh 2 \"$rootdir/emulators/RetroArch/installdir/bin/retroarch -L `find $rootdir/emulatorcores/yabause/ -name \"*libretro*.so\" | head -1` --config $rootdir/configs/all/retroarch.cfg --appendconfig $rootdir/configs/saturn/retroarch.cfg $__tmpnetplaymode$__tmpnetplayhostip_cfile$__tmpnetplayport$__tmpnetplayframes %ROM%\"" "saturn" "saturn"
}

function copy_a_ppsspplibretro() {
    [ -z "$so_filter" ] && so_filter="*libretro*.so"
    find $rootdir/emulatorcores/libretro-ppsspp/libretro/ -name $so_filter | xargs cp -t $outputdir
}
