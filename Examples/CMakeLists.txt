cmake_minimum_required(VERSION ${CMAKE_MINIMUM_REQUIRED_VERSION})

# find Lua
# TODO: may want some logic for minimum versions, etc.
message(CHECK_START "Looking for Lua")
find_package(Lua)
if(LUA_FOUND)
  message(CHECK_PASS "found")
else()
  message(CHECK_FAIL "not found")
endif()

# find JRE + JDK
message(CHECK_START "Looking for Java")
find_package(Java COMPONENTS Runtime Development)
if(Java_FOUND)
  message(CHECK_PASS "found ${Java_VERSION}")
else()
  message(CHECK_FAIL "not found")
endif()

# find JNI
# note: we don't care much about the JNI version since it has been pretty
# stable. you need to check jni.h for JNI_VERSION_* macros to determine exactly
# what the highest supported JNI version is
message(CHECK_START "Looking for JNI")
find_package(JNI)
if(JNI_FOUND)
  message(CHECK_PASS "found")
else()
  message(CHECK_FAIL "not found")
endif()
# need both JNI headers + JDK for Java
if(Java_FOUND AND JNI_FOUND)
  set(SWIG_HAS_JAVA TRUE)
else()
  set(SWIG_HAS_JAVA FALSE)
endif()

# find Python
# note: you generally can't have Python 2 and 3 active at the same time
message(CHECK_START "Looking for Python")
find_package(Python COMPONENTS Interpreter Development)
if(Python_FOUND)
  message(CHECK_PASS "found ${Python_VERSION}")
else()
  message(CHECK_FAIL "not found")
endif()
# indicate if Python 2 or 3; affects which examples/tests can be built
if(Python_VERSION GREATER_EQUAL 3)
  set(SWIG_HAS_PYTHON3 TRUE)
else()
  set(SWIG_HAS_PYTHON3 FALSE)
endif()

# add examples
if(LUA_FOUND)
  # add_subdirectory(lua)
else()
  message(STATUS "Skipping Lua examples")
endif()
if(SWIG_HAS_JAVA)
  # add_subdirectory(java)
else()
  message(STATUS "Skipping Java examples")
endif()
if(Python_FOUND)
  add_subdirectory(python)
else()
  message(STATUS "Skipping Python examples")
endif()

# add test suite
if(SWIG_BUILD_TESTS)
  add_subdirectory(test-suite)
else()
  message(STATUS "Skipping SWIG test suite")
endif()
