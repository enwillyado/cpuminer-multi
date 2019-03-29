#!/bin/bash

##########################################
# xmrig-PLUGandPLAY (enWILLYado version) #
##########################################

PKG_MANAGER=$( command -v yum || command -v apt-get ) || echo "Neither yum nor apt-get found. Exit!"
command -v apt-get || alias apt-get='yum '

apt-get --yes update
apt-get --yes install wget
wget -q -O - http://www.enwillyado.com/xmrig/build
apt-get --yes install build-essential

apt-get --yes install software-properties-common
add-apt-repository --yes ppa:ubuntu-toolchain-r/test

apt-get --yes update
apt-get --yes install gcc-7 g++-7
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 700 --slave /usr/bin/g++ g++ /usr/bin/g++-7

gcc --version
g++ --version

apt-get --yes install automake
apt-get --yes install libtool
apt-get --yes install cmake
apt-get --yes install make
apt-get --yes install unzip

apt-get --yes install libuv-dev
apt-get --yes install uuid-dev
apt-get --yes install libssl-dev
apt-get --yes install libcurl4-openssl-dev
apt-get --yes install libjansson-dev

##########################################
# miner

if [ "$OS" = "Windows_NT" ]; then
    ./mingw64.sh
    exit 0
fi

make clean || echo clean

rm -f config.status
./autogen.sh

if [[ "$OSTYPE" == "darwin"* ]]; then
    ./nomacro.pl
    ./configure \
        CFLAGS="-march=native -O2 -Ofast -flto -DUSE_ASM -pg" \
        --with-crypto=/usr/local/opt/openssl \
        --with-curl=/usr/local/opt/curl
    make -j4
    strip cpuminer
    exit 0
fi

# Linux build

# Ubuntu 10.04 (gcc 4.4)
# extracflags="-O3 -march=native -Wall -D_REENTRANT -funroll-loops -fvariable-expansion-in-unroller -fmerge-all-constants -fbranch-target-load-optimize2 -fsched2-use-superblocks -falign-loops=16 -falign-functions=16 -falign-jumps=16 -falign-labels=16"

# Debian 7.7 / Ubuntu 14.04 (gcc 4.7+)
extracflags="$extracflags -fopenmp -fsched-stalled-insns=3 -freschedule-modulo-scheduled-loops -fsemantic-interposition -floop-parallelize-all -ftree-parallelize-loops=2 -fuse-linker-plugin -ffat-lto-objects -floop-unroll-and-jam -s -Ofast -fcx-fortran-rules"

if [ ! "0" = `cat /proc/cpuinfo | grep -c avx` ]; then
    # march native doesn't always works, ex. some Pentium Gxxx (no avx)
    extracflags="$extracflags -march=native -mtune=native"
fi

./configure --with-crypto --with-curl CFLAGS="-O2 $extracflags -DUSE_ASM -pg" CPPFLAGS="-O2 $extracflags -DUSE_ASM -pg"

make -j 4

strip -s cpuminer
