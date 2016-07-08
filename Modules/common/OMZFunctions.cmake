############# Remove C/CPP comments from file ##############

function(remove_comments SRC_FILE DST_FILE)
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


######### Read description file for debian packages ########

function(read_debian_description)

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


###################### Get definitions #####################

function(get_defenition HEADER DEFENITION INCLUDE_DIRECTORIES OUTPUT_VARIABLE)

    if(NOT DEFINED ${OUTPUT_VARIABLE})

        message(STATUS "Get ${DEFENITION} from ${HEADER}")

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
            RUN_OUTPUT_VARIABLE RUN_OUTPUT)

        if(RUN_RESULT EQUAL 0 AND COMPILE_RESULT)
            message(STATUS "Get ${DEFENITION} from ${HEADER} - \"${RUN_OUTPUT}\"")
        else()
            message(STATUS "Get ${DEFENITION} from ${HEADER} - failed")
        endif()

        set(${OUTPUT_VARIABLE} ${RUN_OUTPUT} CACHE STRING "${DEFENITION} definition from ${HEADER}")

    endif()

endfunction()


########## Combine license files to a single one ###########

function(configure_single_license_file OUTPUT_FILE)

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


###################### Windows RC file #####################

function(configure_rcfile FILE)

    cmake_parse_arguments("IDI" "" "ICON" "" ${ARGN})
    cmake_parse_arguments("RC"  "" "VERSION" "" ${ARGN})
    cmake_parse_arguments("VER" ""
                          "COMPANYNAME;FILEDESCRIPTION;FILEVERSION;PRODUCTVERSION;\
INTERNALNAME;LEGALCOPYRIGHT;ORIGINALFILENAME;PRODUCTNAME"
                          "" ${ARGN})

    # Checking icons
    if(IDI_ICON)
        set(IDI_ICON "IDI_ICON1 ICON DISCARDABLE \"${IDI_ICON}\"\n")
    endif()

    # Checking versions
    if(NOT RC_VERSION)
        set(RC_VERSION  ${PROJECT_VERSION})
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
