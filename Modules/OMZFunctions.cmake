include(CMakeParseArguments)


################## Write versions to cache #################

function(set_project_version)

    #### Parsing arguments
    cmake_parse_arguments("VERSION" "" "MAJOR;MINOR;PATCH;DATE;STATUS" "" ${ARGN})

    #### Checking arguments
    if(NOT VERSION_MAJOR)
        set(VERSION_MAJOR "0")
    endif()
    if(NOT VERSION_MINOR)
        set(VERSION_MINOR "0")
    endif()
    if(NOT VERSION_DATE)
        set(VERSION_DATE "unknown_date")
    endif()

    #### Full version string
    set(VERSION_STRING "${VERSION_MAJOR}.${VERSION_MINOR}")
    if(${VERSION_PATCH})
        set(VERSION_STRING "${VERSION_STRING}-${VERSION_PATCH}")
    endif()
    if(VERSION_STATUS)
        set(VERSION_STRING "${VERSION_STRING}-${VERSION_STATUS}")
    endif()

    #### Writing to cache
    set(${CMAKE_PROJECT_NAME_UPPER}_VERSION_MAJOR  ${VERSION_MAJOR}
        CACHE STRING  "Project major version number" FORCE)
    set(${CMAKE_PROJECT_NAME_UPPER}_VERSION_MINOR  ${VERSION_MINOR}
        CACHE STRING  "Project minor version number" FORCE)
    set(${CMAKE_PROJECT_NAME_UPPER}_VERSION_PATCH  ${VERSION_PATCH}
        CACHE STRING  "Project patch version number" FORCE)
    set(${CMAKE_PROJECT_NAME_UPPER}_VERSION_DATE   ${VERSION_DATE}
        CACHE STRING   "Project version date" FORCE)
    set(${CMAKE_PROJECT_NAME_UPPER}_VERSION_STATUS ${VERSION_STATUS}
        CACHE STRING "Project version status (alpha, beta, rc...)" FORCE)
    set(${CMAKE_PROJECT_NAME_UPPER}_VERSION_STRING ${VERSION_STRING}
        CACHE STRING "Full version string" FORCE)

endfunction()


#################### Set Qt defenitions ####################

function(set_qt_defenitions)
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        add_definitions(-DQT_NO_DEBUG)
        add_definitions(-DQT_NO_DEBUG_OUTPUT)
        add_definitions(-DQT_NO_WARNING)
        add_definitions(-DQT_NO_WARNING_OUTPUT)
        if(CMAKE_COMPILER_IS_GNUCC AND WIN32)
            set(GCC_FLAGS "${GCC_FLAGS} -mwindows")
        endif()
    endif()
endfunction()


###################### Add module/app ######################

function(add_component NAME)

    cmake_parse_arguments("COMPONENT"
                          "BUILD"
                          "VERSION;TYPE;DIRECTORY"
                          "DEPENDS;EXTERNAL_DEPENDS;ADDITIONAL_SOURCES"
                          ${ARGN})

    if(COMPONENT_VERSION)
        string(TOUPPER ${NAME} NAME_UPPER)
        string(REGEX REPLACE "[- ]" "_" NAME_UPPER ${NAME_UPPER})
        file(APPEND ${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}_version.h
                    "#define VERSION_${NAME_UPPER}_STRING \"${COMPONENT_VERSION}\"\n")
    endif()

    if(NOT COMPONENT_TYPE)
        set(COMPONENT_TYPE "MODULE")
    endif()

    list(FIND COMPONENTS ${COMPONENT_TYPE} INDEX)
    if(INDEX EQUAL -1)
        set(COMPONENTS ${COMPONENTS} ${COMPONENT_TYPE} PARENT_SCOPE)
    endif()
    set(COMPONENT_${COMPONENT_TYPE}S ${COMPONENT_${COMPONENT_TYPE}S} ${NAME} PARENT_SCOPE)

    if(COMPONENT_DIRECTORY)
        glob_sources(SRC NAME ${NAME} DIRECTORY ${COMPONENT_DIRECTORY}/${NAME})
    else()
        glob_sources(SRC NAME ${NAME} DIRECTORY ${NAME})
    endif()

    if(COMPONENT_ADDITIONAL_SOURCES)
        set(SRC ${SRC} ${COMPONENT_ADDITIONAL_SOURCES})
    endif()

    set(${COMPONENT_TYPE}_${NAME}_SOURCES  ${SRC}               PARENT_SCOPE)
    set(${COMPONENT_TYPE}_${NAME}_BUILD    ${COMPONENT_BUILD}   PARENT_SCOPE)
    set(${COMPONENT_TYPE}_${NAME}_VERSION  ${COMPONENT_VERSION} PARENT_SCOPE)
    set(${COMPONENT_TYPE}_${NAME}_DEPENDS  ${COMPONENT_DEPENDS} PARENT_SCOPE)
    set(${COMPONENT_TYPE}_${NAME}_EXTERNAL_DEPENDS ${COMPONENT_EXTERNAL_DEPENDS} PARENT_SCOPE)

endfunction()


############# Glob source files for module/app #############

function(glob_sources COMPONENT_SRC)

    cmake_parse_arguments("COMPONENT" "" "NAME;DIRECTORY" "" ${ARGN})

    if(COMPONENT_DIRECTORY)
        set(COMPONENT_PATH ${COMPONENT_DIRECTORY})
    else()
        set(COMPONENT_PATH .)
    endif()

    file(GLOB SRCS ${COMPONENT_PATH}/*.cpp)

    if(COMPONENT_NAME AND EXISTS ${COMPONENT_PATH}/${COMPONENT_NAME}.h)
        set(SRCS ${SRCS} ${COMPONENT_PATH}/${COMPONENT_NAME}.h)
    endif()

    set(${COMPONENT_SRC} ${SRCS} PARENT_SCOPE)

endfunction()


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
    if(NOT INPUT_FILE AND CPACK_PACKAGE_DESCRIPTION_FILE)
        set(INPUT_FILE ${CPACK_PACKAGE_DESCRIPTION_FILE})
    else()
        message(AUTHOR_WARNING "You must specify 'FILE' argument or set 'CPACK_PACKAGE_DESCRIPTION_SUMMARY' variable")
    endif()

    if(EXISTS ${INPUT_FILE})
        file(STRINGS ${INPUT_FILE} PACKAGE_DESCRIPTION)
        foreach(STRING ${PACKAGE_DESCRIPTION})
            string(REPLACE "\"" "\\\"" STRING ${STRING})
            set(CPACK_DEBIAN_PACKAGE_DESCRIPTION "${CPACK_DEBIAN_PACKAGE_DESCRIPTION} ${STRING}\n")
        endforeach()
        set(CPACK_DEBIAN_PACKAGE_DESCRIPTION ${CPACK_DEBIAN_PACKAGE_DESCRIPTION} PARENT_SCOPE)
    else()
        message(AUTHOR_WARNING "Description file '${INPUT_FILE}' does not exists")
    endif()
endfunction()


################## Build Windows ICO files #################

function(convert_ico INPUT_SVG_VAR OUTPUT_ICO_VAR)
    if(CONVERT_EXECUTABLE)
        foreach(INPUT ${${INPUT_SVG_VAR}})
            get_filename_component(FILE_NAME ${INPUT} NAME_WE)
            get_source_file_property(LOCATION ${INPUT} OUTPUT_LOCATION)
            if(LOCATION)
                file(MAKE_DIRECTORY "${LOCATION}")
            else()
                set(LOCATION "${CMAKE_CURRENT_BINARY_DIR}")
            endif()
            set(OUTPUT ${LOCATION}/${FILE_NAME}.ico)
            list(APPEND OUTPUT_ICO ${OUTPUT})
            add_custom_command(OUTPUT ${OUTPUT}
                               COMMAND ${CONVERT_EXECUTABLE} -background none -quantize transparent ${INPUT}
                                       ( -clone 0 -resize 256 )
#                                       ( -clone 0 -resize 96 )
                                       ( -clone 0 -resize 48 )
                                       ( -clone 0 -resize 32 )
                                       ( -clone 0 -resize 16 )
                                       -background none -quantize transparent ${OUTPUT}
                               WORKING_DIRECTORY ${LOCATION}
                               COMMENT "Generating ${FILE_NAME}.ico")
        endforeach()
        set(${OUTPUT_ICO_VAR} ${OUTPUT_ICO} PARENT_SCOPE)
    else()
        message(AUTHOR_WARNING "To build ICO files You must set the CONVERT_EXECUTABLE path variable")
    endif()
endfunction()


###################### Build PNG files #####################

function(convert_png INPUT_SVG_VAR OUTPUT_PNG_VAR)
    if(CONVERT_EXECUTABLE)
        foreach(INPUT ${${INPUT_SVG_VAR}})
            get_filename_component(FILE_NAME ${INPUT} NAME_WE)
            get_source_file_property(LOCATION ${INPUT} OUTPUT_LOCATION)
            if(LOCATION)
                file(MAKE_DIRECTORY "${LOCATION}")
            else()
                set(LOCATION "${CMAKE_CURRENT_BINARY_DIR}")
            endif()
            set(OUTPUT ${LOCATION}/${FILE_NAME}.png)
            list(APPEND OUTPUT_PNG ${OUTPUT})
            add_custom_command(OUTPUT ${OUTPUT}
                               COMMAND ${CONVERT_EXECUTABLE} -background none -quantize transparent ${INPUT} ${OUTPUT}
                               WORKING_DIRECTORY ${LOCATION}
                               COMMENT "Generating ${FILE_NAME}.png")
        endforeach()
        set(${OUTPUT_PNG_VAR} ${OUTPUT_PNG} PARENT_SCOPE)
    else()
        message(AUTHOR_WARNING "To build PNG files You must set the CONVERT_EXECUTABLE path variable")
    endif()
endfunction()
