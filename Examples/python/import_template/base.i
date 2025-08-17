%module base

%begin %{
/* ensure MSVC links the non-debug Python runtime */
#ifdef _MSC_VER
#define SWIG_PYTHON_INTERPRETER_NO_DEBUG
#endif  /* _MSC_VER */
%}

%{
#include "base.h"
%}

%include base.h
%template(intBase) Base<int>;
