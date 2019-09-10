CC := gcc
RM := rm
CD := cd
MAKE := make
LDFLAGS := -shared

CFLAGS += -Wall -Wextra -fpic -O3 -fno-strict-aliasing -Wno-incompatible-pointer-types

SYS := $(shell gcc -dumpmachine)

ifneq (, $(findstring linux, $(SYS)))
	SUFFIX := so
	
	ifndef PYTHONVER
         $(error Couldn't find PYTHONVER)
	endif
	
	INCLUDES += $(shell python${PYTHONVER}-config --includes)
	LDFLAGS += $(shell python${PYTHONVER}-config --ldflags) 
	LIBS += $(shell python${PYTHONVER}-config --libs)
else ifneq (, $(findstring mingw, $(SYS)))
	SUFFIX := dll
	
	ifndef PYTHONHOME
         $(error Couldn't find PYTHONHOME)
	endif
	
	PYTHONVER := $(shell ${PYTHONHOME}/python -c "import sys; print(str(sys.version_info[0])+str(sys.version_info[1]))")
	
	INCLUDES += -I${PYTHONHOME}/include
	LDFLAGS += -L${PYTHONHOME}/Libs
	LIBS  = -lpython${PYTHONVER}
else 
	$(error Unsupported build platform)
endif

ifndef GLOBALS_HOME
     $(error Couldn't find GLOBALS_HOME)
endif

INCLUDES += -I${GLOBALS_HOME}/dev/cpp/include
CFLAGS += $(INCLUDES)

.PHONY: all clean

all: iscpython.$(SUFFIX)

iscpython.o: iscpython.c

iscpython.$(SUFFIX): iscpython.o
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

clean:
	$(RM) *.$(SUFFIX) *.o