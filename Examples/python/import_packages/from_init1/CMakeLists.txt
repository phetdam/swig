cmake_minimum_required(VERSION ${CMAKE_MINIMUM_REQUIRED_VERSION})

# choose based on Python
if(SWIG_HAS_PYTHON3)
    set(subdir py3)
else()
    set(subdir py2)
endif()
# add example
swig_add_python_example(
    from_init1
    CXX
    INTERFACES ${subdir}/pkg2/bar.i ${subdir}/pkg2/foo.i
    OPTIONS -relativeimport
    # graft necessary files to build tree to replicate package structure. we
    # also need to copy the test driver since Python *always* prefers to check
    # the directory of the running Python script first for imports. we cannot
    # tell Python to stop looking in the script directory until Python 3.11,
    # where the -P option was added to ignore unsafe import directories.
    GRAFT_FILES ${subdir}/__init__.py ${subdir}/pkg2/__init__.py runme.py
    # indicate that the location of the test driver is in the build tree
    DRIVER_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}$<${SWIG_IS_MULTI_CONFIG}:/$<CONFIG>>
)
