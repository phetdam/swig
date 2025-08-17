cmake_minimum_required(VERSION ${CMAKE_MINIMUM_REQUIRED_VERSION})

# list of import_packages sub-examples
# TODO: incomplete
set(py_import_packages_examples from_init1 from_init2 from_init3 module_is_init)
# add each sub-example
foreach(example ${py_import_packages_examples})
    add_subdirectory(${example})
endforeach()
