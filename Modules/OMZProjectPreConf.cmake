######################### General ##########################

if(EXISTS ${PROJECT_SOURCE_DIR}/cmake)
    list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)
endif()

include_directories(${CMAKE_BINARY_DIR})

if(NOT ARCH)
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(ARCH 64)
    else()
        set(ARCH 32)
    endif()
elseif(ARCH EQUAL 32)
    set(CMAKE_SIZEOF_VOID_P 4)
endif()

if(WIN32)
    set(CMAKE_SYSTEM_NAME "win${ARCH}")
endif()


################ Architecture and compiler #################

if(NOT DEFINED CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug")
endif()

if(CMAKE_COMPILER_IS_GNUCC)
    if(${CMAKE_BUILD_TYPE} STREQUAL "Release")
        set(GCC_FLAGS "${GCC_FLAGS} -s")
    endif()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${GCC_FLAGS} -m${ARCH}")
endif()

if(NOT COMPILED_ARCH)
    if(ARCH EQUAL 64)
        message(STATUS "Configuring 64 bit version")
        set(COMPILED_ARCH "amd64")
    elseif(ARCH EQUAL 32)
        message(STATUS "Configuring 32 bit version")
        set(COMPILED_ARCH "i386")
        if(WIN32 AND CMAKE_COMPILER_IS_GNUCC)
            set(CMAKE_RC_FLAGS "-F pe-i386")
        endif()
    endif()
else()
    message(STATUS "Configuring architecture independent version")
endif()


######################## Versions ##########################

if(NOT GIT_EXECUTABLE)
    unset(GIT_EXECUTABLE CACHE)
    find_program(GIT_EXECUTABLE git)
endif()

if(GIT_EXECUTABLE AND EXISTS ${CMAKE_SOURCE_DIR}/.git AND VERSION_FROM_GIT)

    execute_process(COMMAND ${GIT_EXECUTABLE} -C ${PROJECT_SOURCE_DIR} describe --tags --always
                    OUTPUT_VARIABLE VERSION)
    execute_process(COMMAND ${GIT_EXECUTABLE} -C ${PROJECT_SOURCE_DIR} log -n 1 --pretty=format:%ad --date=short
                    OUTPUT_VARIABLE ${CMAKE_PROJECT_NAME_UPPER}_VERSION_DATE)
    if(VERSION)
        string(STRIP ${VERSION} VERSION)
        message(STATUS "Using git tag ${VERSION} as version number")
        string(REGEX REPLACE "[-.]" ";" VERSION ${VERSION})
        list(LENGTH VERSION VERSION_LENGTH)
        if(NOT ${VERSION_LENGTH} EQUAL 0)
            if(${VERSION_LENGTH} EQUAL 1)
                set(${CMAKE_PROJECT_NAME_UPPER}_VERSION_MAJOR ${VERSION})
                set(${CMAKE_PROJECT_NAME_UPPER}_VERSION_STRING ${VERSION})
            elseif(${VERSION_LENGTH} GREATER 1)
                list(GET VERSION 0 ${CMAKE_PROJECT_NAME_UPPER}_VERSION_MAJOR)
                list(GET VERSION 1 ${CMAKE_PROJECT_NAME_UPPER}_VERSION_MINOR)
                if(${VERSION_LENGTH} EQUAL 4)
                    list(GET VERSION 2 ${CMAKE_PROJECT_NAME_UPPER}_VERSION_PATCH)
                endif()
            endif()
        endif()
    endif()

    #### File versions

    file(REMOVE ${CMAKE_BINARY_DIR}/sources.h)
    file(GLOB_RECURSE S_FILES RELATIVE ${PROJECT_SOURCE_DIR} ${PROJECT_SOURCE_DIR}/src/*)
    foreach(FILE ${S_FILES})
        execute_process(COMMAND ${GIT_EXECUTABLE} -C ${PROJECT_SOURCE_DIR} log -n 1 --pretty=format:%ci ${FILE} OUTPUT_VARIABLE F_DATE)
        if(NOT ${F_DATE} MATCHES "/\\b(fatal)\\b/i")
            string(STRIP ${F_DATE} F_DATE)
            execute_process(COMMAND ${GIT_EXECUTABLE} -C ${PROJECT_SOURCE_DIR} log -n 1 --pretty=format:%h ${FILE} OUTPUT_VARIABLE F_VERSION)
            string(STRIP ${F_VERSION} F_VERSION)
            file(APPEND ${CMAKE_BINARY_DIR}/sources.h
                 "/**\n * @file ${FILE}\n * @version ${F_VERSION}\n * @date ${F_DATE}\n */\n\n")
        endif()
    endforeach()

else()

    if(NOT GIT_EXECUTABLE)
        message(AUTHOR_WARNING "Git is not found - version can not be defined")
    elseif(NOT EXISTS ${CMAKE_SOURCE_DIR}/.git)
        message(AUTHOR_WARNING "No .git folder - version can not be defined")
    endif()

endif()

#### Full version string
set(${CMAKE_PROJECT_NAME_UPPER}_VERSION_STRING
    "${${CMAKE_PROJECT_NAME_UPPER}_VERSION_MAJOR}.${${CMAKE_PROJECT_NAME_UPPER}_VERSION_MINOR}")
if(${CMAKE_PROJECT_NAME_UPPER}_VERSION_STATUS)
    set(${CMAKE_PROJECT_NAME_UPPER}_VERSION_STRING
        "${${CMAKE_PROJECT_NAME_UPPER}_VERSION_STRING}-${${CMAKE_PROJECT_NAME_UPPER}_VERSION_STATUS}")
endif()
if(${${CMAKE_PROJECT_NAME_UPPER}_VERSION_PATCH})
    set(${CMAKE_PROJECT_NAME_UPPER}_VERSION_STRING
        "${${CMAKE_PROJECT_NAME_UPPER}_VERSION_STRING}-${${CMAKE_PROJECT_NAME_UPPER}_VERSION_PATCH}")
endif()

if(NOT VERSION_FROM_GIT)
    message(STATUS "Using manually defined version ${VERSION}")
endif()

#### Version definitions
add_definitions(-DVERSION_${CMAKE_PROJECT_NAME_UPPER}_MAJOR=${${CMAKE_PROJECT_NAME_UPPER}_VERSION_MAJOR}
                -DVERSION_${CMAKE_PROJECT_NAME_UPPER}_MINOR=${${CMAKE_PROJECT_NAME_UPPER}_VERSION_MINOR}
                -DVERSION_${CMAKE_PROJECT_NAME_UPPER}_STRING="${${CMAKE_PROJECT_NAME_UPPER}_VERSION_STRING}"
                -DVERSION_${CMAKE_PROJECT_NAME_UPPER}_DATE="${${CMAKE_PROJECT_NAME_UPPER}_VERSION_DATE}"
                -DVERSION_${CMAKE_PROJECT_NAME_UPPER}_OS="${CMAKE_SYSTEM_NAME}"
                -DVERSION_${CMAKE_PROJECT_NAME_UPPER}_ARCH="${COMPILED_ARCH}"
)
if(DEFINED ${CMAKE_PROJECT_NAME_UPPER}_VERSION_PATCH)
    add_definitions(-DVERSION_${CMAKE_PROJECT_NAME_UPPER}_PATCH=${${CMAKE_PROJECT_NAME_UPPER}_VERSION_PATCH})
else()
    add_definitions(-DVERSION_${CMAKE_PROJECT_NAME_UPPER}_PATCH=0)
endif()


####################### CPack options ######################

#### Version
if(NOT CPACK_PACKAGE_VERSION_MAJOR)
    set(CPACK_PACKAGE_VERSION_MAJOR ${${CMAKE_PROJECT_NAME_UPPER}_VERSION_MAJOR})
endif()
if(NOT CPACK_PACKAGE_VERSION_MINOR)
    set(CPACK_PACKAGE_VERSION_MINOR ${${CMAKE_PROJECT_NAME_UPPER}_VERSION_MINOR})
endif()
if(NOT CPACK_PACKAGE_VERSION_PATCH)
    set(CPACK_PACKAGE_VERSION_PATCH ${${CMAKE_PROJECT_NAME_UPPER}_VERSION_PATCH})
endif()

set(CPACK_RESOURCE_FILE_LICENSE ${CMAKE_BINARY_DIR}/doc/LICENSE.txt)
file(REMOVE ${CPACK_RESOURCE_FILE_LICENSE})
file(GLOB LICENSE_FILES RELATIVE ${CMAKE_SOURCE_DIR} ${PROJECT_SOURCE_DIR}/LICENSE*)
list(FIND LICENSE_FILES LICENSE.${PROJECT_NAME}.txt IND)
list(GET LICENSE_FILES ${IND} FILE)
file(READ ${FILE} LICENSE_TEXT)
string(REPLACE "." ";" FILE ${FILE})
list(GET FILE 1 FILE)
file(APPEND ${CPACK_RESOURCE_FILE_LICENSE} "Contents:\n1) ${FILE}\n")
set(FULL_LICENSE_TEXT "1) ${FILE} license:\n${LICENSE_TEXT}\n\n")
list(REMOVE_AT LICENSE_FILES ${IND})
set(IND 2)
foreach(FILE ${LICENSE_FILES})
    file(READ ${FILE} LICENSE_TEXT)
    string(REPLACE "." ";" FILE ${FILE})
    list(GET FILE 1 FILE)
    set(FULL_LICENSE_TEXT "${FULL_LICENSE_TEXT}${IND}) ${FILE} license:\n${LICENSE_TEXT}\n\n")
    file(APPEND ${CPACK_RESOURCE_FILE_LICENSE} "${IND}) ${FILE}\n")
    math(EXPR IND "${IND} + 1")
endforeach()
file(APPEND ${CPACK_RESOURCE_FILE_LICENSE} "\n\n${FULL_LICENSE_TEXT}")

message(STATUS "For building packages use \"cpack -G <GENERATOR_NAME>\"")
set(CPACK_PACKAGE_NAME ${PROJECT_NAME})

if(NOT ${COMPILED_ARCH} STREQUAL "all")
    string(TOLOWER "${CMAKE_CXX_COMPILER_ID}${CMAKE_CXX_COMPILER_VERSION}" COMPILER_NAME)
    string(REPLACE "." "" COMPILER_NAME ${COMPILER_NAME})
    set(CPACK_PACKAGE_FILE_NAME
        "${CMAKE_PROJECT_NAME}_${${CMAKE_PROJECT_NAME_UPPER}_VERSION_STRING}_${CMAKE_SYSTEM_NAME}_${COMPILER_NAME}_${COMPILED_ARCH}")
else()
    set(CPACK_PACKAGE_FILE_NAME
        "${CMAKE_PROJECT_NAME}_${${CMAKE_PROJECT_NAME_UPPER}_VERSION_STRING}_${CMAKE_SYSTEM_NAME}_${COMPILED_ARCH}")
endif()

if(WIN32)
    set(CPACK_PACKAGE_INSTALL_DIRECTORY ${PROJECT_NAME})
    set(CPACK_PACKAGE_VERSION ${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR})
    if(CPACK_PACKAGE_VERSION_PATCH)
        set(CPACK_PACKAGE_VERSION ${CPACK_PACKAGE_VERSION}.${CPACK_PACKAGE_VERSION_PATCH})
    endif()
elseif(UNIX)
    set(CPACK_DEBIAN_PACKAGE_VERSION      ${${CMAKE_PROJECT_NAME_UPPER}_VERSION_STRING})
    set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${COMPILED_ARCH})
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_FILE_NAME}_dbg")
else()
    set(CPACK_STRIP_FILES TRUE)
endif()
