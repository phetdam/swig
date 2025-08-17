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

%include "std_string.i"

%catches(int) Test::simple();
%catches(const char *) Test::message();
%catches(Exc) Test::hosed();
%catches(A*) Test::unknown();
%catches(int, const char *, Exc) Test::multi(int x);

/* Let's just grab the original header file here */
%include "example.h"

%inline %{
// The -builtin SWIG option results in SWIGPYTHON_BUILTIN being defined
#ifdef SWIGPYTHON_BUILTIN
bool is_python_builtin() { return true; }
#else
bool is_python_builtin() { return false; }
#endif
%}
