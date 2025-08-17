cmake_minimum_required(VERSION ${CMAKE_MINIMUM_REQUIRED_VERSION})

# list of Python examples to build
set(
    python_examples
        callback
        class
        constants
        contract
        docstrings
        enum
        exception
        exceptproxy
        extend
        # FIXME: requires rethinking swig_add_python_example or a bespoke rule
        # external_runtime
        funcptr
        funcptr2
        functor
        import
        # TODO: may require a bespoke approach
        # import_packages
        import_template
        libffi
        multimap
        operator
        # TODO: this requires a bespoke approach
        # performance
        pointer
        reference
        simple
        smartptr
        std_map
        std_vector
        template
        varargs
        variables
)
# add all the Python example directories. most will be some simple invocation
# of swig_add_python_example, but some examples will be more involved
foreach(example ${python_examples})
    add_subdirectory(${example})
endforeach()
