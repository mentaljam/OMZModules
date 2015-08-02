############ Generate CMake script for debuild #############
#
# Based on the work of
#
#       Daniel Pfeifer <daniel@pfeifer-mail.de>
#       Rosen Diankov  <rosen.diankov@gmail.com>
#
# Variables:
# - CPACK_DEBIAN_BUILD_DEPENDS
# - CPACK_DEBIAN_PACKAGE_DEPENDS
# - CPACK_DEBIAN_DISTRIBUTION_NAMES
# - CPACK_DEBIAN_CHANGELOG
# - CPACK_DEBIAN_DISTRIB_REVISION
# - CPACK_DEBIAN_PREBUILD
# - CPACK_DEBIAN_CMAKE_ARGUMENTS
##

#### Find executables
find_program(DEBUILD_EXECUTABLE debuild)
find_program(DPUT_EXECUTABLE    dput)

if(DEBUILD_EXECUTABLE AND DPUT_EXECUTABLE)

    message(STATUS "Configuring debian source package target")

    #### Variables

    set(TARGET_FILE ${CMAKE_BINARY_DIR}/BuildDebSource.cmake)
    file(WRITE ${TARGET_FILE} "############### Build debian source package ################\n\n")

    if(NOT CPACK_DEBIAN_BUILD_DEPENDS)
        set(CPACK_DEBIAN_BUILD_DEPENDS debhelper cmake)
    endif()
    if(NOT CPACK_DEBIAN_DISTRIBUTION_NAMES)
        set(CPACK_DEBIAN_DISTRIBUTION_NAMES debian)
    endif()
    if(NOT CPACK_DEBIAN_DISTRIB_REVISION)
        set(CPACK_DEBIAN_DISTRIB_REVISION 1)
    endif()
    if(NOT CPACK_DEBIAN_CHANGELOG)
        set(CPACK_DEBIAN_CHANGELOG "  * Nothing there")
    endif()

    if(GIT)
        execute_process(COMMAND ${GIT} -C ${PROJECT_SOURCE_DIR} log -n 1 --pretty=format:%aD
                        OUTPUT_VARIABLE BUILD_DATE)
    else()
        execute_process(COMMAND date -R OUTPUT_VARIABLE BUILD_DATE)
    endif()
    set(LAST_MODIFIED " -- ${CPACK_PACKAGE_CONTACT}  ${BUILD_DATE}")

    foreach(COMPONENT ${CPACK_COMPONENTS_ALL})
        string(TOUPPER ${COMPONENT} UPPER_COMPONENT)
        file(APPEND ${TARGET_FILE}
            "set(CPACK_COMPONENT_${UPPER_COMPONENT}_DESCRIPTION \"${CPACK_COMPONENT_${UPPER_COMPONENT}_DESCRIPTION}\")\n"
            "set(CPACK_COMPONENT_${UPPER_COMPONENT}_DEPENDS \"${CPACK_COMPONENT_${UPPER_COMPONENT}_DEPENDS}\")\n"
        )
    endforeach()

    #### Working directory
    file(APPEND ${TARGET_FILE}
            "\nfile(REMOVE_RECURSE Debian)\n"
            "file(MAKE_DIRECTORY Debian)\n"
            "set(DEBIAN_SOURCE_ORIG_PATH ${CMAKE_BINARY_DIR}/Debian/${CMAKE_PROJECT_NAME}_${V_VERSION})\n\n"
    )

    #### Copy sources
    file(APPEND ${TARGET_FILE}
            "execute_process(COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR} \${DEBIAN_SOURCE_ORIG_PATH}.orig)\n"
            "string(REPLACE \"\\\\\" \"\" IGNORING_ENTRIES \"${CPACK_SOURCE_IGNORE_FILES}\")\n"
            "foreach(IGNORING_ENTRY \${IGNORING_ENTRIES})\n"
            "    set(IGNORING_ENTRY \${DEBIAN_SOURCE_ORIG_PATH}.orig\${IGNORING_ENTRY})\n"
            "    if(IS_DIRECTORY \${IGNORING_ENTRY})\n"
            "        file(REMOVE_RECURSE \${IGNORING_ENTRY})\n"
            "    else()\n"
            "        file(GLOB IGNORING_ENTRY \${IGNORING_ENTRY}*)\n"
            "        if(IGNORING_ENTRY)\n"
            "            file(REMOVE \${IGNORING_ENTRY})\n"
            "        endif()\n"
            "    endif()\n"
            "endforeach()\n\n"
    )

    #### Create the original source tar
    file(APPEND ${TARGET_FILE}
            "execute_process(COMMAND ${CMAKE_COMMAND} -E tar czf \${DEBIAN_SOURCE_ORIG_PATH}.orig.tar.gz \${DEBIAN_SOURCE_ORIG_PATH}.orig\n"
            "                WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/Debian)\n\n"
    )

    #### Start distributions loop
    file(APPEND ${TARGET_FILE}
            "foreach(DISTR ${CPACK_DEBIAN_DISTRIBUTION_NAMES})\n\n"
            "    set(RELEASE_PACKAGE_VERSION -1~\${DISTR}${CPACK_DEBIAN_DISTRIB_REVISION})\n"
            "    set(DEBIAN_SOURCE_DIR \${DEBIAN_SOURCE_ORIG_PATH}\${RELEASE_PACKAGE_VERSION})\n"
            "    set(RELEASE_PACKAGE_VERSION ${V_VERSION}\${RELEASE_PACKAGE_VERSION})\n"
            "    file(MAKE_DIRECTORY \${DEBIAN_SOURCE_DIR}/debian)\n\n")

    #### File: debian/control
    file(APPEND ${TARGET_FILE}
            "    set(DEBIAN_CONTROL \${DEBIAN_SOURCE_DIR}/debian/control)\n"
            "    file(WRITE \${DEBIAN_CONTROL}\n"
            "           \"Source: ${CMAKE_PROJECT_NAME}\\n\"\n"
            "           \"Section: devel\\n\"\n"
            "           \"Priority: optional\\n\"\n"
            "           \"Maintainer: ${CPACK_PACKAGE_CONTACT}\\n\"\n"
            "           \"Build-Depends: \"\n"
            "    )\n"
            "    foreach(DEP ${CPACK_DEBIAN_BUILD_DEPENDS})\n"
            "        file(APPEND \${DEBIAN_CONTROL} \"\${DEP}, \")\n"
            "    endforeach()\n"
            "    file(APPEND \${DEBIAN_CONTROL}\n"
            "            \"\\nStandards-Version: 3.8.4\\n\"\n"
            "            \"Homepage: ${WEB}\\n\\n\"\n"
            "            \"Package: ${CMAKE_PROJECT_NAME}\\n\"\n"
            "            \"Architecture: ${COMPILED_ARCH}\\n\"\n"
            "            \"Suggests: ${CPACK_DEBIAN_BUILD_SUGGESTS}\\n\"\n"
            "            \"Depends: \"\n"
            "    )\n"
            "    foreach(DEP ${CPACK_DEBIAN_PACKAGE_DEPENDS})\n"
            "        file(APPEND \${DEBIAN_CONTROL} \"\${DEP}, \")\n"
            "    endforeach()\n"
            "    file(APPEND \${DEBIAN_CONTROL} \"\\nDescription: ${CPACK_PACKAGE_DESCRIPTION_SUMMARY}\n"
            "${CPACK_DEBIAN_PACKAGE_DESCRIPTION}\\n\"\n"
            "    )\n"
            "    foreach(COMPONENT ${CPACK_COMPONENTS_ALL})\n"
            "        string(TOUPPER \${COMPONENT} UPPER_COMPONENT)\n"
            "        set(DEPENDS \"\\\${shlibs:Depends}\")\n"
            "        foreach(DEP \${CPACK_COMPONENT_\${UPPER_COMPONENT}_DEPENDS})\n"
            "            set(DEPENDS \"\${DEPENDS}, \${DEP}\")\n"
            "        endforeach()\n"
            "        file(APPEND \${DEBIAN_CONTROL}\n"
            "                \"\\nPackage: \${COMPONENT}\\n\"\n"
            "                \"Architecture: ${COMPILED_ARCH}\\n\"\n"
            "                \"Depends: \${DEPENDS}\\n\"\n"
            "                \"Description: \${CPACK_COMPONENT_\${UPPER_COMPONENT}_DESCRIPTION}\\n\"\n"
            "        )\n"
            "    endforeach()\n\n"
    )

    #### File: debian/copyright
    file(APPEND ${TARGET_FILE}
            "    set(DEBIAN_COPYRIGHT \${DEBIAN_SOURCE_DIR}/debian/copyright)\n"
            "    configure_file(${CPACK_RESOURCE_FILE_LICENSE} \${DEBIAN_COPYRIGHT} COPYONLY)\n\n"
    )

    #### File: debian/rules
    file(APPEND ${TARGET_FILE}
            "    set(DEBIAN_RULES \${DEBIAN_SOURCE_DIR}/debian/rules)\n"
            "    file(WRITE \${DEBIAN_RULES}\n"
            "            \"#!/usr/bin/make -f\\n\\n\"\n"
            "            \"BUILDDIR = build_dir\\n\\n\"\n"
            "            \"build:\\n\"\n"
            "            \"\t${CPACK_DEBIAN_PREBUILD}\\n\"\n"
            "            \"\tmkdir $(BUILDDIR)\\n\"\n"
            "            \"\tcd $(BUILDDIR); cmake ${CPACK_DEBIAN_CMAKE_ARGUMENTS} "
                                                  "-DCMAKE_BUILD_TYPE=Release "
                                                  "-DCPACK_PACKAGE_VERSION_MAJOR=\\\"${CPACK_PACKAGE_VERSION_MAJOR}\\\" "
                                                  "-DCPACK_PACKAGE_VERSION_MINOR=\\\"${CPACK_PACKAGE_VERSION_MINOR}\\\" "
                                                  "-DCPACK_PACKAGE_VERSION_PATCH=\\\"${CPACK_PACKAGE_VERSION_PATCH}\\\" "
                                                  "-DV_DATE=\\\"${V_DATE}\\\" "
                                                  "-DCMAKE_INSTALL_PREFIX=../debian/tmp/usr ..\\n\"\n"
            "            \"\t$(MAKE) -C $(BUILDDIR) preinstall\\n\"\n"
            "            \"\ttouch build\\n\\n\"\n"
            "            \"binary: binary-indep binary-arch\\n\\n\"\n"
            "            \"binary-indep: build\\n\\n\"\n"
            "            \"binary-arch: build\\n\"\n"
            "            \"\tcd $(BUILDDIR); cmake -P cmake_install.cmake\\n\"\n"
            "            \"\tmkdir -p debian/tmp/DEBIAN\\n\"\n"
            "            \"\tdpkg-gensymbols -p${CMAKE_PROJECT_NAME}\\n\"\n"
            "    )\n"
            "    foreach(COMPONENT ${CPACK_COMPONENTS_ALL})\n"
            "        set(PATH debian/\${COMPONENT})\n"
            "        file(APPEND \${DEBIAN_RULES}\n"
            "            \"\tcd $(BUILDDIR); cmake -DCOMPONENT=\${COMPONENT} -DCMAKE_INSTALL_PREFIX=../\${PATH}/usr -P cmake_install.cmake\\n\"\n"
            "            \"\tmkdir -p \${PATH}/DEBIAN\\n\"\n"
            "            \"\tdpkg-gensymbols -p\${COMPONENT} -P\${PATH}\\n\"\n"
            "        )\n"
            "    endforeach()\n"
            "    file(APPEND \${DEBIAN_RULES}\n"
            "            \"\tdh_shlibdeps\\n\"\n"
            "            \"\tdh_strip\\n\"\n"
            "            \"\tdpkg-gencontrol -p${CMAKE_PROJECT_NAME}\\n\"\n"
            "            \"\tdpkg --build debian/tmp ..\\n\"\n"
            "    )\n"
            "    foreach(COMPONENT ${CPACK_COMPONENTS_ALL})\n"
            "        set(PATH debian/\${COMPONENT})\n"
            "        file(APPEND \${DEBIAN_RULES}\n"
            "            \"\tdpkg-gencontrol -p\${COMPONENT} -P\${PATH} -Tdebian/\${COMPONENT}.substvars\\n\"\n"
            "            \"\tdpkg --build \${PATH} ..\\n\"\n"
            "        )\n"
            "    endforeach()\n"
            "    file(APPEND \${DEBIAN_RULES}\n"
            "            \"\\nclean:\\n\"\n"
            "            \"\trm -f build\\n\"\n"
            "            \"\trm -rf $(BUILDDIR)\\n\\n\"\n"
            "            \".PHONY: binary binary-arch binary-indep clean\\n\"\n"
            "    )\n"
            "    execute_process(COMMAND chmod +x \${DEBIAN_RULES})\n"
    )

    #### File: debian/compat
    file(APPEND ${TARGET_FILE}
            "    file(WRITE \${DEBIAN_SOURCE_DIR}/debian/compat \"7\")\n"
    )

    #### File: debian/source/format
    file(APPEND ${TARGET_FILE}
            "    file(WRITE \${DEBIAN_SOURCE_DIR}/debian/source/format \"3.0 (quilt)\")\n"
    )

    #### File: debian/changelog
    file(APPEND ${TARGET_FILE}
            "    set(DEBIAN_CHANGELOG \${DEBIAN_SOURCE_DIR}/debian/changelog)\n"
            "    execute_process(COMMAND \"LANG=en\" \"date\" OUTPUT_VARIABLE BUILD_DATE)\n"
            "    file(WRITE \${DEBIAN_CHANGELOG}\n"
            "            \"${CMAKE_PROJECT_NAME} (\${RELEASE_PACKAGE_VERSION}) \${DISTR}; urgency=low\\n\\n\"\n"
            "            \"${CPACK_DEBIAN_CHANGELOG}\\n\\n\"\n"
            "            \"${LAST_MODIFIED}\\n\"\n"
            "    )\n"
    )

    #### Command: debuild -S
    file(APPEND ${TARGET_FILE}
            "    if(DEB_SOURCE_CHANGES)\n"
            "        set(DEBUILD_OPTIONS -sd)\n"
            "    else()\n"
            "        set(DEBUILD_OPTIONS -sa)\n"
            "    endif()\n"
            "    set(SOURCE_CHANGES_FILE ${CMAKE_PROJECT_NAME}_\${RELEASE_PACKAGE_VERSION}_source.changes)\n"
            "    list(APPEND DEB_SOURCE_CHANGES \${SOURCE_CHANGES_FILE})\n"
            "    execute_process(COMMAND ${DEBUILD_EXECUTABLE} -S \${DEBUILD_OPTIONS} WORKING_DIRECTORY \${DEBIAN_SOURCE_DIR})\n"
            "endforeach()\n\n"
    )

else()

    if(NOT DEBUILD_EXECUTABLE)
        message(AUTHOR_WARNING "Could not find 'debuild' executable")
    endif()
    if(NOT DPUT_EXECUTABLE)
        message(AUTHOR_WARNING "Could not find 'dput' executable")
    endif()
    message(AUTHOR_WARNING "Debian source package would not be built")

endif()
