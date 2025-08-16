cmake_minimum_required(VERSION ${CMAKE_MINIMUM_REQUIRED_VERSION})

swig_add_python_example(
    class
    INTERFACES example.i
    DRIVER runme.py
    SOURCES example.cxx
    CXX
)
