%module(package="pkg1") foo

%begin %{
/* ensure MSVC links the non-debug Python runtime */
#ifdef _MSC_VER
#define SWIG_PYTHON_INTERPRETER_NO_DEBUG
#endif  /* _MSC_VER */
%}

%{
#include "../pkg1/foo.hpp"
%}

%include "../pkg1/foo.hpp"
