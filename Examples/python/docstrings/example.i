/* File : example.i */
%module example

%begin %{
/* ensure MSVC links the non-debug Python runtime */
#ifdef _MSC_VER
#define SWIG_PYTHON_INTERPRETER_NO_DEBUG
#endif  /* _MSC_VER */
%}

%{
#include "example.h"
%}

/* %feature("docstring") has to come before the declaration of the method to
 * SWIG. */
%feature("docstring") Foo::bar "No comment"

/* Let's just grab the original header file here */
%include "example.h"
