# Include guard
if(OMZFUNCTIONS_INCLUDED)
    return()
endif()
set(OMZFUNCTIONS_INCLUDED 1)


# Find Git helper
macro(__check_git_executable)
    find_program(GIT_EXECUTABLE git COMMENT "Git executable")
    if(NOT GIT_EXECUTABLE)
        message(WARNING "The Git executable was not found. Make sure Git is in your system path, or explicitly set GIT_EXECUTABLE.")
        return()
    endif()
endmacro()


# Get version from git tag
function(omz_git_version_tag OUTPUT)

    if(DEFINED ${OUTPUT})
        return()
    endif()

    __check_git_executable(TRUE)

    execute_process(
        COMMAND ${GIT_EXECUTABLE} -C ${CMAKE_CURRENT_LIST_DIR} describe --tags --always
        RESULT_VARIABLE RESULT
        OUTPUT_VARIABLE VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(NOT RESULT EQUAL 0)
        return()
    endif()

    if(VERSION MATCHES "v[0-9].*")
        string(REGEX REPLACE "-g[0-9,abcdef]*" "" VERSION ${VERSION})
        string(LENGTH ${VERSION} VERSION_LENGTH)
        string(SUBSTRING ${VERSION} 1 ${VERSION_LENGTH} VERSION)
        string(REPLACE "-" ";" VERSION ${VERSION})
        list(LENGTH VERSION VERSION_LENGTH)
        if(VERSION_LENGTH EQUAL 2)
            list(GET VERSION 1 VERSION_TWEAK)
            list(GET VERSION 0 VERSION)
            string(REPLACE "." ";" VERSION ${VERSION})
            list(LENGTH VERSION VERSION_LENGTH)
            math(EXPR LENGTH_DIFF "3 - ${VERSION_LENGTH}")
            if(LENGTH_DIFF GREATER 0)
                foreach(ITER RANGE 1 ${LENGTH_DIFF})
                    list(APPEND VERSION "0")
                endforeach()
            endif()
            list(APPEND VERSION ${VERSION_TWEAK})
            string(REPLACE ";" "." VERSION "${VERSION}")
        endif()
    else()
        message(WARNING "Unknown git tag format '${VERSION}', expected something like 'v1.0-10'")
        unset(VERSION)
    endif()

    if(NOT VERSION)
        set(VERSION "0.0")
    endif()

    set(${OUTPUT} ${VERSION} CACHE STRING "The ${OUTPUT} value")

endfunction()


# Get version date from git tag
function(omz_git_version_tag_date OUTPUT)

    if(DEFINED ${OUTPUT})
        return()
    endif()

    __check_git_executable(TRUE)

    execute_process(
        COMMAND ${GIT_EXECUTABLE} -C ${CMAKE_CURRENT_LIST_DIR} log -n 1 --pretty=format:%ad --date=short
        OUTPUT_VARIABLE VERSION_DATE
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(NOT VERSION_DATE)
        set(VERSION_DATE "unknown_date")
    endif()

    set(${OUTPUT} ${VERSION_DATE} CACHE STRING "The ${OUTPUT} value")

endfunction()


# Add changelog target
function(omz_add_changelog_target TARGET_NAME)

    __check_git_executable(TRUE)

    #### Get the last tag name
    execute_process(
        COMMAND "${GIT_EXECUTABLE}" describe --abbrev=0 --tags
        WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}"
        RESULT_VARIABLE   RESULT
        OUTPUT_VARIABLE   LAST_TAG
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(NOT RESULT EQUAL 0)
        return()
    endif()

    #### Print log
    add_custom_target(${TARGET_NAME}
        COMMAND "${GIT_EXECUTABLE}" log "${LAST_TAG}.." "--pretty=  - %s"
        WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}"
        COMMENT "Changes from the '${LAST_TAG}' tag:"
    )

endfunction()


# Target architecture
# Based on https://github.com/civetweb/civetweb/blob/master/cmake/DetermineTargetArchitecture.cmake
function(omz_target_architecture OUTPUT)
    if(${OUTPUT})
        return()
    endif()

    get_property(_LANGUAGES GLOBAL PROPERTY ENABLED_LANGUAGES)
    if(_LANGUAGES STREQUAL "NONE")
        set(_ARCH all)
    elseif(MSVC)
        if(MSVC_C_ARCHITECTURE_ID STREQUAL "X86")
            set(_ARCH "i686")
        elseif(MSVC_C_ARCHITECTURE_ID STREQUAL "x64")
            set(_ARCH "x86_64")
        elseif(MSVC_C_ARCHITECTURE_ID STREQUAL "ARM")
            set(_ARCH "arm")
        else()
            message(FATAL_ERROR "Failed to determine the MSVC target architecture: ${MSVC_C_ARCHITECTURE_ID}")
        endif()
    else()
        execute_process(
            COMMAND ${CMAKE_C_COMPILER} -dumpmachine
            RESULT_VARIABLE _RESULT
            OUTPUT_VARIABLE _ARCH
            ERROR_QUIET
        )
        if(NOT _RESULT EQUAL 0)
            message(FATAL_ERROR "Failed to determine target architecture triplet")
        endif()
        string(REGEX MATCH "([^-]+).*" _ARCH_MATCH ${_ARCH})
        if(NOT CMAKE_MATCH_1 OR NOT _ARCH_MATCH)
            message(FATAL_ERROR "Failed to match the target architecture triplet: ${TARGET_ARCHITECTURE}")
        endif()
        set(_ARCH ${CMAKE_MATCH_1})
    endif()

    message(STATUS "Target architecture - ${_ARCH}")
    set(${OUTPUT} ${_ARCH} CACHE STRING "Target architecture")

endfunction()


# Remove C/CPP comments from file
function(omz_remove_comments SRC_FILE DST_FILE)
    file(READ ${SRC_FILE} SRC_CONTENT)
    string(REPLACE "\\" "__CMAKE_SLASH__" SRC_CONTENT "${SRC_CONTENT}")
    string(REPLACE ";" "__CMAKE_NEWLINE__" SRC_CONTENT "${SRC_CONTENT}")
    string(REPLACE "\n" ";" SRC_CONTENT ${SRC_CONTENT})
    foreach(SRC_STRING ${SRC_CONTENT})
        if(SRC_STRING MATCHES ".*\\/\\*.*\\*\\/.*")
            string(REGEX REPLACE "[ ]*\\/\\*.*\\*\\/[ ]*" " " SRC_STRING ${SRC_STRING})
        elseif(SRC_STRING MATCHES ".*\\/\\*.*")
            set(MULTILINE_COMMENT TRUE)
            string(REGEX REPLACE "[ ]*\\/\\*.*" "" SRC_STRING ${SRC_STRING})
        elseif(SRC_STRING MATCHES ".*\\*\\/.*" AND MULTILINE_COMMENT)
            set(MULTILINE_COMMENT FALSE)
            string(REGEX REPLACE ".*\\*\\/[ ]*" "" SRC_STRING ${SRC_STRING})
        elseif(NOT MULTILINE_COMMENT)
            string(REGEX REPLACE "[ ]*\\/\\/.*" "" SRC_STRING ${SRC_STRING})
        else()
            unset(SRC_STRING)
        endif()
        if(SRC_STRING)
            set(DST_OUTPUT "${DST_OUTPUT}${SRC_STRING}\n")
        endif()
    endforeach()
    string(REPLACE "__CMAKE_SLASH__" "\\" DST_OUTPUT ${DST_OUTPUT})
    string(REPLACE "__CMAKE_NEWLINE__" ";" DST_OUTPUT ${DST_OUTPUT})
    file(WRITE ${DST_FILE} "${DST_OUTPUT}")
endfunction()


# Read description file for debian packages
function(omz_read_debian_description)

    cmake_parse_arguments("INPUT" "FILE" "" "" ${ARGN})
    if(NOT INPUT_FILE)
        if(CPACK_PACKAGE_DESCRIPTION_FILE)
            set(INPUT_FILE ${CPACK_PACKAGE_DESCRIPTION_FILE})
        else()
            message(AUTHOR_WARNING "You must specify 'FILE' argument or set 'CPACK_PACKAGE_DESCRIPTION_SUMMARY' variable")
        endif()
    endif()

    if(EXISTS ${INPUT_FILE})
        file(STRINGS ${INPUT_FILE} PACKAGE_DESCRIPTION)
        foreach(STRING ${PACKAGE_DESCRIPTION})
            string(REPLACE "\"" "\\\"" STRING ${STRING})
            set(CPACK_DEBIAN_PACKAGE_DESCRIPTION "${CPACK_DEBIAN_PACKAGE_DESCRIPTION} ${STRING}\n")
        endforeach()
        set(CPACK_DEBIAN_PACKAGE_DESCRIPTION ${CPACK_DEBIAN_PACKAGE_DESCRIPTION} PARENT_SCOPE)
    else()
        message(WARNING "Description file '${INPUT_FILE}' does not exist")
    endif()
endfunction()


# Get definitions
function(omz_get_defenition HEADER DEFENITION INCLUDE_DIRECTORIES OUTPUT_VARIABLE)

    if(DEFINED ${OUTPUT_VARIABLE})
        return()
    endif()

    set(MSG "Get ${DEFENITION} from ${HEADER}")
    message(STATUS "${MSG}")

    set(WORKING_DIR "${CMAKE_BINARY_DIR}")
    string(REGEX REPLACE "[\\\\]\\\\[!\\\"#$%&'()*+,:;<=>?@\\\\^`{|}~]" "_" FILE_NAME ${OUTPUT_VARIABLE})
    set(SOURCE "${WORKING_DIR}/${FILE_NAME}.c")
    if(INCLUDE_DIRECTORIES)
        set(CMAKE_FLAGS CMAKE_FLAGS -DINCLUDE_DIRECTORIES=${INCLUDE_DIRECTORIES})
    endif()

    file(WRITE "${SOURCE}" "\
#include <stdio.h>
#include <${HEADER}>
int main()
{
    printf(${DEFENITION});
    return 0;
}")

    try_run(RUN_RESULT COMPILE_RESULT
        "${WORKING_DIR}" "${SOURCE}"
        ${CMAKE_FLAGS}
        RUN_OUTPUT_VARIABLE RUN_OUTPUT
    )

    file(REMOVE "${SOURCE}")

    if(RUN_RESULT EQUAL 0 AND COMPILE_RESULT)
        message(STATUS "${MSG} - \"${RUN_OUTPUT}\"")
    else()
        message(STATUS "${MSG} - failed")
    endif()

    set(${OUTPUT_VARIABLE} ${RUN_OUTPUT} CACHE STRING "${DEFENITION} definition from ${HEADER}")

endfunction()


# Combine license files to a single one
function(omz_configure_single_license_file OUTPUT_FILE)

    if(NOT EXISTS "${OUTPUT_FILE}")

        cmake_parse_arguments("INPUT" "" "" "FILE" ${ARGN})

        if(NOT INPUT_FILE)
            message(FATAL_ERROR "No license files provided")
            return()
        endif()

        list(LENGTH INPUT_FILE INPUT_FILE_LENGTH)
        math(EXPR INPUT_FILE_ARE_ODD "${INPUT_FILE_LENGTH} % 2")
        if(INPUT_FILE_ARE_ODD)
            message(FATAL_ERROR "Input must be 'FILE <caption> <file>'")
        endif()
        math(EXPR INPUT_FILE_LENGTH "${INPUT_FILE_LENGTH} / 2")

        set(IND 1)
        set(CAPTION_IND 0)
        set(FILE_IND 1)
        while(NOT IND GREATER INPUT_FILE_LENGTH)
            list(GET INPUT_FILE ${CAPTION_IND} CAPTION)
            list(GET INPUT_FILE ${FILE_IND} FILE)
            file(READ "${FILE}" LICENSE_TEXT)
            set(CONTENTS "${CONTENTS}${IND}) ${CAPTION}\n")
            set(FULL_LICENSE_TEXT "${FULL_LICENSE_TEXT}${IND}) ${CAPTION}:\n${LICENSE_TEXT}\n\n")
            math(EXPR IND "${IND} + 1")
            math(EXPR CAPTION_IND "${CAPTION_IND} + 2")
            math(EXPR FILE_IND "${FILE_IND} + 2")
        endwhile()
        file(WRITE ${OUTPUT_FILE} "Contents:\n${CONTENTS}\n\n${FULL_LICENSE_TEXT}")

    endif()

endfunction()


# Windows RC file
function(omz_configure_rcfile FILE)

    set(_VER_VARS
        COMPANYNAME
        FILEDESCRIPTION
        FILEVERSION
        PRODUCTVERSION
        INTERNALNAME
        LEGALCOPYRIGHT
        ORIGINALFILENAME
        PRODUCTNAME
    )

    cmake_parse_arguments("IDI" "" "ICON"         "" ${ARGN})
    cmake_parse_arguments("RC"  "" "VERSION"      "" ${ARGN})
    cmake_parse_arguments("VER" "" "${_VER_VARS}" "" ${ARGN})

    # Checking icons
    if(IDI_ICON)
        set(IDI_ICON "IDI_ICON1 ICON DISCARDABLE \"${IDI_ICON}\"\n")
    endif()

    # Checking versions
    if(NOT RC_VERSION)
        set(RC_VERSION             ${PROJECT_VERSION})
    endif()
    if(NOT VER_FILEVERSION)
        set(VER_FILEVERSION_STR    ${RC_VERSION})
    endif()
    if(NOT VER_PRODUCTVERSION)
        set(VER_PRODUCTVERSION_STR ${RC_VERSION})
    endif()
    string(REGEX REPLACE "[.-]" "," RC_VERSION         ${RC_VERSION})
    string(REGEX REPLACE "[.-]" "," VER_FILEVERSION    ${VER_FILEVERSION_STR})
    string(REGEX REPLACE "[.-]" "," VER_PRODUCTVERSION ${VER_PRODUCTVERSION_STR})

    configure_file("${OMZModules_PATH}/Templates/windows.rc.in"
                   "${FILE}")

endfunction()


# Generate package name
function(omz_generate_package_name OUTPUT)

    get_property(LANGUAGES GLOBAL PROPERTY ENABLED_LANGUAGES)

    if(LANGUAGES STREQUAL "NONE")
        set(TARGET "all")
    else()
        if(MSVC)
            string(TOLOWER "msvc${MSVC_VERSION}" TARGET)
        else()
            string(TOLOWER "${CMAKE_CXX_COMPILER_ID}${CMAKE_CXX_COMPILER_VERSION}" TARGET)
        endif()
        string(REPLACE "." "" TARGET "${TARGET}")
        set(TARGET "${TARGET}_${CMAKE_CXX_COMPILER_TARGET}")
    endif()

    if(CPACK_DOWNLOAD_ALL)
        set(POSTFIX "_online")
    endif()

    if(NOT CMAKE_BUILD_TYPE OR CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(POSTFIX "${POSTFIX}_dbg")
    endif()

    string(TOLOWER
        "${CMAKE_PROJECT_NAME}_${CPACK_PACKAGE_VERSION}_${TARGET}${POSTFIX}"
        _OUTPUT
    )
    set(${OUTPUT} "${_OUTPUT}" PARENT_SCOPE)

endfunction()


# Uninstall target
function(omz_add_uninstall_target)
    configure_file(
        "${OMZModules_PATH}/Templates/cmake_uninstall.cmake.in"
        "${CMAKE_BINARY_DIR}/cmake_uninstall.cmake"
        @ONLY
    )
    add_custom_target(uninstall
        COMMAND ${CMAKE_COMMAND} -P cmake_uninstall.cmake
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    )
endfunction()


# Add QtIFW component translations at configure time
function(omz_ifw_add_translation IFW_QM_FILES IFW_TS_FILES)
    if(NOT Qt5LinguistTools_FOUND)
        message(WARNING "Qt Linguist tools not found, IFW translations not generated")
        return()
    endif()

    foreach(TS ${IFW_TS_FILES})
        get_filename_component(TS_NAME ${TS} NAME_WE)
        if(NOT TS_NAME MATCHES "^[a-z][a-z](_[A-Z][A-Z])?$")
            message(FATAL_ERROR
                "Invalid IFW translation file name \"${TS_NAME}\" - "
                "must be <lang>[_COUNTRY].ts"
            )
        endif()
        get_property(QT5_LRELEASE TARGET Qt5::lrelease PROPERTY IMPORTED_LOCATION)
        get_source_file_property(OUTPUT_LOCATION ${TS} OUTPUT_LOCATION)
        if(NOT OUTPUT_LOCATION)
            get_filename_component(OUTPUT_LOCATION ${TS} DIRECTORY)
            file(RELATIVE_PATH OUTPUT_LOCATION ${CMAKE_CURRENT_SOURCE_DIR} ${OUTPUT_LOCATION})
            set(OUTPUT_LOCATION ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_LOCATION})
        endif()
        file(MAKE_DIRECTORY ${OUTPUT_LOCATION})
        set(QM "${OUTPUT_LOCATION}/${TS_NAME}.qm")
        if(${TS} IS_NEWER_THAN ${QM})
            file(RELATIVE_PATH RELATIVE ${CMAKE_CURRENT_BINARY_DIR} ${QM})
            message(STATUS "Compiling ${RELATIVE}")
            execute_process(COMMAND ${QT5_LRELEASE} ${TS} -qm ${QM} -silent)
        endif()
        list(APPEND _IFW_QM_FILES ${QM})
    endforeach()

    set(${IFW_QM_FILES} ${_IFW_QM_FILES} PARENT_SCOPE)
endfunction()
