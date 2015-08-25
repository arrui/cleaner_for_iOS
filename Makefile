#!/usr/bin/env bash
DEV = /Applications/Xcode.app/Contents/Developer
TOOLCHAIN = $(DEV)/Toolchains/XcodeDefault.xctoolchain
SDK = $(DEV)/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/
CC = $(TOOLCHAIN)/usr/bin/clang -std=gnu99
STRIP = $(TOOLCHAIN)/usr/bin/strip -x
LD = $(CC)

SSH = ssh -p 2222 
SCP = scp -P 2222
IP = localhost


MAIN = cleaner
DIR = /usr/bin
PLIST_DIR = /var/mobile/Library/cleaner
PLIST = cleanConfig.plist
# T_PLIST = $(DIR)/$(PLIST)
# T_MAIN = $(DIR)/$(MAIN)


LDFLAGS = -arch armv7 -isysroot $(SDK) -miphoneos-version-min=3.0 -dead_strip -lobjc
LDFLAGS += -lsqlite3
LDFLAGS += -framework CoreFoundation
LDFLAGS += -framework CoreTelephony
LDFLAGS += -framework Foundation
LDFLAGS += -framework UIKit
LDFLAGS += -L"$(SDK)/usr/lib"
LDFLAGS += -F"$(SDK)/System/Library/Frameworks"
LDFLAGS += -F"$(SDK)/System/Library/PrivateFrameworks"

CFLAGS = -arch armv7 -isysroot $(SDK) -miphoneos-version-min=3.0 
CFLAGS += -I"$(SDK)/usr/include"
CFLAGS += -I"."
CFLAGS += -I"$(SDK)/usr/lib/gcc/arm-apple-darwin10/4.0.1/include/"
CFLAGS += -F"$(SDK)/System/Library/Frameworks"
CFLAGS += -F"$(SDK)/System/Library/PrivateFrameworks"
CFLAGS += -funroll-loops

SOURCES = main.m \
          ScanFilesService.m \
          NSString+Addtion.m 

OBJECTS=\
	$(patsubst %.c,%.o,$(filter %.c,$(SOURCES))) \
	$(patsubst %.m,%.o,$(filter %.m,$(SOURCES)))

ifeq ($(MCLEANER_DEBUG),YES)
CFLAGS += -D__DEBUG__
endif

.SUFFIXES: .c .m .h .o
.PHONY: clean

all: $(MAIN)

$(MAIN): $(OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $^
	$(STRIP) $@
	export CODESIGN_ALLOCATE=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/codesign_allocate
	codesign -f -s "Arrui" $@
	
.m.o: $< $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<

.c.o: $< $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	-rm -f $(MAIN)
	find . -name "*.o" -exec rm {} \; -print

i:install

install: all
	# ./pkg.sh
	$(SSH) root@$(IP) 'rm -f $(DIR)/$(MAIN)'
	$(SCP) $(MAIN) root@$(IP):$(DIR)/$(MAIN)
	$(SSH) root@$(IP) chmod 4777 $(DIR)/$(MAIN)
	$(SSH) root@$(IP) chown root:admin $(DIR)/$(MAIN)
	$(SSH) root@$(IP) mkdir -p $(PLIST_DIR)
	$(SCP) $(PLIST) root@$(IP):$(PLIST_DIR)/$(PLIST)
	
rm:
	$(SSH) root@$(IP) 'rm -f $(DIR)/$(MAIN)'
	$(SSH) root@$(IP) 'rm -f $(PLIST_DIR)/$(PLIST)'

g:gdb
	
gdb: install
	$(SSH) root@$(IP) gdb $(DIR)/$(MAIN)
	
k:kill

kill:
	-$(SSH) root@$(IP) 'killall $(MAIN)'
	-$(SSH) root@$(IP) 'ps aux|grep $(MAIN)'
	
l:login

login:
	$(SSH) root@$(IP)
