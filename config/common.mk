# Copyright (C) 2018 CandyRoms
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

PRODUCT_BUILD_PROP_OVERRIDES += BUILD_UTC_DATE=0

# Google property overides
PRODUCT_SYSTEM_DEFAULT_PROPERTIES  += \
    keyguard.no_require_sim=true \
    ro.url.legal=http://www.google.com/intl/%s/mobile/android/basic/phone-legal.html \
    ro.url.legal.android_privacy=http://www.google.com/intl/%s/mobile/android/basic/privacy.html \
    ro.com.google.clientidbase=android-google \
    ro.com.android.wifi-watchlist=GoogleGuest \
    ro.error.receiver.system.apps=com.google.android.gms \
    ro.setupwizard.enterprise_mode=1 \
    ro.com.android.dataroaming=false \
    ro.atrace.core.services=com.google.android.gms,com.google.android.gms.ui,com.google.android.gms.persistent

# Disable Rescue Party
PRODUCT_SYSTEM_DEFAULT_PROPERTIES  += \
    persist.sys.disable_rescue=true

# Set custom volume steps
PRODUCT_SYSTEM_DEFAULT_PROPERTIES  += \
    ro.config.media_vol_steps=30 \
    ro.config.bt_sco_vol_steps=30

ifeq ($(PRODUCT_GMS_CLIENTID_BASE),)
PRODUCT_SYSTEM_DEFAULT_PROPERTIES  += \
    ro.com.google.clientidbase=android-google
else
PRODUCT_SYSTEM_DEFAULT_PROPERTIES  += \
    ro.com.google.clientidbase=$(PRODUCT_GMS_CLIENTID_BASE)
endif

PRODUCT_SYSTEM_DEFAULT_PROPERTIES  += \
    keyguard.no_require_sim=true

PRODUCT_SYSTEM_DEFAULT_PROPERTIES  += \
    ro.build.selinux=1

# Disable excessive dalvik debug messages
PRODUCT_SYSTEM_DEFAULT_PROPERTIES  += \
    dalvik.vm.debug.alloc=0

# LatinIME gesture typing
ifeq ($(TARGET_ARCH),arm64)
PRODUCT_COPY_FILES += \
    vendor/candy/prebuilt/common/lib64/libjni_latinime.so:system/lib64/libjni_latinime.so \
    vendor/candy/prebuilt/common/lib64/libjni_latinimegoogle.so:system/lib64/libjni_latinimegoogle.so
else
PRODUCT_COPY_FILES += \
    vendor/candy/prebuilt/common/lib/libjni_latinime.so:system/lib/libjni_latinime.so \
    vendor/candy/prebuilt/common/lib/libjni_latinimegoogle.so:system/lib/libjni_latinimegoogle.so
endif

# Backup tool
PRODUCT_COPY_FILES += \
    vendor/candy/prebuilt/common/bin/backuptool.sh:install/bin/backuptool.sh \
    vendor/candy/prebuilt/common/bin/backuptool.functions:install/bin/backuptool.functions \
    vendor/candy/prebuilt/common/bin/50-candy.sh:system/addon.d/50-candy.sh \
    vendor/candy/prebuilt/common/bin/clean_cache.sh:system/bin/clean_cache.sh

# Backup services whitelist
PRODUCT_COPY_FILES += \
    vendor/candy/config/permissions/backup.xml:system/etc/sysconfig/backup.xml

# Signature compatibility validation
PRODUCT_COPY_FILES += \
    vendor/candy/prebuilt/common/bin/otasigcheck.sh:install/bin/otasigcheck.sh

# Candy-specific init file
PRODUCT_COPY_FILES += \
    vendor/candy/prebuilt/common/etc/init.local.rc:root/init.local.rc \
    vendor/candy/prebuilt/common/etc/init.candy.rc:root/init.candy.rc

# SELinux filesystem labels
PRODUCT_COPY_FILES += \
    vendor/candy/prebuilt/common/etc/init.d/50selinuxrelabel:system/etc/init.d/50selinuxrelabel

# Enable SIP+VoIP on all targets
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.sip.voip.xml:system/etc/permissions/android.software.sip.voip.xml

# Candy-specific startup services
PRODUCT_COPY_FILES += \
    vendor/candy/prebuilt/common/etc/init.d/00banner:system/etc/init.d/00banner \
    vendor/candy/prebuilt/common/etc/init.d/90userinit:system/etc/init.d/90userinit \
    vendor/candy/prebuilt/common/bin/sysinit:system/bin/sysinit \
    vendor/candy/prebuilt/bin/clean_cache.sh:system/bin/clean_cache.sh

# Required packages
PRODUCT_PACKAGES += \
    CellBroadcastReceiver \
    Development \
    SpareParts \
    LockClock \
    WeatherClient \
    Lawnchair

# CustomDoze for all devices
PRODUCT_PACKAGES += \
    CustomDoze

# Cutout control overlays
PRODUCT_PACKAGES += \
    HideCutout \
    StatusBarStock

# Fonts packages
PRODUCT_PACKAGES += \
    candy-fonts

# Long screenshot
PRODUCT_PACKAGES += \
    Longshot

# Candy Updater
PRODUCT_PACKAGES += \
    Updater

# Lawnchair
PRODUCT_COPY_FILES += \
    vendor/candy/prebuilt/common/etc/permissions/privapp-permissions-lawnchair.xml:system/etc/permissions/privapp-permissions-lawnchair.xml \
    vendor/candy/prebuilt/common/etc/sysconfig/lawnchair-hiddenapi-package-whitelist.xml:system/etc/sysconfig/lawnchair-hiddenapi-package-whitelist.xml

# Permissions
PRODUCT_COPY_FILES += \
    vendor/candy/config/permissions/candy-privapp-permissions.xml:system/etc/permissions/candy-privapp-permissions.xml

# Weather client
PRODUCT_COPY_FILES += \
    vendor/candy/prebuilt/common/etc/permissions/com.android.providers.weather.xml:system/etc/permissions/com.android.providers.weather.xml \
    vendor/candy/prebuilt/common/etc/default-permissions/com.android.providers.weather.xml:system/etc/default-permissions/com.android.providers.weather.xml

# Include explicitly to work around GMS issues
PRODUCT_PACKAGES += \
    libprotobuf-cpp-full \
    librsjni

# Recommend using the non debug dexpreopter
USE_DEX2OAT_DEBUG := false

# AudioFX
PRODUCT_PACKAGES += \
    AudioFX

# Disable vendor restrictions
PRODUCT_RESTRICT_VENDOR_FILES := false

# Extra Optional packages
PRODUCT_PACKAGES += \
    Calculator \
    bootanimation.zip \
    LatinIME \
    BluetoothExt\
    OmniStyle

## Don't compile SystemUITests
EXCLUDE_SYSTEMUI_TESTS := true

# Extra tools
PRODUCT_PACKAGES += \
    openvpn \
    e2fsck \
    mke2fs \
    tune2fs \
    fsck.exfat \
    mkfs.exfat \
    ntfsfix \
    ntfs-3g

PRODUCT_PACKAGES += \
    charger_res_images

# Stagefright FFMPEG plugin
PRODUCT_PACKAGES += \
    libffmpeg_extractor \
    libffmpeg_omx \
    media_codecs_ffmpeg.xml

PRODUCT_SYSTEM_DEFAULT_PROPERTIES  += \
    media.sf.omx-plugin=libffmpeg_omx.so \
    media.sf.extractor-plugin=libffmpeg_extractor.so

# whitelist packages for location providers not in system
PRODUCT_SYSTEM_DEFAULT_PROPERTIES  += \
    ro.services.whitelist.packagelist=com.google.android.gms

# Storage manager
PRODUCT_SYSTEM_DEFAULT_PROPERTIES  += \
    ro.storage_manager.enabled=true

# Versioning System
# candy first version.
PRODUCT_VERSION_MAJOR = 10
PRODUCT_VERSION_MINOR = Alpha
PRODUCT_VERSION_MAINTENANCE = 0
CANDY_DATE := $(shell date +"%Y%m%d-%H%M")

ifdef CANDY_BUILD_EXTRA
    CANDY_POSTFIX += $(CANDY_BUILD_EXTRA)
endif

# Set the default version to unofficial
ifndef CANDY_BUILD_TYPE
    CANDY_BUILD_TYPE := UNOFFICIAL
endif

# Set all versions
CANDY_BUILD_VERSION := $(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR).$(PRODUCT_VERSION_MAINTENANCE)
CANDY_VERSION := Candy-$(CANDY_BUILD)-$(CANDY_BUILD_VERSION)-$(CANDY_BUILD_TYPE)-$(CANDY_DATE)
CANDY_MOD_VERSION := Candy-$(CANDY_BUILD)-$(CANDY_BUILD_VERSION)-$(CANDY_BUILD_TYPE)-$(CANDY_DATE)

PRODUCT_VERSION := $(TARGET_PRODUCT)
PRODUCT_VERSION := $(subst candy_,,$(PRODUCT_VERSION))

ROM_FINGERPRINT := Candy/$(PLATFORM_VERSION)/$(PRODUCT_VERSION)/$(shell date -u +%H%M)

# easy way to extend to add more packages
-include vendor/extra/product.mk

PRODUCT_PACKAGE_OVERLAYS += vendor/candy/overlay/common

# Google sounds
include vendor/candy/google/GoogleAudio.mk

# Unlimited photo storage in Google Photos
PRODUCT_COPY_FILES += \
    vendor/candy/prebuilt/etc/sysconfig/pixel_2017_exclusive.xml:system/etc/sysconfig/pixel_2017_exclusive.xml

# Accents and themes
include vendor/candy/themes/themes.mk

# Candy Updater and versioning
#include vendor/candy/build/core/main_version.mk

$(call inherit-product-if-exists, vendor/extra/product.mk)
