cmake_minimum_required (VERSION 3.21)

set (CMAKE_BUILD_TYPE Release CACHE STRING "Build type")

project (swig)

if (POLICY CMP0074)
  cmake_policy (SET CMP0074 NEW)
endif()

file (STRINGS configure.ac line LIMIT_COUNT 1 REGEX "AC_INIT\\(.*\\)" )
if (line MATCHES "AC_INIT\\(\\[(.*)\\],[ \t]*\\[(.*)\\],[ \t]*\\[(.*)\\]\\)" )
  set (SWIG_VERSION ${CMAKE_MATCH_2})
  set (PACKAGE_BUGREPORT ${CMAKE_MATCH_3})
else ()
  message (SEND_ERROR "Could not parse version from configure.ac")
endif ()

set (SWIG_ROOT ${PROJECT_SOURCE_DIR})

if (WIN32)
  set (SWIG_LIB bin/Lib)
else ()
  set (SWIG_LIB share/swig/${SWIG_VERSION})
endif ()
# Project wide configuration variables
# ------------------------------------

set (SWIG_SOURCE_DIR ${SWIG_ROOT}/Source CACHE INTERNAL "Path of swig sources" FORCE)

set (PACKAGE_NAME swig)
set (PACKAGE_VERSION ${SWIG_VERSION})

# TODO: decide on <cmd> (<args>) or <cmd>(<args>) for CMake formatting

# Configure
# ---------

# TODO: maybe there should be a dedicated CMake modules directory
list (APPEND CMAKE_MODULE_PATH ${SWIG_ROOT}/Tools/cmake ${SWIG_ROOT}/CMake)

include (swig_add_python_example)

include (CheckIncludeFiles)
include (CheckIncludeFile)
include (CheckIncludeFileCXX)
include (CheckTypeSize)
include (CheckSymbolExists)
include (CheckFunctionExists)
include (CheckLibraryExists)
include (CheckCSourceCompiles)
include (CTest)

# HACK: didn't get the bool check working for Visual Studio 2008
if (MSVC)
  set(HAVE_BOOL 1)
else()
  set (CMAKE_EXTRA_INCLUDE_FILES stdbool.h)
  check_type_size ("bool" HAVE_BOOL)
  set (CMAKE_EXTRA_INCLUDE_FILES)
endif()

check_include_file ("inttypes.h" HAVE_INTTYPES_H)
check_include_file ("stddef.h" HAVE_STDDEF_H)
check_include_file ("stdint.h" HAVE_STDINT_H)
check_include_file ("stdio.h" HAVE_STDIO_H)
check_include_file ("stdlib.h" HAVE_STDLIB_H)
check_include_file ("string.h" HAVE_STRING_H)
check_include_file ("strings.h" HAVE_STRINGS_H)
check_include_file ("sys/stat.h" HAVE_SYS_STAT_H)
check_include_file ("sys/types.h" HAVE_SYS_TYPES_H)
check_include_file ("unistd.h" HAVE_UNISTD_H)
check_include_files ("stdlib.h;stdarg.h;string.h;float.h" STDC_HEADERS)

check_include_file_cxx ("boost/shared_ptr.hpp" HAVE_BOOST)
check_library_exists (dl dlopen "" HAVE_LIBDL)
check_function_exists (popen HAVE_POPEN)

if (MSVC)
  set (CMAKE_CXX_FLAGS "/EHsc ${CMAKE_CXX_FLAGS}")
endif ()

option (SWIG_BUILD_EXAMPLES "Build SWIG examples" OFF)
option (SWIG_BUILD_TESTS "Build SWIG tests" OFF)
option (WITH_PCRE "Enable PCRE" ON)

# determine if multi-config generator. this is important with regards to build
# directory structure, where typically per-config subdirectories are used
get_property(SWIG_IS_MULTI_CONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(SWIG_IS_MULTI_CONFIG)
  message(STATUS "Build config: Multi")
else()
  message(STATUS "Build config: ${CMAKE_BUILD_TYPE}")  # see above
endif()

# report the CMake generator being used
message(STATUS "Build backend: ${CMAKE_GENERATOR}")

if(SWIG_BUILD_EXAMPLES)
  message(STATUS "Build examples: Yes")
else()
  message(STATUS "Build examples: No")
endif()

if(SWIG_BUILD_TESTS)
  message(STATUS "Build test suite: Yes")
else()
  message(STATUS "Build test suite: No")
endif()

if (WITH_PCRE)
  find_package (PCRE2 10.39 REQUIRED COMPONENTS 8BIT)
  set (HAVE_PCRE 1)
endif ()

#if (WIN32)
#  file (TO_NATIVE_PATH ${CMAKE_INSTALL_PREFIX}/${SWIG_LIB} SWIG_LIB_WIN_UNIX)
#  string (REGEX REPLACE "\\\\" "\\\\\\\\" SWIG_LIB_WIN_UNIX "${SWIG_LIB_WIN_UNIX}")
#endif ()
configure_file (${SWIG_ROOT}/Tools/cmake/swigconfig.h.in
                ${CMAKE_CURRENT_BINARY_DIR}/Source/Include/swigconfig.h)

find_package (BISON 3.5 REQUIRED)


# Compiler flags
# --------------

include_directories (
    ${SWIG_SOURCE_DIR}/CParse
    ${SWIG_SOURCE_DIR}/Include
    ${SWIG_SOURCE_DIR}/DOH
    ${SWIG_SOURCE_DIR}/Swig
    ${SWIG_SOURCE_DIR}/Preprocessor
    ${SWIG_SOURCE_DIR}/Modules
    ${PROJECT_BINARY_DIR}/Source/Include
    ${PROJECT_BINARY_DIR}/Source/CParse
    ${PROJECT_SOURCE_DIR}/Source/Doxygen
)

# generate the parser source code (depends on bison)
file (MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/Source/CParse)

BISON_TARGET (swig_parser
    ${SWIG_SOURCE_DIR}/CParse/parser.y
    ${PROJECT_BINARY_DIR}/Source/CParse/parser.c
)

# custom rule for swigwarn.swg generation. this avoids excessive test/example
# rebuild because swigwarn.swg is a dependency that swig -MMD -MF will find
add_custom_command(
  OUTPUT swigwarn.swg
  COMMAND ${CMAKE_COMMAND}
          -DSWIG_WARN_H=${SWIG_SOURCE_DIR}/Include/swigwarn.h
          -DSWIG_WARN_SWG=${CMAKE_CURRENT_BINARY_DIR}/swigwarn.swg
          -P ${SWIG_ROOT}/CMake/swigwarn_generate.cmake
  MAIN_DEPENDENCY ${SWIG_SOURCE_DIR}/Include/swigwarn.h
  COMMENT "Generating swigwarn.swg from swigwarn.h"
  VERBATIM
)
# custom target to trigger swigwarn.swg generation as necessary
# note: custom commands should depend on this target to avoid multiple
# swigwarn.swg generation calls. see add_custom_command documentation
add_custom_target(
  swigwarn_generate ALL
  DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/swigwarn.swg
)

# install lib
install (DIRECTORY ${SWIG_ROOT}/Lib/ DESTINATION ${SWIG_LIB})
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/swigwarn.swg DESTINATION ${SWIG_LIB})

# sources
# ---------
# note: using GLOB is not recommended for IDE integration or auto-detecting if
# configuration needs to be re-run. it's ok for now
file (GLOB DOH_SOURCES ${SWIG_SOURCE_DIR}/DOH/*.c)
file (GLOB CPARSE_SOURCES ${SWIG_SOURCE_DIR}/CParse/*.c)
list (REMOVE_ITEM CPARSE_SOURCES ${SWIG_SOURCE_DIR}/CParse/parser.c)
list (APPEND CPARSE_SOURCES)
file (GLOB PREPROCESSOR_SOURCES ${SWIG_SOURCE_DIR}/Preprocessor/*.c)
file (GLOB CORE_SOURCES ${SWIG_SOURCE_DIR}/Swig/*.c)
file (GLOB DOXYGEN_SOURCES ${SWIG_SOURCE_DIR}/Doxygen/*.cxx)
file (GLOB MODULES_SOURCES ${SWIG_SOURCE_DIR}/Modules/*.cxx)

add_executable (swig
  ${CPARSE_SOURCES}
  ${DOH_SOURCES}
  ${DOXYGEN_SOURCES}
  ${MODULES_SOURCES}
  ${CORE_SOURCES}
  ${PREPROCESSOR_SOURCES}
  ${PROJECT_BINARY_DIR}/Source/Include/swigconfig.h
  # TODO: consider removal since swigwarn_generate handles this already
  ${SWIG_SOURCE_DIR}/Include/swigwarn.h
  ${PROJECT_BINARY_DIR}/Source/CParse/parser.c
  ${PROJECT_BINARY_DIR}/Source/CParse/parser.h
)
# ensure that swigwarn.swg is generated before building. for some reason,
# without this target-level dependency, parallel builds end up calling the
# swigwarn.swg generation step twice. this seems due to swigwarn.h being
# included in the SWIG target's dependency list
add_dependencies(swig swigwarn_generate)
if (PCRE2_FOUND)
  target_link_libraries (swig PRIVATE PCRE2::8BIT)
endif ()
install (TARGETS swig DESTINATION bin)

# 'make package-source' creates tarballs
set (CPACK_PACKAGE_NAME ${PACKAGE_NAME})
set (CPACK_SOURCE_GENERATOR "TGZ;TBZ2")
set (CPACK_SOURCE_IGNORE_FILES "/.git;/build;.*~;${CPACK_SOURCE_IGNORE_FILES}")
set (CPACK_SOURCE_PACKAGE_FILE_NAME ${PACKAGE_NAME}-${PACKAGE_VERSION})
include (CPack)

# SWIG smoke tests
add_test (NAME cmd_version COMMAND swig -version)
add_test (NAME cmd_pcreversion COMMAND swig -pcreversion)
add_test (NAME cmd_swiglib COMMAND swig -swiglib)
add_test (NAME cmd_external_runtime COMMAND swig -external-runtime ext_rt.h)
set_tests_properties(
  cmd_external_runtime PROPERTIES
  ENVIRONMENT "SWIG_LIB=${PROJECT_SOURCE_DIR}/Lib"
)

# Examples contains both examples and the test suite
if(SWIG_BUILD_EXAMPLES OR SWIG_BUILD_TESTS)
  add_subdirectory(Examples)
endif()
