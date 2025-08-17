cmake_minimum_required(VERSION ${CMAKE_MINIMUM_REQUIRED_VERSION})

# FIXME: skip only if libffi is not available
if(NOT WIN32)
    swig_add_python_example(libffi LIBRARIES ffi)
else()
    message(STATUS "Skipping libffi Python example (no libffi)")
endif()
