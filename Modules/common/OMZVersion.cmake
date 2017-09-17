################### Find git if not set ############$#######

if(NOT GIT_EXECUTABLE)
    find_program(GIT_EXECUTABLE git COMMENT "Git executable")
endif()


################### Get version from git ###################

function(get_version_from_git VERSION_ARG VERSION_DATE_ARG)

    if(DEFINED ${VERSION_ARG})
        return()
    endif()

    if(NOT GIT_EXECUTABLE OR NOT EXISTS "${CMAKE_SOURCE_DIR}/.git")
        message(WARNING "Cannot get project version from git. Check GIT_EXECUTABLE variable and ${CMAKE_SOURCE_DIR}/.git directory.")
        return()
    endif()

    execute_process(COMMAND ${GIT_EXECUTABLE} -C ${CMAKE_CURRENT_LIST_DIR} describe --tags --always
        OUTPUT_VARIABLE VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(COMMAND ${GIT_EXECUTABLE} -C ${CMAKE_CURRENT_LIST_DIR} log -n 1 --pretty=format:%ad --date=short
        OUTPUT_VARIABLE VERSION_DATE OUTPUT_STRIP_TRAILING_WHITESPACE)
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

    if(NOT VERSION_DATE)
        set(VERSION_DATE "unknown_date")
    endif()

    set(${VERSION_ARG} ${VERSION} CACHE STRING "The ${VERSION_ARG} value")
    set(${VERSION_DATE_ARG} ${VERSION_DATE} CACHE STRING "The ${VERSION_ARG} value")

endfunction()


################### Add changelog target ###################

function(add_changelog_target TARGET_NAME)

    if(NOT GIT_EXECUTABLE OR NOT EXISTS "${CMAKE_SOURCE_DIR}/.git")
        message(WARNING "Cannot add the changelog target. Check GIT_EXECUTABLE variable and ${CMAKE_SOURCE_DIR}/.git directory.")
        return()
    endif()

    #### Get the last tag name
    execute_process(COMMAND "${GIT_EXECUTABLE}" describe --abbrev=0 --tags
        OUTPUT_VARIABLE LAST_TAG
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    #### Print log
    add_custom_target(${TARGET_NAME}
        COMMAND "${GIT_EXECUTABLE}" log "${LAST_TAG}.." "--pretty=  - %s"
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        COMMENT "Changes from the '${LAST_TAG}' tag:")

endfunction()
