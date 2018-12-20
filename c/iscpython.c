/*
 ============================================================================
 Name        : helloworld.c
 Author      : 
 Version     :
 Copyright   : Your copyright notice
 Description : Hello World in C, Ansi-style
 ============================================================================
 */

#define ZF_DLL  /* Required only for dynamically linked libraries. */

#include <cdzf.h>
#include <Python.h>

#undef ERROR
/*
 *
 #include <stdio.h>
 #include <stdlib.h>
 */


// Reference to scope in which top-level code executes.
PyObject *mainModule;

// Initializes Python environment
// and obtains reference to the main module, to be used by
int Initialize() {
	Py_Initialize();
	mainModule = PyImport_AddModule("__main__");
	return ZF_SUCCESS;
}

int Finalize() {
	Py_DECREF(mainModule);
	Py_Finalize();
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

// Assumes initialized environment
int SimpleString(char *command, char *resultVar, char* result) {
	PyRun_SimpleString(command);

	int exists = PyObject_HasAttrString(mainModule, resultVar);

	if (exists == 1) {
		PyObject *var = PyObject_GetAttrString(mainModule, resultVar);

		//PyObject* varStr = PyObject_Repr(var);
		PyObject* varStr = PyObject_Str(var);
		char* str  = PyUnicode_AsUTF8(varStr);

		sprintf(result, "%s", str);

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
	SimpleString("x=2", "y", result);
	Finalize();

	printf(result);
	return EXIT_SUCCESS;
}

ZFBEGIN
ZFENTRY("Initialize","",Initialize)
ZFENTRY("Finalize","",Finalize)
ZFENTRY("GetRandom","D",GetRandom)
ZFENTRY("GetRandomSimple","D",GetRandomSimple)
ZFENTRY("SimpleStringFull","cD",SimpleStringFull)
ZFENTRY("SimpleString","ccC",SimpleString)
ZFEND
