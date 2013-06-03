#!/bin/bash

## Based on the kernel_build.sh script from NX-Kernel by neobuddy89

# location
export KERNELDIR=`readlink -f .`
export PARENT_DIR=`readlink -f ..`

# kernel
export ARCH=arm
export USE_SEC_FIPS_MODE=true
export KERNEL_CONFIG="cyanogenmod_n7000_defconfig"

# build script
export USER=`whoami`
export OLDMODULES=`find -name *.ko`

# system compiler
export CROSS_COMPILE=${KERNELDIR}/android-toolchain-eabi/bin/arm-eabi-

CPUS=`grep 'processor' /proc/cpuinfo | wc -l`

if [ "${1}" != "" ]; then
	export KERNELDIR=`readlink -f ${1}`
fi;

if [ ! -f ${KERNELDIR}/.config ]; then
	echo "***** Writing Config *****"
	cp ${KERNELDIR}/arch/arm/configs/${KERNEL_CONFIG} .config
	make ${KERNEL_CONFIG}
fi;

. ${KERNELDIR}/.config

# remove previous zImage files
if [ -e ${KERNELDIR}/zImage ]; then
	rm ${KERNELDIR}/zImage
	rm ${KERNELDIR}/boot.img
fi;
if [ -e ${KERNELDIR}/arch/arm/boot/zImage ]; then
	rm ${KERNELDIR}/arch/arm/boot/zImage
fi;

# remove all old modules before compile
cd ${KERNELDIR}
for i in $OLDMODULES; do
	rm -f $i
done;

echo "***** Removing Old Compile Temp Files *****"
echo "***** Please run 'sh clean_kernel.sh' for Complete Clean *****"
# remove previous initramfs files
rm -rf /tmp/cpio* >> /dev/null
rm -rf out/system/lib/modules/* >> /dev/null
rm -rf out/temp/* >> /dev/null
rm -r out/temp >> /dev/null


# clean initramfs old compile data
rm -f usr/initramfs_data.cpio >> /dev/null
rm -f usr/initramfs_data.o >> /dev/null

cd ${KERNELDIR}/

mkdir -p out/system/lib/modules
mkdir -p out/temp

# make modules and install
echo "***** Compiling modules *****"
make -j${CPUS} modules || exit 1
make -j${CPUS} INSTALL_MOD_PATH=out/temp modules_install || exit 1

# copy modules
echo "***** Copying modules *****"
cd out
find -name '*.ko' -exec cp -av {} "${KERNELDIR}/out/system/lib/modules" \;
${CROSS_COMPILE}strip --strip-debug "${KERNELDIR}"/out/system/lib/modules/*.ko
chmod 755 "${KERNELDIR}"/out/system/lib/modules/*
cd ..

# remove temp module files generated during compile
echo "***** Removing temp module stage 2 files *****"
rm -rf out/temp/* >> /dev/null
rm -r out/temp  >> /dev/null

# make zImage
echo "***** Compiling kernel *****"
time make -j${CPUS} zImage

if [ -e ${KERNELDIR}/arch/arm/boot/zImage ]; then
	cp ${KERNELDIR}/arch/arm/boot/zImage ${KERNELDIR}/zImage
	echo "Finished !"
	exit 0
else
	echo "Build failure !"
fi;

