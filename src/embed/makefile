# Julia libs
JL_SHARE =  $(shell julia -e 'print(DEPOT_PATH[end])')
# JULIA_HOME = $(shell julia -e 'print(JULIA_HOME)')
JULIA_LIB = $(shell julia -e 'print(abspath(Base.Libc.Libdl.dlpath("libjulia")))')
# JULIA_DEBUG_LIB = \
  $(shell $(JULIA_HOME)/julia-debug -e 'print(abspath(Base.Libc.Libdl.dlpath("libjulia-debug")))')
JULIA_DEBUG_LIB = $(JULIA_LIB)
CFLAGS   += -DKXVER=3 -O3 -g
CFLAGS   += $(shell $(JL_SHARE)/julia-config.jl --cflags)
CXXFLAGS += $(shell $(JL_SHARE)/julia-config.jl --cflags)
LDFLAGS  += $(shell $(JL_SHARE)/julia-config.jl --ldflags)
LDLIBS   += $(shell $(JL_SHARE)/julia-config.jl --ldlibs)
SOFLAGS_Linux = -shared -fPIC
SOFLAGS_Darwin = -bundle -undefined dynamic_lookup
SOFLAGS_Darwin += -Wl,-rpath $(shell dirname $(JULIA_LIB)) -ljulia
SOFLAGS  += $(SOFLAGS_$(shell uname))

LDLIBS   +=  -l$(QHOME)/../c/m64/c.o
# LDLIBS += "-l/Users/philippecasgrain/bin/kdb/c/c.dylib"

CC := gcc

all: J.c

main: J.c makefile
	$(CC) $(CFLAGS) $(LDFLAGS) $(LDLIBS) $(SOFLAGS) J.c -o J.so

install: J.c
	cp J.q $(QHOME)/J.q
	cp J.so $(QHOME)/$(QARCH)/$(QARCH)
clean:
	$(RM) 
