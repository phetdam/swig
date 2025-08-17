/* File : example.i */
%module example

%begin %{
/* ensure MSVC links the non-debug Python runtime */
#ifdef _MSC_VER
#define SWIG_PYTHON_INTERPRETER_NO_DEBUG
#endif  /* _MSC_VER */
%}

%contract gcd(int x, int y) {
require:
	x >= 0;
	y >= 0;
}

%contract fact(int n) {
require:
	n >= 0;
ensure:
	fact >= 1;
}

%inline %{
extern int    gcd(int x, int y);
extern int    fact(int n);
extern double Foo;
%}
