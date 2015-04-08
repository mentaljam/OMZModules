####################### Documentation ######################

if(GENERATE_HTML OR GENERATE_HTMLHELP OR
   GENERATE_LATEX OR GENERATE_PDF OR
   GENERATE_MAN OR GENERATE_RTF OR GENERATE_XML)

    if(DOXYGEN_EXECUTABLE)
        set(DOXYGEN_FOUND "YES")
    else(DOXYGEN_EXECUTABLE)
        unset(DOXYGEN_EXECUTABLE CACHE)
        find_package(Doxygen)
    endif(DOXYGEN_EXECUTABLE)

    if(DOXYGEN_FOUND)
    message(STATUS "Configuring doxygen")

    #################### HTML CONFIGURATION ####################

        if(WIN32 AND GENERATE_HTMLHELP)
            if(NOT HHC)
                unset(HHC CACHE)
                find_program(HHC hhc)
            endif(NOT HHC)
            if(HHC)
                set(HTML_SEARCHENGINE "NO")
                unset(GENERATE_HTML CACHE)
                set(GENERATE_HTML "YES")
            elseif(HHC)
                message(AUTHOR_WARNING
                        "HTMLHELP compiler not found - Windows HELP will not be created")
            endif(HHC)
        endif(WIN32 AND GENERATE_HTMLHELP)

    #################### PDF CONFIGURATION #####################

        if(${GENERATE_PDF} STREQUAL "YES")
            if(NOT PDFLATEX)
                unset(PDFLATEX CACHE)
                find_program(PDFLATEX pdflatex)
            endif(NOT PDFLATEX)
            if(PDFLATEX)
                set(GENERATE_LATEX "YES")
                set(SED_LINE "'1s/.*/\\\\documentclass[oneside]{scrbook}\\n\\\\renewcommand{\\\\chapterheadstartvskip}{}/'")
            elseif(PDFLATEX)
                message(AUTHOR_WARNING
                        "pdflatex not found - PDF documentation will not be created")
            endif(PDFLATEX)
        endif(${GENERATE_PDF} STREQUAL "YES")

    ######################### TARGETS ##########################

        set(DOC_OUT ${CMAKE_BINARY_DIR}/manual)
        set(CHM_FILE ${DOC_OUT}/${CMAKE_PROJECT_NAME}.chm)
        set(CHM_GEN ../${CMAKE_PROJECT_NAME}.chm)
        set(DOXYGEN_INPUT "${PROJECT_SOURCE_DIR}/README.md ${DOC_DIR}/user")
        configure_file(${DOC_DIR}/doxygen.conf.in ${DOC_OUT}/doxygen.conf)
        file(GLOB MAN_SRC ${DOC_DIR}/user/*)
        add_custom_target(manual COMMAND ${DOXYGEN_EXECUTABLE} ${DOC_OUT}/doxygen.conf)
        if(GENERATE_PDF AND PDFLATEX)
            if(WIN32)
                set(MAKE_PDF ${DOC_OUT}/latex/make.bat)
            else(WIN32)
                set(MAKE_PDF make -C ${DOC_OUT}/latex)
                set(TEX_FORMAT sed -i ${SED_LINE} ${DOC_OUT}/latex/refman.tex)
            endif(WIN32)
            add_custom_target(manual-pdf COMMAND ${TEX_FORMAT}
                                         COMMAND ${MAKE_PDF}
                                         COMMAND ${CMAKE_COMMAND} -E copy ${DOC_OUT}/latex/refman.pdf
                                                                          ${DOC_OUT}/${CMAKE_PROJECT_NAME}-manual.pdf
                                         DEPENDS manual)
        endif(GENERATE_PDF AND PDFLATEX)
        file(GLOB DOC_GEN ${DOC_OUT}/*)
        set(GENERATED_FILES ${GENERATED_FILES} ${DOC_GEN})

        set(DOC_OUT ${CMAKE_BINARY_DIR}/dev_doc)
        set(DOXYGEN_INPUT "${PROJECT_SOURCE_DIR}/README.md ${DOC_DIR}/developer ${PROJECT_SOURCE_DIR}/src ${CMAKE_BINARY_DIR}/sources.h")
        file(GLOB DEV_SRC ${DOC_DIR}/development/*)
        configure_file(${DOC_DIR}/doxygen.conf.in ${DOC_OUT}/doxygen.conf)
        add_custom_target(dev_doc COMMAND ${DOXYGEN_EXECUTABLE} ${DOC_OUT}/doxygen.conf)
        if(GENERATE_PDF AND PDFLATEX)
            if(WIN32)
                set(MAKE_PDF ${DOC_OUT}/latex/make.bat)
            else(WIN32)
                set(MAKE_PDF make -C ${DOC_OUT}/latex)
                set(TEX_FORMAT sed -i ${SED_LINE} ${DOC_OUT}/latex/refman.tex)
            endif(WIN32)
            add_custom_target(dev_doc-pdf COMMAND ${TEX_FORMAT}
                                          COMMAND ${MAKE_PDF}
                                          COMMAND ${CMAKE_COMMAND} -E copy ${DOC_OUT}/latex/refman.pdf
                                                                           ${DOC_OUT}/${CMAKE_PROJECT_NAME}-dev.pdf
                                          DEPENDS dev_doc)
        endif(GENERATE_PDF AND PDFLATEX)
        file(GLOB DOC_GEN ${DOC_OUT}/*)
        set(GENERATED_FILES ${GENERATED_FILES} ${DOC_GEN})

    else(DOXYGEN_FOUND)
        message(AUTHOR_WARNING
                "Doxygen not found - Documentation will not be created")
    endif(DOXYGEN_FOUND)

endif(GENERATE_HTML OR GENERATE_HTMLHELP OR
      GENERATE_LATEX OR GENERATE_PDF OR
      GENERATE_MAN OR GENERATE_RTF OR GENERATE_XML)
