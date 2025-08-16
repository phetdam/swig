cmake_minimum_required(VERSION ${CMAKE_MINIMUM_REQUIRED_VERSION})

# list of Python examples to build
set(
    python_examples
        callback
        class
)
# add all the Python example directories. see each one for build specifics
foreach(example ${python_examples})
    add_subdirectory(${example})
endforeach()
