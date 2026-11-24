#!/bin/bash

. $BIN_DIR/config/L4T/common_functions.sh

# NVIDIA Jetson Linux 39.2.2 (JetPack 7.2.2)
#   * Linux kernel 6.8.12 (kernel/kernel-noble), Ubuntu 24.04 (noble) root file system
#   * Crosstool-NG toolchain GCC 13.2 (x-tools.tbz2, published with r38.2 and used for r39.x)

#toolchain
GCC_URL=https://developer.nvidia.com/downloads/embedded/l4t/r38_release_v2.0/release
GCC_FILE=x-tools.tbz2
GCC_DIR=$TOOLCHAIN_DIR/x-tools/aarch64-none-linux-gnu
GCC_FILE_CHECKSUM="0142eb47d26846133e33e42c90bcab34"
export CROSS_COMPILE=$GCC_DIR/bin/aarch64-none-linux-gnu-

#downloads
DEV_URL=https://developer.nvidia.com/downloads/embedded/l4t/r39_release_v2.2

case $VC_MIPI_SOM in
        OrinNX8GB|OrinNX16GB|OrinNano4GB_SD|OrinNano8GB_SD|OrinNano4GB_NVME|OrinNano8GB_NVME|OrinAGX32GB|OrinAGX64GB)
                BSP_FILE=Jetson_Linux_R39.2.2_aarch64.tbz2
                ;;
esac

RFS_FILE=Tegra_Linux_Sample-Root-Filesystem_R39.2.2_aarch64.tbz2
SRC_FILE=public_sources.tbz2

CHECK4MD5=1

# MD5 sums calculated from the downloaded files. The SHA1 sums of the BSP and RFS files
# were verified against NVIDIA's release_sha_hashes.txt of r39.2.2.
BSP_FILE_CHECKSUM="5c95081282b283e64b3cd42bf9b81aea"
RFS_FILE_CHECKSUM="ff347045d695e30608c042d8b4f18650"
SRC_FILE_CHECKSUM="4055d2a9fb7f80b2183f25849940e6fa"

. $BIN_DIR/config/L4T/urls_35.1.0+.sh

#configure
PATCHES=('kernel_Xavier_39.2.2')

KERNEL_SOURCE=$BSP_DIR/Linux_for_Tegra/source

DTSI_FILE_DICT+=(["NV_DevKit_OrinNano"]="tegra234-p3767-camera-p3768-vc_mipi-dual.dts")
DTSI_DEST_DICT+=(["NV_DevKit_OrinNano"]="$KERNEL_SOURCE/hardware/nvidia/t23x/nv-public/overlay")

DTSI_FILE_DICT+=(["Auvidea_JNX42_OrinNano"]="tegra234-p3767-camera-p3768-vc_mipi-dual.dts")
DTSI_DEST_DICT+=(["Auvidea_JNX42_OrinNano"]="$KERNEL_SOURCE/hardware/nvidia/t23x/nv-public/overlay")

DTSI_FILE_DICT+=(["Auvidea_JNX42_OrinNX"]="tegra234-p3767-camera-p3768-vc_mipi-dual.dts")
DTSI_DEST_DICT+=(["Auvidea_JNX42_OrinNX"]="$KERNEL_SOURCE/hardware/nvidia/t23x/nv-public/overlay")

DTSI_FILE_DICT+=(["Forecr_DSADDON_OrinAGX"]="tegra234-p3737-camera-vc_mipi-overlay.dts" )
DTSI_DEST_DICT+=(["Forecr_DSADDON_OrinAGX"]="$KERNEL_SOURCE/hardware/nvidia/t23x/nv-public/overlay")

#setup
DRIVER_DST_DIR=$KERNEL_SOURCE/nvidia-oot/drivers/media/i2c/vc_mipi
KERNEL_OUT=$KERNEL_SOURCE/nvidia-oot
export KERNEL_HEADERS=$KERNEL_SOURCE/kernel/kernel-noble
export kernel_name=noble

# The kernel release of the stock BSP is 6.8.12-1029-tegra (see kernel/kernel_supplements.tbz2).
# The rebuilt kernel has to use the same release string, otherwise the modules of the
# sample root file system (/lib/modules/6.8.12-1029-tegra) would not match the new kernel.
# This value is picked up by config/configure.sh.
L4T_LOCALVERSION=-1029-tegra

KERNEL_DIR=kernel/kernel-noble/
MODULES_BSP=$BSP_DIR/Linux_for_Tegra/rootfs/usr

DTB_OUT=$KERNEL_SOURCE/build/nvidia-public/devicetree/generic-dtbs

ROOTFS_DIR=$BSP_DIR/Linux_for_Tegra/rootfs
MODULE_TARGET_LOCATION=updates/drivers/media/i2c

ORIN_FLASH_CONFIG_FOLDER="generic"
ORIN_FLASH_PARTITION_MMC="mmcblk0p1"
ORIN_FLASH_PARTITION_NVME="nvme0n1p1"

ORIN_NVME_XML="flash_l4t_t234_nvme.xml"

function L4T_extract_kernel_packages {
        echo "Extracting kernel packages ($VC_MIPI_BSP) ..."

        tar xvf kernel_src.tbz2

        tar xvf kernel_oot_modules_src.tbz2

        # 'make modules' builds the display driver (nvdisplay) and
        # the unified GPU display driver (unifiedgpudisp) since r39.
        tar xvf nvidia_kernel_display_driver_source.tbz2

        tar xvf nvidia_unified_gpu_display_driver_source.tbz2
}

function L4T_add_kernel_to_repo {
        echo "Adding kernel sources to local repository ($VC_MIPI_BSP) ..."

        git add hardware
        git add kernel
        git add nvidia-oot
}

function L4T_setup_nvidia_driver {
# not necessary for this L4T, it is being build and deployed automatically by the Makefile
        return 0
}

function L4T_setup_flash_prerequisites {
        case $VC_MIPI_SOM in
        OrinNano4GB_SD|OrinNano8GB_SD|OrinNano4GB_NVME|OrinNano8GB_NVME|OrinNX8GB|OrinNX16GB|OrinAGX32GB|OrinAGX64GB)
                echo "Setting up flash prerequisites ($VC_MIPI_BSP) ..."
                sudo ./tools/l4t_flash_prerequisites.sh
                ;;
        *)
                return 0
                ;;
        esac
}

EPROM_FILE=${BSP_DIR}/Linux_for_Tegra/bootloader/generic/BCT/tegra234-mb2-bct-misc-p3767-0000.dts
function L4T_setup_eeprom_size {
        Common_setup_eeprom_size
}

GPIO_FILE=${BSP_DIR}/Linux_for_Tegra/bootloader/generic/BCT/tegra234-mb2-bct-scr-p3767-0000.dts
GPIO_SCR_VALUE_STOCK="0x38009494"
GPIO_SCR_VALUE_JNX42="0x38009696"
function L4T_setup_gpio_file {
        # Since r39 the stock BCT already contains the register GPIO_M_SCR_00_0 (reg@322)
        # with the value 0x38009494. Common_setup_gpio_file would remove this stock entry
        # (NVIDIA DevKit) or would not set the value needed by the Auvidea JNX42.
        # So only the value of the existing entry is switched here.
        case $VC_MIPI_SOM in
        OrinNano4GB_SD|OrinNano8GB_SD|OrinNano4GB_NVME|OrinNano8GB_NVME|OrinNX8GB|OrinNX16GB)
                if [ ! -e ${GPIO_FILE} ]
                then
                        echo "Could not find ${GPIO_FILE}! (pwd $(pwd))"
                        exit 1
                fi

                if ! grep -q "reg@322 " ${GPIO_FILE}
                then
                        # Entry not present (not expected for r39), use the common handling.
                        Common_setup_gpio_file
                        return 0
                fi

                if [[ "Auvidea_JNX42" = $VC_MIPI_BOARD ]]
                then
                        GPIO_SCR_VALUE=${GPIO_SCR_VALUE_JNX42}
                else
                        GPIO_SCR_VALUE=${GPIO_SCR_VALUE_STOCK}
                fi

                echo "Modifying ${GPIO_FILE} ($VC_MIPI_BSP) ..."
                echo "Setting GPIO_M_SCR_00_0 to ${GPIO_SCR_VALUE} ..."
                sed -i "/reg@322 /,/};/ s/value = <0x[0-9a-fA-F]*>;/value = <${GPIO_SCR_VALUE}>;/" ${GPIO_FILE}
                echo "done"
                ;;
        *)
                return 0
                ;;
        esac
}

ORIN_NANO_CONF_FILE=${BSP_DIR}/Linux_for_Tegra/p3768-0000-p3767-0000-a0.conf
ORIN_AGX_CONF_FILE=${BSP_DIR}/Linux_for_Tegra/p3737-0000-p3701-0000.conf
function L4T_setup_conf_file {
        Common_setup_conf_file
}

function L4T_setup_dynamic_dtbo_file {
        case $VC_MIPI_SOM in
        OrinNano4GB_SD|OrinNano8GB_SD|OrinNano4GB_NVME|OrinNano8GB_NVME|OrinNX8GB|OrinNX16GB)
                # Since r39 tegra234-p3768-0000+p3767-0000-dynamic.dts does not include
                # any camera module anymore, so there is nothing to remove.
                return 0
                ;;
        OrinAGX32GB|OrinAGX64GB)
                DYNAMIC_DTBO_FILE=${BSP_DIR}/Linux_for_Tegra/source/hardware/nvidia/t23x/nv-public/overlay/tegra234-p3737-0000+p3701-0000-dynamic.dts
                if [ ! -e ${DYNAMIC_DTBO_FILE} ]
                then
                        echo "Could not find ${DYNAMIC_DTBO_FILE}! (pwd $(pwd))"
                        exit 1
                fi

                echo "Modifying ${DYNAMIC_DTBO_FILE} ($VC_MIPI_BSP) ..."
                sed -i '/#include \"tegra234-p3737-camera-modules.dtsi\"/d' ${DYNAMIC_DTBO_FILE}
                echo "done"
                ;;

        *)
                return 0
                ;;
        esac

}

function L4T_setup_addon_file {
# not necessary for this L4T
        return 0
}

function L4T_setup_toolchain {
        echo "Setup toolchain ($VC_MIPI_BSP) ..."

        if [[ ! -e $GCC_DIR ]]; then
                cd $DOWNLOAD_DIR
                tar xvf $GCC_FILE -C $TOOLCHAIN_DIR
        fi
        return 0
}

#build
function L4T_build_device_tree {
        echo "Build device tree ($VC_MIPI_BSP) ..."

        make dtbs

        cp $DTB_OUT/* $BSP_DIR/Linux_for_Tegra/kernel/dtb/
}

function L4T_build_kernel {
        echo "Build kernel ($VC_MIPI_BSP) ..."

        make -C kernel -j$(($(nproc)-1))

        export INSTALL_MOD_PATH=$ROOTFS_DIR/
        sudo -E make install -C kernel

        cp kernel/kernel-noble/arch/arm64/boot/Image $BSP_DIR/Linux_for_Tegra/kernel/Image
}

function L4T_build_modules {
        echo "Build modules ($VC_MIPI_BSP) ..."

        make modules -j$(($(nproc)-1))
}

function L4T_install_modules {
        echo "Install modules ($VC_MIPI_BSP) ..."

        export INSTALL_MOD_PATH=$ROOTFS_DIR/
        sudo -E make modules_install

        # The initrd contains kernel modules, so it has to be regenerated
        # after the modules of the rebuilt kernel have been installed.
        echo "Update initrd ($VC_MIPI_BSP) ..."
        cd $BSP_DIR/Linux_for_Tegra
        sudo ./tools/l4t_update_initrd.sh
        cd $KERNEL_SOURCE
}

function L4T_build_nvidia_driver {
# not necessary for this L4T, it is being build and deployed automatically by the Makefile
        return 0
}
