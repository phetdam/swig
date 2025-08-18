cmake_minimum_required(VERSION ${CMAKE_MINIMUM_REQUIRED_VERSION})

# if libffi wasn't found, skip
if(NOT FFI_FOUND)
    message(STATUS "Skipping libffi Python example (no libffi)")
    return()
endif()

swig_add_python_example(libffi LIBRARIES FFI::ffi)
