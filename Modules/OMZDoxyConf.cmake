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
                  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
)

if(DOXYGEN_FOUND)

    message(STATUS "Configuring doxygen")

    set(DOXY_FORMATS_ALL HTML HTMLHELP QHP LATEX PDF MAN RTF XML DOCBOOK)
    set(DOXY_CONF_IN ${CMAKE_CURRENT_LIST_DIR}/doxygen.conf.in)

else(DOXYGEN_FOUND)

    message(WARNING "Doxygen not found - Documentation will not be created")

    add_custom_command(TARGET build_docs
                       COMMAND ${CMAKE_COMMAND} -E cmake_echo_color --red "No doxygen executable was found, skipping..."
    )

endif()


######################### Functions ########################

#### Add documentation target
function(doxy_add_target)

    #### Checking doxygen
    if(NOT DOXYGEN_FOUND)
        return()
    endif()

    #### Parse arguments
    cmake_parse_arguments("DOXY"
                          "HTMLHELP;QHP;PDF"
                          "NAME;LOGO;OUT_DIRECTORY;LANGUAGE;HTML_STYLESHEET;CHM_FILE;QCH_FILE;QHP_NAMESPACE;QHP_VIRTUAL_FOLDER;QHP_FILTER_NAME;QHP_FILTER_ATTRS"
                          "INPUT;FORMATS;FILE_PATTERNS;EXCLUDE_PATTERNS"
                          ${ARGN}
    )

    #### Exit function if there is no input specified
    if(NOT DOXY_INPUT)
        message(AUTHOR_WARNING "No input files were specified. Make shure the 'INPUT' argument is not empty.")
        return()
    endif()
    #### Prepare input string for doxygen.conf
    string(REPLACE ";" " " DOXY_INPUT "${DOXY_INPUT}")

    #### Check project name
    if(NOT DOXY_NAME)
        set(DOXY_NAME "${PROJECT_NAME}")
    endif()
    #### Prepare strings for file names
    string(REGEX REPLACE "[\\/\\\\\\?%\\*:\\|\"<>. ]" "_" DOXY_NAME_FIX "${DOXY_NAME}")
    string(TOLOWER ${DOXY_NAME_FIX} DOXY_NAME_FIX_LOWER)

    #### Check output directory
    if(NOT DOXY_OUT_DIRECTORY)
        set(DOXY_OUT_DIRECTORY "${CMAKE_BINARY_DIR}/doc")
    endif()
    #### Set doxygen.conf path
    set(DOXY_CONF_OUT "${DOXY_OUT_DIRECTORY}/${DOXY_NAME_FIX_LOWER}_doxygen.conf")

    #### Check language
    if(NOT DOXY_LANGUAGE)
        set(DOXY_LANGUAGE "English")
    endif()

    #### Check formats and process extra options for HTMLHELP, QHP and PDF
    if(DOXY_HTMLHELP OR DOXY_QHP OR DOXY_PDF OR NOT DOXY_FORMATS)

        set(DOXY_FORMATS "html")

        #### HTMLHELP
        if(DOXY_HTMLHELP)

            if(NOT HHC_EXECUTABLE)
                unset(HHC_EXECUTABLE CACHE)
                find_program(HHC_EXECUTABLE "hhc")
            endif()
            if(HHC_EXECUTABLE)
                list(APPEND DOXY_FORMATS "htmlhelp")
                set(DOXY_HTML_SEARCHENGINE "NO")
                set(DOXY_DISABLE_INDEX "YES")
                set(DOXY_GRAPHVIS "NO")
            else()
                message(WARNING "'hhc' compiler is not found - Windows HELP files will not be created")
            endif()

        #### QHP
        elseif(DOXY_QHP)

            if(NOT QHG_EXECUTABLE)
                unset(QHG_EXECUTABLE CACHE)
                find_program(QHG_EXECUTABLE "qhelpgenerator")
            endif()
            if(QHG_EXECUTABLE)
                list(APPEND DOXY_FORMATS "qhp")
                set(DOXY_HTML_SEARCHENGINE "NO")
                set(DOXY_DISABLE_INDEX "YES")
                set(DOXY_GRAPHVIS "NO")
            else()
                message(WARNING "'qhelpgenerator' is not found - Qt HELP files will not be created")
            endif()

        elseif(DOXY_PDF)

            if(NOT PDFLATEX_EXECUTABLE)
                unset(PDFLATEX_EXECUTABLE CACHE)
                find_program(PDFLATEX_EXECUTABLE pdflatex)
            endif()
            if(PDFLATEX_EXECUTABLE)
                list(APPEND DOXY_FORMATS "latex")
                if(WIN32)
                    set(PDF_MAKE_FILE "${DOXY_OUT_DIRECTORY}/latex/make.bat")
                else()
                    set(PDF_MAKE_FILE make -C "${DOC_OUT}/latex")
                    set(TEX_FORMAT sed -i "'1s/.*/\\\\documentclass[oneside]{scrbook}\\n\\\\renewcommand{\\\\chapterheadstartvskip}{}/'"
                                   "${DOC_OUT}/latex/refman.tex")
                endif()
                add_custom_command(TARGET build_docs
                                   COMMAND ${TEX_FORMAT}
                                   COMMAND ${MAKE_PDF}
                                   COMMAND ${CMAKE_COMMAND} -E copy ${DOXY_OUT_DIRECTORY}/latex/refman.pdf
                                                                    ${DOXY_OUT_DIRECTORY}/${DOXY_NAME_FIX_LOWER}.pdf
                                   COMMENT "Generating documentation in PDF"
                                   VERBATIM
                )
            elseif()
                message(WARNING "'pdflatex' not found - PDF documentation will not be created")
            endif()

        endif()

    endif()

    #### Check file patterns
    if(NOT DOXY_FILE_PATTERNS)
        set(DOXY_FILE_PATTERNS "*.h *.h.in *.hpp *.cpp *.md *.txt")
    endif()

    #### Create output directory
    file(MAKE_DIRECTORY "${DOXY_OUT_DIRECTORY}")

    #### Process formats variables
    foreach(FORMAT ${DOXY_FORMATS})
        string(TOUPPER ${FORMAT} FORMAT_UPPER)
        list(FIND DOXY_FORMATS_ALL ${FORMAT_UPPER} IND)
        if(NOT IND EQUAL -1)
            set(DOXY_GEN_${FORMAT_UPPER} "YES")
        else()
            message(WARNING "Unknown doxygen format '${FORMAT}'")
        endif()
    endforeach()

    foreach(FORMAT ${DOXY_FORMATS_ALL})
        if(NOT DOXY_GEN_${FORMAT})
            set(DOXY_GEN_${FORMAT} "NO")
        endif()
    endforeach()

    #### Adding command
    add_custom_command(TARGET build_docs
                       COMMAND ${DOXYGEN_EXECUTABLE} ${DOXY_CONF_OUT}
                       COMMENT "Generating doxygen output"
    )

    #### Generating doxygen.conf file
    if(EXISTS ${DOXY_CONF_OUT})
        file(REMOVE ${DOXY_CONF_OUT})
    endif()
    configure_file(${DOXY_CONF_IN} ${DOXY_CONF_OUT})

    set(GENERATED_FILES ${GENERATED_FILES} ${DOXY_OUT_DIRECTORY} PARENT_SCOPE)

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
        "        <register>\n"
    )
    foreach(QCH ${DOXY_QCH_LIST})
        file(APPEND ${DOXY_QHC_FILE}p
            "            <file>${QCH}</file>\n"
        )
    endforeach()
    file(APPEND ${DOXY_QHC_FILE}p
        "        </register>\n"
        "    </docFiles>\n"
        "</QHelpCollectionProject>\n"
    )

    #### Adding command to generate QHC file
    add_custom_command(TARGET build_docs
                       COMMAND ${QCOLGEN_EXECUTABLE} ${DOXY_QHC_FILE}p -o ${DOXY_QHC_FILE}
                       COMMENT "Generating Qt collection output"
    )

endfunction()
