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
#include "smartptr.h"
%}

/* Let's just grab the original header file here */
%include "example.h"

/* Grab smart pointer template */

%include "smartptr.h"

/* Instantiate smart-pointers */

%template(ShapePtr) SmartPtr<Shape>;
