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

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug")
endif()

if(CMAKE_COMPILER_IS_GNUCC)
    if(${CMAKE_BUILD_TYPE} STREQUAL "Release")
        set(GCC_FLAGS "${GCC_FLAGS} -s")
    endif()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${GCC_FLAGS} -m${ARCH}")
elseif(MSVC)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${MSVC_FLAGS}")
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

if(VERSION_FROM_GIT AND EXISTS ${CMAKE_SOURCE_DIR}/.git)

    if(NOT GIT_EXECUTABLE)
        unset(GIT_EXECUTABLE CACHE)
        find_program(GIT_EXECUTABLE git)
    endif()
    if(GIT_EXECUTABLE)

        unset(${PROJECT_NAME_UPPER}_VERSION_MAJOR CACHE)
        unset(${PROJECT_NAME_UPPER}_VERSION_MINOR CACHE)
        unset(${PROJECT_NAME_UPPER}_VERSION_PATCH CACHE)
        unset(${PROJECT_NAME_UPPER}_VERSION_DATE  CACHE)

        execute_process(COMMAND ${GIT_EXECUTABLE} -C ${PROJECT_SOURCE_DIR} describe --tags --always
                        OUTPUT_VARIABLE VERSION)
        execute_process(COMMAND ${GIT_EXECUTABLE} -C ${PROJECT_SOURCE_DIR} log -n 1 --pretty=format:%ad --date=short
                        OUTPUT_VARIABLE ${PROJECT_NAME_UPPER}_VERSION_DATE)
        if(VERSION)
            string(STRIP ${VERSION} VERSION)
            message(STATUS "Using git tag ${VERSION} as version number")
            string(REGEX REPLACE "[-.]" ";" VERSION ${VERSION})
            list(LENGTH VERSION VERSION_LENGTH)
            if(NOT ${VERSION_LENGTH} EQUAL 0)
                if(${VERSION_LENGTH} EQUAL 1)
                    set(${PROJECT_NAME_UPPER}_VERSION_MAJOR ${VERSION})
                elseif(${VERSION_LENGTH} GREATER 1)
                    list(GET VERSION 0 ${PROJECT_NAME_UPPER}_VERSION_MAJOR)
                    list(GET VERSION 1 ${PROJECT_NAME_UPPER}_VERSION_MINOR)
                    if(${VERSION_LENGTH} EQUAL 4)
                        list(GET VERSION 2 ${PROJECT_NAME_UPPER}_VERSION_PATCH)
                    endif()
                endif()
            endif()
        endif()

        set_project_version(MAJOR  ${${PROJECT_NAME_UPPER}_VERSION_MAJOR}
                            MINOR  ${${PROJECT_NAME_UPPER}_VERSION_MINOR}
                            PATCH  ${${PROJECT_NAME_UPPER}_VERSION_PATCH}
                            DATE   ${${PROJECT_NAME_UPPER}_VERSION_DATE}
                            STATUS ${${PROJECT_NAME_UPPER}_VERSION_STATUS})

    else()
        message(AUTHOR_WARNING "Git is not found - version can not be defined")
    endif()

elseif(VERSION_FROM_GIT AND NOT EXISTS ${CMAKE_SOURCE_DIR}/.git)
    message(AUTHOR_WARNING "No .git folder - version can not be defined")
endif()

if(NOT VERSION_FROM_GIT)
    message(STATUS "Using manually defined version ${VERSION}")
endif()

#### Version definitions
file(WRITE ${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}_version.h
        "#ifndef VERSION_${PROJECT_NAME_UPPER}\n#define VERSION_${PROJECT_NAME_UPPER}\n\n"
        "#define VERSION_${PROJECT_NAME_UPPER}_MAJOR  ${${PROJECT_NAME_UPPER}_VERSION_MAJOR}\n"
        "#define VERSION_${PROJECT_NAME_UPPER}_MINOR  ${${PROJECT_NAME_UPPER}_VERSION_MINOR}\n"
        "#define VERSION_${PROJECT_NAME_UPPER}_PATCH  ${${PROJECT_NAME_UPPER}_VERSION_PATCH}\n"
        "#define VERSION_${PROJECT_NAME_UPPER}_STRING \"${${PROJECT_NAME_UPPER}_VERSION_STRING}\"\n"
        "#define VERSION_${PROJECT_NAME_UPPER}_DATE   \"${${PROJECT_NAME_UPPER}_VERSION_DATE}\"\n"
        "#define VERSION_${PROJECT_NAME_UPPER}_OS     \"${CMAKE_SYSTEM_NAME}\"\n"
        "#define VERSION_${PROJECT_NAME_UPPER}_ARCH   \"${COMPILED_ARCH}\"\n"
)
if(DEFINED ${PROJECT_NAME_UPPER}_VERSION_PATCH)
    add_definitions(-DVERSION_${PROJECT_NAME_UPPER}_PATCH=${${PROJECT_NAME_UPPER}_VERSION_PATCH})
else()
    add_definitions(-DVERSION_${PROJECT_NAME_UPPER}_PATCH=0)
endif()


####################### CPack options ######################

#### Version
if(NOT DEFINED CPACK_PACKAGE_VERSION_MAJOR)
    set(CPACK_PACKAGE_VERSION_MAJOR ${${PROJECT_NAME_UPPER}_VERSION_MAJOR})
endif()
if(NOT DEFINED CPACK_PACKAGE_VERSION_MINOR)
    set(CPACK_PACKAGE_VERSION_MINOR ${${PROJECT_NAME_UPPER}_VERSION_MINOR})
endif()
if(NOT DEFINED CPACK_PACKAGE_VERSION_PATCH)
    set(CPACK_PACKAGE_VERSION_PATCH ${${PROJECT_NAME_UPPER}_VERSION_PATCH})
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
        "${CMAKE_PROJECT_NAME}_${${PROJECT_NAME_UPPER}_VERSION_STRING}_${CMAKE_SYSTEM_NAME}_${COMPILER_NAME}_${COMPILED_ARCH}")
else()
    set(CPACK_PACKAGE_FILE_NAME
        "${CMAKE_PROJECT_NAME}_${${PROJECT_NAME_UPPER}_VERSION_STRING}_${CMAKE_SYSTEM_NAME}_${COMPILED_ARCH}")
endif()

if(WIN32)
    set(CPACK_PACKAGE_INSTALL_DIRECTORY ${PROJECT_NAME})
    set(CPACK_PACKAGE_VERSION ${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR})
    if(CPACK_PACKAGE_VERSION_PATCH)
        set(CPACK_PACKAGE_VERSION ${CPACK_PACKAGE_VERSION}.${CPACK_PACKAGE_VERSION_PATCH})
    endif()
elseif(UNIX)
    set(CPACK_DEBIAN_PACKAGE_VERSION      ${${PROJECT_NAME_UPPER}_VERSION_STRING})
    set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${COMPILED_ARCH})
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_FILE_NAME}_dbg")
else()
    set(CPACK_STRIP_FILES TRUE)
endif()

if(CPACK_DOWNLOAD_ALL)
    set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_FILE_NAME}_online")
endif()
