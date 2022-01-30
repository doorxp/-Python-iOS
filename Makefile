PROJECT_DIR=$(shell pwd)

PYTHON_VERSION=3.10.2
PYTHON_VER= $(basename $(PYTHON_VERSION))

OPENSSL_VERSION_NUMBER=1.1.1
OPENSSL_REVISION=m
OPENSSL_VERSION=$(OPENSSL_VERSION_NUMBER)$(OPENSSL_REVISION)

BZIP2_VERSION=1.0.6

XZ_VERSION=5.2.5

FFI_VERSION=3.4.2

MINVER=11.0

TARGETS=iphonesimulator.x86_64 iphoneos.arm64

PYTHON_CONFIGURE-iOS= ac_cv_file__dev_ptmx=no ac_cv_file__dev_ptc=no ac_cv_type_long_double=no ac_cv_func_getentropy=no ac_cv_func_timegm=yes ac_cv_func_clock=yes

clean:
	rm -rf build dist

distclean: clean
	rm -rf downloads

downloads: downloads/openssl-$(OPENSSL_VERSION).tgz downloads/bzip2-$(BZIP2_VERSION).tgz downloads/xz-$(XZ_VERSION).tgz downloads/libffi-$(FFI_VERSION).tgz downloads/Python-$(PYTHON_VERSION).tgz

# ---download OpenSSL
clean-OpenSSL:
	rm -rf build/*/openssl-$(OPENSSL_VERSION)-* \
		build/*/libssl.a build/*/libcrypto.a \
		build/*/OpenSSL.framework

downloads/openssl-$(OPENSSL_VERSION).tgz:
	-if [ ! -d "$(PROJECT_DIR)/downloads" ]; then mkdir -p $(PROJECT_DIR)/downloads fi
	-if [ ! -e downloads/openssl-$(OPENSSL_VERSION).tgz ]; then curl --fail -L http://openssl.org/source/openssl-$(OPENSSL_VERSION).tar.gz -o downloads/openssl-$(OPENSSL_VERSION).tgz; fi
	-if [ ! -e downloads/openssl-$(OPENSSL_VERSION).tgz ]; then curl --fail -L http://openssl.org/source/old/$(OPENSSL_VERSION_NUMBER)/openssl-$(OPENSSL_VERSION).tar.gz -o downloads/openssl-$(OPENSSL_VERSION).tgz; fi
# ---download OpenSSL


# ---download bzip2
clean-bzip2:
	rm -rf build/*/bzip2-$(BZIP2_VERSION)-* \
		build/*/bzip2

downloads/bzip2-$(BZIP2_VERSION).tgz:
	mkdir -p downloads
	if [ ! -e downloads/bzip2-$(BZIP2_VERSION).tgz ]; then curl --fail -L https://src.fedoraproject.org/lookaside/pkgs/bzip2/bzip2-$(BZIP2_VERSION).tar.gz/00b516f4704d4a7cb50a1d97e6e8e15b/bzip2-$(BZIP2_VERSION).tar.gz -o downloads/bzip2-$(BZIP2_VERSION).tgz; fi
# ---download bzip2

# ---download xz
clean-xz:
	rm -rf build/*/xz-$(XZ_VERSION)-* \
		build/*/xz

downloads/xz-$(XZ_VERSION).tgz:
	mkdir -p downloads
	if [ ! -e downloads/xz-$(XZ_VERSION).tgz ]; then curl --fail -L http://tukaani.org/xz/xz-$(XZ_VERSION).tar.gz -o downloads/xz-$(XZ_VERSION).tgz; fi
# ---download xz


# ---download libffi
clean-libffi:
	rm -rf build/*/libffi-$(FFI_VERSION)-* \
		build/*/xz

downloads/libffi-$(FFI_VERSION).tgz:
	mkdir -p downloads
	if [ ! -e downloads/libffi-$(FFI_VERSION).tgz ]; then curl --fail -L https://github.com/libffi/libffi/releases/download/v$(FFI_VERSION)/libffi-$(FFI_VERSION).tar.gz -o downloads/libffi-$(FFI_VERSION).tgz; fi
# ---download libffi

# ---download Python
clean-Python:
	rm -rf build/Python-$(PYTHON_VERSION)-host build/*/Python-$(PYTHON_VERSION)-* \
		build/*/libpython$(PYTHON_VER).a build/*/pyconfig-*.h \
		build/*/Python.framework

downloads/Python-$(PYTHON_VERSION).tgz:
	mkdir -p downloads
	if [ ! -e downloads/Python-$(PYTHON_VERSION).tgz ]; then curl -L https://www.python.org/ftp/python/$(PYTHON_VERSION)/Python-$(PYTHON_VERSION).tgz > downloads/Python-$(PYTHON_VERSION).tgz; fi
# ---download Python


define build-target
	ARCH = $(subst .,,$(suffix $1))
	SDK  = $(basename $1)

	ARCH-$1	:= $$(ARCH)
	SDK-$1	:= $$(SDK)

	XARCH := x86_64
	XTARGET := x86_64-apple-darwin
	CC-$1	:= $$(shell xcrun --sdk $$(SDK-$1) -f clang)
	ifeq ($$(ARCH), arm64)
		XARCH := aarch64
		XTARGET := arm64-apple-ios
		# CC-$1	:= $$(shell xcrun --sdk $$(SDK-$1) -f clang) -D __arm64__
	endif

	SDK_ROOT-$1 :=	$$(shell xcrun --sdk $$(SDK-$1) --show-sdk-path)
	

	RANLIB-$1 := $$(shell xcrun --sdk $$(SDK-$1) -f ranlib)
	AR-$1 :=$$(shell xcrun --sdk $$(SDK-$1) -f ar)
	AS-$1 :=$$(shell xcrun --sdk $$(SDK-$1) -f as)
	LD-$1 := $$(shell xcrun --sdk $$(SDK-$1) -f ld)
	READELF-$1 :=$$(shell xcrun --sdk $$(SDK-$1) -f readelf)
	LLVM_PROFDATA-$1 :=$$(shell xcrun --sdk  $$(SDK-$1) -f llvm-profdata)

	FLAGSARGS := -miphoneos-version-min=$(MINVER) -arch $$(ARCH) -isysroot $$(SDK_ROOT-$1)

	MYHOME := $(PROJECT_DIR)/$1



	OPENSSL_DIR-$1 	:=	build/openssl-$(OPENSSL_VERSION)-$1
	BZIP2_DIR-$1   	:=   build/bzip2-$(BZIP2_VERSION)-$1
	XZ_DIR-$1      	:= 	build/xz-$(XZ_VERSION)-$1
	FFI_DIR-$1     	:= 	build/ffi-$(FFI_VERSION)-$1
	PYTHON_DIR-$1	:=  build/Python-$(PYTHON_VERSION)-$1

	TARGET_OPENSSL_PREFIX-$1	:=$$(MYHOME)/OpenSSL
	TARGET_BZIP2_PREFIX-$1		:=$$(MYHOME)/bzip2
	TARGET_XZ_PREFIX-$1			:=$$(MYHOME)/xz
	TARGET_FFI_PREFIX-$1		:=$$(MYHOME)/ffi
	TARGET_PYTHON_PREFIX-$1		:=$$(MYHOME)/Python


#-I$$(TARGET_OPENSSL_PREFIX-$)/include -I$$(TARGET_XZ_PREFIX-$1)/include -I$$(TARGET_BZIP2_PREFIX-$1)/include  -I$$(TARGET_FFI_PREFIX-$1)/include
#-L$$(TARGET_OPENSSL_PREFIX-$1)/lib -L$$(TARGET_BZIP2_PREFIX-$1)/lib -L$$(TARGET_XZ_PREFIX-$1)/lib -lbz2 -llzma -lssl -lcrypto


	CFLAGS-$1 :=$$(FLAGSARGS) -fembed-bitcode -I/usr/include/ -include _ctype.h  -include _types.h -include AvailabilityMacros.h -include stdio.h -include string.h -include netdb.h -include time.h -include sys/syscall.h -include sys/socket.h -include sys/types.h -std=gnu11 -stdlib=libstdc++
	CPPFLAGS-$1 :=$$(CFLAGS-$1)

	LDFLAGS-$1 :="$$(FLAGSARGS)  -L/usr/lib/ -lcurses -target $$(XTARGET)"

$$(TARGET_OPENSSL_PREFIX-$1):
	mkdir -p $$@
$$(TARGET_BZIP2_PREFIX-$1):
	mkdir -p $$@
$$(TARGET_XZ_PREFIX-$1):
	mkdir -p $$@
$$(TARGET_FFI_PREFIX-$1):
	mkdir -p $$@
$$(TARGET_PYTHON_PREFIX-$1):
	mkdir -p $$@

# Unpack OpenSSL
$$(OPENSSL_DIR-$1)/Makefile: downloads/openssl-$(OPENSSL_VERSION).tgz $$(TARGET_OPENSSL_PREFIX-$1)
	# Unpack sources
	mkdir -p $$(OPENSSL_DIR-$1)
	tar zxf $$< --strip-components 1 -C $$(OPENSSL_DIR-$1)

	# Configure the build
	cd $$(OPENSSL_DIR-$1) && \
		CC="$$(CC-$1)" \
		RANLIB="$$(RANLIB-$1)" \
		AR="$$(AR-$1)" \
		READELF="$$(READELF-$1)" \
		CROSS_TOP="$$(dir $$(SDK_ROOT-$1)).." \
		CROSS_SDK="$$(notdir $$(SDK_ROOT-$1))" \
		./Configure darwin64-$$(ARCH-$1)-cc --prefix=$$(TARGET_OPENSSL_PREFIX-$1) \
		LDFLAGS=$$(LDFLAGS-$1) \
		CFLAGS="$$(CFLAGS-$1)" \
		CXXFLAGS="$$(CFLAGS-$1)" \
		no-tests no-stdio no-ui-console no-unit-test no-external-tests no-dynamic-engine no-asm no-shared no-dso no-hw no-engine --openssldir=$$(TARGET_OPENSSL_PREFIX-$1)

# Build OpenSSL
$$(TARGET_OPENSSL_PREFIX-$1)/lib/libssl.a $$(TARGET_OPENSSL_PREFIX-$1)/lib/libcrypto.a: $$(OPENSSL_DIR-$1)/Makefile
	# Make the build
	cd $$(OPENSSL_DIR-$1) && \
	CC="$$(CC-$1)" \
	CROSS_TOP="$$(dir $$(SDK_ROOT-$1)).." \
	CROSS_SDK="$$(notdir $$(SDK_ROOT-$1))" \
	make build_libs && make install > /dev/null

	# Build OpenSSL
$$(TARGET_OPENSSL_PREFIX-$1)/lib/libOpenSSL.a: $$(TARGET_OPENSSL_PREFIX-$1)/lib/libssl.a $$(TARGET_OPENSSL_PREFIX-$1)/lib/libcrypto.a
	libtool -static -o $$@ $$^

# Unpack BZip2
$$(BZIP2_DIR-$1)/Makefile: downloads/bzip2-$(BZIP2_VERSION).tgz $$(TARGET_BZIP2_PREFIX-$1)
	# Unpack sources
	mkdir -p $$(BZIP2_DIR-$1)
	tar zxf downloads/bzip2-$(BZIP2_VERSION).tgz --strip-components 1 -C $$(BZIP2_DIR-$1)

	# Patch sources to use correct compiler
	sed -ie 's#CC=gcc#CC=$$(CC-$1)#' $$(BZIP2_DIR-$1)/Makefile
	sed -ie 's#AR=ar#AR=$$(AR-$1)#' $$(BZIP2_DIR-$1)/Makefile
	sed -ie 's#RANLIB=ranlib#RANLIB=$$(RANLIB-$1)#' $$(BZIP2_DIR-$1)/Makefile
	sed -ie 's#LDFLAGS=#$$(LDFLAGS-$1)#' $$(BZIP2_DIR-$1)/Makefile
	sed -ie 's#CFLAGS=#CFLAGS=$$(CFLAGS-$1) #' $$(BZIP2_DIR-$1)/Makefile
	
	# Patch sources to use correct install directory
	sed -ie 's#PREFIX=/usr/local#PREFIX=$$(TARGET_BZIP2_PREFIX-$1)#' $$(BZIP2_DIR-$1)/Makefile

# Build BZip2
$$(TARGET_BZIP2_PREFIX-$1)/lib/libbz2.a: $$(BZIP2_DIR-$1)/Makefile
	cd $$(BZIP2_DIR-$1) && make libbz2.a && make install

# Unpack XZ
$$(XZ_DIR-$1)/Makefile: downloads/xz-$(XZ_VERSION).tgz $$(TARGET_XZ_PREFIX-$1)
	# Unpack sources
	mkdir -p $$(XZ_DIR-$1)
	tar zxf downloads/xz-$(XZ_VERSION).tgz --strip-components 1 -C $$(XZ_DIR-$1)
	# Configure the build

	cd $$(XZ_DIR-$1) && ./configure cross_compiling=yes \
	CC="xcrun -sdk $$(SDK-$1) clang -arch $$(ARCH-$1)" \
	RANLIB="xcrun -sdk $$(SDK-$1) ranlib" \
	READELF="xcrun -sdk $$(SDK-$1) readelf" \
	AR="xcrun -sdk $$(SDK-$1) ar" \
	LDFLAGS="-target $$(ARCH-$1)-apple-darwin" \
	CFLAGS="-miphoneos-version-min=11.0  -fembed-bitcode -std=gnu11 -stdlib=libstdc++ -arch $$(ARCH-$1)" \
	--disable-shared --disable-xz --enable-static --disable-xz --disable-xzdec --disable-lzmainfo --disable-lzmadec \
	--disable-scripts --disable-doc --enable-decoders="lzma1 lzma2" --enable-decoders="lzma1 lzma2" \
	--prefix=$$(TARGET_XZ_PREFIX-$1)

# Build XZ
$$(TARGET_XZ_PREFIX-$1)/lib/liblzma.a: $$(XZ_DIR-$1)/Makefile
	cd $$(XZ_DIR-$1) && make install

# Unpack FFI
$$(FFI_DIR-$1)/Makefile: downloads/libffi-$(FFI_VERSION).tgz $$(TARGET_FFI_PREFIX-$1)
	# Unpack sources
	mkdir -p $$(FFI_DIR-$1)

	tar zxf downloads/libffi-$(FFI_VERSION).tgz --strip-components 1 -C $$(FFI_DIR-$1)
	# Configure the build
	
	cd $$(FFI_DIR-$1) && ./configure --disable-builddir --disable-docs -disable-shared --disable-portable-binary  --disable-multi-os-directory \
	CC="xcrun -sdk $$(SDK-$1) clang -arch $$(ARCH-$1)" \
	RANLIB="xcrun -sdk $$(SDK-$1) ranlib" \
	READELF="xcrun -sdk $$(SDK-$1) readelf" \
	AR="xcrun -sdk $$(SDK-$1) ar" \
	CFLAGS="-miphoneos-version-min=$(MINVER)" --with-gcc-arch=$$(ARCH-$1) \
	 --prefix=$$(TARGET_FFI_PREFIX-$1) \
	 --host=$$(ARCH-$1)-apple-darwin \
	 --build=$$(ARCH-$1)-apple-darwin \
	 cross_compiling=yes

# Build FFI
$$(TARGET_FFI_PREFIX-$1)/lib/libffi.a: $$(FFI_DIR-$1)/Makefile
	cd $$(FFI_DIR-$1) && make install

# Unpack Python
$$(PYTHON_DIR-$1)/Makefile: downloads/Python-$(PYTHON_VERSION).tgz $$(TARGET_PYTHON_PREFIX-$1)
	# Unpack target Python
	mkdir -p $$(PYTHON_DIR-$1)
	tar zxf downloads/Python-$(PYTHON_VERSION).tgz --strip-components 1 -C $$(PYTHON_DIR-$1)
	# Apply target Python patches

	cd $$(PYTHON_DIR-$1)

	patch $$(PYTHON_DIR-$1)/configure < $$(PROJECT_DIR)/patch/configure

	
	export LLVM_PROFDATA="$$(LLVM_PROFDATA-$1)"
	cd $$(PYTHON_DIR-$1) && ./configure --prefix=$$(TARGET_PYTHON_PREFIX-$1) \
	CC="xcrun -sdk $$(SDK-$1) clang -arch $$(ARCH-$1)" \
	READELF="xcrun -sdk $$(SDK-$1) readelf" \
	AR="xcrun -sdk $$(SDK-$1) AR" \
	LDFLAGS=$$(LDFLAGS-$1) CFLAGS="$$(CFLAGS-$1)" \
--enable-ipv6 --disable-test-modules --without-system-libmpdec --with-dtrace \
--with-static-libpython --with-system-expat \
--enable-optimizations --disable-test-modules --without-cxx-main \
--host=$$(ARCH-$1)-apple-darwin \
--build=$$(ARCH-$1)-apple-darwin --with-openssl-rpath=auto \
cross_compiling=yes \
ac_cv_file__dev_ptmx=no ac_cv_file__dev_ptc=no ac_cv_type_long_double=no ac_cv_func_getentropy=no ac_cv_func_timegm=yes ac_cv_func_clock=yes

	

# Build Python
$$(TARGET_PYTHON_PREFIX-$1)/lib/libPython$(PYTHON_VER).a: $$(TARGET_OPENSSL_PREFIX-$1)/lib/libssl.a $$(TARGET_OPENSSL_PREFIX-$1)/lib/libcrypto.a $$(TARGET_BZIP2_PREFIX-$1)/lib/libbz2.a $$(TARGET_XZ_PREFIX-$1)/lib/liblzma.a $$(TARGET_FFI_PREFIX-$1)/lib/libffi.a $$(PYTHON_DIR-$1)/Makefile
	# Build target Python
	sed -ie '/HAVE_SYSTEM.*1/s!^.*!//&!' $$(PYTHON_DIR-$1)/Modules/posixmodule.c
	cd $$(PYTHON_DIR-$1) && make install

# Dump vars (for test)
vars-$1:
	@echo "ARCH-$1: $$(ARCH-$1)"
	@echo "SDK-$1: $$(SDK-$1)"
	@echo "SDK_ROOT-$1: $$(SDK_ROOT-$1)"
	@echo "CC-$1: $$(CC-$1)"
	@echo "TARGET_XZ_PREFIX-$1:$$(TARGET_XZ_PREFIX-$1)"
	
endef

$(foreach target,$(TARGETS),$(eval $(call build-target,$(target))))

xz.xcframework:$(foreach target,$(TARGETS),$(PROJECT_DIR)/$(target)/xz/lib/liblzma.a)
	rm -rf $(PROJECT_DIR)/xcframework/$@
	xcodebuild -create-xcframework -output $(PROJECT_DIR)/xcframework/$@ $(foreach i, $^, -library $i -headers $(dir $i)../include)

bzip2.xcframework:$(foreach target,$(TARGETS),$(PROJECT_DIR)/$(target)/bzip2/lib/libbz2.a)
	-if [ ! -d "$(PROJECT_DIR)/xcframework" ]; then mkdir -p $(PROJECT_DIR)/xcframework fi
	rm -rf $(PROJECT_DIR)/xcframework/$@
	xcodebuild -create-xcframework -output $(PROJECT_DIR)/xcframework/$@ $(foreach i, $^, -library $i -headers $(dir $i)../include)


ffi.xcframework:$(foreach target,$(TARGETS),$(PROJECT_DIR)/$(target)/ffi/lib/libffi.a)
	rm -rf $(PROJECT_DIR)/xcframework/$@
	xcodebuild -create-xcframework -output $(PROJECT_DIR)/xcframework/$@ $(foreach i, $^, -library $i -headers $(dir $i)../include)

OpenSSL.xcframework:$(foreach target,$(TARGETS),$(PROJECT_DIR)/$(target)/OpenSSL/lib/libOpenSSL.a)
	-if [ ! -d "$(PROJECT_DIR)/xcframework" ]; then mkdir -p $(PROJECT_DIR)/xcframework fi
	rm -rf $(PROJECT_DIR)/xcframework/$@
	xcodebuild -create-xcframework -output $(PROJECT_DIR)/xcframework/$@ $(foreach i, $^, -library $i -headers $(dir $i)../include)

Python.xcframework:$(foreach target,$(TARGETS),$(PROJECT_DIR)/$(target)/Python/lib/libPython$(PYTHON_VER).a)
	-if [ ! -d "$(PROJECT_DIR)/xcframework" ]; then mkdir -p $(PROJECT_DIR)/xcframework fi
	rm -rf $(PROJECT_DIR)/xcframework/$@
	xcodebuild -create-xcframework -output $(PROJECT_DIR)/xcframework/$@ $(foreach i, $^, -library $i -headers $(dir $i)../include)

# xcfamework:$(PROJECT_DIR)/xcframework/xz.xcfamework $(PROJECT_DIR)/xcframework/bzip2.xcframework $(PROJECT_DIR)/xcframework/ffi.xcframework: $(PROJECT_DIR)/xcframework/OpenSSL.xcfamework $(PROJECT_DIR)/xcframework/Python.xcfamework

xcframework:xz.xcframework bzip2.xcframework ffi.xcframework OpenSSL.xcframework Python.xcframework

all:xcframework