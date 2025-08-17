cmake_minimum_required(VERSION 3.21)

include_guard(GLOBAL)

##
# Add a SWIG Python example.
#
# This function defines rules for generating C or C++ SWIG wrapper code from
# the provided .i module that will be generated in the build output directory.
# In particular, multiple .i modules can be built for a single example with
# this function, with any extra C/C++ sources compiled as objects and
# statically linked into each module as necessary.
#
# A CTest test will be registered for the example with PYTHONPATH correctly set
# for the test driver script, typically runme.py. The working directory of the
# test is will be the directory in which swig_add_python_example was called.
#
# This function correctly tracks SWIG dependencies via -MMD -MF <depfile>.
#
# Arguments:
#   name                        Example/target name
#   [CXX]                       Enable SWIG C++ processing, e.g. with -c++
#   [INTERFACES files...]       SWIG .i interface file(s) to compile as Python
#                               extension modules separately. If none are
#                               provided, example.i is assumed to be present
#   [DRIVER driver]             Python script run as the test driver. If this
#                               is omitted, runme.py is assumed as the driver
#   [SOURCES sources...]        Additional C/C++ sources used in module
#                               compilation. These are compiled into a static
#                               library of position-independent code and linked
#                               as necessary into each SWIG module if present.
#   [OPTIONS options...]        Extra SWIG options to use
#
function(swig_add_python_example name)
    cmake_parse_arguments(ARG "CXX" "DRIVER" "INTERFACES;OPTIONS;SOURCES" ${ARGN})
    # DRIVER + INTERFACES have defaults
    if(NOT ARG_DRIVER)
        set(ARG_DRIVER runme.py)
    endif()
    if(NOT ARG_INTERFACES)
        set(ARG_INTERFACES example.i)
    endif()
    # add static library for sources
    if(ARG_SOURCES)
        add_library(swig_python_example_${name}_lib STATIC ${ARG_SOURCES})
        # e.g. ensure -fPIC is used with GCC. ignored for MSVC
        set_target_properties(
            swig_python_example_${name}_lib PROPERTIES
            POSITION_INDEPENDENT_CODE TRUE
        )
    endif()
    # get file path to built SWIG
    # for each interface
    foreach(swig_input ${ARG_INTERFACES})
        # get the input name + wrapper output name
        cmake_path(GET swig_input STEM swig_input_name)
        set(swig_output_name ${swig_input_name}PYTHON_wrap)
        # SWIG include paths into local Lib
        set(
            swig_includes
            -I${SWIG_ROOT}/Lib
            -I${SWIG_ROOT}/Lib/python  # for Python-specific
            -I${PROJECT_BINARY_DIR}  # for swigwarn.swg
        )
        # C++ wrapper rule
        add_custom_command(
            OUTPUT ${swig_output_name}.cxx
            COMMAND swig
                    -python ${ARG_OPTIONS}
                    -c++
                    -MMD -MF ${swig_output_name}.cxx.d
                    ${swig_includes}
                    -o ${swig_output_name}.cxx
                    # support multi-config generator as necessary
                    -outdir $<IF:${SWIG_IS_MULTI_CONFIG},$<CONFIG>,.>
                    # enable use of extension module to be same as target name
                    -interface swig_python_example_${name}
                    ${CMAKE_CURRENT_SOURCE_DIR}/${swig_input}
            # need swigwarn_generate dependency to prevent repeated
            # swigwarn.swg generation if swigwarn.h changes
            DEPENDS swig swigwarn_generate ${swig_input}
            DEPFILE ${swig_output_name}.cxx.d
            COMMENT "SWIG Python compile for C++ example ${name}"
            VERBATIM
            COMMAND_EXPAND_LISTS
        )
        # C wrapper rule
        add_custom_command(
            OUTPUT ${swig_output_name}.c
            COMMAND swig
                    -python ${ARG_OPTIONS}
                    -MMD -MF ${swig_output_name}.c.d
                    ${swig_includes}
                    -o ${swig_output_name}.c
                    # support multi-config generator as necessary
                    -outdir $<IF:${SWIG_IS_MULTI_CONFIG},$<CONFIG>,.>
                    # enable use of extension module to be same as target name
                    -interface swig_python_example_${name}
                    ${CMAKE_CURRENT_SOURCE_DIR}/${swig_input}
            # need swigwarn_generate dependency to prevent repeated
            # swigwarn.swg generation if swigwarn.h changes
            DEPENDS swig swigwarn_generate ${swig_input}
            DEPFILE ${swig_output_name}.c.d
            COMMENT "SWIG Python compile for C example ${name}"
            VERBATIM
            COMMAND_EXPAND_LISTS
        )
        # set SWIG output file to determine rule
        set(swig_output ${swig_output_name}.c)
        if(ARG_CXX)
            string(APPEND swig_output xx)
        endif()
        # build Python module
        Python_add_library(
            swig_python_example_${name} MODULE
            ${CMAKE_CURRENT_BINARY_DIR}/${swig_output}
        )
        # on Windows, use standard release C runtime even in debug builds
        set_target_properties(
            swig_python_example_${name} PROPERTIES
            MSVC_RUNTIME_LIBRARY MultiThreadedDLL
        )
        # pick up curernt source directory as include path
        target_include_directories(
            swig_python_example_${name} PRIVATE
            ${CMAKE_CURRENT_SOURCE_DIR}
        )
        # link against helper library if it is defined
        if(TARGET swig_python_example_${name}_lib)
            target_link_libraries(
                swig_python_example_${name} PRIVATE
                swig_python_example_${name}_lib
            )
        endif()
    endforeach()
    # register test. run in source directory to emulate "manual" running
    add_test(
        NAME example_python_${name}
        COMMAND ${Python_EXECUTABLE} ${ARG_DRIVER}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )
    # ensure PYTHONPATH includes CMAKE_CURRENT_BINARY_DIR with per-config
    # subdirectory as required so Python can correctly load the modules
    set_tests_properties(
        example_python_${name} PROPERTIES
        ENVIRONMENT
            "PYTHONPATH=${CMAKE_CURRENT_BINARY_DIR}$<${SWIG_IS_MULTI_CONFIG}:/$<CONFIG>>"
    )
endfunction()
