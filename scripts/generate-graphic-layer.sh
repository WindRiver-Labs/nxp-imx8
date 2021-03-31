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
    Optional parameters: [-s source-dir] [-d destination-dir] [-p platform-type] [-h]"
    echo "
    * [-s source-dir]: Source directory where the graphic layer come from
    * [-d destination-dir]: Destination directory where the graphic will be merged into
    * [-p platform-type]: Indicate the platform where the graphic will be used
			  Value: imx8mq imx8qm imx8mm imx8qxp
    * [-h]: help
    "
}

clean_up()
{
    unset CWD GRAPHIC_SRC GRAPHIC_DTS PLATFORM_TYPE
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
while getopts "s:d:p:h" fsl_setup_flag
do
    case $fsl_setup_flag in
        s) GRAPHIC_SRC="$OPTARG";
           echo "Graphic source directory is " $GRAPHIC_SRC
           ;;
        d) GRAPHIC_DTS="$OPTARG";
           echo "Graphic destination directory is " $GRAPHIC_DTS
           ;;
        p) PLATFORM_TYPE="$OPTARG";
           echo "Graphic destination directory is " $PLATFORM_TYPE
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
elif test -z "$PLATFORM_TYPE"; then
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

EXTENDED_WRLINUX_RECIPES_LIST = '${LAYERDIR}/conf/third_party_build.inc'

require imx8-graphic.inc

# We have a packages directory, add to BBFILES
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \
	${LAYERDIR}/recipes-*/*/*.bbappend \
	${LAYERDIR}/classes/*.bbclass"

BBFILE_COLLECTIONS += "imx8-graphic-layer"
BBFILE_PATTERN_imx8-graphic-layer := "^${LAYERDIR}/"
BBFILE_PRIORITY_imx8-graphic-layer = "7"

INHERIT += "machine-overrides-extender"
MACHINE_SOCARCH = "nxp_imx8"
MACHINE_HAS_VIVANTE_KERNEL_DRIVER_SUPPORT = "1"

BANNER[nxp-imx8_default] = "The nxp-imx8 layer includes third party components, where additional third party licenses may apply."

IMX_MIRROR ?= "https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/"
FSL_MIRROR ?= "${IMX_MIRROR}"
FSL_EULA_FILE_GRAPHIC = "${LAYERDIR}/EULA"

LAYERSERIES_COMPAT_imx8-graphic-layer = "wrl hardknott"
DISTRO_FEATURES_append = " imx8-graphic"
EOF
fi

file_modify()
{
	file_name=$1
	shift

	while test -n "$1"; do
		sed -i "$1" $file_name
		shift
	done
}

if [ $PLATFORM_TYPE = "imx8mq" ]; then
file_modify $GRAPHIC_DTS/imx8-graphic/conf/layer.conf \
			"20iMACHINEOVERRIDES_EXTENDER_nxp-imx8   = \"imx:mx8:mx8m:mx8mq:imxdrm:imxdcss:imxvpu:imxvpuhantro:imxgpu:imxgpu3d\"" \
			"24iIMAGE_INSTALL_append += \"assimp devil imx-vpu-hantro imx-gpu-viv imx-gpu-sdk imx-gpu-viv-demos\""
elif [ $PLATFORM_TYPE = "imx8mm" ]; then
file_modify $GRAPHIC_DTS/imx8-graphic/conf/layer.conf \
			"20iMACHINEOVERRIDES_EXTENDER_nxp-imx8   = \"imx:mx8:mx8m:mx8mm:imxdrm:imxvpu:imxvpuhantro:imxgpu:imxgpu2d:imxgpu3d\"" \
			"24iIMAGE_INSTALL_append += \"assimp devil imx-vpu-hantro imx-gpu-viv imx-gpu-sdk imx-gpu-viv-demos\""
elif [ $PLATFORM_TYPE = "imx8qm" ]; then
file_modify $GRAPHIC_DTS/imx8-graphic/conf/layer.conf \
			"20iMACHINEOVERRIDES_EXTENDER_nxp-imx8   = \"imx:mx8:mx8qm:imxdrm:imxdpu:imxgpu:imxgpu2d:imxgpu3d\"" \
			"24iIMAGE_INSTALL_append += \"assimp devil imx-gpu-viv imx-gpu-sdk imx-gpu-viv-demos\""
elif [ $PLATFORM_TYPE = "imx8qxp" ]; then
file_modify $GRAPHIC_DTS/imx8-graphic/conf/layer.conf \
			"20iMACHINEOVERRIDES_EXTENDER_nxp-imx8   = \"imx:mx8:mx8qxp:imxdrm:imxdpu:imxgpu:imxgpu2d:imxgpu3d\"" \
			"24iIMAGE_INSTALL_append += \"assimp devil imx-gpu-viv imx-gpu-sdk imx-gpu-viv-demos\""
fi

if [ ! -f $GRAPHIC_DTS/imx8-graphic/conf/imx8-graphic.inc ]; then
cat > $GRAPHIC_DTS/imx8-graphic/conf/imx8-graphic.inc << EOF
PREFERRED_PROVIDER_virtual/egl_imxgpu        ?= "imx-gpu-viv"
PREFERRED_PROVIDER_virtual/libgl_imxgpu3d    ?= "imx-gpu-viv"
PREFERRED_PROVIDER_virtual/libgles1_imxgpu3d ?= "imx-gpu-viv"
PREFERRED_PROVIDER_virtual/libgles2_imxgpu3d ?= "imx-gpu-viv"
PREFERRED_PROVIDER_virtual/libg2d            ?= "imx-gpu-g2d"
PREFERRED_PROVIDER_virtual/libg2d_imxdpu     ?= "imx-dpu-g2d"
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

if [ ! -f $GRAPHIC_DTS/imx8-graphic/conf/third_party_build.inc ]; then
	cat > $GRAPHIC_DTS/imx8-graphic/conf/third_party_build.inc << EOF
WRLINUX_SUPPORTED_RECIPE_pn-imx-gpu-sdk ?= "0 "
WRLINUX_SUPPORTED_RECIPE_pn-imx-gpu-viv ?= "0 "
WRLINUX_SUPPORTED_RECIPE_pn-imx-gpu-g2d ?= "0 "
WRLINUX_SUPPORTED_RECIPE_pn-imx-gpu-apitrace ?= "0 "
WRLINUX_SUPPORTED_RECIPE_pn-imx-dpu-g2d ?= "0 "
EOF
fi

if [ $PLATFORM_TYPE = "imx8mq" ]; then
file_modify $GRAPHIC_DTS/imx8-graphic/conf/imx8-graphic.inc \
			"21iPNWHITELIST_imx8-graphic-layer += 'imx-vpu-hantro'"

elif [ $PLATFORM_TYPE = "imx8mm" ]; then
file_modify $GRAPHIC_DTS/imx8-graphic/conf/imx8-graphic.inc \
                        "21iPNWHITELIST_imx8-graphic-layer += 'imx-vpu-hantro'" \
			"22iPNWHITELIST_imx8-graphic-layer += 'imx-gpu-g2d'"

elif [ $PLATFORM_TYPE = "imx8qm" ]; then
file_modify $GRAPHIC_DTS/imx8-graphic/conf/imx8-graphic.inc \
			"21iPNWHITELIST_imx8-graphic-layer += 'imx-gpu-g2d'" \
			"22iPNWHITELIST_imx8-graphic-layer += 'imx-dpu-g2d'"

elif [ $PLATFORM_TYPE = "imx8qxp" ]; then
file_modify $GRAPHIC_DTS/imx8-graphic/conf/imx8-graphic.inc \
			"21iPNWHITELIST_imx8-graphic-layer += 'imx-dpu-g2d'"
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

SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/
DESTINATION_DIR=$GRAPHIC_DTS/imx8-graphic/

file_copy classes/fsl-eula-unpack.bbclass \
			"s/FSL_EULA_FILE/FSL_EULA_FILE_GRAPHIC/g" \
			'30i\FSL_EULA_FILE_GRAPHIC_MD5SUM_LA_OPT_NXP_SOFTWARE_LICENSE_V13 = \"1b4db4b25c3a1e422c0c0ed64feb65d2\"' \
			'31i\FSL_EULA_FILE_GRAPHIC_MD5SUM_LA_OPT_NXP_SOFTWARE_LICENSE_V15 = \"983e4c77621568488dd902b27e0c2143\"' \
			'32i\FSL_EULA_FILE_GRAPHIC_MD5SUM_LA_OPT_NXP_SOFTWARE_LICENSE_V16 = \"e9e880185bda059c90c541d40ceca922\"' \
			'33i\FSL_EULA_FILE_GRAPHIC_MD5SUM_LA_OPT_NXP_SOFTWARE_LICENSE_V17 = \"cf3f9b8d09bc3926b1004ea71f7a248a\"' \
			'55a\    ${FSL_EULA_FILE_GRAPHIC_MD5SUM_LA_OPT_NXP_SOFTWARE_LICENSE_V13} \\' \
			'56a\    ${FSL_EULA_FILE_GRAPHIC_MD5SUM_LA_OPT_NXP_SOFTWARE_LICENSE_V15} \\' \
			'57a\    ${FSL_EULA_FILE_GRAPHIC_MD5SUM_LA_OPT_NXP_SOFTWARE_LICENSE_V16} \\' \
                        '58a\    ${FSL_EULA_FILE_GRAPHIC_MD5SUM_LA_OPT_NXP_SOFTWARE_LICENSE_V17} \\' \
			"64d" \
			'64i\    "${FSL_EULA_FILE_GRAPHIC_MD5SUM_LA_OPT_NXP_SOFTWARE_LICENSE_V17}"'
mv $GRAPHIC_DTS/imx8-graphic/classes/fsl-eula-unpack.bbclass $GRAPHIC_DTS/imx8-graphic/classes/fsl-eula-unpack-graphic.bbclass

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-sdk/
file_copy classes/features_check.bbclass

SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/

file_copy classes/machine-overrides-extender.bbclass
file_copy classes/use-imx-headers.bbclass

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/

file_copy recipes-bsp/imx-vpu-hantro/imx-vpu-hantro_1.20.0.bb
file_copy recipes-bsp/imx-vpu-hantro/imx-vpu-hantro.inc \
			"s/fsl-eula-unpack/fsl-eula-unpack-graphic/g"

file_copy recipes-core/systemd/systemd/0020-logind.conf-Set-HandlePowerKey-to-ignore.patch
file_copy recipes-core/systemd/systemd_%.bbappend \
			"4d"

file_copy recipes-core/systemd/systemd-gpuconfig/gpuconfig
file_copy recipes-core/systemd/systemd-gpuconfig/gpuconfig.service
file_copy recipes-core/systemd/systemd-gpuconfig_1.0.bb \
			"s/GPL-2.0/GPL-2.0-only/g"

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-sdk/

file_copy recipes-devtools/half/half_2.1.0.bb
file_copy recipes-devtools/stb/stb_git.bb

SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/

file_copy recipes-graphics/cairo/cairo_%.bbappend


SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-sdk/

file_copy recipes-graphics/devil/devil_1.8.0.bb \
			"s/LGPL-2.1/LGPL-2.1-only/g"
file_copy recipes-graphics/devil/devil_%.bbappend
file_copy recipes-graphics/devil/devil/0001-CMakeLists-Use-CMAKE_INSTALL_LIBDIR-for-install-libs.patch

SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/

file_copy recipes-graphics/drm/libdrm_%.bbappend
file_copy recipes-graphics/drm/libdrm_2.4.91.imx.bb \
			"s/libpthread-stubs libpciaccess/libpthread-stubs/g" \
			"s/libdrm-imx-2.4.91/libdrm-imx-2.4.99/g" \
			"16,20d" \
			'16i\	file://musl-ioctl.patch \\' \
			'17i\	file://0001-meson-add-libdrm-vivante-to-the-meson-meta-data.patch "' \
			"s/95645843f59495387a072d48374718f22e69d7a4/f421c9c8c4b8fe48d9e6ef43910e98569c94a4b2/g" \
			"s/autotools/meson/g" \
			"25,31d" \
			'25i\PACKAGECONFIG ??= "libkms intel radeon amdgpu nouveau vmwgfx omap freedreno vc4 etnaviv install-test-programs"' \
			'26i\PACKAGECONFIG[libkms] = "-Dlibkms=true,-Dlibkms=false"' \
			'27i\PACKAGECONFIG[intel] = "-Dintel=true,-Dintel=false,libpciaccess"' \
			'28i\PACKAGECONFIG[radeon] = "-Dradeon=true,-Dradeon=false"' \
			'29i\PACKAGECONFIG[amdgpu] = "-Damdgpu=true,-Damdgpu=false"' \
			'30i\PACKAGECONFIG[nouveau] = "-Dnouveau=true,-Dnouveau=false"' \
			'31i\PACKAGECONFIG[vmwgfx] = "-Dvmwgfx=true,-Dvmwgfx=false"' \
			'32i\PACKAGECONFIG[omap] = "-Domap=true,-Domap=false"' \
			'33i\PACKAGECONFIG[exynos] = "-Dexynos=true,-Dexynos=false"' \
			'34i\PACKAGECONFIG[freedreno] = "-Dfreedreno=true,-Dfreedreno=false"' \
			'35i\PACKAGECONFIG[tegra] = "-Dtegra=true,-Dtegra=false"' \
			'36i\PACKAGECONFIG[vc4] = "-Dvc4=true,-Dvc4=false"' \
			'37i\PACKAGECONFIG[etnaviv] = "-Detnaviv=true,-Detnaviv=false"' \
			'38i\PACKAGECONFIG[freedreno-kgsl] = "-Dfreedreno-kgsl=true,-Dfreedreno-kgsl=false"' \
			'39i\PACKAGECONFIG[valgrind] = "-Dvalgrind=true,-Dvalgrind=false,valgrind"' \
			'40i\PACKAGECONFIG[install-test-programs] = "-Dinstall-test-programs=true,-Dinstall-test-programs=false"' \
			'41i\PACKAGECONFIG[cairo-tests] = "-Dcairo-tests=true,-Dcairo-tests=false"' \
			'42i\PACKAGECONFIG[udev] = "-Dudev=true,-Dudev=false,udev"' \
			"s/'--enable-manpages', '--disable-manpages'/'-Dman-pages=true', '-Dman-pages=false'/g" \
			"s/EXTRA_OECONF_append_imxgpu = \" --enable-vivante-experimental-api\"/BBCLASSEXTEND = \"native nativesdk\"/g" \
			'69a\PACKAGECONFIG_append_imxgpu = " vivante"' \
			'70a\PACKAGECONFIG[vivante] = "-Dvivante=true,-Dvivante=false"' \
			"s/--enable-manpages/-Dman-pages=true/g" \
			"s/--disable-manpages/-Dman-pages=false/g"
mv $GRAPHIC_DTS/imx8-graphic/recipes-graphics/drm/libdrm_2.4.91.imx.bb $GRAPHIC_DTS/imx8-graphic/recipes-graphics/drm/libdrm_2.4.99.imx.bb
file_copy recipes-graphics/drm/libdrm/imxgpu2d/drm-update-arm.patch
file_copy recipes-graphics/drm/libdrm/0001-configure.ac-Allow-explicit-enabling-of-cunit-tests.patch
file_copy recipes-graphics/drm/libdrm/fix_O_CLOEXEC_undeclared.patch
file_copy recipes-graphics/drm/libdrm/installtests.patch
SOURCE_DIR=$GRAPHIC_SRC/poky/meta
file_copy recipes-graphics/drm/libdrm/musl-ioctl.patch
touch $GRAPHIC_DTS/imx8-graphic/recipes-graphics/drm/libdrm/0001-meson-add-libdrm-vivante-to-the-meson-meta-data.patch
echo "From 45f48f8a5de59c04b0510c23853772bc970f411e Mon Sep 17 00:00:00 2001
From: Max Krummenacher <max.krummenacher@toradex.com>
Date: Thu, 9 Jan 2020 01:01:35 +0000
Subject: [PATCH] meson: add libdrm-vivante to the meson meta data

Upstream libdrm added the option to use meason as the buildsystem.
Integrate Vivante into the relevant meson build information.

Upstream-Status: Pending

Signed-off-by: Max Krummenacher <max.krummenacher@toradex.com>
---
 meson.build         | 14 +++++++++++++
 meson_options.txt   |  7 +++++++
 vivante/meson.build | 50 +++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 71 insertions(+)
 create mode 100644 vivante/meson.build

diff --git a/meson.build b/meson.build
index e292554a..f4740634 100644
--- a/meson.build
+++ b/meson.build
@@ -157,6 +157,15 @@ if _vc4 != 'false'
   with_vc4 = _vc4 == 'true' or ['arm', 'aarch64'].contains(host_machine.cpu_family())
 endif

+with_vivante = false
+_vivante = get_option('vivante')
+if _vivante == 'true'
+  if not with_atomics
+    error('libdrm_vivante requires atomics.')
+  endif
+  with_vivante = true
+endif
+
 # XXX: Apparently only freebsd and dragonfly bsd actually need this (and
 # gnu/kfreebsd), not openbsd and netbsd
 with_libkms = false
@@ -312,6 +321,7 @@ install_headers(
   'include/drm/savage_drm.h', 'include/drm/sis_drm.h',
   'include/drm/tegra_drm.h', 'include/drm/vc4_drm.h',
   'include/drm/via_drm.h', 'include/drm/virtgpu_drm.h',
+  'include/drm/vivante_drm.h',
   subdir : 'libdrm',
 )
 if with_vmwgfx
@@ -362,6 +372,9 @@ endif
 if with_etnaviv
   subdir('etnaviv')
 endif
+if with_vivante
+  subdir('vivante')
+endif
 if with_man_pages
   subdir('man')
 endif
 @@ -382,5 +395,6 @@ message('  EXYNOS API     @0@'.format(with_exynos))
 message('  Freedreno API  @0@ (kgsl: @1@)'.format(with_freedreno, with_freedreno_kgsl))
 message('  Tegra API      @0@'.format(with_tegra))
 message('  VC4 API        @0@'.format(with_vc4))
+message('  Vivante API    @0@'.format(with_etnaviv))
 message('  Etnaviv API    @0@'.format(with_etnaviv))
 message('')
diff --git a/meson_options.txt b/meson_options.txt
index 8af33f1c..dc69563d 100644
--- a/meson_options.txt
+++ b/meson_options.txt
@@ -95,6 +95,13 @@ option(
   choices : ['true', 'false', 'auto'],
   description : '''Enable support for vc4's KMS API.''',
 )
+option(
+  'vivante',
+  type : 'combo',
+  value : 'false',
+  choices : ['true', 'false', 'auto'],
+  description : '''Enable support for vivante's propriatary experimental KMS API.''',
+)
 option(
   'etnaviv',
   type : 'combo',
diff --git a/vivante/meson.build b/vivante/meson.build
new file mode 100644
index 00000000..f6adb598
--- /dev/null
+++ b/vivante/meson.build
@@ -0,0 +1,50 @@
+# Copyright © 2017-2018 Intel Corporation
+
+# Permission is hereby granted, free of charge, to any person obtaining a copy
+# of this software and associated documentation files (the "Software"), to deal
+# in the Software without restriction, including without limitation the rights
+# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
+# copies of the Software, and to permit persons to whom the Software is
+# furnished to do so, subject to the following conditions:
+
+# The above copyright notice and this permission notice shall be included in
+# all copies or substantial portions of the Software.
+
+# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
+# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
+# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
+# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
+# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
+# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
+# SOFTWARE.
+
+
+libdrm_vivante = shared_library(
+  'drm_vivante',
+  [
+    files(
+      'vivante_bo.c',
+    ),
+    config_file
+  ],
+  include_directories : [inc_root, inc_drm],
+  link_with : libdrm,
+  c_args : libdrm_c_args,
+  dependencies : [dep_pthread_stubs, dep_rt, dep_atomic_ops],
+  version : '1.0.0',
+  install : true,
+)
+
+pkg.generate(
+  name : 'libdrm_vivante',
+  libraries : libdrm_vivante,
+  subdirs : ['.', 'libdrm'],
+  version : meson.project_version(),
+  requires_private : 'libdrm',
+  description : 'Userspace interface to Vivante kernel DRM services',
+)
+
+ext_libdrm_vivante = declare_dependency(
+  link_with : [libdrm, libdrm_vivante],
+  include_directories : [inc_drm, include_directories('.')],
+)" > $GRAPHIC_DTS/imx8-graphic/recipes-graphics/drm/libdrm/0001-meson-add-libdrm-vivante-to-the-meson-meta-data.patch 

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-sdk/
file_copy recipes-graphics/gli/gli_0.8.2.0.bb
file_copy recipes-graphics/gli/gli/0001-Set-C-standard-through-CMake-standard-options.patch
file_copy recipes-graphics/glm/glm_0.9.8.5.bb
file_copy recipes-graphics/glm/glm/Fixed-GCC-7.3-compile.patch

if [ $PLATFORM_TYPE = "imx8qm" ]; then
SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/
file_copy recipes-graphics/imx-dpu-g2d/imx-dpu-g2d_1.8.12.bb
SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/
file_copy recipes-graphics/imx-dpu-g2d/imx-dpu-g2d_1.7.0.bb \
			"s/fsl-eula-unpack/fsl-eula-unpack-graphic/g"

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/
file_copy recipes-graphics/imx-gpu-g2d/imx-gpu-g2d_6.4.3.p1.0.bb
SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/
file_copy recipes-graphics/imx-gpu-g2d/imx-gpu-g2d_6.2.4.p4.0.bb \
			"s/fsl-eula-unpack/fsl-eula-unpack-graphic/g"

elif [ $PLATFORM_TYPE = "imx8mm" ]; then
SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/
file_copy recipes-graphics/imx-gpu-g2d/imx-gpu-g2d_6.4.3.p1.0.bb
SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/
file_copy recipes-graphics/imx-gpu-g2d/imx-gpu-g2d_6.2.4.p4.0.bb \
                        "s/fsl-eula-unpack/fsl-eula-unpack-graphic/g"

elif [ $PLATFORM_TYPE = "imx8qxp" ]; then
SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/
file_copy recipes-graphics/imx-dpu-g2d/imx-dpu-g2d_1.8.12.bb
SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/
file_copy recipes-graphics/imx-dpu-g2d/imx-dpu-g2d_1.7.0.bb \
			"s/fsl-eula-unpack/fsl-eula-unpack-graphic/g"
fi

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/
file_copy recipes-graphics/imx-gpu-apitrace/imx-gpu-apitrace_9.0.0.bb

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-sdk/
file_copy recipes-graphics/imx-gpu-sdk/imx-gpu-sdk_5.6.2.bb \
                        "/glslang-native rapidvulkan vulkan-headers vulkan-loader/d" \

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/
file_copy recipes-graphics/imx-gpu-viv/imx-gpu-viv/Add-dummy-libgl.patch
file_copy recipes-graphics/imx-gpu-viv/imx-gpu-viv_6.4.3.p1.0-aarch64.bb \
			"s/fd4b227530cd88a82af6a5982cfb724d/6c12031a11b81db21cdfe0be88cac4b3/g" \
			"s/f4005a4a2dba6a79d8f25547612aa3b9/7c2f504897e6b4495433546ab7d27912/g" \
			"s/148e1b1a9e382a8159d5763dd2b08caad008eb931f3d925ac901c2438440d508/45852a5c3c61a9215a2ffb7387a6e1cce7ddac6f12513fc77459ad7e1f1b3a27/g"
file_copy recipes-graphics/imx-gpu-viv/imx-gpu-viv-6.inc \
			"s/fsl-eula-unpack/fsl-eula-unpack-graphic/g" \
			"/kernel-module-imx-gpu-viv/d"
			

SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/
file_copy recipes-graphics/mesa/mesa_%.bbappend \
			"s/'DISTRO_FEATURES', 'wayland'/'DISTRO_FEATURES', 'weston-demo'/g" \
			"47,49d" \
			"31,33d" \
			"47i\    rm -f \${D}\${includedir}/GL/glcorearb.h" \
			"\$a\\\n# Undo customization in meta-freescale that doesn't apply to 8DXL" \
			"\$aPACKAGECONFIG_remove_mx8dxl = \"osmesa\"" \
			"\$aDRIDRIVERS_remove = \"swrast\""

file_copy recipes-graphics/mesa/mesa-demos/Add-OpenVG-demos-to-support-wayland.patch
file_copy recipes-graphics/mesa/mesa-demos/fix-clear-build-break.patch
file_copy recipes-graphics/mesa/mesa-demos/Replace-glWindowPos2iARB-calls-with-glWindowPos2i.patch
file_copy recipes-graphics/mesa/mesa-demos_%.bbappend
file_copy recipes-graphics/mesa/mesa-gl_%.bbappend

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-sdk/

file_copy recipes-graphics/rapidopencl/rapidopencl_1.1.0.1.bb
file_copy recipes-graphics/rapidopenvx/rapidopenvx_1.1.0.bb
file_copy recipes-graphics/rapidvulkan/rapidvulkan_1.2.141.2001.bb

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
SOURCE_DIR=$GRAPHIC_SRC/poky/meta/
file_copy recipes-graphics/wayland/weston-init.bb \
		'49i\COMPATIBLE_MACHINE_nxp-imx8 = \"nxp-imx8\"' \	
file_copy recipes-graphics/wayland/weston-init/weston-start
file_copy recipes-graphics/wayland/weston-init/weston@.service
file_copy recipes-graphics/wayland/weston-init/init
file_copy recipes-graphics/wayland/weston-init/71-weston-drm.rules
SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/
file_copy recipes-graphics/wayland/weston-init/mx6sl/weston.config

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/
file_copy recipes-graphics/wayland/weston_9.0.0.imx.bb
file_copy recipes-graphics/wayland/weston_9.0.0.bb
file_copy recipes-graphics/wayland/weston/0001-weston-launch-Provide-a-default-version-that-doesn-t.patch
file_copy recipes-graphics/wayland/weston/0001-tests-include-fcntl.h-for-open-O_RDWR-O_CLOEXEC-and-.patch
file_copy recipes-graphics/wayland/weston/weston.desktop
file_copy recipes-graphics/wayland/weston/weston.png
file_copy recipes-graphics/wayland/weston/xwayland.weston-start

file_copy recipes-graphics/wayland/wayland-protocols_1.20.imx.bb
SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/
file_copy recipes-graphics/wayland/wayland-protocols_1.17.imx.bb

file_copy recipes-graphics/xorg-xserver/xserver-xorg_%.bbappend \
			"\$a# Trailing space is intentional due to a bug in meta-freescale" \
			"\$aSRC_URI += \"file://0001-glamor-Use-CFLAGS-for-EGL-and-GBM.patch \"" \
			"8d"
SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/
file_copy recipes-graphics/xorg-xserver/xserver-xorg/0001-glamor-Use-CFLAGS-for-EGL-and-GBM.patch

SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/
file_copy recipes-graphics/xorg-xserver/xserver-xf86-config_%.bbappend
SOURCE_DIR=$GRAPHIC_SRC/meta-imx/meta-bsp/
file_copy recipes-graphics/xorg-xserver/xserver-xf86-config/imx/xorg.conf
file_copy recipes-graphics/xorg-xserver/xserver-xf86-config/imxdrm/xorg.conf

file_copy recipes-kernel/linux/linux-imx-headers_5.4.bb \
			"9iDEPENDS += \"rsync-native\"" \
			"11,14d" \
			"11iSRCBRANCH = \"v5.4/standard/nxp-imx8\"" \
			"12iKERNEL_SRC ?= \"git://\${LAYER_PATH_wrlinux}/git/linux-yocto.git;protocol=file\"" \
			"13iSRC_URI = \"\${KERNEL_SRC};branch=\${SRCBRANCH}\"" \
			"14iSRCREV = \"\${AUTOREV}\""

SOURCE_DIR=$GRAPHIC_SRC/meta-freescale/
file_copy recipes-graphics/waffle/waffle_%.bbappend
file_copy recipes-graphics/waffle/waffle/0001-meson-Add-missing-wayland-dependency-on-EGL.patch
file_copy recipes-graphics/waffle/waffle/0002-meson-Separate-surfaceless-option-from-x11.patch

SOURCE_DIR=$GRAPHIC_SRC/meta-imx/
file_copy EULA.txt
mv $GRAPHIC_DTS/imx8-graphic/EULA.txt $GRAPHIC_DTS/imx8-graphic/EULA

echo "Graphic layer is generated successfully!"
clean_up && exit 1
