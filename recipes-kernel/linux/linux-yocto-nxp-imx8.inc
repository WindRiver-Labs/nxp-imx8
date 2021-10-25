#
# Copyright (C) 2020 Wind River Systems, Inc.
#

COMPATIBLE_MACHINE_nxp-imx8 = "nxp-imx8"
TARGET_SUPPORTED_KTYPES_nxp-imx8 = "standard preempt-rt"

KERNEL_VERSION_SANITY_SKIP = "1"
SRCREV_machine_nxp-imx8 ?= "${AUTOREV}"
SRCREV_meta_nxp-imx8 ?= "${AUTOREV}"
