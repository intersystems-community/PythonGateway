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

// Initializes Python environment
// and obtains reference to the main module, to be used by
int Initialize() {
	if (isInitialized == false) {
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
	return ZF_SUCCESS;
}


// Test method, returns random double
int GetRandom(double* random) {

	Py_Initialize();
	// https://stackoverflow.com/questions/3286448/calling-a-python-method-from-c-c-and-extracting-its-return-value
	// First, import your module :
	PyObject* myModuleString = PyUnicode_FromString((char*) "random");
	PyObject* myModule = PyImport_Import(myModuleString);

	// Then getting a reference to your function :
	PyObject* myFunction = PyObject_GetAttrString(myModule, (char*) "random");
	//PyObject* args = PyTuple_Pack(1,PyFloat_FromDouble(2.0));
	PyObject* args = PyTuple_Pack(0);

	//Then getting your result :
	PyObject* myResult = PyObject_CallObject(myFunction, args);

	//And getting back to a double :
	double result = PyFloat_AsDouble(myResult);

	//Py_Main(argc, argv);
	Py_Finalize();
	*random = result;
	// set value to be returned by the $ZF function call
	return ZF_SUCCESS;   // set the exit status code
}

// Test method, returns random double
int GetRandomSimple(double* random) {

	Py_Initialize();
	PyRun_SimpleString("import random;");
	PyRun_SimpleString("x=random.random();");

	PyObject *mainModule = PyImport_AddModule("__main__");
	PyObject *var = PyObject_GetAttrString(mainModule, "x");

	*random = PyFloat_AsDouble(var);
	Py_Finalize();

	return ZF_SUCCESS;
}

// Does complete initialization, executes code and finalizes environment
int SimpleStringFull(char *command, double* result) {

	Py_Initialize();
	PyRun_SimpleString(command);

	PyObject *mainModule = PyImport_AddModule("__main__");
	PyObject *var = PyObject_GetAttrString(mainModule, "x");

	*result = PyFloat_AsDouble(var);
	Py_Finalize();

	return ZF_SUCCESS;
}

// Execute simple command.
// Initializes environment if required
// Does not finalize the environment.
int SimpleString(CACHE_EXSTRP command, char *resultVar, int serialization, CACHE_EXSTRP result) {

	if (isInitialized == false) {
		Initialize();
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

// Code for testing and debugging as an executable
int main(int argc, char **argv) {
	printf("X: ");

	//double random = 0;
	//GetRandom(&random);
	//GetRandomSimple(&random);
	//printf("%lf", random);

	char* result = malloc(sizeof(char) * 1024);

	Initialize();
	//SimpleString("x=2", "x", result);
	Finalize();

	printf("%s", result);
	return EXIT_SUCCESS;
}

ZFBEGIN
	ZFENTRY("Initialize","",Initialize)
	ZFENTRY("Finalize","",Finalize)
	ZFENTRY("GetRandom","D",GetRandom)
	ZFENTRY("GetRandomSimple","D",GetRandomSimple)
	ZFENTRY("SimpleStringFull","cD",SimpleStringFull)
	ZFENTRY("SimpleString","jciJ",SimpleString)
ZFEND
