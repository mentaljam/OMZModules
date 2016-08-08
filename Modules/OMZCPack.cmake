macro(generate_package_name)

    if(NOT ${TARGET_ARCHITECTURE} STREQUAL "all")
        if(MSVC)
            if(MSVC_VERSION STREQUAL "1310")
                set(COMPILER_NAME "msvc2003")
            elseif(MSVC_VERSION STREQUAL "1400")
                set(COMPILER_NAME "msvc2005")
            elseif(MSVC_VERSION STREQUAL "1500")
                set(COMPILER_NAME "msvc2008")
            elseif(MSVC_VERSION STREQUAL "1600")
                set(COMPILER_NAME "msvc2010")
            elseif(MSVC_VERSION STREQUAL "1700")
                set(COMPILER_NAME "msvc2012")
            elseif(MSVC_VERSION STREQUAL "1800")
                set(COMPILER_NAME "msvc2013")
            elseif(MSVC_VERSION STREQUAL "1900")
                set(COMPILER_NAME "msvc2015")
            endif()
        else()
            string(TOLOWER "${CMAKE_CXX_COMPILER_ID}${CMAKE_CXX_COMPILER_VERSION}" COMPILER_NAME)
        endif()
        string(REPLACE "." "" COMPILER_NAME "_${COMPILER_NAME}")
    endif()

    if(CPACK_DOWNLOAD_ALL)
        set(POSTFIX "_online")
    endif()

    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(POSTFIX "${POSTFIX}_dbg")
    endif()

    string(TOLOWER
        ${CMAKE_PROJECT_NAME}_${CPACK_PACKAGE_VERSION}_${CMAKE_SYSTEM_NAME}${COMPILER_NAME}_${TARGET_ARCHITECTURE}${POSTFIX}
        CPACK_PACKAGE_FILE_NAME)
    string(REGEX REPLACE "[- ]" "_" CPACK_PACKAGE_FILE_NAME ${CPACK_PACKAGE_FILE_NAME})

endmacro()
