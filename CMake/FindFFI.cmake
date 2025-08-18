cmake_minimum_required(VERSION 3.15)

##
# FindFFI.cmake
#
# Find module for libffi.
#

include(FindPackageHandleStandardArgs)

# locate ffi.h include directory
find_path(FFI_INCLUDE_DIR ffi.h)
# stop early if not found
if(NOT FFI_INCLUDE_DIR)
    find_package_handle_standard_args(FFI REQUIRED_VARS FFI_INCLUDE_DIR)
    return()
endif()

# if found, read ffi.h header for version
file(STRINGS ${FFI_INCLUDE_DIR}/ffi.h FFI_VERSION REGEX "^[ ]*libffi[ ]+[0-9.]+$")
# if failed, this is empty
if(NOT FFI_VERSION)
    message(WARNING "Unable to read libffi version from ffi.h")
    find_package_handle_standard_args(FFI REQUIRED_VARS FFI_VERSION)
    return()
endif()
# clean up by removing non-numeric components
string(REGEX REPLACE "([ ]*libffi[ ]+)([0-9.]+)" "\\2" FFI_VERSION "${FFI_VERSION}")

# find libffi library
find_library(FFI_LIBRARY ffi)
# stop early if not found
if(NOT FFI_LIBRARY)
    find_package_handle_standard_args(FFI REQUIRED_VARS FFI_LIBRARY)
    return()
endif()

# create imported target for library
add_library(FFI::ffi UNKNOWN IMPORTED)
set_target_properties(FFI::ffi PROPERTIES IMPORTED_LOCATION ${FFI_LIBRARY})
target_include_directories(FFI::ffi INTERFACE ${FFI_INCLUDE_DIR})

# report success (library variable goes first for visibility in message)
find_package_handle_standard_args(
    FFI
    REQUIRED_VARS FFI_LIBRARY FFI_INCLUDE_DIR
    VERSION_VAR FFI_VERSION
)
