/*
 ============================================================================
 Name        : iscpython.c
 Author      : Eduard
 Version     :
 Copyright   : MIT
 Description : Python callout library for InterSystems Platforms
 ============================================================================
 */

#define USE_CALLIN_CHAR

#define ZF_DLL  /* Required only for dynamically linked libraries. */

#include <cdzf.h>
#include <Python.h>
#include <stdbool.h>

#ifdef __linux__
	#include <dlfcn.h>
#endif

#undef ERROR
/*
 *
 #include <stdio.h>
 #include <stdlib.h>
 */


// Reference to scope in which top-level code executes.
PyObject *mainModule;

// Current state of Python Environment.
// Should be managed by C code automatically.
// Relevant for SimpleString method
bool isInitialized = false;

// Pointer to incoming code to execute
char* inStream = NULL;

// Current position in incoming code to execute
int curpos = 0;

// Size of inStream pointer
int maxpos = 0;

// Haldle for a library if we want to load it explicitly
void *libHandle = NULL;

// Initializes Python environment
// and obtains reference to the main module.
// Due to the problems with lib-dynload, sometimes library file should be loaded explicitly
// https://bugs.python.org/issue4434
// Do not use it, unless you get errors like: undefined symbol: _Py_TrueStruct and so on)
int Initialize(char *file) {
	if (isInitialized == false) {
		if ((file) && (!libHandle)) {
			#ifdef __linux__
				//linux code goes here
				//http://tldp.org/HOWTO/Program-Library-HOWTO/dl-libraries.html
				libHandle = dlopen(file, RTLD_LAZY |RTLD_GLOBAL);
			#endif
		}
		Py_Initialize();
		mainModule = PyImport_AddModule("__main__");
		isInitialized = true;
	}
	return ZF_SUCCESS;
}

int Finalize() {
	if (isInitialized) {
		isInitialized = false;
		Py_DECREF(mainModule);
		Py_Finalize();
	}

	if (libHandle) {
		#ifdef __linux__
			dlclose(libHandle);
		#endif
		libHandle = NULL;
	}

	return ZF_SUCCESS;
}

// Execute simple command.
// Initializes environment if required
// Does not finalize the environment.
int SimpleString(CACHE_EXSTRP command, char *resultVar, int serialization, CACHE_EXSTRP result) {

	if (isInitialized == false) {
		Initialize(NULL);
	}

	// Copy command text to a new pointer and add null at the end
	char* commandChar = malloc(1 + sizeof(char)*command->len);
	memcpy(commandChar, command->str.ch,  command->len);
	memcpy(commandChar + command->len, "\0", 1);

	PyRun_SimpleString(commandChar);

	CACHEEXSTRKILL(command);
	free(commandChar);

	int exists = PyObject_HasAttrString(mainModule, resultVar);

	if (exists == 1) {
		PyObject *var = PyObject_GetAttrString(mainModule, resultVar);
		PyObject* varStr;

		if (serialization==0) {
			varStr = PyObject_Str(var);
		} else {
			varStr = PyObject_Repr(var);
		}

		char* str = PyUnicode_AsUTF8(varStr);

		int len = strlen(str);
		CACHEEXSTRKILL(result);
		if (!CACHEEXSTRNEW(result,len)) {
			return ZF_FAILURE;
		}
		memcpy(result->str.ch, str, len);   // copy to retval->str.ch

		Py_DECREF(varStr);
		Py_DECREF(var);
	}

	return ZF_SUCCESS;
}

// Init incoming stream (inStream) to length bytes + 1
int StreamInit(int length)
{
	// Free previous stream, if any.
	if (inStream) {
		free(inStream);
		inStream = NULL;
	}

	// Allocate stream
	inStream = calloc(length + 1, sizeof(char));
	curpos = 0;
	maxpos = length;

	// Return failure if allocation failed
	if (!inStream) {
		return ZF_FAILURE;
	}

	return ZF_SUCCESS;
}

// Write piece of inStream
int StreamWrite(CACHE_EXSTRP command)
{
	// Stream should be initiate first
	if (!inStream) {
		return ZF_FAILURE;
	}

	// We want to write more bytes, then available.
	// Need to extend the pointer first
	if ((int)command->len + curpos > maxpos) {
		maxpos = (int)command->len + curpos + 1;
		char *inStreamTemp = realloc(inStream, maxpos);

		if (inStreamTemp) {
			inStream = inStreamTemp;
			memset(inStream + curpos, '0', maxpos - curpos);
		} else {
			// Reallocation failed
			return ZF_FAILURE;
		}
	}

	memcpy(inStream + curpos, command->str.ch,  command->len);
	curpos += command->len;
	return ZF_SUCCESS;
}

// Send inStream to Python and free it
int StreamExecute()
{
	if (isInitialized == false) {
		Initialize(NULL);
	}

	if (!inStream) {
		return ZF_FAILURE;
	}

	memcpy(inStream + curpos, "\0", 1);

	PyRun_SimpleString(inStream);
	free(inStream);
	inStream = NULL;
	curpos = 0;

	return ZF_SUCCESS;
}

/// Escape string
int EscapeString(CACHE_EXSTRP string,  CACHE_EXSTRP result)
{
	if (isInitialized == false) {
		Initialize(NULL);
	}

	PyObject *var = PyUnicode_FromStringAndSize(string->str.ch, string->len);
	PyObject *varStr = PyObject_Repr(var);
	char* str = PyUnicode_AsUTF8(varStr);

	int len = strlen(str);
	CACHEEXSTRKILL(result);
	if (!CACHEEXSTRNEW(result,len)) {
		return ZF_FAILURE;
	}
	memcpy(result->str.ch, str, len);   // copy to retval->str.ch

	Py_DECREF(var);
	Py_DECREF(varStr);
	CACHEEXSTRKILL(string);

	return ZF_SUCCESS;

}

// Code for testing and debugging as an executable
int main(int argc, char **argv) {
	printf("X: ");

	//double random = 0;
	//GetRandom(&random);
	//GetRandomSimple(&random);
	//printf("%lf", random);

	char* result = malloc(sizeof(char) * 1024);

	Initialize(NULL);
	//SimpleString("x=2", "x", result);
	Finalize();

	printf("%s", result);
	return EXIT_SUCCESS;
}

ZFBEGIN
	ZFENTRY("Initialize","c",Initialize)
	ZFENTRY("Finalize","",Finalize)
	ZFENTRY("SimpleString","jciJ",SimpleString)
	ZFENTRY("StreamInit","i",StreamInit)
	ZFENTRY("StreamWrite","j",StreamWrite)
	ZFENTRY("StreamExecute","",StreamExecute)
	ZFENTRY("EscapeString","jJ",EscapeString)
ZFEND
