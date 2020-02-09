#!/bin/sh
#
# i.MX8 Graphic Layer Generation Script
#
# Copyright (C) 2019 WindRiver
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
CWD=`pwd`
BSP_NAME=nxp-imx8
LAYER_NAME=imx8-graphic

echo "Generate graphic layer for BSP" $BSP_NAME
echo

usage()
{
    echo "Usage: source generate-graphic-layer.sh
    Optional parameters: [-s source-dir] [-d destination-dir] [-h]"
    echo "
    * [-s source-dir]: Source directory where the graphic layer come from
    * [-d destination-dir]: Destination directory where the graphic will be merged into
    * [-h]: help
    "
}

clean_up()
{
    unset CWD GRAPHIC_SRC GRAPHIC_DST
    unset usage clean_up
}


cat <<EOF
Warning: Once customer generats $LAYER_NAME layer, and then build with this layer.
There are some libraries and packages which are covered by Freescale's End User
License Agreement (EULA). To have the right to use these binaries in your images,
please read EULA carefully firstly.
WindRiver doesn't support imx8's GPU or VPU hardware acceleration feature in product
release. Customers who want to enable graphic hardware acceleration feature need to
run this script on their own PC to generate $LAYER_NAME layer.
EOF

echo
REPLY=
while [ -z "$REPLY" ]; do
	echo -n "Do you read the WARNING carefully? (y/n) "
	read REPLY
	case "$REPLY" in
		y|Y)
		echo "WARNING has been read."
		;;
		n|N)
		echo "WARNING has not been read."
		exit 1
		;;
		*)
		echo "WARNING has not been read."
		exit 1
		;;
	esac
done

# get command line options
OLD_OPTIND=$OPTIND
while getopts "s:d:h" fsl_setup_flag
do
    case $fsl_setup_flag in
        s) GRAPHIC_SRC="$OPTARG";
           echo "Graphic source directory is " $GRAPHIC_SRC
           ;;
        d) GRAPHIC_DST="$OPTARG";
           echo "Graphic destination directory is " $GRAPHIC_DST
           ;;
        h) fsl_setup_help='true';
           ;;
        \?) fsl_setup_error='true';
           ;;
    esac
done
shift $((OPTIND-1))
if [ $# -ne 0 ]; then
    fsl_setup_error=true
    echo "Invalid command line ending: '$@'"
fi
OPTIND=$OLD_OPTIND
if test $fsl_setup_help; then
    usage && clean_up && exit 1
elif test -z "$GRAPHIC_SRC"; then
    usage && clean_up && exit 1
elif test -z "$GRAPHIC_DST"; then
    usage && clean_up && exit 1
elif test $fsl_setup_error; then
    clean_up && exit 1
fi

mkdir -p $GRAPHIC_DST/$LAYER_NAME/conf
if [ ! -f $GRAPHIC_DST/$LAYER_NAME/conf/layer.conf ]; then
cat > $GRAPHIC_DST/$LAYER_NAME/conf/layer.conf <<"EOF"
#
# Copyright (C) 2016-2017 Wind River Systems, Inc.
#

# We have a conf and classes directory, add to BBPATH
BBPATH .= ":${LAYERDIR}"

require imx8-graphic.inc

# We have a packages directory, add to BBFILES
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \
	${LAYERDIR}/recipes-*/*/*.bbappend \
	${LAYERDIR}/classes/*.bbclass"

BBFILE_COLLECTIONS += "imx8-graphic-layer"
BBFILE_PATTERN_imx8-graphic-layer := "^${LAYERDIR}/"
BBFILE_PRIORITY_imx8-graphic-layer = "7"

INHERIT += "machine-overrides-extender"
MACHINEOVERRIDES_EXTENDER_nxp-imx8   = "mx8:mx8m:mx8mq:imxdrm:imxdcss:imxvpu:imxvpuhantro:imxgpu:imxgpu3d"
MACHINE_SOCARCH = "nxp_imx8"
MACHINE_HAS_VIVANTE_KERNEL_DRIVER_SUPPORT = "1"

IMAGE_INSTALL_append += "assimp devil vulkan imx-vpu-hantro imx-gpu-viv imx-gpu-sdk imx-gpu-viv-demos"
BANNER[nxp-imx8_default] = "The nxp-imx8 layer includes third party components, where additional third party licenses may apply."

LAYERSERIES_COMPAT_imx8-graphic-layer = "thud"
DISTRO_FEATURES_append = " imx8-graphic"
EOF
fi


if [ ! -f $GRAPHIC_DST/$LAYER_NAME/conf/$LAYER_NAME.inc ]; then
cat > $GRAPHIC_DST/$LAYER_NAME/conf/$LAYER_NAME.inc << EOF
PREFERRED_PROVIDER_virtual/egl_$BSP_NAME = "imx-gpu-viv"
PREFERRED_PROVIDER_virtual/libgles1_$BSP_NAME = "imx-gpu-viv"
PREFERRED_PROVIDER_virtual/libgles2_$BSP_NAME = "imx-gpu-viv"
PREFERRED_PROVIDER_virtual/libgl_$BSP_NAME = "imx-gpu-viv"
PREFERRED_VERSION_imx-vpu = "5.4.38"
PREFERRED_VERSION_vulkan = "1.0.65"
PREFERRED_VERSION_wayland-protocols = "1.16.imx"
PREFERRED_VERSION_libdrm = "2.4.91.imx"

PNWHITELIST_openembedded-layer += 'freeglut'
PNWHITELIST_$LAYER_NAME-layer += 'imx-gpu-viv'
PNWHITELIST_$LAYER_NAME-layer += 'imx-gpu-viv-demos'
PNWHITELIST_$LAYER_NAME-layer += 'imx-gpu-sdk'
PNWHITELIST_$LAYER_NAME-layer += 'imx-vpu-hantro'
PNWHITELIST_$LAYER_NAME-layer += 'assimp'
PNWHITELIST_$LAYER_NAME-layer += 'devil'
PNWHITELIST_$LAYER_NAME-layer += 'weston'
PNWHITELIST_$LAYER_NAME-layer += 'imx-gpu-apitrace'
PNWHITELIST_$LAYER_NAME-layer += 'systemd-gpuconfig'
PNWHITELIST_$LAYER_NAME-layer += 'spirv-tools'
PNWHITELIST_$LAYER_NAME-layer += 'glslang'
PNWHITELIST_$LAYER_NAME-layer += 'vulkan'
PNWHITELIST_$LAYER_NAME-layer += 'wayland-protocols'
PNWHITELIST_$LAYER_NAME-layer += 'libdrm'
EOF
fi

file_copy()
{
	src_file=$SOURCE_DIR/$1
	dst_file=$DESTINATION_DIR/$2

	if [ ! -f $src_file ]; then
		echo "No file $src_file"
		return 1
	fi

	cp $src_file $dst_file

	if [ $# = 2 ]; then
		return 0
	fi

	while [ $# != 2 ]; do
		sed -i "$3" $dst_file
		shift
	done
}

dir_copy()
{
	src_dir=$SOURCE_DIR/$1
	dst_dir=$DESTINATION_DIR/$2

	if [ ! -d $src_dir ]; then
		echo "Not dir $src_file"
		return 1
	fi

	if [ ! -e $dst_dir ]; then
		mkdir -p $dst_dir
	fi
	cp $src_dir $dst_dir -Rf
}

SOURCE_DIR=$GRAPHIC_SRC/
DESTINATION_DIR=$GRAPHIC_DST/$LAYER_NAME/

# systemd-gpuconfig
dir_copy meta-fsl-bsp-release/imx/meta-bsp/recipes-core/systemd/systemd-gpuconfig  recipes-core/systemd
file_copy meta-fsl-bsp-release/imx/meta-bsp/recipes-core/systemd/systemd-gpuconfig_1.0.bb  recipes-core/systemd

# imx-vpu-hantro
dir_copy meta-fsl-bsp-release/imx/meta-bsp/recipes-bsp/imx-vpu-hantro/ recipes-bsp/

# devil
dir_copy meta-freescale-distro/recipes-graphics/devil/ recipes-graphics/
file_copy meta-fsl-bsp-release/imx/meta-sdk/recipes-graphics/devil/devil_%.bbappend recipes-graphics/devil/devil_%.bbappend

# libdrm
dir_copy meta-fsl-bsp-release/imx/meta-bsp/recipes-graphics/drm/ recipes-graphics/

# imx-gpu-viv
dir_copy meta-fsl-bsp-release/imx/meta-bsp/recipes-graphics/imx-gpu-viv/ recipes-graphics/
# we need to do away with this RDEPENDS because imx-gpu-viv driver has been merged into kernel source.
file_copy meta-fsl-bsp-release/imx/meta-bsp/recipes-graphics/imx-gpu-viv/imx-gpu-viv-v6.inc recipes-graphics/imx-gpu-viv/imx-gpu-viv-v6.inc \
			"s/RDEPENDS_libgal-imx += \"kernel-module-imx-gpu-viv\"/#RDEPENDS_libgal-imx += \"kernel-module-imx-gpu-viv\"/g"

# imx-gpu-apitrace
dir_copy meta-fsl-bsp-release/imx/meta-bsp/recipes-graphics/imx-gpu-apitrace/ recipes-graphics/

# imx-gpu-sdk
dir_copy meta-fsl-bsp-release/imx/meta-sdk/recipes-graphics/imx-gpu-sdk/ recipes-graphics/
file_copy meta-fsl-bsp-release/imx/meta-sdk/recipes-graphics/imx-gpu-sdk/imx-gpu-sdk_5.2.0.bb recipes-graphics/imx-gpu-sdk/imx-gpu-sdk_5.2.0.bb \
			"s/'DISTRO_FEATURES', 'wayland'/'DISTRO_FEATURES', 'weston-demo'/g" \
			"24iSRC_URI_append_nxp-imx8 = \" file://0001-imx-gpu-sdk-open-https-link-without-ssl-certificate-.patch\"" \
			"54i    export GIT_SSL_NO_VERIFY=true"
mkdir -p $GRAPHIC_DST/$LAYER_NAME/recipes-graphics/imx-gpu-sdk/imx-gpu-sdk
if [ ! -f $GRAPHIC_DST/$LAYER_NAME/recipes-graphics/imx-gpu-sdk/imx-gpu-sdk/0001-imx-gpu-sdk-open-https-link-without-ssl-certificate-.patch ]; then
cat > $GRAPHIC_DST/$LAYER_NAME/recipes-graphics/imx-gpu-sdk/imx-gpu-sdk/0001-imx-gpu-sdk-open-https-link-without-ssl-certificate-.patch << "EOF"
From 052ea73778cc7dc7e2aae380dac0037af630010e Mon Sep 17 00:00:00 2001
From: Limeng <Meng.Li@windriver.com>
Date: Tue, 12 Mar 2019 21:22:10 +0800
Subject: [PATCH] imx-gpu-sdk: open https link without ssl certificate
 verification

When open a https protocol web page with Python(version > 2.7.9)
interface, it is need to verify certificate signatures. But there
is no appropriate crt file in wrlinux build system, so implement a
workaround to ignore certificate verification.

Signed-off-by: Meng Li <Meng.Li@windriver.com>
---
 .Config/FslBuild.py | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/.Config/FslBuild.py b/.Config/FslBuild.py
index 05b9ff2..ce7e601 100755
--- a/.Config/FslBuild.py
+++ b/.Config/FslBuild.py
@@ -37,4 +37,7 @@ PythonVersionCheck.CheckVersion()
 from FslBuildGen.Tool import ToolAppMain
 from FslBuildGen.Tool.Flow.ToolFlowBuild import ToolAppFlowFactory
 
+import ssl
+ssl._create_default_https_context = ssl._create_unverified_context
+
 ToolAppMain.Run(ToolAppFlowFactory())
-- 
2.7.4

EOF
fi

# mesa
dir_copy meta-fsl-bsp-release/imx/meta-bsp/recipes-graphics/mesa/ recipes-graphics/
# Copy content from layers/meta-freescale/recipes-graphics/mesa/mesa_%.bbappend
file_copy meta-freescale/recipes-graphics/mesa/mesa_%.bbappend recipes-graphics/mesa/mesa_%.bbappend \
			"s/'DISTRO_FEATURES', 'wayland'/'DISTRO_FEATURES', 'weston-demo'/g"

# wayland
dir_copy meta-fsl-bsp-release/imx/meta-bsp/recipes-graphics/wayland recipes-graphics/

# xorg-xserver
dir_copy meta-fsl-bsp-release/imx/meta-bsp/recipes-graphics/xorg-xserver/ recipes-graphics/
# delete this patch because xorg-xserver-2.21 has contain it.
file_copy meta-fsl-bsp-release/imx/meta-bsp/recipes-graphics/xorg-xserver/xserver-xorg_%.bbappend \
			recipes-graphics/xorg-xserver/xserver-xorg_%.bbappend \
			"s/file:\/\/0002-glamor_egl-Automatically-choose-a-GLES2-context-if-d.patch/ /g"

# add cairo_%.bbappend because we should enable cairo_egl and cairo_glesv2, or else weston-imx-5.0.0 will
# throw error as below:
# | checking for wayland-egl egl cairo-egl >= 1.11.3 cairo-glesv2... no
# | configure: error: cairo-egl not used because No package 'cairo-egl' found
dir_copy meta-freescale/recipes-graphics/cairo/ recipes-graphics/
file_copy meta-freescale/recipes-graphics/cairo/cairo_%.bbappend recipes-graphics/cairo/cairo_%.bbappend \
			"1i\PACKAGECONFIG_remove_imxgpu3d = \" opengl\" \ "

# vulkan
dir_copy meta-fsl-bsp-release/imx/meta-sdk/recipes-graphics/vulkan recipes-graphics/
dir_copy poky/meta/recipes-graphics/vulkan/vulkan recipes-graphics/vulkan/
file_copy poky/meta/recipes-graphics/vulkan/vulkan_1.0.65.2.bb recipes-graphics/vulkan/

echo "Graphic layer is generated successfully!"
clean_up && exit 1
