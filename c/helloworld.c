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

int Initialize() {
	Py_Initialize();
	return ZF_SUCCESS;
}

int Finalize() {
	Py_Finalize();
	return ZF_SUCCESS;
}

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

int GetRandomSimple(double* random) {

	Py_Initialize();
	PyRun_SimpleString("import random;");
	PyRun_SimpleString("x=random.random();");

	PyObject *mainModule = PyImport_AddModule("__main__");
	PyObject *var = PyObject_GetAttrString(mainModule, "x");

	*random = PyFloat_AsDouble(var);
	Py_Finalize();

	// set value to be returned by the $ZF function call
	return ZF_SUCCESS;   // set the exit status code
}

int SimpleString(char *command, double* result) {

	Py_Initialize();
	PyRun_SimpleString(command);

	PyObject *mainModule = PyImport_AddModule("__main__");
	PyObject *var = PyObject_GetAttrString(mainModule, "x");

	*result = PyFloat_AsDouble(var);
	Py_Finalize();

	// set value to be returned by the $ZF function call
	return ZF_SUCCESS;   // set the exit status code
}

int SimpleStringN(char *command, char *resultVar, char* result) {
	PyRun_SimpleString(command);

	PyObject *mainModule = PyImport_AddModule("__main__");

	//char varName = *resultVar;

	PyObject *var = PyObject_GetAttrString(mainModule, resultVar);
	//*result = PyFloat_AsDouble(var);

	//PyObject* objectsRepresentation = PyObject_Repr(var);
	PyObject* objectsRepresentation = PyObject_Str(var);
	char* s = PyUnicode_AsUTF8(objectsRepresentation);

	sprintf(result,"%s",s);

	//strcpy (result, s);
	//result = s;
	// TODO
	// https://stackoverflow.com/questions/5356773/python-get-string-representation-of-pyobject


	// set value to be returned by the $ZF function call
	return ZF_SUCCESS;   // set the exit status code
}

int main(int argc, char **argv) {
	printf("X: ");
	//exec_interactive_interpreter(argc, argv);
	//double random = 0;
	//GetRandom(&random);
	//GetRandomSimple(&random);
	// printf("%lf", random);
	char* result = malloc(sizeof(char) * 1024);


	Initialize();
	SimpleStringN("x=2", "x", result);
	Finalize();

	printf(result);
	return 0;
}

ZFBEGIN
ZFENTRY("Initialize","",Initialize)
ZFENTRY("Finalize","",Finalize)
ZFENTRY("GetRandom","D",GetRandom)
ZFENTRY("SimpleString","cD",SimpleString)
ZFENTRY("SimpleStringN","ccC",SimpleStringN)
ZFEND
