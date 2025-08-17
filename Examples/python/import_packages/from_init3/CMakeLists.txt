cmake_minimum_required(VERSION ${CMAKE_MINIMUM_REQUIRED_VERSION})

# choose based on Python
if(SWIG_HAS_PYTHON3)
    set(subdir py3)
else()
    set(subdir py2)
endif()
# add example
swig_add_python_example(
    from_init3
    CXX
    INTERFACES ${subdir}/pkg2/bar.i ${subdir}/pkg2/pkg3/pkg4/foo.i
    OPTIONS -relativeimport
    # graft necessary files to build tree to replicate package structure. see
    # ../from_init1/CMakeLists.txt for more details
    GRAFT_FILES
        ${subdir}/__init__.py
        ${subdir}/pkg2/__init__.py
        ${subdir}/pkg2/pkg3/__init__.py
        ${subdir}/pkg2/pkg3/pkg4/__init__.py
        runme.py
    # indicate that the location of the test driver is in the build tree
    DRIVER_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}$<${SWIG_IS_MULTI_CONFIG}:/$<CONFIG>>
)
