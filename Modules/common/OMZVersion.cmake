################## Write versions to cache #################

function(set_project_version)

    #### Parsing arguments
    cmake_parse_arguments("VERSION" "GIT" "MAJOR;MINOR;PATCH;TWEAK;DATE;STATUS" "" ${ARGN})

    #### Reading
    if(VERSION_GIT AND EXISTS ${CMAKE_SOURCE_DIR}/.git)

        if(NOT GIT_EXECUTABLE)
            unset(GIT_EXECUTABLE CACHE)
            find_program(GIT_EXECUTABLE git)
        endif()
        if(GIT_EXECUTABLE)

            execute_process(COMMAND ${GIT_EXECUTABLE} -C ${PROJECT_SOURCE_DIR} describe --tags --always
                            OUTPUT_VARIABLE VERSION)
            execute_process(COMMAND ${GIT_EXECUTABLE} -C ${PROJECT_SOURCE_DIR} log -n 1 --pretty=format:%ad --date=short
                            OUTPUT_VARIABLE VERSION_DATE)
            if(VERSION MATCHES "v[0-9]\\.[0-9].*")
                string(STRIP ${VERSION} VERSION)
                message(STATUS "Using git tag '${VERSION}' as the version number")
                string(LENGTH ${VERSION} VERSION_LENGTH)
                math(EXPR VERSION_LENGTH "${VERSION_LENGTH} - 1")
                string(SUBSTRING ${VERSION} 1 ${VERSION_LENGTH} VERSION)
                string(REPLACE "-" ";" VERSION ${VERSION})
                list(LENGTH VERSION VERSION_LENGTH)
                if(VERSION_LENGTH GREATER 1)
                    list(GET VERSION 1 VERSION_TWEAK)
                    list(GET VERSION 0 VERSION)
                endif()
                string(REPLACE "." ";" VERSION ${VERSION})
                list(GET VERSION 0 VERSION_MAJOR)
                list(GET VERSION 1 VERSION_MINOR)
                list(LENGTH VERSION VERSION_LENGTH)
                if(VERSION_LENGTH GREATER 2)
                    list(GET VERSION 2 VERSION_PATCH)
                endif()
            else()
                message(STATUS "Unknown git tag format, expected something like 'v1.0-10'")
            endif()

        else()
            message(AUTHOR_WARNING "Git is not found - version can not be defined")
        endif()

    elseif(VERSION_GIT AND NOT EXISTS ${CMAKE_SOURCE_DIR}/.git)
        message(AUTHOR_WARNING "No .git folder - version can not be defined")
    endif()

    if(NOT VERSION_GIT)
        message(STATUS "Using manually defined version")
    endif()

    #### Checking arguments
    if(NOT VERSION_MAJOR)
        set(VERSION_MAJOR "0")
    endif()
    if(NOT VERSION_MINOR)
        set(VERSION_MINOR "0")
    endif()
    if(NOT VERSION_PATCH)
        set(VERSION_PATCH "0")
    endif()
    if(NOT VERSION_TWEAK)
        set(VERSION_TWEAK "0")
    endif()
    if(NOT VERSION_DATE)
        set(VERSION_DATE "unknown_date")
    endif()

    #### Full version string
    set(VERSION_STRING "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}")
    if(VERSION_STATUS)
        set(VERSION_STRING "${VERSION_STRING}-${VERSION_STATUS}")
    endif()
    if(VERSION_TWEAK)
        set(VERSION_STRING "${VERSION_STRING}-${VERSION_TWEAK}")
    endif()

    #### Writing to cache
    unset(PROJECT_VERSION_MAJOR PARENT_SCOPE)
    set(PROJECT_VERSION_MAJOR  ${VERSION_MAJOR}
        CACHE STRING  "Project major version number" FORCE)
    unset(PROJECT_VERSION_MINOR PARENT_SCOPE)
    set(PROJECT_VERSION_MINOR  ${VERSION_MINOR}
        CACHE STRING  "Project minor version number" FORCE)
    unset(PROJECT_VERSION_PATCH PARENT_SCOPE)
    set(PROJECT_VERSION_PATCH  ${VERSION_PATCH}
        CACHE STRING  "Project patch version number" FORCE)
    unset(PROJECT_VERSION_TWEAK PARENT_SCOPE)
    set(PROJECT_VERSION_TWEAK   ${VERSION_TWEAK}
        CACHE STRING  "Project version tweak" FORCE)
    unset(PROJECT_VERSION_DATE PARENT_SCOPE)
    set(PROJECT_VERSION_DATE   ${VERSION_DATE}
        CACHE STRING  "Project version date" FORCE)
    unset(PROJECT_VERSION_STATUS PARENT_SCOPE)
    set(PROJECT_VERSION_STATUS ${VERSION_STATUS}
        CACHE STRING  "Project version status (alpha, beta, rc...)" FORCE)
    unset(PROJECT_VERSION PARENT_SCOPE)
    set(PROJECT_VERSION ${VERSION_STRING}
        CACHE STRING  "Full version string" FORCE)

endfunction()


############ Write version definitions to a file ###########

function(write_version_file FILE)

    #### Parsing additional definitions
    set(WRITING 0)
    foreach(ARG ${ARGN})
        if(${ARG} STREQUAL "DEFINE")
            if(NOT WRITING EQUAL 1)
                set(WRITING 1)
                set(DEFINITIONS "${DEFINITIONS}\n#define")
            else()
                message(FATAL_ERROR "Trying to add an empty definition")
            endif()
        else()
            if(NOT WRITING EQUAL 0)
                set(WRITING 2)
                set(DEFINITIONS "${DEFINITIONS} ${ARG}")
            else()
                message(WARNING "Unknown option '${ARG}'")
            endif()
        endif()
    endforeach()
    if(DEFINITIONS)
        set(DEFINITIONS "\n// Additional definitions${DEFINITIONS}\n")
    endif()

    #### Writing definitions to a file
    file(WRITE ${FILE}
            "#ifndef VERSION_${PROJECT_NAME_UPPER}\n#define VERSION_${PROJECT_NAME_UPPER}\n\n"
            "// ${PROJECT_NAME} version definitions\n"
            "#define VERSION_${PROJECT_NAME_UPPER}_MAJOR  ${${PROJECT_NAME}_VERSION_MAJOR}\n"
            "#define VERSION_${PROJECT_NAME_UPPER}_MINOR  ${${PROJECT_NAME}_VERSION_MINOR}\n"
            "#define VERSION_${PROJECT_NAME_UPPER}_PATCH  ${${PROJECT_NAME}_VERSION_PATCH}\n"
            "#define VERSION_${PROJECT_NAME_UPPER}_TWEAK  ${${PROJECT_NAME}_VERSION_TWEAK}\n"
            "#define VERSION_${PROJECT_NAME_UPPER}_STRING \"${${PROJECT_NAME}_VERSION}\"\n"
            "#define VERSION_${PROJECT_NAME_UPPER}_DATE   \"${${PROJECT_NAME}_VERSION_DATE}\"\n"
            "#define VERSION_${PROJECT_NAME_UPPER}_OS     \"${CMAKE_SYSTEM_NAME}\"\n"
            "#define VERSION_${PROJECT_NAME_UPPER}_ARCH   \"${COMPILED_ARCH}\"\n"
            "${DEFINITIONS}"
            "\n#endif // VERSION_${PROJECT_NAME_UPPER}\n"
    )

endfunction()
