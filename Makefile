OS := $(shell uname)

CPPFLAGS = -I./brotli/c/include/ -I./src -I./include

AR = emar
CC = emcc
CXX = em++

# It's helpful to be able to turn these off for fuzzing
CANONICAL_PREFIXES ?= -no-canonical-prefixes
NOISY_LOGGING ?= -DFONT_COMPRESSION_BIN

COMMON_FLAGS += -fno-omit-frame-pointer
COMMON_FLAGS += $(CANONICAL_PREFIXES)
COMMON_FLAGS += $(NOISY_LOGGING)
COMMON_FLAGS += -DNDEBUG
COMMON_FLAGS += -O2
COMMON_FLAGS += -s NO_DYNAMIC_EXECUTION=1
COMMON_FLAGS += -s NO_FILESYSTEM=1

CPPFLAGS += -std=c++11
CPPFLAGS += -fno-exceptions
CPPFLAGS += -fno-rtti
CPPFLAGS += -s DISABLE_EXCEPTION_CATCHING=1
CPPFLAGS += $(COMMON_FLAGS)

CFLAGS += $(COMMON_FLAGS)

LDFLAGS += $(COMMON_FLAGS)
LDFLAGS += -s NO_EXIT_RUNTIME=1
LDFLAGS += --memory-init-file 0
LDFLAGS += -s ERROR_ON_UNDEFINED_SYMBOLS=1
LDFLAGS += -s EXPORTED_FUNCTIONS='["_output_bytes", "_output_length", "_woff2_to_TTF"]'
LDFLAGS += -s EXPORT_NAME='"EmscriptenModule"'
LDFLAGS += -s MODULARIZE=1
LDFLAGS += --llvm-lto 2

ARFLAGS = cr

SRCDIR = src

OUROBJ = font.o glyph.o normalize.o table_tags.o transform.o \
         woff2_dec.o woff2_enc.o woff2_common.o woff2_out.o \
         variable_length.o

BROTLI = brotli
BROTLIOBJ = $(BROTLI)/bin/obj/c
DECOBJ = $(BROTLIOBJ)/dec/*.o
COMMONOBJ = $(BROTLIOBJ)/common/*.o

OBJS = $(patsubst %, $(SRCDIR)/%, $(OUROBJ))
EXECUTABLES=woff2_to_ttf.js
EXE_OBJS=$(patsubst %.js, $(SRCDIR)/%.o, $(EXECUTABLES))

ifeq (,$(wildcard $(BROTLI)/*))
  $(error Brotli dependency not found : you must initialize the Git submodule)
endif

$(EXECUTABLES) : $(EXE_OBJS) $(OBJS) deps
	$(CXX) $(LDFLAGS) $(OBJS) $(COMMONOBJ) $(DECOBJ) $(EXE_OBJS) -o $@

dist/index.js : $(EXECUTABLES)
	# I can't figure out how to get emscripten to generate
	# the output targeting *only* the browser, so this is my
	# sily hack to get around the output containing references
	# to require("fs") and require("path")
	sed "s/require(.*)/null/" woff2_to_ttf.js > dist/index.js
	echo >> dist/index.js
	cat index.js >> dist/index.js

deps :
	npm install
	AR=$(AR) CC=$(CC) $(MAKE) -C $(BROTLI) lib

clean :
	rm -f dist/index.js
	rm -f $(OBJS) $(EXE_OBJS) $(EXECUTABLES)
	$(MAKE) -C $(BROTLI) clean
