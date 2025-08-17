cmake_minimum_required(VERSION 3.15)

##
# Generates swigwarn.swg in the top-level build directory.
#
# This is run by a custom build rule so swigwarn.swg is not needlessly
# regenerated every time which will cause excessive rebuilding of the tests and
# examples as swigwarn.swg will be found by using -MMD -MF on in-tree files.
#
# The following external CMake variables should be defined:
#
#   SWIG_WARN_H         Path to swigwarn.h to transform
#   SWIG_WARN_SWG       Path to swigwarn.swg to write to
#

# must only run in script mode
if(NOT CMAKE_SCRIPT_MODE_FILE)
    message(FATAL_ERROR "Must only run in CMake script mode")
endif()

# need expected variables
if(NOT DEFINED SWIG_WARN_H)
    message(FATAL_ERROR "SWIG_WARN_H required")
endif()
if(NOT DEFINED SWIG_WARN_SWG)
    message(FATAL_ERROR "SWIG_WARN_SWG required")
endif()

# read swigwarn.h header
file(READ ${SWIG_WARN_H} swig_warn_header)
string(
  REGEX REPLACE
  "#define WARN([^ \\t]*)[ \\t]*([0-9]+)" "%define SWIGWARN\\1 \\2 %enddef"
  swig_warn_swg "${swig_warn_header}"
)
# write to specified file (swigwarn.swg)
file(WRITE ${SWIG_WARN_SWG} "${swig_warn_swg}")
