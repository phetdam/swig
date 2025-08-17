cmake_minimum_required(VERSION ${CMAKE_MINIMUM_REQUIRED_VERSION})

swig_add_python_example(import_template CXX INTERFACES bar.i base.i foo.i spam.i)
