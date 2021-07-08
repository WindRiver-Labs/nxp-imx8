require linux-yocto-nxp-imx8.inc

KBRANCH_nxp-imx8  = "v5.10/standard/nxp-sdk-5.10/nxp-soc"

LINUX_VERSION_nxp-imx8 ?= "5.10.x"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append_nxp-imx8 = " \
    file://imx8.cfg \
"

