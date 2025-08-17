cmake_minimum_required(VERSION ${CMAKE_MINIMUM_REQUIRED_VERSION})

# list of Python examples to build
set(
    python_examples
        callback
        class
        constants
        contract
)
# add all the Python example directories. most will be some simple invocation
# of swig_add_python_example, but some examples will be more involved
foreach(example ${python_examples})
    add_subdirectory(${example})
endforeach()
