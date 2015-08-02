####################### Documentation ######################

if(GENERATE_HTML OR GENERATE_HTMLHELP OR GENERATE_LATEX OR
   GENERATE_PDF OR GENERATE_MAN OR GENERATE_RTF OR GENERATE_XML)

    if(DOXYGEN_EXECUTABLE)
        set(DOXYGEN_FOUND "YES")
    else()
        unset(DOXYGEN_EXECUTABLE CACHE)
        find_package(Doxygen)
    endif()

    if(DOXYGEN_FOUND)
    message(STATUS "Configuring doxygen")

    #################### HTML CONFIGURATION ####################

        if(WIN32 AND GENERATE_HTMLHELP)
            if(NOT HHC)
                unset(HHC CACHE)
                find_program(HHC hhc)
            endif()
            if(HHC)
                set(HTML_SEARCHENGINE "NO")
                unset(GENERATE_HTML CACHE)
                set(GENERATE_HTML "YES")
            else()
                message(AUTHOR_WARNING "HTMLHELP compiler not found - Windows HELP will not be created")
            endif()
        endif()

    #################### PDF CONFIGURATION #####################

        if(${GENERATE_PDF} STREQUAL "YES")
            if(NOT PDFLATEX)
                unset(PDFLATEX CACHE)
                find_program(PDFLATEX pdflatex)
            endif(NOT PDFLATEX)
            if(PDFLATEX)
                set(GENERATE_LATEX "YES")
                set(SED_LINE "'1s/.*/\\\\documentclass[oneside]{scrbook}\\n\\\\renewcommand{\\\\chapterheadstartvskip}{}/'")
            elseif()
                message(AUTHOR_WARNING "pdflatex not found - PDF documentation will not be created")
            endif()
        endif()

    ######################### TARGETS ##########################

        file(GLOB MAN_DIRS ${DOC_DIR}/user/*)
        foreach(MAN_DIR ${MAN_DIRS})
            if(IS_DIRECTORY ${MAN_DIR})
                get_filename_component(MAN_PRJ ${MAN_DIR} NAME)
                set(DOC_OUT ${CMAKE_BINARY_DIR}/doc/manual/${MAN_PRJ})
                set(CHM_FILES ${CHM_FILES} ${DOC_OUT}/${MAN_PRJ}.chm)
                set(CHM_GEN ../${MAN_PRJ}.chm)
                set(DOXYGEN_INPUT ${MAN_DIR})
                configure_file(${DOC_DIR}/doxygen.conf.in ${DOC_OUT}/doxygen.conf)
                add_custom_target(manual COMMAND ${DOXYGEN_EXECUTABLE} ${DOC_OUT}/doxygen.conf)
                if(GENERATE_PDF AND PDFLATEX)
                    if(WIN32)
                        set(MAKE_PDF ${DOC_OUT}/latex/make.bat)
                    else()
                        set(MAKE_PDF make -C ${DOC_OUT}/latex)
                        set(TEX_FORMAT sed -i ${SED_LINE} ${DOC_OUT}/latex/refman.tex)
                    endif()
                    add_custom_target(manual-pdf COMMAND ${TEX_FORMAT}
                                                 COMMAND ${MAKE_PDF}
                                                 COMMAND ${CMAKE_COMMAND} -E copy ${DOC_OUT}/latex/refman.pdf
                                                                                  ${DOC_OUT}/${CMAKE_PROJECT_NAME}-manual.pdf
                                                 DEPENDS manual)
                endif()
                set(GENERATED_FILES ${GENERATED_FILES} ${DOC_OUT})
            endif()
        endforeach()

        set(DOC_OUT ${CMAKE_BINARY_DIR}/doc/developer)
        set(DOXYGEN_INPUT "${PROJECT_SOURCE_DIR}/README.md ${DOC_DIR}/developer ${PROJECT_SOURCE_DIR}/src ${CMAKE_BINARY_DIR}/sources.h")
        file(GLOB DEV_SRC ${DOC_DIR}/development/*)
        configure_file(${DOC_DIR}/doxygen.conf.in ${DOC_OUT}/doxygen.conf)
        add_custom_target(dev_doc COMMAND ${DOXYGEN_EXECUTABLE} ${DOC_OUT}/doxygen.conf)
        if(GENERATE_PDF AND PDFLATEX)
            if(WIN32)
                set(MAKE_PDF ${DOC_OUT}/latex/make.bat)
            else()
                set(MAKE_PDF make -C ${DOC_OUT}/latex)
                set(TEX_FORMAT sed -i ${SED_LINE} ${DOC_OUT}/latex/refman.tex)
            endif()
            add_custom_target(dev_doc-pdf COMMAND ${TEX_FORMAT}
                                          COMMAND ${MAKE_PDF}
                                          COMMAND ${CMAKE_COMMAND} -E copy ${DOC_OUT}/latex/refman.pdf
                                                                           ${DOC_OUT}/${CMAKE_PROJECT_NAME}-dev.pdf
                                          DEPENDS dev_doc)
        endif()
        file(GLOB DOC_GEN ${DOC_OUT}/*)
        set(GENERATED_FILES ${GENERATED_FILES} ${DOC_GEN})

    else(DOXYGEN_FOUND)
        message(AUTHOR_WARNING "Doxygen not found - Documentation will not be created")
    endif()

endif()
