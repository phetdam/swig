/* File : example.i */
%module(directors="1") example

%begin %{
/* ensure MSVC links the non-debug Python runtime */
#ifdef _MSC_VER
#define SWIG_PYTHON_INTERPRETER_NO_DEBUG
#endif  /* _MSC_VER */
%}

%{
#include "example.h"
%}

/* turn on director wrapping Callback */
%feature("director") Callback;

%include "example.h"
