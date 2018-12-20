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
	LDFLAGS := -shared
	LIBS += -ldl
else ifneq (, $(findstring mingw, $(SYS)))
	SUFFIX := dll
	LDFLAGS := -shared
else 
	$(error Unsupported build platform)
endif




ifndef GLOBALS_HOME
    $(error Couldn't find GLOBALS_HOME)
endif

ifndef PYTHONHOME
    $(error Couldn't find PYTHONHOME)
endif

PYTHONVER := $(shell ${PYTHONHOME}python -c "import sys; print(sys.version_info[0],sys.version_info[1],sep='')")
LIBS  = -lpython${PYTHONVER}

LDFLAGS += -L${PYTHONHOME}/Libs

INCLUDES += -I${GLOBALS_HOME}/dev/cpp/include
INCLUDES += -I${PYTHONHOME}/include
CFLAGS += $(INCLUDES)

.PHONY: all clean

all: iscpython.$(SUFFIX)

iscpython.o: iscpython.c

iscpython.$(SUFFIX): iscpython.o
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

clean:
	$(RM) *.$(SUFFIX) *.o