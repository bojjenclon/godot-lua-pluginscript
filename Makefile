DEBUG ?= 0
GODOT_BIN ?= godot
LUA_BIN ?= lua
LIPO ?= lipo
STRIP ?= strip
LUAJIT_52_COMPAT ?= 1
NDK_TOOLCHAIN_BIN ?=

CFLAGS += -std=c11 "-I$(CURDIR)/lib/godot-headers" "-I$(CURDIR)/lib/high-level-gdnative" "-I$(CURDIR)/lib/luajit/src"
ifeq ($(DEBUG), 1)
	CFLAGS += -g -O0 -DDEBUG
else
	CFLAGS += -O3 -DNDEBUG
endif

ifeq ($(LUAJIT_52_COMPAT), 1)
	MAKE_LUAJIT_ARGS += XCFLAGS=-DLUAJIT_ENABLE_LUA52COMPAT
endif

_CC = $(CROSS)$(CC)
_LIPO = $(CROSS)$(LIPO)
_STRIP = $(CROSS)$(STRIP)

SRC = language_gdnative.c language_in_editor_callbacks.c
OBJS = $(SRC:.c=.o) init_script.o
BUILT_OBJS = $(addprefix build/%/,$(OBJS))
MAKE_LUAJIT_OUTPUT = build/%/luajit/src/luajit.o build/%/luajit/src/lua51.dll build/%/luajit/src/libluajit.a

GDNLIB_ENTRY_PREFIX = addons/godot-lua-pluginscript
BUILD_FOLDERS = build build/native build/windows_x86 build/windows_x86_64 build/linux_x86 build/linux_x86_64 build/osx_x86_64 build/osx_arm64 build/osx_universal64 build/android_armv7a build/android_aarch64 build/android_x86 build/android_x86_64 build/$(GDNLIB_ENTRY_PREFIX)

LUASRCDIET_SRC = $(wildcard lib/luasrcdiet/luasrcdiet/*.lua) lib/luasrcdiet/COPYRIGHT lib/luasrcdiet/COPYRIGHT_Lua51
LUASRCDIET_DEST = $(addprefix plugin/luasrcdiet/,$(notdir $(LUASRCDIET_SRC)))
LUASRCDIET_FLAGS = --maximum --quiet --noopt-binequiv

DIST_SRC = LICENSE
DIST_ADDONS_SRC = LICENSE lps_coroutine.lua lua_pluginscript.gdnlib build/.gdignore $(wildcard build/jit/*.lua build/*/*lua*.* plugin/*.* plugin/in_editor_callbacks/* plugin/*/.gdignore) $(LUASRCDIET_DEST)
DIST_ZIP_SRC = $(DIST_SRC) $(addprefix $(GDNLIB_ENTRY_PREFIX)/,$(DIST_ADDONS_SRC))
DIST_DEST = $(addprefix build/,$(DIST_SRC)) $(addprefix build/$(GDNLIB_ENTRY_PREFIX)/,$(DIST_ADDONS_SRC))

# Note that the order is important!
LUA_INIT_SCRIPT_SRC = \
	src/godot_ffi.lua \
	src/cache_lua_libs.lua \
	src/lua_globals.lua \
	src/lua_string_extras.lua \
	src/godot_enums.lua \
	src/godot_class.lua \
	src/godot_variant.lua \
	src/godot_string.lua \
	src/godot_string_name.lua \
	src/godot_vector2.lua \
	src/godot_vector3.lua \
	src/godot_color.lua \
	src/godot_rect2.lua \
	src/godot_plane.lua \
	src/godot_quat.lua \
	src/godot_basis.lua \
	src/godot_aabb.lua \
	src/godot_transform2d.lua \
	src/godot_transform.lua \
	src/godot_object.lua \
	src/godot_rid.lua \
	src/godot_node_path.lua \
	src/godot_dictionary.lua \
	src/godot_array.lua \
	src/godot_pool_byte_array.lua \
	src/godot_pool_int_array.lua \
	src/godot_pool_real_array.lua \
	src/godot_pool_string_array.lua \
	src/godot_pool_vector2_array.lua \
	src/godot_pool_vector3_array.lua \
	src/godot_pool_color_array.lua \
	src/pluginscript_class_metadata.lua \
	src/pluginscript_callbacks.lua \
	src/late_globals.lua \
	src/lua_package_extras.lua \
	src/lua_math_extras.lua \
	src/register_in_editor_callbacks.lua

ifneq (1,$(DEBUG))
	EMBED_SCRIPT_SED := src/tools/compact_c_ffi.sed
	LUA_INIT_SCRIPT_TO_USE = build/init_script-diet.lua
	STRIP_CMD = $(_STRIP) $1
else
	LUA_INIT_SCRIPT_TO_USE = build/init_script.lua
	STRIP_CMD =
endif
EMBED_SCRIPT_SED += src/tools/embed_to_c.sed src/tools/add_script_c_decl.sed

# Avoid removing intermediate files created by chained implicit rules
.PRECIOUS: build/%/luajit build/%/init_script.c $(BUILT_OBJS) build/%/lua51.dll $(MAKE_LUAJIT_OUTPUT)

$(BUILD_FOLDERS):
	mkdir -p $@

build/%/language_gdnative.o: src/language_gdnative.c
	$(_CC) -o $@ $< -c $(CFLAGS)
build/%/language_in_editor_callbacks.o: src/language_in_editor_callbacks.c
	$(_CC) -o $@ $< -c $(CFLAGS)

$(MAKE_LUAJIT_OUTPUT): | build/%/luajit build/jit
	$(MAKE) -C $(firstword $|) $(and $(TARGET_SYS),TARGET_SYS=$(TARGET_SYS)) $(MAKE_LUAJIT_ARGS)
	@mkdir -p build/jit
	cp $(firstword $|)/src/jit/vmdef.lua build/jit
build/%/lua51.dll: build/%/luajit/src/lua51.dll
	cp $< $@
build/%/luajit: | build/%
	cp -r lib/luajit $@
build/jit: | build
	cp -r lib/luajit/src/jit/ $@

build/init_script.lua: $(LUA_INIT_SCRIPT_SRC) | build
	cat $^ > $@
build/init_script-diet.lua: build/init_script.lua
	env LUA_PATH=';;lib/luasrcdiet/?.lua;lib/luasrcdiet/?/init.lua' $(LUA_BIN) lib/luasrcdiet/bin/luasrcdiet $< -o $@ $(LUASRCDIET_FLAGS)
build/%/init_script.c: $(LUA_INIT_SCRIPT_TO_USE) $(EMBED_SCRIPT_SED) | build/%
	sed -E $(addprefix -f ,$(EMBED_SCRIPT_SED)) $< > $@

build/%/init_script.o: build/%/init_script.c
	$(_CC) -o $@ $< -c $(CFLAGS)

build/%/liblua_pluginscript.so: TARGET_SYS = Linux
build/%/liblua_pluginscript.so: $(BUILT_OBJS) build/%/luajit/src/libluajit.a
	$(_CC) -o $@ $^ -shared $(CFLAGS) -lm -ldl $(LDFLAGS)
	$(call STRIP_CMD,$@)

build/%/lua_pluginscript.dll: TARGET_SYS = Windows
build/%/lua_pluginscript.dll: EXE = .exe
build/%/lua_pluginscript.dll: $(BUILT_OBJS) build/%/lua51.dll
	$(_CC) -o $@ $^ -shared $(CFLAGS) $(LDFLAGS)
	$(call STRIP_CMD,$@)

build/%/lua_pluginscript.dylib: TARGET_SYS = Darwin
build/%/lua_pluginscript.dylib: $(BUILT_OBJS) build/%/luajit/src/libluajit.a
	$(_CC) -o $@ $^ -shared $(CFLAGS) $(LDFLAGS)
	$(call STRIP_CMD,-x $@)
build/osx_x86_64/lua_pluginscript.dylib: MACOSX_DEPLOYMENT_TARGET ?= 10.7
build/osx_x86_64/lua_pluginscript.dylib: CFLAGS += -arch x86_64
build/osx_x86_64/lua_pluginscript.dylib: MAKE_LUAJIT_ARGS += TARGET_FLAGS="-arch x86_64" MACOSX_DEPLOYMENT_TARGET="$(MACOSX_DEPLOYMENT_TARGET)"
build/osx_arm64/lua_pluginscript.dylib: MACOSX_DEPLOYMENT_TARGET ?= 11.0
build/osx_arm64/lua_pluginscript.dylib: CFLAGS += -arch arm64
build/osx_arm64/lua_pluginscript.dylib: MAKE_LUAJIT_ARGS += TARGET_FLAGS="-arch arm64" MACOSX_DEPLOYMENT_TARGET="$(MACOSX_DEPLOYMENT_TARGET)"
build/osx_universal64/lua_pluginscript.dylib: build/osx_x86_64/lua_pluginscript.dylib build/osx_arm64/lua_pluginscript.dylib | build/osx_universal64
	$(_LIPO) $^ -create -output $@

plugin/luasrcdiet/%.lua: lib/luasrcdiet/luasrcdiet/%.lua | plugin/luasrcdiet
	cp $< $@
plugin/luasrcdiet/%: lib/luasrcdiet/% | plugin/luasrcdiet
	cp $< $@

build/$(GDNLIB_ENTRY_PREFIX)/%: %
	@mkdir -p $(dir $@)
	cp $< $@
$(addprefix build/,$(DIST_SRC)): | build
	cp $(notdir $@) $@
build/lua_pluginscript.zip: $(DIST_DEST)
	cd build && zip lua_pluginscript $(DIST_ZIP_SRC)
build/project.godot: src/tools/project.godot | build
	cp $< $@

# Phony targets
.PHONY: clean dist docs test plugin
clean:
	$(RM) -r build/*/ plugin/luasrcdiet/*

dist: build/lua_pluginscript.zip

docs:
	ldoc .

test: $(DIST_DEST) build/project.godot
	$(GODOT_BIN) --path build --no-window --quit --script "$(CURDIR)/src/test/init.lua"

plugin: $(LUASRCDIET_DEST)

native-luajit: MACOSX_DEPLOYMENT_TARGET ?= 11.0
native-luajit: MAKE_LUAJIT_ARGS = MACOSX_DEPLOYMENT_TARGET=$(MACOSX_DEPLOYMENT_TARGET)
native-luajit: build/native/luajit/src/luajit.o

# Targets by OS + arch
linux32: MAKE_LUAJIT_ARGS += CC="$(CC) -m32 -fPIC"
linux32: CFLAGS += -m32 -fPIC
linux32: build/linux_x86/liblua_pluginscript.so

linux64: MAKE_LUAJIT_ARGS += CC="$(CC) -fPIC"
linux64: CFLAGS += -fPIC
linux64: build/linux_x86_64/liblua_pluginscript.so

windows32: build/windows_x86/lua_pluginscript.dll
mingw-windows32: CROSS = i686-w64-mingw32-
mingw-windows32: MAKE_LUAJIT_ARGS += HOST_CC="$(CC) -m32" CROSS="$(CROSS)" LDFLAGS=-static-libgcc
mingw-windows32: windows32

windows64: build/windows_x86_64/lua_pluginscript.dll
mingw-windows64: CROSS = x86_64-w64-mingw32-
mingw-windows64: MAKE_LUAJIT_ARGS += HOST_CC="$(CC)" CROSS="$(CROSS)" LDFLAGS=-static-libgcc
mingw-windows64: windows64

osx-x86_64: build/osx_x86_64/lua_pluginscript.dylib
osx-arm64: build/osx_arm64/lua_pluginscript.dylib
osx64: build/osx_universal64/lua_pluginscript.dylib

android-armv7a: NDK_TARGET_API ?= 16
android-armv7a: _CC = "$(NDK_TOOLCHAIN_BIN)/armv7a-linux-androideabi$(NDK_TARGET_API)-clang" -fPIC
android-armv7a: CROSS = "$(NDK_TOOLCHAIN_BIN)/arm-linux-androideabi-"
android-armv7a: MAKE_LUAJIT_ARGS += HOST_CC="$(CC) -m32 -fPIC" CROSS="$(CROSS)" STATIC_CC="$(_CC)" DYNAMIC_CC="$(_CC)" TARGET_LD="$(_CC)"
android-armv7a: build/android_armv7a/liblua_pluginscript.so

android-aarch64: NDK_TARGET_API ?= 21
android-aarch64: _CC = "$(NDK_TOOLCHAIN_BIN)/aarch64-linux-android$(NDK_TARGET_API)-clang" -fPIC
android-aarch64: CROSS = "$(NDK_TOOLCHAIN_BIN)/aarch64-linux-android-"
android-aarch64: MAKE_LUAJIT_ARGS += HOST_CC="$(CC) -fPIC" CROSS="$(CROSS)" STATIC_CC="$(_CC)" DYNAMIC_CC="$(_CC)" TARGET_LD="$(_CC)"
android-aarch64: build/android_aarch64/liblua_pluginscript.so

android-x86: NDK_TARGET_API ?= 16
android-x86: _CC = "$(NDK_TOOLCHAIN_BIN)/i686-linux-android$(NDK_TARGET_API)-clang" -fPIC
android-x86: CROSS = "$(NDK_TOOLCHAIN_BIN)/i686-linux-android-"
android-x86: MAKE_LUAJIT_ARGS += HOST_CC="$(CC) -m32 -fPIC" CROSS="$(CROSS)" STATIC_CC="$(_CC)" DYNAMIC_CC="$(_CC)" TARGET_LD="$(_CC)"
android-x86: build/android_x86/liblua_pluginscript.so

android-x86_64: NDK_TARGET_API ?= 21
android-x86_64: _CC = "$(NDK_TOOLCHAIN_BIN)/x86_64-linux-android$(NDK_TARGET_API)-clang" -fPIC
android-x86_64: CROSS = "$(NDK_TOOLCHAIN_BIN)/x86_64-linux-android-"
android-x86_64: MAKE_LUAJIT_ARGS += HOST_CC="$(CC) -fPIC" CROSS="$(CROSS)" STATIC_CC="$(_CC)" DYNAMIC_CC="$(_CC)" TARGET_LD="$(_CC)"
android-x86_64: build/android_x86_64/liblua_pluginscript.so

