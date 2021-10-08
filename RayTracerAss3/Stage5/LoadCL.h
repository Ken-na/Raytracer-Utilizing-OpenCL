#ifndef _CLLOADSOURCE_H
#define _CLLOADSOURCE_H

#undef CL_VERSION_3_0
#undef CL_VERSION_2_0
#include <CL/cl.h>

cl_program clLoadSource(cl_context context, char* filename, cl_int* err);

#endif