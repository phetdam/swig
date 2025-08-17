%begin %{
/* ensure MSVC links the non-debug Python runtime */
#ifdef _MSC_VER
#define SWIG_PYTHON_INTERPRETER_NO_DEBUG
#endif  /* _MSC_VER */
%}

%inline %{
class MyClass {
public:
    MyClass () {}
    ~MyClass () {}
    MyClass& operator+ (int i) { return *this; }
};
%}
