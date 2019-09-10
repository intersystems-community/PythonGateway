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
#include <datetime.h>
#include <stdbool.h>
#include <math.h>
#include <time.h>

#ifdef __linux__
	#include <dlfcn.h>
#endif

/// Possible list types
enum ListTypes {NONE, STRING, USTRING, NONE2, INTP, INTN, DOUBLEP, DOUBLEN, FLOAT};

///const char Months[] = {31,28,31,30,31,30,31,31,30,31,30,31};



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
		PyDateTime_IMPORT;
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


/// Convert $lb positive (unsigned) integer bytes to int64_t
/// buff - pointer to $list data
/// offset - start of int data
/// offsetinint - int offset
/// len - length of int data
int64_t Makeint(const char *buff, size_t offset, size_t offsetinint, size_t len)
{
    union
    {
        int64_t i64;
        uint8_t u8[8];
    }d64;

    offsetinint = offsetinint & 7;
    memset(&d64, 0, sizeof(d64));

    memcpy(&d64.u8[offsetinint], buff + offset, len > (8 - offsetinint) ? (8 - offsetinint) : len);
    return d64.i64;
}

/// Get next power of 2, greater than v.
/// if v is a power of 2 returns v
int64_t Next2(int64_t v)
{
	v--;
	v |= v >> 1;
	v |= v >> 2;
	v |= v >> 4;
	v |= v >> 8;
	v |= v >> 16;
	v |= v >> 32;
	v++;
	return v;
}

/// Convert $lb to Python tuple
/// result - pointer to $lb data
/// mask - what fields from $lb do we need
/// maskLength - Number of significant characters in mask
/// maskSymbolLength - Number of total characters in mask
/// key - key value for $lb (would be first element in tuple)
PyTupleObject* ListToTuple(CACHE_EXSTRP result, const char* mask, int maskLength, int maskSymbolLength, int key)
{
	// $lb structure
	char* list = result->str.ch;
	int listLength = result->len;
	PyTupleObject* tuple = PyTuple_New(maskLength + 1); //length

	PyTuple_SET_ITEM(tuple, 0, PyLong_FromLong(key));

	// current byte position
	int i=0;

	// length of current element
	int l = 0;

	// datatype
	int type = 0;

	// current tuple position
	// 0 is id
	int position = 1;

	// current mask position
	int maskPosition = -1;

	while (i<listLength) {
		if ((maskPosition+1)>=maskSymbolLength) {
			break;
		} else {
			maskPosition++;
		}

		// Calculate length of current element - START
		if (0 == (l = (list[i]&255))) {

			  // First BYTE is 0, length is in following 2 BYTEs
			  size_t t_n = ((list[i+1]&255)|((list[i+2]&255)<<8));
			  if (t_n != 0) {
				  l = t_n + 3;
			  } else {
				  // 4 Byte length
				  l = ((list[i+3]&255) | ((list[i+4]&255) << 8) | ((list[i+5]&255) << 16) | ((list[i+6]&255) << 24)) + 7;
			  }
	   }
	   // Calculate length of current element - END

		// Skip - masks
		if (mask[maskPosition]=='-') {
			i+=l;
			continue;
		}

		// Calculate length and offset of current data - START
		int dataStart = i;
		int dataLength = l;

		if (l==1) {
			// do nothing
		} else if (l < 255) {
			type = list[i+1];
			dataStart += 2;
			dataLength -= 2;
		} else if (l < 65536) {
			type = list[i+3];
			dataStart += 4;
			dataLength -= 4;
		} else {
			type = list[i+7];
			dataStart += 8;
			dataLength -= 8;
		}
		// Calculate length and offset of current data - END

		// Parse element data - START

		// List element, whatever type it is
		PyObject* item = Py_None;
		if (l==1) {
			item = Py_None;
		} else if (type==STRING) {
			if (mask[maskPosition]=='m') {
				int year = 0;
				int month = 1;
				int day = 1;
				int hour = 0;
				int minute = 0;
				int second = 0;
				int result = sscanf(list+dataStart, "%d-%d-%d %d:%d:%d", &year, &month, &day, &hour, &minute, &second);
				if (result>0) {
					item = PyDateTime_FromDateAndTime(year, month, day, hour, minute, second, 0);
				}
			} else {
				item =  PyUnicode_FromStringAndSize(list+dataStart, dataLength);
			}
		} else if (type==USTRING) {
			item = PyUnicode_FromUnicode(list+dataStart, dataLength / 2);
		} else if (type == INTP) {

			int64_t temp = Makeint(list, dataStart, 0, dataLength);
			if (mask[maskPosition]=='b') {
				item = temp==0 ? Py_False : Py_True;
			} else if (mask[maskPosition]=='t') {
				int hour = temp / 3600;
				int minute = (temp - (hour*3600)) / 60;
				int second = temp - (hour*3600) - (minute*60);
				item = PyTime_FromTime(hour, minute, second, 0);
			} else if (mask[maskPosition]=='d') {
				/*int year = temp / 365.25;
				//+ 1840;
				//if (year>1900) { year++;}

				float yearDay = temp - (year * 365.25);
				int wholeMonthDays = 0;
				int days = 0;
				for (int month = 0; yearDay>wholeMonthDays; month++) {
					wholeMonthDays += Months()
				}*/

				struct tm date = { 0 };
				date.tm_year = 70;
				date.tm_mday = 1;
				date.tm_mday += temp - 47117; // 47117 is horolog for Jan 1 1970
				time_t result = mktime(&date);
				if (result!=-1) {
					item = PyDate_FromDate(date.tm_year + 1900, date.tm_mon + 1, date.tm_mday); //date.tm_mday);
				}
			} else {
				item = PyLong_FromLongLong(temp);
			}
		} else if (type==INTN) {
			int64_t temp = 0;
			if (l==2) {
				temp = -1;
			} else {
				memcpy(&temp, list+dataStart, dataLength);
				if (temp == 0) {
					temp = - (1 << (dataLength * 8));
				} else {
					int64_t pow2 = Next2(temp);
					temp = temp - pow2;
				}
			}
			item = PyLong_FromLongLong(temp);
		} else if (type==DOUBLEP) {
			int64_t temp = Makeint(list, dataStart+1, 0, dataLength-1);
			signed char exp = list[dataStart];
			item = PyFloat_FromDouble(temp*pow(10, exp));
		} else if (type==DOUBLEN) {
			int64_t temp = 0;
			memcpy(&temp, list+dataStart+1, dataLength-1);
			if (temp == 0) {
				temp = - (1 << (dataLength * 8));
			} else {
				int64_t pow2 = Next2(temp);
				temp = temp - pow2;
			}
			signed char exp = list[dataStart];
			item = PyFloat_FromDouble(temp*pow(10, exp));
		} else if (type==FLOAT) {
			double db;
			memcpy(&db, list+dataStart, 8);
			item = PyFloat_FromDouble(db);
		}
		// Parse element data - END

		PyTuple_SET_ITEM(tuple, position, item);
		i += l;
		position++;
	}


	// List didn't have enough elements to fill the mask
	// TODO maybe fill with NONE instead?
	if (position<(maskLength + 1)) {
		tuple = PyTuple_GetSlice(tuple, 0, position);
	}
	return tuple;

}

/// Given mask calculate number of non '-' characters
int CalculateMaskLength(const char *mask)
{
	int length = 0;
	int maxLength = (int)strlen(mask);
	for (int i=0; i<maxLength;i++) {
		if (mask[i]!='-') {
			length++;
		}
	}
	return length;
}

/// Transfer global to Python list of tuples
/// global - name of global
/// start - starting global key
/// end - final global key
/// mask - mask for $lb fields
/// name - list name
/// value - placeholder for global values.
int GetGlobalOrder(const char *global, int start, int end, const char* mask, const char* name, CACHE_EXSTRP value)
{
	if (isInitialized == false) {
		Initialize(NULL);
	}

	// maximum size of final list (all keys are set
	long size = end - start + 1;
	PyObject* list = PyList_New(size);

	// narg Number of subscript expressions pushed onto the argument stack.
	int narg = 1;

	// Direction for the $Order is 1 for forward, -1 for reverse.
	int dir = 1;
	// Indicates whether the data value, if there is one, should be returned.
	int valueflag = 1;

	// Has argument flag
	int flag = 0;

	// Current global subscript
	int key = start - 1;

	// Number of real rows in list
	int row=0;

	// Number of significant characters in mask
	int maskLength = CalculateMaskLength(mask);

	// Number of total characters in mask
	int maskSymbolLength = strlen(mask);

	// Global value
	// CACHE_EXSTRP value = calloc(1, sizeof value);

	while (key<=end) {
		CACHEPUSHGLOBAL(strlen(global), global);
		CACHEPUSHINT(key);
		CACHEGLOBALORDER(narg,  dir, valueflag);

		CACHEPOPINT(&flag);
		if (flag) {
		  CACHEEXSTRKILL(value);
		  CACHEPOPEXSTR(value);
		  CACHEPOPINT(&key);

		  PyList_SET_ITEM(list, row, ListToTuple(value, mask, maskLength, maskSymbolLength, key));
		} else {
		  CACHEPOPINT(&key);
		}

		row++;

		if (key==NULL) {
			break;
		}
	}
	CACHEEXSTRKILL(value);

	PyObject_SetAttrString(mainModule, name, PyList_GetSlice(list, 0, row-1));
	//Py_DECREF(list);

	return ZF_SUCCESS;
}

ZFBEGIN
	ZFENTRY("Initialize","c",Initialize)
	ZFENTRY("Finalize","",Finalize)
	ZFENTRY("SimpleString","jciJ",SimpleString)
	ZFENTRY("StreamInit","i",StreamInit)
	ZFENTRY("StreamWrite","j",StreamWrite)
	ZFENTRY("StreamExecute","",StreamExecute)
	ZFENTRY("EscapeString","jJ",EscapeString)
	ZFENTRY("GetGlobalOrder","ciiccJ",GetGlobalOrder)
ZFEND
