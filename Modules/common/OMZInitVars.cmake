######################### Variables ########################

#### Project name upper
string(TOUPPER ${CMAKE_PROJECT_NAME} PROJECT_NAME_UPPER)
string(REGEX REPLACE "[- ]" "_" PROJECT_NAME_UPPER ${PROJECT_NAME_UPPER})

#### Build architecture
# 32 - 32bit, 64 - 64bit
set(ARCH "" CACHE STRING "Build x86 or x86-64 application")

#### Additional packages paths
set(DOXYGEN_EXECUTABLE  "" CACHE FILEPATH "Doxygen path")
set(GIT_EXECUTABLE      "" CACHE FILEPATH "Git path (need for version number defining)")
set(HHC_EXECUTABLE      "" CACHE FILEPATH "HTML Help generator path")
set(QHG_EXECUTABLE      "" CACHE FILEPATH "QHP generator path")
set(QCOLGEN_EXECUTABLE  "" CACHE FILEPATH "Qt collection generator path")
set(PDFLATEX_EXECUTABLE "" CACHE FILEPATH "PDFLatex path")
set(CONVERT_EXECUTABLE  "" CACHE FILEPATH "ImageMagick convert utility")

#### Architecture variable
get_property(${PROJECT_NAME_UPPER}_LANGUAGES GLOBAL PROPERTY ENABLED_LANGUAGES)
if(${PROJECT_NAME_UPPER}_LANGUAGES STREQUAL "NONE" AND NOT ARCH)
    set(COMPILED_ARCH "all")
endif()
if(NOT ARCH)
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(ARCH 64)
    else()
        set(ARCH 32)
    endif()
elseif(ARCH EQUAL 32)
    set(CMAKE_SIZEOF_VOID_P 4)
endif()
if(COMPILED_ARCH STREQUAL "all")
    message(STATUS "Configuring architecture independent version")
elseif(ARCH EQUAL 64)
    message(STATUS "Configuring 64 bit version")
    set(COMPILED_ARCH "amd64")
elseif(ARCH EQUAL 32)
    message(STATUS "Configuring 32 bit version")
    set(COMPILED_ARCH "i386")
endif()

#### Platform name
if(WIN32)
    set(CMAKE_SYSTEM_NAME "win${ARCH}")
endif()

#### Build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug")
endif()

#### Compiler flags
if(CMAKE_COMPILER_IS_GNUCC)
    if(${CMAKE_BUILD_TYPE} STREQUAL "Release")
        set(GCC_FLAGS "${GCC_FLAGS} -s")
    endif()
    if(WIN32 AND ARCH EQUAL 32)
        set(CMAKE_RC_FLAGS "-F pe-i386")
    endif()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${GCC_FLAGS} -m${ARCH}")
elseif(MSVC)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${MSVC_FLAGS}")
endif()
