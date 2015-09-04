######################### General ##########################

set(DOXYGEN_EXECUTABLE  "" CACHE FILEPATH "Doxygen path")
set(GIT_EXECUTABLE      "" CACHE FILEPATH "Git path (need for version number defining)")
set(HHC_EXECUTABLE      "" CACHE FILEPATH "HTML Help generator path")
set(QHG_EXECUTABLE      "" CACHE FILEPATH "QHP generator path")
set(QCOLGEN_EXECUTABLE  "" CACHE FILEPATH "Qt collection generator path")
set(PDFLATEX_EXECUTABLE "" CACHE FILEPATH "PDFLatex path")
set(CONVERT_EXECUTABLE  "" CACHE FILEPATH "ImageMagick convert utility")

if(EXISTS ${PROJECT_SOURCE_DIR}/cmake)
    list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)
endif(EXISTS ${PROJECT_SOURCE_DIR}/cmake)

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

if(CMAKE_COMPILER_IS_GNUCC)
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

if(NOT CPACK_PACKAGE_VERSION_MAJOR)
    set(CPACK_PACKAGE_VERSION_MAJOR "0")
endif()
if(NOT CPACK_PACKAGE_VERSION_MINOR)
    set(CPACK_PACKAGE_VERSION_MINOR "0")
endif()
if(NOT CPACK_PACKAGE_VERSION_PATCH)
    set(CPACK_PACKAGE_VERSION_PATCH "0")
endif()
if(NOT V_DATE)
    set(V_DATE "unknown_build")
endif()

if(NOT GIT_EXECUTABLE)
    unset(GIT_EXECUTABLE CACHE)
    find_program(GIT_EXECUTABLE git)
endif()

if(GIT_EXECUTABLE AND EXISTS ${CMAKE_SOURCE_DIR}/.git)

    execute_process(COMMAND ${GIT_EXECUTABLE} -C ${PROJECT_SOURCE_DIR} describe --tags --always
                    OUTPUT_VARIABLE VERSION)
    execute_process(COMMAND ${GIT_EXECUTABLE} -C ${PROJECT_SOURCE_DIR} log -n 1 --pretty=format:%ad --date=short
                    OUTPUT_VARIABLE V_DATE)
    if(VERSION)
        string(STRIP ${VERSION} VERSION)
        message(STATUS "Using git tag ${VERSION} as version number")
        string(REGEX REPLACE "[-.]" ";" VERSION ${VERSION})
        list(LENGTH VERSION VERSION_LENGTH)
        if(NOT ${VERSION_LENGTH} EQUAL 0)
            if(${VERSION_LENGTH} EQUAL 1)
                set(CPACK_PACKAGE_VERSION_MAJOR ${VERSION})
                set(V_VERSION ${VERSION})
            elseif(${VERSION_LENGTH} GREATER 1)
                list(GET VERSION 0 CPACK_PACKAGE_VERSION_MAJOR)
                list(GET VERSION 1 CPACK_PACKAGE_VERSION_MINOR)
                if(${VERSION_LENGTH} EQUAL 4)
                    list(GET VERSION 2 CPACK_PACKAGE_VERSION_PATCH)
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

else(GIT_EXECUTABLE)

    message(AUTHOR_WARNING "Git not found - version can not be defined")

endif()

#### Full version string
set(V_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}")
if(VERSION_STATUS)
    set(V_VERSION "${V_VERSION}-${VERSION_STATUS}")
endif()
if(${CPACK_PACKAGE_VERSION_PATCH} GREATER 0)
    set(V_VERSION "${V_VERSION}-${CPACK_PACKAGE_VERSION_PATCH}")
endif()

#### Writing versions header
string(TOUPPER ${CMAKE_PROJECT_NAME} NAME_UP)
string(REGEX REPLACE "[- ]" "_" NAME_UP ${NAME_UP})
file(WRITE ${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}_version.h
     "#ifndef ${NAME_UP}_VERSION_H\n#define ${NAME_UP}_VERSION_H\n\n"
     "#define VERSION_${NAME_UP} \"${V_VERSION}\"\n"
     "#define VER_DATE_${NAME_UP} \"${V_DATE}\"\n"
     "#define VER_PLATFORM_${NAME_UP} \"${CMAKE_SYSTEM_NAME}\"\n"
     "#define VER_ARCH_${NAME_UP} \"${COMPILED_ARCH}\"\n\n")


####################### CPack options ######################

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
    set(CPACK_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}_${V_VERSION}_${CMAKE_SYSTEM_NAME}_${COMPILER_NAME}_${COMPILED_ARCH}")
else()
    set(CPACK_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}_${V_VERSION}_${CMAKE_SYSTEM_NAME}_${COMPILED_ARCH}")
endif()

if(WIN32)
    set(CPACK_PACKAGE_INSTALL_DIRECTORY ${PROJECT_NAME})
    set(CPACK_PACKAGE_VERSION ${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR})
    if(CPACK_PACKAGE_VERSION_PATCH)
        set(CPACK_PACKAGE_VERSION ${CPACK_PACKAGE_VERSION}.${CPACK_PACKAGE_VERSION_PATCH})
    endif(CPACK_PACKAGE_VERSION_PATCH)
elseif(UNIX)
    set(CPACK_DEBIAN_PACKAGE_VERSION      ${V_VERSION})
    set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${COMPILED_ARCH})
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_FILE_NAME}_dbg")
else()
    set(CPACK_STRIP_FILES TRUE)
endif()
