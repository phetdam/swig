%module foo

%begin %{
/* ensure MSVC links the non-debug Python runtime */
#ifdef _MSC_VER
#define SWIG_PYTHON_INTERPRETER_NO_DEBUG
#endif  /* _MSC_VER */
%}

%{
#include "foo.h"
%}

%import base.i
%include "foo.h"

%template(intFoo) Foo<int>;
