# Include guard
if(OMZDOXYCONF_INCLUDED)
    return()
endif()
set(OMZDOXYCONF_INCLUDED 1)


# Add option string to Doxygen configuration
macro(_doxy_add_option VARIABLE OPTION VALUE)

    string(LENGTH "${OPTION}" OPTION_LENGTH)
    set(${VARIABLE} "${${VARIABLE}}${OPTION}")
    foreach(ITR RANGE ${OPTION_LENGTH} 21)
        set(${VARIABLE} "${${VARIABLE}} ")
    endforeach()
    set(${VARIABLE} "${${VARIABLE}} = ${VALUE}\n")

endmacro()


# Configure Doxygen configuration file
function(omz_configure_doxy_file CONFIGURATION_FILE)

    # Formats
    set(DOXY_FORMATS_ALL
        HTML
        HTMLHELP
        QHP
        LATEX
        MAN
        RTF
        XML
        DOCBOOK)

    # Bool options
    set(DOXY_OPTIONS_BOOL
        RECURSIVE
        DISABLE_INDEX
        SEARCHENGINE
        QUIET)
    # Single options
    set(DOXY_OPTIONS_SINGLE
        IMAGE_PATH
        USE_MDFILE_AS_MAINPAGE
        PROJECT_NAME
        PROJECT_NUMBER
        PROJECT_BRIEF
        PROJECT_LOGO
        OUTPUT_DIRECTORY
        OUTPUT_LANGUAGE
        HTML_EXTRA_STYLESHEET
        CHM_FILE
        CHM_INDEX_ENCODING
        HHC_LOCATION
        QCH_FILE
        QHP_NAMESPACE
        QHP_VIRTUAL_FOLDER
        QHP_CUST_FILTER_NAME
        QHP_CUST_FILTER_ATTRS
        QHP_SECT_FILTER_ATTRS
        QHG_LOCATION
        MAN_EXTENSION)
    # Multi options
    set(DOXY_OPTIONS_MULTI
        INPUT
        FILE_PATTERNS
        EXCLUDE_PATTERNS)

    # Parse function arguments
    cmake_parse_arguments(DOXY
        "${DOXY_OPTIONS_BOOL}"
        "${DOXY_OPTIONS_SINGLE}"
        "FORMATS;${DOXY_OPTIONS_MULTI}"
        ${ARGN})
    if(DOXY_UNPARSED_ARGUMENTS)
        foreach(ARG ${DOXY_UNPARSED_ARGUMENTS})
            message(WARNING "Unknown argument: ${ARG}")
        endforeach()
    endif()

    # Exit function if there is no input specified
    if(NOT DOXY_INPUT)
        message(WARNING "No input files were specified. Make shure the 'INPUT' argument is not empty.")
        return()
    endif()
    # Prepare input string for doxygen.conf
    string(REPLACE ";" " " DOXY_INPUT "${DOXY_INPUT}")

    # Check project name
    if(NOT DOXY_PROJECT_NAME)
        set(DOXY_PROJECT_NAME "${PROJECT_NAME}")
    endif()
    set(DOXY_PROJECT_NAME \"${DOXY_PROJECT_NAME}\")

    # Check project version
    if(NOT DOXY_PROJECT_NUMBER)
        set(DOXY_PROJECT_NUMBER ${PROJECT_VERSION})
    endif()

    # Check output directory
    if(NOT DOXY_OUTPUT_DIRECTORY)
        set(DOXY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
    endif()

    # Check OUTPUT_LANGUAGE
    if(NOT DOXY_OUTPUT_LANGUAGE)
        set(DOXY_OUTPUT_LANGUAGE "English")
    endif()

    # HTMLHELP
    if("HTMLHELP" IN_LIST DOXY_FORMATS)
        if(NOT CHM_FILE)
            message(CRITICAL "HTMLHELP is enabled but CHM_FILE is not set")
        endif()
        if(NOT DOXY_HHC_LOCATION)
            find_program(DOXY_HHC_LOCATION "hhc")
            if(NOT DOXY_HHC_LOCATION)
                message(WARNING "HHC executable was not found")
                set(DOXY_HHC_LOCATION "hhc.exe" CACHE PATH "HHC executable" FORCE)
            endif()
        endif()
        list(APPEND DOXY_FORMATS "html" "htmlhelp")
        set(DOXY_SEARCHENGINE "NO")
        set(DOXY_DISABLE_INDEX "YES")
        set(DOXY_GRAPHVIS "NO")
        set(CHM_FILE \"${CHM_FILE}\")
    endif()

    # QHP
    if("QHP" IN_LIST DOXY_FORMATS)
        if(NOT DOXY_QCH_FILE)
            message(CRITICAL "QHP is enabled but QCH_FILE is not set")
        endif()
        if(NOT DOXY_QHG_LOCATION)
            find_program(DOXY_QHG_LOCATION "qhelpgenerator")
            if(NOT DOXY_QHG_LOCATION)
                message(WARNING "qhelpgenerator executable was not found")
                set(DOXY_QHG_LOCATION "qhelpgenerator" CACHE PATH "QHG executable" FORCE)
            endif()
        endif()
        list(APPEND DOXY_FORMATS "html" "qhp")
        set(DOXY_SEARCHENGINE "NO")
        set(DOXY_DISABLE_INDEX "YES")
        set(DOXY_GRAPHVIS "NO")
        set(DOXY_QCH_FILE \"${DOXY_QCH_FILE}\")
    endif()

    # Check if no formats are enabled
    if(NOT DOXY_FORMATS)
        set(DOXY_FORMATS "html")
    endif()

    # Check file patterns
    if(NOT DOXY_FILE_PATTERNS)
        set(DOXY_FILE_PATTERNS "*.h *.h.in *.hpp *.cpp *.md *.txt")
    endif()

    # Exclude patterns
    list(APPEND DOXY_EXCLUDE_PATTERNS "CMakeLists.txt")

    # Create output directory
    file(MAKE_DIRECTORY "${DOXY_OUTPUT_DIRECTORY}")
    set(DOXY_OUTPUT_DIRECTORY \"${DOXY_OUTPUT_DIRECTORY}\")

    # Process formats variables
    list(REMOVE_DUPLICATES DOXY_FORMATS)
    foreach(FORMAT ${DOXY_FORMATS})
        string(TOUPPER ${FORMAT} FORMAT_UPPER)
        list(FIND DOXY_FORMATS_ALL ${FORMAT_UPPER} IND)
        if(NOT IND EQUAL -1)
            set(DOXY_GEN_${FORMAT_UPPER} "YES")
        else()
            message(WARNING "Unknown doxygen format: ${FORMAT}")
        endif()
    endforeach()

    # Generating Doxygen configuration
    unset(DOXY_CONF_CONTENT CACHE)

    # Executables
    foreach(EXECUTABLE HHC QHG)
        if(DOXY_${EXECUTABLE}_LOCATION)
            _doxy_add_option(DOXY_CONF_CONTENT ${EXECUTABLE}_LOCATION "\"${DOXY_${EXECUTABLE}_LOCATION}\"")
        endif()
    endforeach()
    if(DOXY_CONF_CONTENT)
        set(DOXY_CONF_CONTENT "# Executables:\n${DOXY_CONF_CONTENT}\n")
    endif()

    # Formats
    set(DOXY_CONF_CONTENT "${DOXY_CONF_CONTENT}# Formats:\n")
    foreach(FORMAT ${DOXY_FORMATS_ALL})
        if(DOXY_GEN_${FORMAT})
            _doxy_add_option(DOXY_CONF_CONTENT GENERATE_${FORMAT} YES)
        else()
            _doxy_add_option(DOXY_CONF_CONTENT GENERATE_${FORMAT} NO)
        endif()
    endforeach()
    # Options
    set(DOXY_CONF_CONTENT "${DOXY_CONF_CONTENT}\n# Options:\n")
    foreach(ARG IN LISTS DOXY_OPTIONS_BOOL DOXY_OPTIONS_SINGLE DOXY_OPTIONS_MULTI)
        if(DEFINED DOXY_${ARG})
            _doxy_add_option(DOXY_CONF_CONTENT ${ARG} "${DOXY_${ARG}}")
        endif()
    endforeach()

    # Writing Doxygen file if need
    unset(DOXY_CONF_CONTENT_OLD CACHE)
    if(EXISTS "${CONFIGURATION_FILE}")
        file(READ "${CONFIGURATION_FILE}" DOXY_CONF_CONTENT_OLD)
    endif()
    if(NOT "${DOXY_CONF_CONTENT_OLD}" STREQUAL "${DOXY_CONF_CONTENT}")
        file(WRITE "${CONFIGURATION_FILE}" "${DOXY_CONF_CONTENT}")
    endif()

endfunction()


# Configure a QHCP file
function(omz_configure_qhcp_file DOXY_QHCP_FILE)

    # Check arguments
    if(NOT ARGN)
        message(CRITICAL "Usage: configure_qhcp_file(<qhcp_file> <qch_file> [<qch_file> ...])")
    endif()

    # Generating QHCP file content
    unset(DOXY_QHCP_CONTENT CACHE)

    set(DOXY_QHCP_CONTENT "\
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<QHelpCollectionProject version=\"1.0\">
    <docFiles>
        <register>")

    foreach(QCH ${ARGN})
        set(DOXY_QHCP_CONTENT "${DOXY_QHCP_CONTENT}
            <file>${QCH}</file>")
    endforeach()

    set(DOXY_QHCP_CONTENT "${DOXY_QHCP_CONTENT}
        </register>
    </docFiles>
</QHelpCollectionProject>
")

    # Writing QHCP file if need
    unset(DOXY_QHCP_CONTENT_OLD CACHE)
    if(EXISTS "${DOXY_QHCP_FILE}")
       file(READ "${DOXY_QHCP_FILE}" DOXY_QHCP_CONTENT_OLD)
    endif()
    if(NOT "${DOXY_QHCP_CONTENT_OLD}" STREQUAL "${DOXY_QHCP_CONTENT}")
       file(WRITE "${DOXY_QHCP_FILE}" "${DOXY_QHCP_CONTENT}")
    endif()

endfunction()


# Write a file for sources versions
function(omz_write_sources_versions OUTPUT_FILE SOURCES)

    __check_git_executable()

    set(VERSIONS_CONTENT "/**\n")
    foreach(FILE ${SOURCES})
        if(${FILE} MATCHES ".*(CMakeLists\\.txt)")
            continue()
        endif()
        execute_process(COMMAND ${GIT_EXECUTABLE} -C ${PROJECT_SOURCE_DIR} log -n 1 --pretty=format:%ci ${FILE}
            OUTPUT_VARIABLE SOURCE_DATE
            RESULT_VARIABLE RESULT
            OUTPUT_STRIP_TRAILING_WHITESPACE)
        if(${RESULT} EQUAL 0)
            execute_process(COMMAND ${GIT_EXECUTABLE} -C ${PROJECT_SOURCE_DIR} log -n 1 --pretty=format:%h ${FILE}
                OUTPUT_VARIABLE SOURCE_VERSION
                OUTPUT_STRIP_TRAILING_WHITESPACE)
            set(VERSIONS_CONTENT
                "${VERSIONS_CONTENT} *\n * @file ${FILE}\n * @version ${SOURCE_VERSION}\n * @date ${SOURCE_DATE}\n")
        endif()
    endforeach()
    set(VERSIONS_CONTENT "${VERSIONS_CONTENT} *\n **/\n\n")

    unset(VERSIONS_CONTENT_OLD CACHE)
    if(EXISTS "${OUTPUT_FILE}")
        file(READ "${OUTPUT_FILE}" VERSIONS_CONTENT_OLD)
    endif()
    if(NOT "${VERSIONS_CONTENT_OLD}" STREQUAL "${VERSIONS_CONTENT}")
        file(WRITE "${OUTPUT_FILE}" "${VERSIONS_CONTENT}")
    endif()

endfunction()
