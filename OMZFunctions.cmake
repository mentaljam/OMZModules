include(CMakeParseArguments)

###################### Add module/app ######################

function(add_component NAME)

    cmake_parse_arguments("COMPONENT" "BUILD" "VERSION;TYPE;DIRECTORY" "DEPENDS;ADDITIONAL_SOURCES" ${ARGN})

    if(COMPONENT_VERSION)
        string(TOUPPER ${NAME} NAME_UP)
        file(APPEND ${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}_version.h
                    "#define VERSION_${NAME_UP} \"${COMPONENT_VERSION}\"\n")
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
