################################################################################
#
# firmware-imx
#
################################################################################

FIRMWARE_IMX_VERSION = 8.8
FIRMWARE_IMX_SITE = $(FREESCALE_IMX_SITE)
FIRMWARE_IMX_SOURCE = firmware-imx-$(FIRMWARE_IMX_VERSION).bin

FIRMWARE_IMX_LICENSE = NXP Semiconductor Software License Agreement
FIRMWARE_IMX_LICENSE_FILES = EULA COPYING
FIRMWARE_IMX_REDISTRIBUTE = NO

FIRMWARE_IMX_INSTALL_IMAGES = YES

define FIRMWARE_IMX_EXTRACT_CMDS
	$(call FREESCALE_IMX_EXTRACT_HELPER,$(FIRMWARE_IMX_DL_DIR)/$(FIRMWARE_IMX_SOURCE))
endef

#
# DDR firmware
#
ifeq ($(BR2_PACKAGE_FIRMWARE_IMX_NEEDS_DDR_FW),y)

FIRMWARE_IMX_DDR_FW_VERSION = $(call qstrip, $(BR2_PACKAGE_FIRMWARE_IMX_DDR_FW_VERSION))
FIRMWARE_IMX_DDRFW_DIR = $(@D)/firmware/ddr/synopsys

define FIRMWARE_IMX_PREPARE_DDR_FW
	$(TARGET_OBJCOPY) -I binary -O binary \
		--pad-to $(BR2_PACKAGE_FIRMWARE_IMX_IMEM_LEN) --gap-fill=0x0 \
		$(FIRMWARE_IMX_DDRFW_DIR)/$(strip $(1)).bin \
		$(FIRMWARE_IMX_DDRFW_DIR)/$(strip $(1))_pad.bin
	$(TARGET_OBJCOPY) -I binary -O binary \
		--pad-to $(BR2_PACKAGE_FIRMWARE_IMX_DMEM_LEN) --gap-fill=0x0 \
		$(FIRMWARE_IMX_DDRFW_DIR)/$(strip $(2)).bin \
		$(FIRMWARE_IMX_DDRFW_DIR)/$(strip $(2))_pad.bin
	cat $(FIRMWARE_IMX_DDRFW_DIR)/$(strip $(1))_pad.bin \
		$(FIRMWARE_IMX_DDRFW_DIR)/$(strip $(2))_pad.bin > \
		$(FIRMWARE_IMX_DDRFW_DIR)/$(strip $(3)).bin
endef


ifeq ($(BR2_PACKAGE_FIRMWARE_IMX_DDR4),y)
FIRMWARE_IMX_DDR_TYPE=ddr4
FIRMWARE_IMX_DDR_1D_IMEM_NAME=ddr4_imem_1d$(FIRMWARE_IMX_DDR_FW_VERSION)
FIRMWARE_IMX_DDR_1D_DMEM_NAME=ddr4_dmem_1d$(FIRMWARE_IMX_DDR_FW_VERSION)
FIRMWARE_IMX_DDR_2D_IMEM_NAME=ddr4_imem_2d$(FIRMWARE_IMX_DDR_FW_VERSION)
FIRMWARE_IMX_DDR_2D_DMEM_NAME=ddr4_dmem_2d$(FIRMWARE_IMX_DDR_FW_VERSION)
else
ifeq ($(BR2_PACKAGE_FIRMWARE_IMX_LPDDR4),y)
FIRMWARE_IMX_DDR_TYPE=lpddr4
FIRMWARE_IMX_DDR_1D_IMEM_NAME=lpddr4_pmu_train_1d_imem$(FIRMWARE_IMX_DDR_FW_VERSION)
FIRMWARE_IMX_DDR_1D_DMEM_NAME=lpddr4_pmu_train_1d_dmem$(FIRMWARE_IMX_DDR_FW_VERSION)
FIRMWARE_IMX_DDR_2D_IMEM_NAME=lpddr4_pmu_train_2d_imem$(FIRMWARE_IMX_DDR_FW_VERSION)
FIRMWARE_IMX_DDR_2D_DMEM_NAME=lpddr4_pmu_train_2d_dmem$(FIRMWARE_IMX_DDR_FW_VERSION)

endif
endif


ifeq ($(BR2_PACKAGE_FIRMWARE_IMX_DDR_FW_MULTIPLE),y)
define FIRMWARE_IMX_COPY_DDR_FW
	$(foreach f, $(1),
		cp $(FIRMWARE_IMX_DDRFW_DIR)/$(f).bin $(BINARIES_DIR)/$(subst $(FIRMWARE_IMX_DDR_FW_VERSION),,$(f)).bin \
	)
endef
else
define FIRMWARE_IMX_COPY_DDR_FW
	true
endef
endif


define FIRMWARE_IMX_INSTALL_IMAGE_DDR_FW
	# Create padded versions of [lp]ddr4_* and generate ddr_fw.bin.
	# ddr4_fw.bin is needed when generating imx8-boot-sd.bin
	# which is done in post-image script.
	$(call FIRMWARE_IMX_PREPARE_DDR_FW, \
		$(FIRMWARE_IMX_DDR_1D_IMEM_NAME), \
		$(FIRMWARE_IMX_DDR_1D_DMEM_NAME), \
		$(FIRMWARE_IMX_DDR_TYPE)_1d$(FIRMWARE_IMX_DDR_FW_VERSION)_fw)
	$(call FIRMWARE_IMX_PREPARE_DDR_FW, \
		$(FIRMWARE_IMX_DDR_2D_IMEM_NAME), \
		$(FIRMWARE_IMX_DDR_2D_DMEM_NAME), \
		$(FIRMWARE_IMX_DDR_TYPE)_2d$(FIRMWARE_IMX_DDR_FW_VERSION)_fw)
	cat $(FIRMWARE_IMX_DDRFW_DIR)/$(FIRMWARE_IMX_DDR_TYPE)_1d$(FIRMWARE_IMX_DDR_FW_VERSION)_fw.bin \
		$(FIRMWARE_IMX_DDRFW_DIR)/$(FIRMWARE_IMX_DDR_TYPE)_2d$(FIRMWARE_IMX_DDR_FW_VERSION)_fw.bin  > \
		$(BINARIES_DIR)/$(FIRMWARE_IMX_DDR_TYPE)$(FIRMWARE_IMX_DDR_FW_VERSION)_fw.bin
	ln -sf \
		$(BINARIES_DIR)/$(FIRMWARE_IMX_DDR_TYPE)$(FIRMWARE_IMX_DDR_FW_VERSION)_fw.bin \
		$(BINARIES_DIR)/ddr_fw.bin
	$(call FIRMWARE_IMX_COPY_DDR_FW, \
		$(FIRMWARE_IMX_DDR_1D_IMEM_NAME) \
		$(FIRMWARE_IMX_DDR_1D_DMEM_NAME) \
		$(FIRMWARE_IMX_DDR_2D_IMEM_NAME) \
		$(FIRMWARE_IMX_DDR_2D_DMEM_NAME))

endef
endif

#
# HDMI firmware
#

ifeq ($(BR2_PACKAGE_FIRMWARE_IMX_NEEDS_HDMI_FW),y)
define FIRMWARE_IMX_INSTALL_IMAGE_HDMI_FW
	cp $(@D)/firmware/hdmi/cadence/signed_hdmi_imx8m.bin \
		$(BINARIES_DIR)/signed_hdmi_imx8m.bin
endef
endif

#
# EPDC firmware
#

ifeq ($(BR2_PACKAGE_FIRMWARE_IMX_NEEDS_EPDC_FW),y)
define FIRMWARE_IMX_INSTALL_TARGET_EPDC_FW
	mkdir -p $(TARGET_DIR)/lib/firmware/imx
	cp -r $(@D)/firmware/epdc $(TARGET_DIR)/lib/firmware/imx
	mv $(TARGET_DIR)/lib/firmware/imx/epdc/epdc_ED060XH2C1.fw.nonrestricted \
		$(TARGET_DIR)/lib/firmware/imx/epdc/epdc_ED060XH2C1.fw
endef
endif

#
# SDMA firmware
#

FIRMWARE_IMX_SDMA_FW_NAME = $(call qstrip,$(BR2_PACKAGE_FIRMWARE_IMX_SDMA_FW_NAME))
ifneq ($(FIRMWARE_IMX_SDMA_FW_NAME),)
define FIRMWARE_IMX_INSTALL_TARGET_SDMA_FW
	mkdir -p $(TARGET_DIR)/lib/firmware/imx/sdma
	cp -r $(@D)/firmware/sdma/sdma-$(FIRMWARE_IMX_SDMA_FW_NAME)*.bin \
	       $(TARGET_DIR)/lib/firmware/imx/sdma/
endef
endif

#
# VPU firmware
#

FIRMWARE_IMX_VPU_FW_NAME = $(call qstrip,$(BR2_PACKAGE_FIRMWARE_IMX_VPU_FW_NAME))
ifneq ($(FIRMWARE_IMX_VPU_FW_NAME),)
define FIRMWARE_IMX_INSTALL_TARGET_VPU_FW
	mkdir -p $(TARGET_DIR)/lib/firmware/imx/vpu
	cp $(@D)/firmware/vpu/vpu_fw_$(FIRMWARE_IMX_VPU_FW_NAME)*.bin \
		$(TARGET_DIR)/lib/firmware/imx/vpu/
endef
endif

define FIRMWARE_IMX_INSTALL_IMAGES_CMDS
	$(FIRMWARE_IMX_INSTALL_IMAGE_DDR_FW)
	$(FIRMWARE_IMX_INSTALL_IMAGE_HDMI_FW)
endef

define FIRMWARE_IMX_INSTALL_TARGET_CMDS
	$(FIRMWARE_IMX_INSTALL_TARGET_EPDC_FW)
	$(FIRMWARE_IMX_INSTALL_TARGET_SDMA_FW)
	$(FIRMWARE_IMX_INSTALL_TARGET_VPU_FW)
endef

$(eval $(generic-package))
