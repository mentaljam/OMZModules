####################### Documentation ######################


################### Checking executables ###################

if(DOXYGEN_EXECUTABLE)
    set(DOXYGEN_FOUND "YES")
else()
    unset(DOXYGEN_EXECUTABLE CACHE)
    find_package(Doxygen)
endif()

add_custom_target(build_docs
                  COMMENT "${PROJECT_NAME} documentation"
                  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})

if(DOXYGEN_FOUND)

    message(STATUS "Configuring doxygen")

    #### Formats
    set(DOXY_FORMATS_ALL    HTML HTMLHELP QHP LATEX MAN RTF XML DOCBOOK)

    #### Options

    # Bool
    set(DOXY_OPTIONS_BOOL   RECURSIVE DISABLE_INDEX SEARCHENGINE)
    # Single
    set(DOXY_OPTIONS_SINGLE IMAGE_PATH USE_MDFILE_AS_MAINPAGE
                            PROJECT_NAME PROJECT_NUMBER PROJECT_BRIEF PROJECT_LOGO
                            OUTPUT_DIRECTORY OUTPUT_LANGUAGE
                            HTML_EXTRA_STYLESHEET
                            CHM_FILE CHM_INDEX_ENCODING
                            QCH_FILE QHP_NAMESPACE QHP_VIRTUAL_FOLDER QHP_CUST_FILTER_NAME QHP_CUST_FILTER_ATTRS QHP_SECT_FILTER_ATTRS
                            MAN_EXTENSION)
    # Multi
    set(DOXY_OPTIONS_MULTI  INPUT FILE_PATTERNS EXCLUDE_PATTERNS)

else(DOXYGEN_FOUND)

    message(WARNING "Doxygen not found - Documentation will not be created")

    add_custom_command(TARGET build_docs
                       COMMAND ${CMAKE_COMMAND} -E cmake_echo_color --red "No doxygen executable was found, skipping...")

endif()


######################### Functions ########################

#### Add option string to doxygen.conf
function(doxy_add_option CONF_FILE OPTION VALUE)

    string(LENGTH "${OPTION}" OPTION_LENGTH)
    file(APPEND ${CONF_FILE} "${OPTION}")
    foreach(ITR RANGE ${OPTION_LENGTH} 21)
        file(APPEND ${CONF_FILE} " ")
    endforeach()
    file(APPEND ${CONF_FILE} " = ${VALUE}\n")

endfunction()

#### Add documentation target
function(doxy_add_target)

    #### Checking doxygen
    if(NOT DOXYGEN_FOUND)
        return()
    endif()

    #### Parse function arguments
    cmake_parse_arguments(DOXY
                          "HTMLHELP;QHP;PDF;${DOXY_OPTIONS_BOOL}"
                          "${DOXY_OPTIONS_SINGLE}"
                          "FORMATS;${DOXY_OPTIONS_MULTI}"
                          ${ARGN})
    if(DOXY_UNPARSED_ARGUMENTS)
        foreach(ARG ${DOXY_UNPARSED_ARGUMENTS})
            message(AUTHOR_WARNING "Unknown argument '${ARG}'")
        endforeach()
    endif()

    #### Exit function if there is no input specified
    if(NOT DOXY_INPUT)
        message(AUTHOR_WARNING "No input files were specified. Make shure the 'INPUT' argument is not empty.")
        return()
    endif()
    #### Prepare input string for doxygen.conf
    string(REPLACE ";" " " DOXY_INPUT "${DOXY_INPUT}")

    #### Check project name
    if(NOT DOXY_PROJECT_NAME)
        set(DOXY_PROJECT_NAME "${PROJECT_NAME}")
    endif()
    #### Prepare strings for file names
    string(REGEX REPLACE "[\\/\\\\\\?%\\*:\\|\"<>. ]" "_" DOXY_NAME_FIX "${DOXY_PROJECT_NAME}")
    string(TOLOWER ${DOXY_NAME_FIX} DOXY_NAME_FIX_LOWER)
    set(DOXY_PROJECT_NAME \"${DOXY_PROJECT_NAME}\")

    #### Check project version
    if(NOT DOXY_PROJECT_NUMBER)
        set(DOXY_PROJECT_NUMBER ${${PROJECT_NAME_UPPER}_VERSION_STRING})
    endif()

    #### Check output directory
    if(NOT DOXY_OUTPUT_DIRECTORY)
        set(DOXY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/doc")
    endif()
    #### Set doxygen.conf path
    set(DOXY_CONF_OUT "${DOXY_OUTPUT_DIRECTORY}/${DOXY_NAME_FIX_LOWER}_doxygen.conf")

    #### Check OUTPUT_LANGUAGE
    if(NOT DOXY_OUTPUT_LANGUAGE)
        set(DOXY_OUTPUT_LANGUAGE "English")
    endif()

    #### Check formats and process extra options for HTMLHELP, QHP and PDF
    if(NOT DOXY_FORMATS AND NOT DOXY_HTMLHELP AND NOT DOXY_QHP AND NOT DOXY_PDF)

        set(DOXY_FORMATS "html")

    else()

        #### HTMLHELP
        if(DOXY_HTMLHELP)
            if(NOT HHC_EXECUTABLE)
                unset(HHC_EXECUTABLE CACHE)
                find_program(HHC_EXECUTABLE "hhc")
            endif()
            if(HHC_EXECUTABLE)
                list(APPEND DOXY_FORMATS "html" "htmlhelp")
                set(DOXY_SEARCHENGINE "NO")
                set(DOXY_DISABLE_INDEX "YES")
                set(DOXY_GRAPHVIS "NO")
            else()
                message(WARNING "'hhc' compiler is not found - Windows HELP files will not be created")
            endif()
        endif()

        #### QHP
        if(DOXY_QHP)
            if(NOT QHG_EXECUTABLE)
                unset(QHG_EXECUTABLE CACHE)
                find_program(QHG_EXECUTABLE "qhelpgenerator")
            endif()
            if(QHG_EXECUTABLE)
                list(APPEND DOXY_FORMATS "html" "qhp")
                set(DOXY_SEARCHENGINE "NO")
                set(DOXY_DISABLE_INDEX "YES")
                set(DOXY_GRAPHVIS "NO")
            else()
                message(WARNING "'qhelpgenerator' is not found - Qt HELP files will not be created")
            endif()
        endif()

        #### PDF
        if(DOXY_PDF)
            if(NOT PDFLATEX_EXECUTABLE)
                unset(PDFLATEX_EXECUTABLE CACHE)
                find_program(PDFLATEX_EXECUTABLE pdflatex)
            endif()
            if(PDFLATEX_EXECUTABLE)
                list(APPEND DOXY_FORMATS "latex")
                if(WIN32)
                    set(PDF_MAKE_FILE "${DOXY_OUTPUT_DIRECTORY}/latex/make.bat")
                else()
                    set(PDF_MAKE_FILE make -C "${DOC_OUT}/latex")
                    set(TEX_FORMAT sed -i "'1s/.*/\\\\documentclass[oneside]{scrbook}\\n\\\\renewcommand{\\\\chapterheadstartvskip}{}/'"
                                   "${DOC_OUT}/latex/refman.tex")
                endif()
                add_custom_command(TARGET build_docs
                                   COMMAND ${TEX_FORMAT}
                                   COMMAND ${MAKE_PDF}
                                   COMMAND ${CMAKE_COMMAND} -E copy ${DOXY_OUTPUT_DIRECTORY}/latex/refman.pdf
                                                                    ${DOXY_OUTPUT_DIRECTORY}/${DOXY_NAME_FIX_LOWER}.pdf
                                   COMMENT "Generating documentation in PDF"
                                   VERBATIM)
            elseif()
                message(WARNING "'pdflatex' not found - PDF documentation will not be created")
            endif()
        endif()

    endif()

    #### Check file patterns
    if(NOT DOXY_FILE_PATTERNS)
        set(DOXY_FILE_PATTERNS "*.h *.h.in *.hpp *.cpp *.md *.txt")
    endif()

    #### Exclude patterns
    list(APPEND DOXY_EXCLUDE_PATTERNS "CmakeLists.txt")

    #### Create output directory
    file(MAKE_DIRECTORY "${DOXY_OUTPUT_DIRECTORY}")

    #### Process formats variables
    list(REMOVE_DUPLICATES DOXY_FORMATS)
    foreach(FORMAT ${DOXY_FORMATS})
        string(TOUPPER ${FORMAT} FORMAT_UPPER)
        list(FIND DOXY_FORMATS_ALL ${FORMAT_UPPER} IND)
        if(NOT IND EQUAL -1)
            set(DOXY_GEN_${FORMAT_UPPER} "YES")
        else()
            message(WARNING "Unknown doxygen format '${FORMAT}'")
        endif()
    endforeach()

    #### Generating doxygen.conf file
    # Deletting old one
    if(EXISTS ${DOXY_CONF_OUT})
        file(REMOVE ${DOXY_CONF_OUT})
    endif()
    # Executables
    if(HHC_EXECUTABLE OR QHG_EXECUTABLE)
        file(WRITE ${DOXY_CONF_OUT} "# Executables:\n")
        if(HHC_EXECUTABLE)
            doxy_add_option(${DOXY_CONF_OUT} HHC_LOCATION ${HHC_EXECUTABLE})
        endif()
        if(QHG_EXECUTABLE)
            doxy_add_option(${DOXY_CONF_OUT} QHG_LOCATION ${QHG_EXECUTABLE})
        endif()
    endif()
    # Formats
    file(APPEND ${DOXY_CONF_OUT} "\n# Formats:\n")
    foreach(FORMAT ${DOXY_FORMATS_ALL})
        if(DOXY_GEN_${FORMAT})
            doxy_add_option(${DOXY_CONF_OUT} GENERATE_${FORMAT} YES)
        else()
            doxy_add_option(${DOXY_CONF_OUT} GENERATE_${FORMAT} NO)
        endif()
    endforeach()
    file(APPEND ${DOXY_CONF_OUT} "\n# Options:\n")
    foreach(ARG IN LISTS DOXY_OPTIONS_BOOL DOXY_OPTIONS_SINGLE DOXY_OPTIONS_MULTI)
        if(DEFINED DOXY_${ARG})
            doxy_add_option(${DOXY_CONF_OUT} ${ARG} ${DOXY_${ARG}})
        endif()
    endforeach()

    #### Adding command
    add_custom_command(TARGET build_docs
                       COMMAND ${DOXYGEN_EXECUTABLE} ${DOXY_CONF_OUT}
                       COMMENT "Generating doxygen output")

    set(GENERATED_FILES ${GENERATED_FILES} ${DOXY_OUTPUT_DIRECTORY} PARENT_SCOPE)

endfunction()


#### Generate a Qt Help Collection
function(doxy_generate_qhc DOXY_QHC_FILE DOXY_QCH_LIST)

    #### Checking doxygen
    if(NOT DOXYGEN_FOUND)
        return()
    endif()

    #### Checking qcollectiongenerator
    if(NOT QCOLGEN_EXECUTABLE)
        unset(QCOLGEN_EXECUTABLE CACHE)
        find_program(QCOLGEN_EXECUTABLE "qcollectiongenerator")
    endif()
    if(NOT QCOLGEN_EXECUTABLE)
        message(WARNING "'qcollectiongenerator' is not found - Qt help collections will not be created")
        return()
    endif()

    #### Writing QHCP file
    file(WRITE ${DOXY_QHC_FILE}p
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<QHelpCollectionProject version=\"1.0\">\n"
        "    <docFiles>\n"
        "        <register>\n")
    foreach(QCH ${DOXY_QCH_LIST})
        file(APPEND ${DOXY_QHC_FILE}p
            "            <file>${QCH}</file>\n")
    endforeach()
    file(APPEND ${DOXY_QHC_FILE}p
        "        </register>\n"
        "    </docFiles>\n"
        "</QHelpCollectionProject>\n")

    #### Adding command to generate QHC file
    add_custom_command(TARGET build_docs
                       COMMAND ${QCOLGEN_EXECUTABLE} ${DOXY_QHC_FILE}p -o ${DOXY_QHC_FILE}
                       COMMENT "Generating Qt collection output")

endfunction()


#### Write a file for sources versions
function(write_sources_versions OUTPUT_FILE SOURCES)

    if(GIT_EXECUTABLE)

        list(REMOVE_ITEM ARGN ${OUTPUT_FILE} "CMakeLists.txt")

        file(WRITE ${OUTPUT_FILE} "/**\n")
        foreach(FILE ${ARGN})
            if(${FILE} MATCHES ".*(CMakeLists\\.txt)")
                continue()
            endif()
            execute_process(COMMAND ${GIT_EXECUTABLE} -C ${PROJECT_SOURCE_DIR} log -n 1 --pretty=format:%ci ${FILE}
                            OUTPUT_VARIABLE SOURCE_DATE
                            RESULT_VARIABLE RESULT)
            if(${RESULT} EQUAL 0)
                string(STRIP ${SOURCE_DATE} SOURCE_DATE)
                execute_process(COMMAND ${GIT_EXECUTABLE} -C ${PROJECT_SOURCE_DIR} log -n 1 --pretty=format:%h ${FILE}
                                OUTPUT_VARIABLE SOURCE_VERSION)
                string(STRIP ${SOURCE_VERSION} SOURCE_VERSION)
                file(APPEND ${OUTPUT_FILE}
                     " *\n * @file ${FILE}\n * @version ${SOURCE_VERSION}\n * @date ${SOURCE_DATE}\n")
            endif()
        endforeach()
        file(APPEND ${OUTPUT_FILE} " *\n **/\n\n")

    else()

        message(WARNING "Git is not found - sources versions can not be read")
        return()

    endif()

endfunction()
