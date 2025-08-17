cmake_minimum_required(VERSION 3.21)

include_guard(GLOBAL)

##
# Add a SWIG Python example.
#
# This function defines rules for generating C or C++ SWIG wrapper code from
# the provided .i module that will be generated in the build output directory.
# In particular, multiple .i modules can be built for a single example with
# this function, with any extra C/C++ sources compiled as objects and linked
# linked into each extension module as necessary.
#
# A CTest test will be registered for the example with PYTHONPATH correctly set
# for the test driver script, typically runme.py. The working directory of the
# test is will be the directory in which swig_add_python_example was called.
#
# This function correctly tracks SWIG dependencies via -MMD -MF <depfile>. It
# expects that each example is in its own source directory and should be
# invoked in the CMakeLists.txt in that source directory to ensure that each
# generated C/C++ file gets its own build directory. This is because many
# examples use example.i or (foo|bar|spam).i and without directory namespacing,
# there would be conflicts in the generated file paths.
#
# For multi-config generators, the build tree will have the corresponding
# per-config subdirectories added. E.g. ${input_name}.i will have an artifact
# in ${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG> in the multi-config case. This also
# affects GRAFT_FILES, which will match this per-configuration namespacing.
#
# Arguments:
#   name                        Example name. The resulting module targets for
#                               each interface ${input_name}.i will be named
#                               swig_python_${name}_${input_name}.
#   [CXX]                       Enable SWIG C++ processing, e.g. with -c++
#   [INTERFACES files...]       SWIG .i interface file(s) to compile as Python
#                               extension modules separately. If none are
#                               provided, example.i is assumed to be present
#   [DRIVER driver]             Python script run as the test driver. If this
#                               is omitted, runme.py is assumed as the driver.
#   [SOURCES sources...]        Additional C/C++ sources used in module
#                               compilation. These are compiled into a static
#                               library of position-independent code and linked
#                               as necessary into each SWIG module if present.
#   [LIBRARIES libs...]         Additional libraries used in module linking.
#                               These are passed to target_link_libraries and
#                               so can be targets, library files, or -l args.
#   [OPTIONS options...]        Extra SWIG options to use
#
#   [DRIVER_DIRECTORY dir...]
#                               Working directory to run the test driver from
#                               *and* the directory the test driver script is
#                               expected to be. If not specified,
#                               ${CMAKE_CURRENT_SOURCE_DIR} is assumed. This
#                               can be a generator expression which is useful.
#
#   [GRAFT_FILES files...]      Extra files to graft relative to
#                               ${CMAKE_CURRENT_BINARY_DIR} for each interface
#                               to support running the Python test driver. This
#                               can include the test driver script itself. For
#                               multi-config generators, $<CONFIG> is added.
#
function(swig_add_python_example name)
    cmake_parse_arguments(
        ARG
        "CXX"
        "DRIVER;DRIVER_DIRECTORY"
        "INTERFACES;OPTIONS;SOURCES;LIBRARIES;GRAFT_FILES"
        ${ARGN}
    )
    # set defaults
    if(NOT ARG_DRIVER)
        set(ARG_DRIVER runme.py)
    endif()
    if(NOT ARG_INTERFACES)
        set(ARG_INTERFACES example.i)
    endif()
    if(NOT ARG_DRIVER_DIRECTORY)
        set(ARG_DRIVER_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
    endif()
    # generator expression for current output directory
    set(output_dir "${CMAKE_CURRENT_BINARY_DIR}$<${SWIG_IS_MULTI_CONFIG}:/$<CONFIG>>")
    # add static library for sources
    # TODO: consider using object library
    if(ARG_SOURCES)
        add_library(swig_python_${name}_example_lib STATIC ${ARG_SOURCES})
        # ensure -fPIC is used with GCC/Clang (ignored for MSVC) and ensure
        # MSVC uses the non-debug C runtime (ignored for non-MSVC)
        set_target_properties(
            swig_python_${name}_example_lib PROPERTIES
            POSITION_INDEPENDENT_CODE TRUE
            MSVC_RUNTIME_LIBRARY MultiThreadedDLL
        )
        # TODO: enable linking other libraries here too
    endif()
     # custom target copy grafted files in
    if(ARG_GRAFT_FILES)
        # build sequence of commands
        foreach(graft_file ${ARG_GRAFT_FILES})
            # build sequence of arguments for add_custom_target
            list(
                APPEND swig_graft_cmds
                COMMAND ${CMAKE_COMMAND}
                        -E copy_if_different ${graft_file} ${output_dir}/${graft_file}
            )
        endforeach()
        # finally add custom target
        add_custom_target(
            swig_python_${name}_example_graft ALL
            ${swig_graft_cmds}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Grafting files for ${name} Python example"
            VERBATIM
            COMMAND_EXPAND_LISTS
        )
    endif()
    # for each interface
    foreach(swig_input ${ARG_INTERFACES})
        # get the input name, parent directory, and wrapper output name
        cmake_path(GET swig_input STEM swig_input_name)
        cmake_path(GET swig_input PARENT_PATH swig_input_dir)
        set(swig_output_name ${swig_input_name}PYTHON_wrap)
        # SWIG include paths into local Lib
        set(
            swig_includes
            -I${SWIG_ROOT}/Lib/python  # for Python-specific (must go first)
            -I${SWIG_ROOT}/Lib
            -I${PROJECT_BINARY_DIR}  # for swigwarn.swg
        )
        # C++ wrapper rule
        add_custom_command(
            OUTPUT ${swig_output_name}.cxx
            # create output directory if it doesn't exist
            # note: not needed unless ${swig_input_dir} is not empty or .
            COMMAND ${CMAKE_COMMAND} -E make_directory
                    $<IF:${SWIG_IS_MULTI_CONFIG},$<CONFIG>,.>/${swig_input_dir}
            COMMAND swig
                    -python ${ARG_OPTIONS}
                    -c++
                    -MMD -MF ${swig_output_name}.cxx.d
                    ${swig_includes}
                    -o ${swig_output_name}.cxx
                    # support multi-config generator as necessary
                    -outdir $<IF:${SWIG_IS_MULTI_CONFIG},$<CONFIG>,.>/${swig_input_dir}
                    # enable use of extension module to be same as target name
                    -interface swig_python_${name}_${swig_input_name}
                    ${CMAKE_CURRENT_SOURCE_DIR}/${swig_input}
            # need swigwarn_generate dependency to prevent repeated
            # swigwarn.swg generation if swigwarn.h changes
            DEPENDS swig swigwarn_generate ${swig_input}
            DEPFILE ${swig_output_name}.cxx.d
            COMMENT "SWIG Python C++ compile for ${name} ${swig_input_name}.i"
            VERBATIM
            COMMAND_EXPAND_LISTS
        )
        # C wrapper rule
        add_custom_command(
            OUTPUT ${swig_output_name}.c
            # create output directory if it doesn't exist
            # note: not needed unless ${swig_input_dir} is not empty or .
            COMMAND ${CMAKE_COMMAND} -E make_directory
                    $<IF:${SWIG_IS_MULTI_CONFIG},$<CONFIG>,.>/${swig_input_dir}
            COMMAND swig
                    -python ${ARG_OPTIONS}
                    -MMD -MF ${swig_output_name}.c.d
                    ${swig_includes}
                    -o ${swig_output_name}.c
                    # support multi-config generator as necessary
                    -outdir $<IF:${SWIG_IS_MULTI_CONFIG},$<CONFIG>,.>/${swig_input_dir}
                    # enable use of extension module to be same as target name
                    -interface swig_python_${name}_${swig_input_name}
                    ${CMAKE_CURRENT_SOURCE_DIR}/${swig_input}
            # need swigwarn_generate dependency to prevent repeated
            # swigwarn.swg generation if swigwarn.h changes
            DEPENDS swig swigwarn_generate ${swig_input}
            DEPFILE ${swig_output_name}.c.d
            COMMENT "SWIG Python C compile for ${name} ${swig_input_name}.i"
            VERBATIM
            COMMAND_EXPAND_LISTS
        )
        # set SWIG output file to determine rule
        set(swig_output ${swig_output_name}.c)
        if(ARG_CXX)
            string(APPEND swig_output xx)
        endif()
        # build Python module
        # TODO: consider emitting artifacts with name _${swig_input_name} since
        # some Python tests, e.g. import_packages/namespace_pkg, require this
        Python_add_library(
            swig_python_${name}_${swig_input_name} MODULE
            ${CMAKE_CURRENT_BINARY_DIR}/${swig_output}
        )
        set_target_properties(
            swig_python_${name}_${swig_input_name} PROPERTIES
            # use standard release C runtime even in debug builds with MSVC.
            # this removes the need for the SWIG_PYTHON_INTERPRETER_NO_DEBUG
            # definition needed if you wish to use a debug C runtime
            MSVC_RUNTIME_LIBRARY MultiThreadedDLL
            # note: LIBRARY_OUTPUT_DIRECTORY used since MODULE type is used.
            # this generator expression ensures that multi-config generators
            # are supported and that .i files in subdirectories have the build
            # artifact locations correctly mirrored in the build tree
            LIBRARY_OUTPUT_DIRECTORY "${output_dir}/${swig_input_dir}"
        )
        # pick up source directory of SWIG interface as include path since most
        # source files are typically in that same directory
        target_include_directories(
            swig_python_${name}_${swig_input_name} PRIVATE
            ${CMAKE_CURRENT_SOURCE_DIR}/${swig_input_dir}
        )
        # link against helper library if it is defined
        if(TARGET swig_python_${name}_example_lib)
            target_link_libraries(
                swig_python_${name}_${swig_input_name}
                PRIVATE swig_python_${name}_example_lib
            )
        endif()
        # link additional libraries if any
        if(ARG_LIBRARIES)
            target_link_libraries(
                swig_python_${name}_${swig_input_name}
                PRIVATE ${ARG_LIBRARIES}
            )
        endif()
    endforeach()
    # register test. run in source directory to emulate invocation by hand
    add_test(
        NAME python_${name}_example
        COMMAND ${Python_EXECUTABLE} ${ARG_DRIVER}
        WORKING_DIRECTORY ${ARG_DRIVER_DIRECTORY}
    )
    # ensure PYTHONPATH includes CMAKE_CURRENT_BINARY_DIR with per-config
    # subdirectory as required so Python can correctly load the modules
    set_tests_properties(
        python_${name}_example PROPERTIES
        ENVIRONMENT "PYTHONPATH=${output_dir}"
    )
endfunction()
