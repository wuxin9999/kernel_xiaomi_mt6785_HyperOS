#!/bin/bash
#
# Compile script for NoVA Kernel.
# Adapted from hanikrnl (https://github.com/Dominium-Apum/kernel_xiaomi_chime)
#

SECONDS=0 # builtin bash timer
KERNEL_PATH=$PWD
AK3_DIR="$HOME/tc/Anykernel"
DEFCONFIG="begonia_user_defconfig"

# Exports for shits and giggles
export KBUILD_BUILD_USER=NoVA
export KBUILD_BUILD_HOST=Abdul7852

# Install needed tools
if [[ $1 = "-t" || $1 = "--tools" ]]; then
        mkdir toolchain
	cd toolchain

	curl -LO "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman" || exit 1

	chmod -x antman

	echo 'Setting up toolchain in $(PWD)/toolchain'
	bash antman -S --noprogress || exit 1

#	echo 'Patch for glibc'
#	bash antman --patch=glibc
fi

# Regenerate defconfig file
if [[ $1 = "-r" || $1 = "--regen" ]]; then
	make O=out ARCH=arm64 $DEFCONFIG savedefconfig
	cp out/defconfig arch/arm64/configs/$DEFCONFIG
	echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
fi

if [[ $1 = "-b" || $1 = "--build" ]]; then
	PATH=$PWD/toolchain/bin:$PATH
	mkdir -p out
	make O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 $DEFCONFIG
        rm -rf out/error.log
	exec 2> >(tee -a out/error.log >&2)
	echo -e ""
	echo -e ""
	echo -e "*****************************"
	echo -e "**                         **"
	echo -e "** Starting compilation... **"
	echo -e "**                         **"
	echo -e "*****************************"
	echo -e ""
	echo -e ""
	make O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 -j$(nproc) || exit 1

	kernel="out/arch/arm64/boot/Image.gz-dtb"

	if [ -f "$kernel" ]; then
		hash=$(git log -n 1 --pretty=format:'%h' | cut -c 1-7)
		lastcommit=$hash
		REVISION=NoVA-$(git rev-parse --abbrev-ref HEAD)
		ZIPNAME=""$REVISION"-begonia-$(date '+%d.%m.%y-%H%M').zip"

		if [ -f "$ZIPNAME" ]; then
			counter=1
			while [ -f "${ZIPNAME%.zip}-$counter.zip" ]; do
				((counter++))
			done
		        ZIPNAME="${ZIPNAME%.zip}-$counter.zip"
		fi
		echo -e ""
		echo -e ""
		echo -e "********************************************"
		echo -e "\nKernel compiled succesfully! Zipping up...\n"
		echo -e "********************************************"
		echo -e ""
		echo -e ""
	if [ -d "$AK3_DIR" ]; then
		cp -r $AK3_DIR Anykernel
	elif ! git clone -q https://github.com/Wahid7852/Anykernel; then
			echo -e "\nAnykernel repo not found locally and couldn't clone from GitHub! Aborting..."
	fi
		cp $kernel Anykernel

		cd Anykernel
		zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
		cd ..

        echo -e ""
        echo -e ""
        echo -e "************************************************************"
        echo -e "**                                                        **"
        echo -e "**   File name: $ZIPNAME   **"
        echo -e "**   Build completed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)!    **"
        echo -e "**                                                        **"
        echo -e "************************************************************"
        echo -e ""
        echo -e ""
	else
        echo -e ""
        echo -e ""
        echo -e "*****************************"
        echo -e "**                         **"
        echo -e "**   Compilation failed!   **"
        echo -e "**                         **"
        echo -e "*****************************"
	fi
	fi
