# Append path for freescale layer to include alsa-state asound.conf
FILESEXTRAPATHS_prepend_nxp-imx8 := "${THISDIR}/${PN}:"

SRC_URI_append_nxp-imx8 = " \
	file://asound.state \
	file://asound.conf \
"

PACKAGE_ARCH_nxp-imx8 = "${MACHINE_ARCH}"
