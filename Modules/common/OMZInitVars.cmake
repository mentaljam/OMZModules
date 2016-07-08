macro(omz_init_vars)

    #### Project name upper
    string(TOUPPER ${CMAKE_PROJECT_NAME} PROJECT_NAME_UPPER)
    string(REGEX REPLACE "[- ]" "_" PROJECT_NAME_UPPER ${PROJECT_NAME_UPPER})

    #### Additional packages paths
    #set(DOXYGEN_EXECUTABLE  "" CACHE FILEPATH "Doxygen path")
    #set(HHC_EXECUTABLE      "" CACHE FILEPATH "HTML Help generator path")
    #set(QHG_EXECUTABLE      "" CACHE FILEPATH "QHP generator path")
    #set(QCOLGEN_EXECUTABLE  "" CACHE FILEPATH "Qt collection generator path")
    #set(PDFLATEX_EXECUTABLE "" CACHE FILEPATH "PDFLatex path")

    #### Build architecture
    get_property(${PROJECT_NAME_UPPER}_LANGUAGES GLOBAL PROPERTY ENABLED_LANGUAGES)
    if(${PROJECT_NAME_UPPER}_LANGUAGES STREQUAL "NONE")
        message(STATUS "Configuring architecture independent version")
        set(TARGET_ARCHITECTURE all)
    elseif(CMAKE_SIZEOF_VOID_P MATCHES 8)
        message(STATUS "Configuring 64 bit version")
        set(TARGET_ARCHITECTURE amd64)
    else()
        message(STATUS "Configuring 32 bit version")
        set(TARGET_ARCHITECTURE i386)
    endif()
    set(TARGET_ARCHITECTURE ${TARGET_ARCHITECTURE} CACHE STRING "Target application architecture")

    #### Build type
    if(NOT CMAKE_BUILD_TYPE)
        set(CMAKE_BUILD_TYPE "Debug")
    endif()

    #### Additional flags
    if(WIN32 AND TARGET_ARCHITECTURE EQUAL i386)
        set(CMAKE_RC_FLAGS "-F pe-i386")
    endif()

endmacro()
