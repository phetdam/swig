cmake_minimum_required(VERSION ${CMAKE_MINIMUM_REQUIRED_VERSION})

# subexample name
set(example module_is_init)
# from README. requires Python 2.7.x or >= 3.3.x
if(SWIG_HAS_PYTHON3)
    if(Python_VERSION VERSION_LESS 3.3)
        message(
            STATUS
            "Skipping Python example ${example} since Python ${Python_VERSION} < 3.3"
        )
        return()  # return control to preceding directory
    endif()
elseif(Python_VERSION VERSION_LESS 2.7)
    message(
        STATUS
        "Skipping Python example ${example} since Python ${Python_VERSION} < 2.7"
    )
endif()
# generator expression for current binary directory + per-config subdirectory
set(output_dir ${CMAKE_CURRENT_BINARY_DIR}$<${SWIG_IS_MULTI_CONFIG}:/$<CONFIG>>)
# add example
swig_add_python_example(
    ${example}
    CXX
    INTERFACES pkg1/foo.i
    # graft test driver. see ../from_init1/CMakeLists.txt for more details
    GRAFT_FILES runme.py
    # indicate that the location of the test driver is in the build tree
    DRIVER_DIRECTORY ${output_dir}
)
# as a post-build command, we want to rename foo.py to __init__.py
add_custom_command(
    TARGET swig_python_${example}_foo
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E rename
            ${output_dir}/pkg1/foo.py ${output_dir}/pkg1/__init__.py
    BYPRODUCTS ${output_dir}/pkg1/__init__.py
    COMMENT "Renaming pkg1/foo.py to pkg1/__init__.py for ${example}"
    VERBATIM
    COMMAND_EXPAND_LISTS
)
