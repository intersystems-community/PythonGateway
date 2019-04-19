/*
 *  iscpython.h
 *
 *  Created on: 16 Dec 2018
 *      Author: Eduard
 */

#ifndef ISCPYTHON_H
#define ISCPYTHON_H


// Production methods
int Initialize(char *file);
int Finalize();
int SimpleString(CACHE_EXSTRP command, char *resultVar, int serialization, CACHE_EXSTRP result);
int StreamInit(int length)
int StreamWrite(CACHE_EXSTRP command);
int StreamExecute();

int EscapeString(CACHE_EXSTRP string,  CACHE_EXSTRP result)
PyTupleObject* ListToTuple(CACHE_EXSTRP result,  char* mask, int maskLength, int maskSymbolLength, int key)
int GetGlobalOrder(const char *global, int start, int end, const char* mask, const char* name, CACHE_EXSTRP value)

// Console test method
int main(int argc, char **argv);

#endif /* ISCPYTHON_H */
