###################### Add component #######################

function(add_component NAME)

    list(FIND ARGN "BUILD" BUILD_DEFINED)

    cmake_parse_arguments("COMPONENT"
                          "BUILD;RECURSE"
                          "VERSION;TYPE;DIRECTORY"
                          "SOURCES;DEPENDS;EXTERNAL_DEPENDS"
                          ${ARGN})

    # Scan sources
    if(COMPONENT_DIRECTORY)
        set(PATTERN ${COMPONENT_DIRECTORY}/*.cpp
                    ${COMPONENT_DIRECTORY}/*.c
                    ${COMPONENT_DIRECTORY}/*.h
                    ${COMPONENT_DIRECTORY}/*.hpp)
        if(COMPONENT_RECURSE)
            file(GLOB_RECURSE SRC ${PATTERN})
        else()
            file(GLOB SRC ${PATTERN})
        endif()
    endif()

    # Additional sources
    if(COMPONENT_SOURCES)
        list(APPEND SRC ${COMPONENT_SOURCES})
    endif()

    # Check type
    if(NOT COMPONENT_TYPE)
        set(COMPONENT_TYPE "MODULE")
    endif()

    # Append component to list
    list(FIND COMPONENTS ${COMPONENT_TYPE} INDEX)
    if(INDEX EQUAL -1)
        set(COMPONENTS ${COMPONENTS} ${COMPONENT_TYPE} PARENT_SCOPE)
        if(NOT DEFINED BUILD_COMPONENT_TYPE)
            set(BUILD_COMPONENT_TYPE ON)
        endif()
        option(BUILD_${COMPONENT_TYPE}S "Build ${COMPONENT_TYPE}s" ${BUILD_COMPONENT_TYPE})
    endif()
    set(COMPONENT_${COMPONENT_TYPE}S ${COMPONENT_${COMPONENT_TYPE}S} ${NAME} PARENT_SCOPE)

    # Build by default
    if(BUILD_DEFINED EQUAL -1)
        set(COMPONENT_BUILD ON)
    endif()

    # Form component's variables
    option(BUILD_${COMPONENT_TYPE}_${NAME} "Build ${COMPONENT_TYPE} '${NAME}'" ${COMPONENT_BUILD})
    set(${COMPONENT_TYPE}_${NAME}_SOURCES  ${SRC}               PARENT_SCOPE)
    set(${COMPONENT_TYPE}_${NAME}_VERSION  ${COMPONENT_VERSION} PARENT_SCOPE)
    set(${COMPONENT_TYPE}_${NAME}_DEPENDS  ${COMPONENT_DEPENDS} PARENT_SCOPE)
    set(${COMPONENT_TYPE}_${NAME}_EXTERNAL_DEPENDS ${COMPONENT_EXTERNAL_DEPENDS} PARENT_SCOPE)

endfunction()


############## Check components dependencies ##############

function(check_components)

    # Iterate over components
    foreach(TYPE ${COMPONENTS})
        if(NOT BUILD_${TYPE}S)
            message(STATUS "Skip building ${TYPE}s")
        else()
            foreach(COMPONENT ${COMPONENT_${TYPE}S})
                if(BUILD_${TYPE}_${COMPONENT})
                    # Appending list of unskipped components
                    list(APPEND COMPONENT_TOTAL ${COMPONENT})
                    # Dependencies of unskipped components
                    list(APPEND DEPENDS_TOTAL   ${${TYPE}_${COMPONENT}_DEPENDS})
                    # Adding definition
                    add_definitions("-DBUILD_${TYPE}_${COMPONENT}=1")
                else()
                    message(STATUS "Skip building ${TYPE} '${COMPONENT}'")
                endif()
            endforeach()
        endif()
    endforeach()

    # Check if all dependencies of unskipped components are satisfied
    foreach(DEPENDENCY ${DEPENDS_TOTAL})
        list(FIND COMPONENT_TOTAL ${DEPENDENCY} INDEX)
            # Unsatisfied dependency
            if(INDEX EQUAL -1)
                message(FATAL_ERROR "Unsatisfied dependency '${DEPENDENCY}' while skipping components.")
            endif()
    endforeach()

endfunction()


############# Write components list to a file #############

function(write_components_list)

    # Forming list
    foreach(TYPE ${COMPONENTS})
        foreach(ITEM ${COMPONENT_${TYPE}S})
            if(BUILD_${TYPE}_${ITEM})
                set(ITEM_LINE "\n    + ${ITEM}\t")
            else()
                set(ITEM_LINE "\n    - ${ITEM}\t")
            endif()
            if(${TYPE}_${ITEM}_VERSION)
                set(ITEM_LINE "${ITEM_LINE}v${${TYPE}_${ITEM}_VERSION}\t")
            else()
                set(ITEM_LINE "${ITEM_LINE}\t")
            endif()
            if(${TYPE}_${ITEM}_DEPENDS)
            string(REPLACE ";" ", " DEPENDS "${${TYPE}_${ITEM}_DEPENDS}")
                set(ITEM_LINE "${ITEM_LINE}depends on ${DEPENDS}")
            endif()
            set(${TYPE}_LIST "${${TYPE}_LIST} ${ITEM_LINE}")
        endforeach()
        if(BUILD_${TYPE}S)
            set(${TYPE}_LIST "\n+ ${TYPE}S:${${TYPE}_LIST}")
        else()
            set(${TYPE}_LIST "\n- ${TYPE}S:${${TYPE}_LIST}")
        endif()
        set(FULL_LIST "${FULL_LIST} ${${TYPE}_LIST}\n")
    endforeach()

    # Title
    set(TITLE "${PROJECT_NAME} components")
    string(LENGTH ${TITLE} TITLE_LENGTH)
    set(TITLE "${TITLE}\n")
    math(EXPR TITLE_LENGTH "${TITLE_LENGTH} - 1")
    foreach(SYMBOL RANGE ${TITLE_LENGTH})
        set(TITLE "${TITLE}=")
    endforeach()

    # Writing file
    if(NOT ARGV0)
        set(ARGV0 "${CMAKE_BINARY_DIR}/BuildComponentsList.txt")
    endif()
    file(WRITE ${ARGV0} "${TITLE}\n" ${FULL_LIST})

endfunction()
