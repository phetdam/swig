%module(package="py3.pkg2") bar

%begin %{
/* ensure MSVC links the non-debug Python runtime */
#ifdef _MSC_VER
#define SWIG_PYTHON_INTERPRETER_NO_DEBUG
#endif  /* _MSC_VER */
%}

%{
#include "../../py3/pkg2/bar.hpp"
%}

%import  "../../py3/pkg2/pkg3/pkg4/foo.i"
%include "../../py3/pkg2/bar.hpp"
