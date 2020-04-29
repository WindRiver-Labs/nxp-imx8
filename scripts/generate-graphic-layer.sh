#!/bin/sh
#
# i.MX8 Graphic Layer Generation Script
#
# Copyright (C) 2020 WindRiver
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
echo "\nGenerate graphic layer for BSP" $BSP_NAME
echo

usage()
{
    echo "\n Usage: source generate-graphic-layer.sh
    Optional parameters: [-s source-dir] [-d destination-dir] [-h]"
    echo "
    * [-s source-dir]: Source directory where the graphic layer come from
    * [-d destination-dir]: Destination directory where the graphic will be merged into
    * [-h]: help
    "
}

clean_up()
{
    unset CWD GRAPHIC_SRC GRAPHIC_DTS
    unset usage clean_up
}


cat <<EOF
Warning: Once customer generates imx8 graphic layer, and then build with this layer.
There are some libraries and packages which are covered by Freescale's End User
License Agreement (EULA). To have the right to use these binaries in your images,
please read EULA carefully firstly.
WindRiver doesn't support imx8's GPU or VPU hardware acceleration feature in product
release. Customers who want to enable graphic hardware acceleration feature need to
run this script on their own PC to generate imx8-graphic layer.
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
        d) GRAPHIC_DTS="$OPTARG";
           echo "Graphic destination directory is " $GRAPHIC_DTS
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
elif test -z "$GRAPHIC_DTS"; then
    usage && clean_up && exit 1
elif test $fsl_setup_error; then
    clean_up && exit 1
fi

mkdir -p $GRAPHIC_DTS/imx8-graphic/conf
if [ ! -f $GRAPHIC_DTS/imx8-graphic/conf/layer.conf ]; then
cat > $GRAPHIC_DTS/imx8-graphic/conf/layer.conf << "EOF"
#
# Copyright (C) 2019-2020 Wind River Systems, Inc.
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
MACHINEOVERRIDES_EXTENDER_nxp-imx8   = "imx:mx8:mx8m:mx8mq:imxdrm:imxdcss:imxvpu:imxvpuhantro:imxgpu:imxgpu3d"
MACHINE_SOCARCH = "nxp_imx8"
MACHINE_HAS_VIVANTE_KERNEL_DRIVER_SUPPORT = "1"

IMAGE_INSTALL_append += "assimp devil imx-vpu-hantro imx-gpu-viv imx-gpu-sdk imx-gpu-viv-demos"
BANNER[nxp-imx8_default] = "The nxp-imx8 layer includes third party components, where additional third party licenses may apply."

IMX_MIRROR ?= "https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/"
FSL_MIRROR ?= "${IMX_MIRROR}"
FSL_EULA_FILE = "${LAYERDIR}/EULA"

LAYERSERIES_COMPAT_imx8-graphic-layer = "wrl warrior zeus"
DISTRO_FEATURES_append = " imx8-graphic"
EOF
fi


if [ ! -f $GRAPHIC_DTS/imx8-graphic/conf/imx8-graphic.inc ]; then
cat > $GRAPHIC_DTS/imx8-graphic/conf/imx8-graphic.inc << EOF
PREFERRED_PROVIDER_virtual/egl_nxp-imx8 = "imx-gpu-viv"
PREFERRED_PROVIDER_virtual/libgles1_nxp-imx8 = "imx-gpu-viv"
PREFERRED_PROVIDER_virtual/libgles2_nxp-imx8 = "imx-gpu-viv"
PREFERRED_PROVIDER_virtual/libgl_nxp-imx8 = "imx-gpu-viv"
PREFERRED_VERSION_imx-vpu = "5.4.39.1"
PREFERRED_VERSION_wayland-protocols = "1.18.imx"
PREFERRED_VERSION_libdrm = "2.4.99.imx"
PREFERRED_VERSION_weston = "7.0.0.imx"

PREFERRED_PROVIDER_opencl-headers_nxp-imx8 = "imx-gpu-viv"

DISTRO_FEATURES_remove = "directfb "
DISTRO_FEATURES_append = " x11 wayland pam"

PNWHITELIST_openembedded-layer += 'freeglut'
PNWHITELIST_imx8-graphic-layer += 'imx-gpu-viv'
PNWHITELIST_imx8-graphic-layer += 'imx-gpu-viv-demos'
PNWHITELIST_imx8-graphic-layer += 'imx-gpu-sdk'
PNWHITELIST_imx8-graphic-layer += 'imx-vpu-hantro'
PNWHITELIST_imx8-graphic-layer += 'assimp'
PNWHITELIST_imx8-graphic-layer += 'devil'
PNWHITELIST_imx8-graphic-layer += 'weston'
PNWHITELIST_imx8-graphic-layer += 'imx-gpu-apitrace'
PNWHITELIST_imx8-graphic-layer += 'systemd-gpuconfig'
PNWHITELIST_imx8-graphic-layer += 'spirv-tools'
PNWHITELIST_imx8-graphic-layer += 'glslang'
PNWHITELIST_imx8-graphic-layer += 'wayland-protocols'
PNWHITELIST_imx8-graphic-layer += 'libdrm'
PNWHITELIST_openembedded-layer += 'fmt'
PNWHITELIST_openembedded-layer += 'googletest'
PNWHITELIST_openembedded-layer += 'rapidjson'
PNWHITELIST_openembedded-layer += 'glm'
PNWHITELIST_imx8-graphic-layer += 'stb'
PNWHITELIST_imx8-graphic-layer += 'rapidvulkan'
PNWHITELIST_imx8-graphic-layer += 'rapidopencl'
PNWHITELIST_imx8-graphic-layer += 'half'
PNWHITELIST_imx8-graphic-layer += 'gli'
PNWHITELIST_imx8-graphic-layer += 'rapidopenvx'
PNWHITELIST_imx8-graphic-layer += 'vulkan-validationlayers'
PNWHITELIST_imx8-graphic-layer += 'linux-imx-headers'
PNWHITELIST_imx8-graphic-layer += 'vulkan-headers'
PNWHITELIST_imx8-graphic-layer += 'vulkan-loader'
PNWHITELIST_imx8-graphic-layer += 'vulkan-tools'
PNWHITELIST_imx8-graphic-layer += 'weston-init'
PNWHITELIST_imx8-graphic-layer += 'weston'
PNWHITELIST_openembedded-layer += 'libxaw'
PNWHITELIST_openembedded-layer += 'xterm'

IMAGE_INSTALL_append += " \\
    \${@bb.utils.contains('DISTRO_FEATURES', 'wayland', 'weston-init', '', d)} \\
    \${@bb.utils.contains('DISTRO_FEATURES', 'x11 wayland', 'weston-xwayland xterm', '', d)} \\
    imx-gpu-apitrace \\
"


IMAGE_FEATURES_remove = "\${@bb.utils.contains('DISTRO_FEATURES', 'wayland', 'x11-base  x11-sato', '', d)}"

# QA check settings - a little stricter than the OE-Core defaults
WARN_TO_ERROR_QA = "already-stripped compile-host-path install-host-path \\
                    installed-vs-shipped ldflags pn-overrides rpaths staticdev \\
                    useless-rpaths"
WARN_QA_remove = "\${WARN_TO_ERROR_QA}"
ERROR_QA_append = " \${WARN_TO_ERROR_QA}"

EOF
fi

file_copy()
{
	src_file=$SOURCE_DIR/$1
	dts_file=$DESTINATION_DIR/$1

	if [ -f $dts_file ]; then
		return 1
	fi

	if [ ! -f $src_file ]; then
		echo "No file $src_file"
		return 1
	fi

	mkdir -p $DESTINATION_DIR/`dirname $1`
	shift

	cp $src_file $dts_file

	while test -n "$1"; do
		sed -i "$1" $dts_file
		shift
	done
}



SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/
DESTINATION_DIR=$GRAPHIC_DTS/imx8-graphic/

file_copy classes/fsl-eula-unpack.bbclass

SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/

file_copy classes/machine-overrides-extender.bbclass
file_copy classes/use-imx-headers.bbclass

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/

file_copy recipes-bsp/imx-vpu-hantro/imx-vpu-hantro_1.16.0.bb
file_copy recipes-bsp/imx-vpu-hantro/imx-vpu-hantro.inc

file_copy recipes-core/systemd/systemd/0001-systemd-udevd.service.in-Set-PrivateMounts-to-no-to-.patch
file_copy recipes-core/systemd/systemd/0020-logind.conf-Set-HandlePowerKey-to-ignore.patch
file_copy recipes-core/systemd/systemd_%.bbappend

file_copy recipes-core/systemd/systemd-gpuconfig/gpuconfig
file_copy recipes-core/systemd/systemd-gpuconfig/gpuconfig.service
file_copy recipes-core/systemd/systemd-gpuconfig_1.0.bb

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-sdk/

file_copy recipes-devtools/half/half_1.12.0.bb
file_copy recipes-devtools/stb/stb_git.bb

SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/

file_copy recipes-graphics/cairo/cairo_%.bbappend


SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-sdk/

file_copy recipes-graphics/devil/devil_1.8.0.bb
file_copy recipes-graphics/devil/devil_%.bbappend \
		"\$a\\\ndo_install_append() {" \
		"\$a\	mv \${D}/usr/lib \${D}\${libdir}" \
		"\$a}"

SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/

file_copy recipes-graphics/drm/libdrm_%.bbappend
file_copy recipes-graphics/drm/libdrm_2.4.91.imx.bb
file_copy recipes-graphics/drm/libdrm/imxgpu2d/drm-update-arm.patch
file_copy recipes-graphics/drm/libdrm/0001-configure.ac-Allow-explicit-enabling-of-cunit-tests.patch
file_copy recipes-graphics/drm/libdrm/fix_O_CLOEXEC_undeclared.patch
file_copy recipes-graphics/drm/libdrm/installtests.patch

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/

file_copy recipes-graphics/drm/libdrm_2.4.99.imx.bb

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-sdk/
file_copy recipes-graphics/gli/gli_0.8.2.0.bb
file_copy recipes-graphics/gli/gli/0001-Set-C-standard-through-CMake-standard-options.patch

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/
file_copy recipes-graphics/imx-gpu-apitrace/imx-gpu-apitrace_8.0.0.bb

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-sdk/
file_copy recipes-graphics/imx-gpu-sdk/imx-gpu-sdk_5.4.0.bb \
			"s/'DISTRO_FEATURES', 'wayland'/'DISTRO_FEATURES', 'weston-demo'/g" \
			"/glslang-native rapidvulkan vulkan-headers vulkan-loader/d" \
			"16iDEPENDS_VULKAN_mx8   = \\\ " \
			"17i\    \"\${@bb.utils.contains('DISTRO_FEATURES', 'weston-demo', 'glslang-native rapidvulkan vulkan-headers vulkan-loader', \\\ " \
			"18i\        bb.utils.contains('DISTRO_FEATURES',     'x11',                      '', \\\ " \
			"19i\                                                        'glslang-native rapidvulkan vulkan-headers vulkan-loader', d), d)}\"" \
			"s/\\\ /\\\/g"


SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/
file_copy recipes-graphics/imx-gpu-viv/imx-gpu-viv/Add-dummy-libgl.patch
file_copy recipes-graphics/imx-gpu-viv/imx-gpu-viv_6.4.0.p2.0-aarch64.bb
file_copy recipes-graphics/imx-gpu-viv/imx-gpu-viv-v6.inc

SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/
file_copy recipes-graphics/imx-gpu-viv/imx-gpu-viv-6.inc \
			"s/'DISTRO_FEATURES', 'wayland'/'DISTRO_FEATURES', 'weston-demo'/g" \
			"s/\"DISTRO_FEATURES\", \"wayland\"/\"DISTRO_FEATURES\", \"weston-demo\"/g" \
			"/RDEPENDS_libgal-imx/d" \


file_copy recipes-graphics/mesa/mesa_%.bbappend \
			"s/'DISTRO_FEATURES', 'wayland'/'DISTRO_FEATURES', 'weston-demo'/g" \
			"50i\    rm -f \${D}\${includedir}/GL/glcorearb.h" \
			"\$a\\\n# Undo customization in meta-freescale that doesn't apply to 8DXL" \
			"\$aPACKAGECONFIG_remove_mx8dxl = \"osmesa\"" \
			"\$aDRIDRIVERS_remove_mx8dxl = \"swrast\""

file_copy recipes-graphics/mesa/mesa-demos/Add-OpenVG-demos-to-support-wayland.patch
file_copy recipes-graphics/mesa/mesa-demos/fix-clear-build-break.patch
file_copy recipes-graphics/mesa/mesa-demos/Replace-glWindowPos2iARB-calls-with-glWindowPos2i.patch
file_copy recipes-graphics/mesa/mesa-demos_%.bbappend
file_copy recipes-graphics/mesa/mesa-gl_%.bbappend

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-sdk/

file_copy recipes-graphics/rapidopencl/rapidopencl_1.1.0.1.bb
file_copy recipes-graphics/rapidopenvx/rapidopenvx_1.1.0.bb
file_copy recipes-graphics/rapidvulkan/rapidvulkan_1.1.114.1000.bb

file_copy recipes-graphics/vulkan/spirv-tools_git.bb
file_copy recipes-graphics/vulkan/spirv-tools/0001-Avoid-GCC8-warning-in-text_handler.cpp.-2197.patch
file_copy recipes-graphics/vulkan/spirv-tools/0001-tools-lesspipe-Allow-generic-shell.patch

file_copy recipes-graphics/vulkan/vkmark_1.0.bb
file_copy recipes-graphics/vulkan/vkmark/0001-scenes-Use-depth-format-supported-by-i.MX.patch

file_copy recipes-graphics/vulkan/vulkan-loader_1.1.121.bb
file_copy recipes-graphics/vulkan/vulkan-loader_1.1.121.bbappend
file_copy recipes-graphics/vulkan/vulkan-loader/0001-STDIO-844-No-need-to-change-the-App-s-apiVersion-to-.patch

file_copy recipes-graphics/vulkan/vulkan-validationlayers_1.1.121.bb
file_copy recipes-graphics/vulkan/vulkan-validationlayers_%.bbappend
file_copy recipes-graphics/vulkan/vulkan-validationlayers/0001-CMakeLists.txt-Change-the-installation-path-of-JSON-.patch
file_copy recipes-graphics/vulkan/vulkan-validationlayers/icd_VSI.json

file_copy recipes-graphics/vulkan/glslang_git.bb

file_copy recipes-graphics/vulkan/vulkan-headers_%.bbappend
file_copy recipes-graphics/vulkan/vulkan-headers_1.1.121.bb

file_copy recipes-graphics/vulkan/vulkan-demos_%.bbappend

file_copy recipes-graphics/vulkan/vulkan-tools_1.1.121.bb
file_copy recipes-graphics/vulkan/vulkan-tools_%.bbappend

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/
file_copy recipes-graphics/vulkan/assimp_4.1.0.bbappend

SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/
file_copy recipes-graphics/wayland/weston-init.bbappend \
			"44i\    install -Dm0755 \${WORKDIR}/profile \${D}\${sysconfdir}/profile.d/weston.sh" \
			"\$a\\\nSRC_URI += \"file://profile\""

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/
file_copy recipes-graphics/wayland/weston-init/weston.ini
file_copy recipes-graphics/wayland/weston-init/profile
SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/
file_copy recipes-graphics/wayland/weston-init/mx6sl/weston.config

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/
file_copy recipes-graphics/wayland/weston_7.0.0.imx.bb
file_copy recipes-graphics/wayland/weston/0001-weston-launch-Provide-a-default-version-that-doesn-t.patch
file_copy recipes-graphics/wayland/weston/weston.desktop
file_copy recipes-graphics/wayland/weston/weston.png
file_copy recipes-graphics/wayland/weston/xwayland.weston-start

file_copy recipes-graphics/wayland/wayland-protocols_1.18.imx.bb
file_copy recipes-graphics/wayland/wayland-protocols/0001-linux-dmabuf-support-passing-buffer-DTRC-meta-to-com.patch
file_copy recipes-graphics/wayland/wayland-protocols/0001-unstable-Add-alpha-compositing-protocol.patch
file_copy recipes-graphics/wayland/wayland-protocols/0002-unstable-Add-hdr10-metadata-protocol.patch
SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/
file_copy recipes-graphics/wayland/wayland-protocols_1.17.imx.bb

file_copy recipes-graphics/xorg-xserver/xserver-xorg_%.bbappend \
			"\$a# Trailing space is intentional due to a bug in meta-freescale" \
			"\$aSRC_URI += \"file://0001-glamor-Use-CFLAGS-for-EGL-and-GBM.patch \""
SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/
file_copy recipes-graphics/xorg-xserver/xserver-xorg/0001-glamor-Use-CFLAGS-for-EGL-and-GBM.patch
file_copy recipes-graphics/xorg-xserver/xserver-xorg/0003-Remove-check-for-useSIGIO-option.patch

SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/
file_copy recipes-graphics/xorg-xserver/xserver-xf86-config_%.bbappend
SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/
file_copy recipes-graphics/xorg-xserver/xserver-xf86-config/imx/xorg.conf
file_copy recipes-graphics/xorg-xserver/xserver-xf86-config/imxdrm/xorg.conf

file_copy recipes-kernel/linux/linux-imx-headers_5.4.bb \
			"9iDEPENDS += \"rsync-native\""

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/
file_copy EULA.txt
mv $GRAPHIC_DTS/imx8-graphic/EULA.txt $GRAPHIC_DTS/imx8-graphic/EULA

echo "Graphic layer is generated successfully!"
clean_up && exit 1
