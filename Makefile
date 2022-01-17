ifeq ($(WIFI_MODE),)
RT28xx_MODE = STA
else
RT28xx_MODE = $(WIFI_MODE)
endif

ifeq ($(TARGET),)
TARGET = LINUX
endif

ifeq ($(CHIPSET),)
CHIPSET = 7601U
endif

MODULE = $(word 1, $(CHIPSET))

#OS ABL - YES or NO
OSABL = YES

RT28xx_DIR = $(shell pwd)

include $(RT28xx_DIR)/os/linux/config.mk

RTMP_SRC_DIR = $(RT28xx_DIR)/RT$(MODULE)

#PLATFORM: Target platform
PLATFORM = PC

#APSOC
ifeq ($(MODULE),3050)
PLATFORM = RALINK_3050
endif
ifeq ($(MODULE),3052)
PLATFORM = RALINK_3052
endif
ifeq ($(MODULE),3350)
PLATFORM = RALINK_3050
endif
ifeq ($(MODULE),3352)
PLATFORM = RALINK_3352
endif

#RELEASE Package
RELEASE = DPA

ifeq ($(TARGET),LINUX)
MAKE = make
endif

ifeq ($(PLATFORM),PC)
#LINUX_SRC = /lib/modules/$(shell uname -r)/build
#LINUX_SRC_MODULE = /lib/modules/$(KVER)/kernel/drivers/net/wireless/
#CROSS_COMPILE = 
#ARCH =
LINUX_SRC = /home/cronyx/openipc/firmware/output/build/linux-3.0.8
CROSS_COMPILE = /home/cronyx/openipc/firmware/output/host/bin/arm-openipc-linux-musleabi-
ARCH:=arm
export $ARCH
endif

export ARCH KVER OSABL RT28xx_DIR RT28xx_MODE LINUX_SRC CROSS_COMPILE CROSS_COMPILE_INCLUDE PLATFORM RELEASE CHIPSET MODULE RTMP_SRC_DIR LINUX_SRC_MODULE TARGET HAS_WOW_SUPPORT

# The targets that may be used.
PHONY += all build_tools test LINUX release prerelease clean uninstall install libwapi osabl

ifeq ($(TARGET),LINUX)
all: build_tools $(TARGET)
else
all: $(TARGET)
endif 


build_tools:
	$(MAKE) -C tools
	$(RT28xx_DIR)/tools/bin2h

test:
	$(MAKE) -C tools test


LINUX:
ifeq ($(OSABL),YES)
	cp -f os/linux/Makefile.6.util $(RT28xx_DIR)/os/linux/Makefile
	$(MAKE) -C $(LINUX_SRC) SUBDIRS=$(RT28xx_DIR)/os/linux modules
endif

	cp -f os/linux/Makefile.6 $(RT28xx_DIR)/os/linux/Makefile
	$(MAKE) -C $(LINUX_SRC) SUBDIRS=$(RT28xx_DIR)/os/linux modules

ifeq ($(OSABL),YES)
	cp -f os/linux/Makefile.6.netif $(RT28xx_DIR)/os/linux/Makefile
	$(MAKE) -C $(LINUX_SRC) SUBDIRS=$(RT28xx_DIR)/os/linux modules
endif

ifeq ($(RT28xx_MODE),AP)
ifneq ($(findstring 7601,$(CHIPSET)),)
	cp -f $(RT28xx_DIR)/os/linux/mt$(MODULE)ap.ko /tftpboot
else
	cp -f $(RT28xx_DIR)/os/linux/rt$(MODULE)ap.ko /tftpboot
endif

ifeq ($(OSABL),YES)
	cp -f $(RT28xx_DIR)/os/linux/rtutil$(MODULE)ap.ko /tftpboot
	cp -f $(RT28xx_DIR)/os/linux/rtnet$(MODULE)ap.ko /tftpboot
endif
	rm -f os/linux/rt$(MODULE)ap.ko.lzma
	/root/bin/lzma e os/linux/rt$(MODULE)ap.ko os/linux/rt$(MODULE)ap.ko.lzma
else	
ifeq ($(RT28xx_MODE),APSTA)
	cp -f $(RT28xx_DIR)/os/linux/rt$(MODULE)apsta.ko /tftpboot
ifeq ($(OSABL),YES)
	cp -f $(RT28xx_DIR)/os/linux/rtutil$(MODULE)apsta.ko /tftpboot
	cp -f $(RT28xx_DIR)/os/linux/rtnet$(MODULE)apsta.ko /tftpboot
endif
else
ifneq ($(findstring 7601,$(CHIPSET)),)
	cp -f $(RT28xx_DIR)/os/linux/mt$(MODULE)sta.ko /tftpboot
else
	cp -f $(RT28xx_DIR)/os/linux/rt$(MODULE)sta.ko /tftpboot
endif

ifeq ($(OSABL),YES)
ifneq ($(findstring 7601,$(CHIPSET)),)
	cp -f $(RT28xx_DIR)/os/linux/mtutil$(MODULE)sta.ko /tftpboot
	cp -f $(RT28xx_DIR)/os/linux/mtnet$(MODULE)sta.ko /tftpboot
else
	cp -f $(RT28xx_DIR)/os/linux/rtutil$(MODULE)sta.ko /tftpboot
	cp -f $(RT28xx_DIR)/os/linux/rtnet$(MODULE)sta.ko /tftpboot
endif
endif
endif
endif


release: build_tools
	$(MAKE) -C $(RT28xx_DIR)/striptool -f Makefile.release clean
	$(MAKE) -C $(RT28xx_DIR)/striptool -f Makefile.release
	striptool/striptool.out
ifeq ($(RELEASE), DPO)
	gcc -o striptool/banner striptool/banner.c
	./striptool/banner -b striptool/copyright.gpl -s DPO/ -d DPO_GPL -R
	./striptool/banner -b striptool/copyright.frm -s DPO_GPL/include/firmware.h
endif

prerelease:
ifeq ($(MODULE), 2880)
	$(MAKE) -C $(RT28xx_DIR)/os/linux -f Makefile.release.2880 prerelease
else
	$(MAKE) -C $(RT28xx_DIR)/os/linux -f Makefile.release prerelease
endif

	cp $(RT28xx_DIR)/os/linux/Makefile.DPB $(RTMP_SRC_DIR)/os/linux/.
	cp $(RT28xx_DIR)/os/linux/Makefile.DPA $(RTMP_SRC_DIR)/os/linux/.
	cp $(RT28xx_DIR)/os/linux/Makefile.DPC $(RTMP_SRC_DIR)/os/linux/.

ifeq ($(RT28xx_MODE),STA)
	cp $(RT28xx_DIR)/os/linux/Makefile.DPD $(RTMP_SRC_DIR)/os/linux/.
	cp $(RT28xx_DIR)/os/linux/Makefile.DPO $(RTMP_SRC_DIR)/os/linux/.
endif	

clean:
ifeq ($(TARGET), LINUX)
	cp -f os/linux/Makefile.clean os/linux/Makefile
	$(MAKE) -C os/linux clean
	rm -rf os/linux/Makefile
endif	

uninstall:
ifeq ($(TARGET), LINUX)
	$(MAKE) -C $(RT28xx_DIR)/os/linux -f Makefile.6 uninstall
endif

install:
ifeq ($(TARGET), LINUX)
	$(MAKE) -C $(RT28xx_DIR)/os/linux -f Makefile.6 install
	$(MAKE) -C $(RT28xx_DIR)/os/linux -f Makefile.6.util install
	$(MAKE) -C $(RT28xx_DIR)/os/linux -f Makefile.6.netif install
endif

libwapi:
	cp -f os/linux/Makefile.libwapi.6 $(RT28xx_DIR)/os/linux/Makefile	
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C  $(LINUX_SRC) SUBDIRS=$(RT28xx_DIR)/os/linux modules	

osutil:
ifeq ($(OSABL),YES)
	cp -f os/linux/Makefile.6.util $(RT28xx_DIR)/os/linux/Makefile
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(LINUX_SRC) SUBDIRS=$(RT28xx_DIR)/os/linux modules
endif

osnet:
ifeq ($(OSABL),YES)
	cp -f os/linux/Makefile.6.netif $(RT28xx_DIR)/os/linux/Makefile
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(LINUX_SRC) SUBDIRS=$(RT28xx_DIR)/os/linux modules
endif

osdrv:
	cp -f os/linux/Makefile.6 $(RT28xx_DIR)/os/linux/Makefile
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(LINUX_SRC) SUBDIRS=$(RT28xx_DIR)/os/linux modules

# Declare the contents of the .PHONY variable as phony.  We keep that information in a variable
.PHONY: $(PHONY)
