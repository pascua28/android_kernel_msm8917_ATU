#!/bin/bash
cd $(readlink -f .)

if [ ! -f .config ]; then
	cp arch/arm64/configs/atu_defconfig .config
	make -j5 ARCH=arm64 oldconfig
else
	make -j5 ARCH=arm64 oldconfig
fi

export KBUILD_COMPILER_STRING=$(~/sdclang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

DATE_START=$(date +"%s")
make -j$(nproc --all) \
ARCH=arm64 \
CC=~/sdclang/bin/clang \
CLANG_TRIPLE=aarch64-linux-gnu- \
CROSS_COMPILE=~/linaro/bin/aarch64-linux-gnu- \
Image.gz-dtb
DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
