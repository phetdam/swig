%begin %{
/* ensure MSVC links the non-debug Python runtime */
#ifdef _MSC_VER
#define SWIG_PYTHON_INTERPRETER_NO_DEBUG
#endif  /* _MSC_VER */
%}

%inline %{

class A {
public:
    A () {}
    ~A () {}
    void func () {}
    A& operator+= (int i) { return *this; }
};

class B : public A {
public:
    B () {}
    ~B () {}
};

class C : public B {
public:
    C () {}
    ~C () {}
};

class D : public C {
public:
    D () {}
    ~D () {}
};

class E : public D {
public:
    E () {}
    ~E () {}
};

class F : public E {
public:
    F () {}
    ~F () {}
};

class G : public F {
public:
    G () {}
    ~G () {}
};

class H : public G {
public:
    H () {}
    ~H () {}
};

%}
