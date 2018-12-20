CC := gcc
RM := rm
CD := cd
MAKE := make

CFLAGS += -Wall -Wextra -fpic -O2 -fno-strict-aliasing -Wno-unused-parameter

SYS := $(shell gcc -dumpmachine)

ifeq ($(SYS), x86_64-w64-mingw32)
	BUILDSYS := $(SYS)
else
	BUILDSYS := $(shell bash $(LIBFFI_PATH)/config.guess)
endif

ifneq (, $(findstring linux, $(SYS)))
	SUFFIX := so
	
	ifndef PYTHONVER
         $(error Couldn't find PYTHONVER)
	endif
	
	INCLUDES += $(shell python${PYTHONVER}-config --includes)
	LDFLAGS := -shared $(shell python${PYTHONVER}-config --ldflags) 
	LIBS += $(shell python${PYTHONVER}-config --libs)
else ifneq (, $(findstring mingw, $(SYS)))
	SUFFIX := dll
	
	ifndef PYTHONHOME
         $(error Couldn't find PYTHONHOME)
	endif
	
	PYTHONVER := $(shell ${PYTHONHOME}python -c "import sys; print(str(sys.version_info[0])+str(sys.version_info[1]))")
	
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