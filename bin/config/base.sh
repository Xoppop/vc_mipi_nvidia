#!/bin/bash

WORKING_DIR=$(dirname $PWD)
BIN_DIR=$WORKING_DIR/bin
BUILD_DIR=$WORKING_DIR/build
TOOLCHAIN_DIR=$BUILD_DIR/toolchain
PATCH_DIR=$WORKING_DIR/patch
DT_CAM_DIR=$WORKING_DIR/src/devicetree
ISP_DIR=$WORKING_DIR/src/isp
# ISP override files are selected per camera by the badge of the camera module in the device tree
ISP_TARGET_DIR=/var/nvidia/nvcam/settings
DRIVER_DIR=$WORKING_DIR/src/driver
TARGET_FILE=$BUILD_DIR/target.sh
CONFIGURATION_FILE=$BUILD_DIR/configuration.sh

declare -A -g DTSI_FILE_DICT
declare -A -g DTSI_DEST_DICT

VC_DEFAULT_USER="vc"
VC_DEFAULT_PW="vc"

ORIN_DTB_FILE=