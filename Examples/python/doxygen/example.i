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

%immutable NumSquares;
%immutable NumCircles;

%include "example.h"

/*! - this instantiation uses type int */
%template(RectangleInt) Rectangle<int>;

/*! - this instantiation uses type int */
%template(MakeRectangleInt) MakeRectangle<int>;
