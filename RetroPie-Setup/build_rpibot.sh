#!/bin/bash

pushd "/home/pi/RetroPie-Setup"

now=`date +%Y%m%d`
outputdir=$(pwd)/bin/$now

#git reset --hard HEAD
#git pull

./build_retropie.sh -u

if [ $1 = '-rpi2' ]; then
    outputzip=$outputdir/cores-rpi-armv7-$now.zip
    FORMAT_COMPILER_TARGET=armv7-cortexa7-hardfloat ./build_retropie.sh -b -name=a_retroarch,a_gpsplibretro,a_armsneslibretro,a_fbalibretro,a_fceunextlibretro,a_fmsxlibretro,a_gambattelibretro,a_genesislibretro,a_imamelibretro,a_mednafenpcefastlibretro,a_mupen64libretro,a_pcsx_rearmedlibretro,a_picodrivelibretro,a_pocketsneslibretro,a_prboomlibretro,a_snes9xnextlibretro,a_stellalibretro,a_virtualjaguarlibretro,a_yabauselibretro
else
    outputzip=$outputdir/cores-rpi-$now.zip
    ./build_retropie.sh -b -name=a_retroarch,a_gpsplibretro,a_armsneslibretro,a_fbalibretro,a_fceunextlibretro,a_fmsxlibretro,a_gambattelibretro,a_genesislibretro,a_imamelibretro,a_mednafenpcefastlibretro,a_mupen64libretro,a_pcsx_rearmedlibretro,a_picodrivelibretro,a_pocketsneslibretro,a_prboomlibretro,a_snes9xnextlibretro,a_stellalibretro,a_virtualjaguarlibretro,a_yabauselibretro
fi

zip ${outputzip} build_retropie.log -j $outputdir/*.so

popd

