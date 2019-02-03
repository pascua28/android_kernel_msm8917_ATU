#!/bin/sh

if [ -e .config ]
    then
        make ARCH=arm64 -j4 oldconfig
    else
        cp arch/arm64/configs/atu_defconfig .config
        make ARCH=arm64 -j4 oldconfig
fi

BUILD_START=$(date +"%s")
ARCH=arm64 \
CROSS_COMPILE=~/gcc/bin/aarch64-linux-gnu- \
make -j4 Image.gz-dtb
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo "Compile time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds"
