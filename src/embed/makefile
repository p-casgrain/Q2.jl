# CFLAGS=-ggdb3 -O2 -Wno-pointer-sign -Wno-parentheses -Wextra -Werror -Wsign-compare -Wwrite-strings
CFLAGS=-ggdb3 -O2 -Wwrite-strings 
#  -Wno-pointer-sign -Wno-incompatible-pointer-types-discards-qualifiers

UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)
MS      := $(shell getconf LONG_BIT)

ifeq ($(UNAME_S),Linux)
  OSFLAG  = l
  LDFLAGS += -fPIC -shared
  ifeq ($(UNAME_M),armv7l)
    CFLAGS  += $(filter-out -Wwrite-strings,$(CFLAGS))
  else
  ifeq ($(UNAME_M),armv6l)
    CFLAGS  += $(filter-out -Wwrite-strings,$(CFLAGS))
  endif
  endif
else ifeq ($(UNAME_S),Darwin)
  OSFLAG  = m
  LDFLAGS += -fPIC -shared -undefined dynamic_lookup #-bundle
  CC=clang
  ifeq ($(UNAME_M),arm64)
    CFLAGS += -arch arm64 -arch x86_64
  else
    CFLAGS += -arch arm64 -arch x86_64
  endif
endif

QARCH = $(OSFLAG)$(MS)
Q     = $(QHOME)/$(QARCH)


# Julia libs
JL_SHARE =  $(shell julia -e 'print(DEPOT_PATH[end])')
JULIA_LIB = $(shell julia -e 'print(abspath(Base.Libc.Libdl.dlpath("libjulia")))')
JULIA_DEBUG_LIB = $(JULIA_LIB)
CFLAGS   += -DKXVER=3 -O3 -g
CFLAGS   += $(shell $(JL_SHARE)/julia-config.jl --cflags)
CXXFLAGS += $(shell $(JL_SHARE)/julia-config.jl --cflags)
LDFLAGS  += $(shell $(JL_SHARE)/julia-config.jl --ldflags)
LDLIBS   += $(shell $(JL_SHARE)/julia-config.jl --ldlibs)

.PHONY: all
all: k.h c.o J.so

k.h:
	curl -O -J -L https://github.com/KxSystems/kdb/raw/master/c/c/k.h
  
c.o:
	curl -O -J -L https://github.com/KxSystems/kdb/raw/master/$(QARCH)/c.o
  
J.so: J.c c.o k.h
	$(CC) $(CFLAGS) $(LDFLAGS) $(LDLIBS) J.c -o J.so
  
install: J.so J.q
	cp J.q $(QHOME)/J.q
	cp J.so $(QHOME)/$(QARCH)/J.so
  
clean:
	rm -rf J.so* J.so c.o k.h



