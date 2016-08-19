# Top level make file for building PandA socket server and associated device
# drivers for interfacing to the FPGA resources.

TOP := $(CURDIR)

# Build defaults that can be overwritten by the CONFIG file if present

BUILD_DIR = $(TOP)/build
VIVADO = /dls_sw/FPGA/Xilinx/Vivado/2015.1/settings64.sh
PYTHON = python2
ARCH = arm
CROSS_COMPILE = arm-xilinx-linux-gnueabi-
BINUTILS_DIR = /dls_sw/FPGA/Xilinx/SDK/2015.1/gnu/arm/lin/bin
KERNEL_DIR = $(error Define KERNEL_DIR before building driver)
DEFAULT_TARGETS = sim_server docs zpkg

-include CONFIG


CC = $(CROSS_COMPILE)gcc

# DRIVER_BUILD_DIR = $(BUILD_DIR)/driver
# SERVER_BUILD_DIR = $(BUILD_DIR)/server
SIM_SERVER_BUILD_DIR = $(BUILD_DIR)/sim_server
DOCS_BUILD_DIR = $(BUILD_DIR)/html
SLOW_FPGA_BUILD_DIR = $(BUILD_DIR)/SlowFPGA
FPGA_BUILD_DIR = $(BUILD_DIR)/CarrierFPGA

DRIVER_FILES := $(wildcard driver/*)
SERVER_FILES := $(wildcard server/*)

ifdef BINUTILS_DIR
PATH := $(BINUTILS_DIR):$(PATH)
endif

default: $(DEFAULT_TARGETS)
.PHONY: default

export GIT_VERSION := $(shell git describe --abbrev=7 --dirty --always --tags)

# ------------------------------------------------------------------------------
# Documentation

$(DOCS_BUILD_DIR)/index.html: $(wildcard docs/*.rst docs/*/*.rst docs/conf.py)
	sphinx-build -b html docs $(DOCS_BUILD_DIR)

docs: $(DOCS_BUILD_DIR)/index.html

.PHONY: docs


# ------------------------------------------------------------------------------
# Build installation package

# SERVER_ZPKG = $(BUILD_DIR)/panda-server@$(GIT_VERSION).zpg
CONFIG_ZPKG = $(BUILD_DIR)/panda-config@$(GIT_VERSION).zpg

$(SERVER_ZPKG): $(PANDA_KO) $(SERVER) $(wildcard etc/*)

$(CONFIG_ZPKG): $(wildcard config_d/*)

$(BUILD_DIR)/%.zpg:
	etc/make-zpkg $(TOP) $(BUILD_DIR) $@

zpkg: $(SERVER_ZPKG) $(CONFIG_ZPKG)
.PHONY: zpkg


# ------------------------------------------------------------------------------
# FPGA builds

FMC_DESIGN = loopback
SFP_DESIGN = loopback

export LM_LICENSE_FILE

SLOW_FPGA_PROM = slow_top.mcs


$(SLOW_FPGA_PROM): $(SLOW_FPGA_BUILD_DIR)
	source $(ISE_SETUP)  &&  $(MAKE) -C $< -f $(TOP)/SlowFPGA/Makefile \
            TOP=$(TOP) SRC_DIR=$(TOP)/SlowFPGA mcs

slow-fpga: $(SLOW_FPGA_PROM)
.PHONY: slow-fpga

carrier: $(FPGA_BUILD_DIR)
	$(MAKE) -C $< -f $(TOP)/CarrierFPGA/Makefile VIVADO=$(VIVADO) \
	    TOP=$(TOP) OUTDIR=$(FPGA_BUILD_DIR) \
		FMC_DESIGN=$(FMC_DESIGN) SFP_DESIGN=$(SFP_DESIGN)

# ------------------------------------------------------------------------------

# This needs to go more or less last to avoid conflict with other targets.
$(BUILD_DIR)/%:
	mkdir -p $@

clean:
	rm -rf $(BUILD_DIR)
	rm -f simserver
	find -name '*.pyc' -delete

.PHONY: clean

# 
# DEPLOY += $(PANDA_KO)
# DEPLOY += $(SERVER)
# 
# deploy: $(DEPLOY)
# 	scp $^ root@172.23.252.202:/opt
# 
# .PHONY: deploy

