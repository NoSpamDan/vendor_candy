# Copyright (C) 2012 The CyanogenMod Project
#           (C) 2017-2018 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Kernel variables are configured in vendor/potato/config/BoardConfigKernel.mk

ifneq ($(TARGET_NO_KERNEL),true)

ifeq ($(FULL_KERNEL_BUILD),true)

ifeq ($(NEED_KERNEL_MODULE_ROOT),true)
    KERNEL_MODULES_INSTALL := root
    KERNEL_MODULES_OUT := $(TARGET_ROOT_OUT)/lib/modules
    KERNEL_DEPMOD_STAGING_DIR := $(call intermediates-dir-for,PACKAGING,depmod_recovery)
    KERNEL_MODULE_MOUNTPOINT :=
else ifeq ($(NEED_KERNEL_MODULE_SYSTEM),true)
    KERNEL_MODULES_INSTALL := $(TARGET_COPY_OUT_SYSTEM)
    KERNEL_MODULES_OUT := $(TARGET_OUT)/lib/modules
    KERNEL_DEPMOD_STAGING_DIR := $(call intermediates-dir-for,PACKAGING,depmod_system)
    KERNEL_MODULE_MOUNTPOINT := system
else
    KERNEL_MODULES_INSTALL := $(TARGET_COPY_OUT_VENDOR)
    KERNEL_MODULES_OUT := $(TARGET_OUT_VENDOR)/lib/modules
    KERNEL_DEPMOD_STAGING_DIR := $(call intermediates-dir-for,PACKAGING,depmod_vendor)
    KERNEL_MODULE_MOUNTPOINT := vendor
endif

PATH_OVERRIDE := PATH=$(shell cat $(OUT_DIR)/.path_interposer_origpath):$$PATH

ifeq ($(TARGET_KERNEL_CLANG_COMPILE),true)
    ifneq ($(TARGET_KERNEL_CLANG_VERSION),)
        KERNEL_CLANG_VERSION := clang-$(TARGET_KERNEL_CLANG_VERSION)
    else
        # Use the default version of clang if TARGET_KERNEL_CLANG_VERSION hasn't been set by the device config
        KERNEL_CLANG_VERSION := $(LLVM_PREBUILTS_VERSION)
    endif
    TARGET_KERNEL_CLANG_PATH ?= $(BUILD_TOP)/prebuilts/clang/host/$(HOST_OS)-x86/$(KERNEL_CLANG_VERSION)/bin
    ifeq ($(KERNEL_ARCH),arm64)
        KERNEL_CLANG_TRIPLE ?= CLANG_TRIPLE=aarch64-linux-gnu-
    else ifeq ($(KERNEL_ARCH),arm)
        KERNEL_CLANG_TRIPLE ?= CLANG_TRIPLE=arm-linux-gnu-
    else ifeq ($(KERNEL_ARCH),x86)
        KERNEL_CLANG_TRIPLE ?= CLANG_TRIPLE=x86_64-linux-gnu-
    endif
	PATH_OVERRIDE := $(PATH_OVERRIDE):$(TARGET_KERNEL_CLANG_PATH) LD_LIBRARY_PATH=$(BUILD_TOP)/prebuilts/clang/host/$(HOST_OS)-x86/$(KERNEL_CLANG_VERSION)/lib64:$$LD_LIBRARY_PATH
    ifeq ($(KERNEL_CC),)
        KERNEL_CC := CC="$(CCACHE_BIN) clang"
    endif
endif

ifeq ($(TARGET_KERNEL_MODULES),)
    TARGET_KERNEL_MODULES := INSTALLED_KERNEL_MODULES
endif

KERNEL_ADDITIONAL_CONFIG_OUT := $(KERNEL_OUT)/.additional_config

# Internal implementation of make-kernel-target
# $(1): output path (The value passed to O=)
# $(2): target to build (eg. defconfig, modules, dtbo.img)
define internal-make-kernel-target
$(PATH_OVERRIDE) $(MAKE) $(KERNEL_MAKE_FLAGS) -C $(KERNEL_SRC) O=$(1) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_CLANG_TRIPLE) $(KERNEL_CC) $(2)
endef

# Make a kernel target
# $(1): The kernel target to build (eg. defconfig, modules, modules_install)
define make-kernel-target
$(call internal-make-kernel-target,$(KERNEL_OUT),$(1))
endef

# Make a DTBO target
# $(1): The DTBO target to build (eg. dtbo.img, defconfig)
define make-dtbo-target
$(call internal-make-kernel-target,$(PRODUCT_OUT)/dtbo,$(1))
endef

$(KERNEL_ADDITIONAL_CONFIG_OUT):
	$(hide) cmp -s $(KERNEL_ADDITIONAL_CONFIG_SRC) $@ || cp $(KERNEL_ADDITIONAL_CONFIG_SRC) $@;

$(KERNEL_CONFIG): $(KERNEL_DEFCONFIG_SRC) $(KERNEL_ADDITIONAL_CONFIG_OUT)
	@echo "Building Kernel Config"
	$(hide) mkdir -p $(KERNEL_OUT)
	$(PATH_OVERRIDE) $(MAKE_PREBUILT) $(KERNEL_MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_CLANG_TRIPLE) $(KERNEL_CC) VARIANT_DEFCONFIG=$(VARIANT_DEFCONFIG) SELINUX_DEFCONFIG=$(SELINUX_DEFCONFIG) $(KERNEL_DEFCONFIG)
	$(hide) if [ ! -z "$(KERNEL_CONFIG_OVERRIDE)" ]; then \
			echo "Overriding kernel config with '$(KERNEL_CONFIG_OVERRIDE)'"; \
			echo $(KERNEL_CONFIG_OVERRIDE) >> $(KERNEL_OUT)/.config; \
			$(PATH_OVERRIDE) $(MAKE_PREBUILT) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_CLANG_TRIPLE) $(KERNEL_CC) oldconfig; fi
	# Create defconfig build artifact
	$(hide) $(PATH_OVERRIDE) $(MAKE_PREBUILT) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_CLANG_TRIPLE) $(KERNEL_CC) savedefconfig
	$(hide) if [ ! -z "$(KERNEL_ADDITIONAL_CONFIG)" ]; then \
			echo "Using additional config '$(KERNEL_ADDITIONAL_CONFIG)'"; \
			$(KERNEL_SRC)/scripts/kconfig/merge_config.sh -m -O $(KERNEL_OUT) $(KERNEL_OUT)/.config $(KERNEL_SRC)/arch/$(KERNEL_ARCH)/configs/$(KERNEL_ADDITIONAL_CONFIG); \
			$(PATH_OVERRIDE) $(MAKE_PREBUILT) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_CLANG_TRIPLE) $(KERNEL_CC) KCONFIG_ALLCONFIG=$(KERNEL_OUT)/.config alldefconfig; fi

$(TARGET_PREBUILT_INT_KERNEL): $(KERNEL_CONFIG)
	@echo "Building Kernel"
	$(hide) rm -rf $(KERNEL_MODULES_OUT)
	$(hide) mkdir -p $(KERNEL_MODULES_OUT)
	$(hide) rm -rf $(KERNEL_DEPMOD_STAGING_DIR)
	$(PATH_OVERRIDE) $(MAKE_PREBUILT) $(KERNEL_MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_CLANG_TRIPLE) $(KERNEL_CC) $(BOARD_KERNEL_IMAGE_NAME)
	$(hide) if grep -q '^CONFIG_OF=y' $(KERNEL_CONFIG); then \
			echo "Building DTBs"; \
			$(PATH_OVERRIDE) $(MAKE_PREBUILT) $(KERNEL_MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_CLANG_TRIPLE) $(KERNEL_CC) dtbs; \
		fi
	$(hide) if grep -q '^CONFIG_MODULES=y' $(KERNEL_CONFIG) && grep -q '=m$$' $(KERNEL_CONFIG); then \
			echo "Building Kernel Modules"; \
			$(PATH_OVERRIDE) $(MAKE_PREBUILT) $(KERNEL_MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_CLANG_TRIPLE) $(KERNEL_CC) modules; \
		fi

.PHONY: INSTALLED_KERNEL_MODULES
INSTALLED_KERNEL_MODULES: depmod-host
	$(hide) if grep -q '^CONFIG_MODULES=y' $(KERNEL_CONFIG) && grep -q '=m$$' $(KERNEL_CONFIG); then \
			echo "Installing Kernel Modules"; \
			$(PATH_OVERRIDE) $(MAKE_PREBUILT) $(KERNEL_MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_CLANG_TRIPLE) $(KERNEL_CC) INSTALL_MOD_PATH=../../$(KERNEL_MODULES_INSTALL) modules_install && \
			mofile=$$(find $(KERNEL_MODULES_OUT) -type f -name modules.order) && \
			mpath=$$(dirname $$mofile) && \
			for f in $$(find $$mpath/kernel -type f -name '*.ko'); do \
				$(KERNEL_TOOLCHAIN_PATH)strip --strip-unneeded $$f; \
				mv $$f $(KERNEL_MODULES_OUT); \
			done && \
			rm -rf $$mpath && \
			mkdir -p $(KERNEL_DEPMOD_STAGING_DIR)/lib/modules/0.0/$(KERNEL_MODULE_MOUNTPOINT)/lib/modules && \
			find $(KERNEL_MODULES_OUT) -name *.ko -exec cp {} $(KERNEL_DEPMOD_STAGING_DIR)/lib/modules/0.0/$(KERNEL_MODULE_MOUNTPOINT)/lib/modules \; && \
			$(DEPMOD) -b $(KERNEL_DEPMOD_STAGING_DIR) 0.0 && \
			sed -e 's/\(.*modules.*\):/\/\1:/g' -e 's/ \([^ ]*modules[^ ]*\)/ \/\1/g' $(KERNEL_DEPMOD_STAGING_DIR)/lib/modules/0.0/modules.dep > $(KERNEL_MODULES_OUT)/modules.dep; \
		fi

$(TARGET_KERNEL_MODULES): $(TARGET_PREBUILT_INT_KERNEL)

.PHONY: kerneltags
kerneltags: $(KERNEL_CONFIG)
	$(hide) mkdir -p $(KERNEL_OUT)
	$(PATH_OVERRIDE) $(MAKE_PREBUILT) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_CLANG_TRIPLE) $(KERNEL_CC) tags

.PHONY: kernelconfig kernelxconfig kernelsavedefconfig alldefconfig

kernelconfig:  KERNELCONFIG_MODE := menuconfig
kernelxconfig: KERNELCONFIG_MODE := xconfig
kernelxconfig kernelconfig:
	$(hide) mkdir -p $(KERNEL_OUT)
	$(MAKE_PREBUILT) $(KERNEL_MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_CLANG_TRIPLE) $(KERNEL_CC) $(KERNEL_DEFCONFIG)
	env KCONFIG_NOTIMESTAMP=true \
		 $(MAKE_PREBUILT) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_CLANG_TRIPLE) $(KERNEL_CC) $(KERNELCONFIG_MODE)
	env KCONFIG_NOTIMESTAMP=true \
		 $(MAKE_PREBUILT) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_CLANG_TRIPLE) $(KERNEL_CC) savedefconfig
	cp $(KERNEL_OUT)/defconfig $(KERNEL_DEFCONFIG_SRC)

kernelsavedefconfig:
	$(hide) mkdir -p $(KERNEL_OUT)
	$(PATH_OVERRIDE) $(MAKE_PREBUILT) $(KERNEL_MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_CLANG_TRIPLE) $(KERNEL_CC) $(KERNEL_DEFCONFIG)
	env KCONFIG_NOTIMESTAMP=true \
		 $(PATH_OVERRIDE) $(MAKE_PREBUILT) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_CLANG_TRIPLE) $(KERNEL_CC) savedefconfig
	cp $(KERNEL_OUT)/defconfig $(KERNEL_DEFCONFIG_SRC)

alldefconfig: $(KERNEL_OUT)
	env KCONFIG_NOTIMESTAMP=true \
		 $(PATH_OVERRIDE) $(MAKE_PREBUILT) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE) $(KERNEL_CLANG_TRIPLE) $(KERNEL_CC) alldefconfig

endif # FULL_KERNEL_BUILD

ifeq ($(TARGET_NEEDS_DTBOIMAGE),true)
BOARD_PREBUILT_DTBOIMAGE = $(PRODUCT_OUT)/dtbo/arch/$(KERNEL_ARCH)/boot/dtbo.img
$(BOARD_PREBUILT_DTBOIMAGE):
	echo -e ${CL_GRN}"Building DTBO.img"${CL_RST}
	$(call make-dtbo-target,$(KERNEL_DEFCONFIG))
	$(call make-dtbo-target,dtbo.img)
endif # TARGET_NEEDS_DTBOIMAGE

## Install it

ifeq ($(NEEDS_KERNEL_COPY),true)
file := $(INSTALLED_KERNEL_TARGET)
ALL_PREBUILT += $(file)
$(file) : $(KERNEL_BIN) | $(ACP)
	$(transform-prebuilt-to-target)

ALL_PREBUILT += $(INSTALLED_KERNEL_TARGET)
endif

INSTALLED_DTBOIMAGE_TARGET := $(PRODUCT_OUT)/dtbo.img
ALL_PREBUILT += $(INSTALLED_DTBOIMAGE_TARGET)

.PHONY: kernel
kernel: $(INSTALLED_KERNEL_TARGET) $(TARGET_KERNEL_MODULES)

.PHONY: dtboimage
dtboimage: $(INSTALLED_DTBOIMAGE_TARGET)

endif # TARGET_NO_KERNEL
