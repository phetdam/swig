cmake_minimum_required(VERSION 3.21)

include_guard(GLOBAL)

##
# Add a SWIG Python example.
#
# This function defines rules for generating C or C++ SWIG wrapper code from
# the provided .i module that will be generated in the build output directory.
#
# Note: Currently this only works for single-config generators.
#
# Arguments:
#   name                        Example/target name
#   INTERFACES interfaces...    SWIG .i interface file
#   DRIVER driver               Python script run as the test driver
#   [SOURCES sources...]        Additional C/C++ sources used in module
#                               compilation. These are compiled into a static
#                               library of position-independent code and linked
#                               as necessary into each SWIG module.
#   [CXX]                       Enable SWIG C++ processing, e.g. with -c++
#   [OPTIONS options...]        Extra SWIG options to use
#
function(swig_add_python_example name)
    cmake_parse_arguments(ARG "CXX" "DRIVER" "INTERFACES;OPTIONS;SOURCES" ${ARGN})
    # DRIVER + INTERFACES required
    if(NOT ARG_DRIVER)
        message(FATAL_ERROR "Missing required Python test driver")
    endif()
    if(NOT ARG_INTERFACES)
        message(FATAL_ERROR "Missing required SWIG .i interface(s)")
    endif()
    # add static library for sources
    if(ARG_SOURCES)
        add_library(swig_python_example_${name}_lib STATIC ${ARG_SOURCES})
        # e.g. ensure -fPIC is used with GCC
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
        # C++ dependency file rule
        # C++ wrapper rule
        add_custom_command(
            OUTPUT ${swig_output_name}.cxx
            COMMAND swig
                    -python ${ARG_OPTIONS}
                    -c++
                    -MMD
                    -MF ${swig_output_name}.cxx.d
                    ${swig_includes}
                    -o ${swig_output_name}.cxx
                    -outdir .
                    # enable use of extension module to be same as target name
                    -interface swig_python_example_${name}
                    ${CMAKE_CURRENT_SOURCE_DIR}/${swig_input}
            # of course, if SWIG is recompiled, we must re-build the example
            DEPENDS swig ${swig_input}
            COMMENT "SWIG Python compile for C++ example ${name}"
            # use depfile for actual dependencies. this is why we run in
            # CMAKE_CURRENT_BINARY_DIR; relative paths are expected to be
            # relative to CMAKE_CURRENT_BINARY_DIR
            DEPFILE ${swig_output_name}.cxx.d
            VERBATIM
            COMMAND_EXPAND_LISTS
        )
        # C wrapper rule
        add_custom_command(
            OUTPUT ${swig_output_name}.c
            COMMAND swig
                    -python ${ARG_OPTIONS}
                    -MMD
                    -MF ${swig_output_name}.c.d
                    ${swig_includes}
                    -o ${swig_output_name}.c
                    # enable use of extension module to be same as target name
                    -interface swig_python_example_${name}
                    -outdir .
                    ${CMAKE_CURRENT_SOURCE_DIR}/${swig_input}
            DEPENDS swig ${swig_input}
            COMMENT "SWIG Python compile for C example ${name}"
            DEPFILE ${swig_output_name}.c.d
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
        # on Windows, use release C runtime to avoid Python headers from
        # auto-linking the Python debug runtime
        set_target_properties(
            swig_python_example_${name} PROPERTIES
            MSVC_RUNTIME_LIBRARY MultiThreadedDLL
        )
        # pick up source directory as include path
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
    # register test. must run in same directory as the specified driver script
    add_test(
        NAME example_python_${name}
        COMMAND ${Python_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/${ARG_DRIVER}
    )
    # ensure PYTHONPATH includes CMAKE_CURRENT_BINARY_DIR
    set_tests_properties(
        example_python_${name} PROPERTIES
        ENVIRONMENT "PYTHONPATH=${CMAKE_CURRENT_BINARY_DIR}"
    )
endfunction()
