%module spam

%begin %{
/* ensure we link against the non-debug Python runtime */
#ifdef _MSC_VER
#define SWIG_PYTHON_INTERPRETER_NO_DEBUG
#endif  /* _MSC_VER */
%}

%{
#include "spam.h"
%}

%import bar.i
%include "spam.h"
