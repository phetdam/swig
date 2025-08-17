%module(package="pkg2") foo

%begin %{
/* ensure MSVC links the non-debug Python runtime */
#ifdef _MSC_VER
#define SWIG_PYTHON_INTERPRETER_NO_DEBUG
#endif  /* _MSC_VER */
%}

%{
#include "../pkg2/foo.hpp"
%}

%import  "../pkg1/foo.i"
%include "../pkg2/foo.hpp"
