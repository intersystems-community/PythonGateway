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

// Test methods
int GetRandom(double* random);
int GetRandomSimple(double* random);
int SimpleStringFull(char *command, double* result);

// Console test method
int main(int argc, char **argv);

#endif /* ISCPYTHON_H */
