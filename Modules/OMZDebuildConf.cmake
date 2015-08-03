############ Generate CMake script for debuild #############
#
# Based on the work of
#
#       Daniel Pfeifer <daniel@pfeifer-mail.de>
#       Rosen Diankov  <rosen.diankov@gmail.com>
#
# Input variables:
# - CPACK_DEBIAN_BUILD_DEPENDS
# - CPACK_DEBIAN_PACKAGE_DEPENDS
# - CPACK_DEBIAN_DISTRIBUTION_NAMES
# - CPACK_DEBIAN_CHANGELOG
# - CPACK_DEBIAN_DISTRIB_REVISION
# - CPACK_DEBIAN_PREBUILD
# - CPACK_DEBIAN_CMAKE_ARGUMENTS
# - CPACK_DEBIAN_COMPONENT_INSTALL
# - CPACK_DEBIAN_<COMPONENT>_BUILD_DEPENDS
# - CPACK_DEBIAN_PPA
#
# Internal variables
# - CPACK_GROUPS
# - CPACK_GROUP_<GROUP>_COMPONENTS
# - CPACK_GROUP_<GROUP>_DEPENDS
# - LAST_MODIFIED
# - TARGET_FILE
# - CPACK_DEBIAN_TOTAL_BUILD_DEPENDS
#
# Output
# - BuildDebSource.cmake
# - Target 'debian_source_package'
# - Target 'upload_debian_source_package'
##

#### Find executables
find_program(DEBUILD_EXECUTABLE debuild)
find_program(DPUT_EXECUTABLE    dput)

if(DEBUILD_EXECUTABLE)

    message(STATUS "Configuring debian source package target")

    #### Target file
    set(TARGET_FILE ${CMAKE_BINARY_DIR}/BuildDebSource.cmake)
    file(WRITE ${TARGET_FILE}
            "############### Build debian source package ################\n\n"
    )

    #### Prepare components, components groups and total dependencies
    ## Groups lists
    set(CPACK_DEBIAN_TOTAL_BUILD_DEPENDS ${CPACK_DEBIAN_BUILD_DEPENDS})
    foreach(COMPONENT ${CPACK_COMPONENTS_ALL})
        string(TOUPPER ${COMPONENT} UPPER_COMPONENT)
        if(NOT CPACK_COMPONENT_${UPPER_COMPONENT}_GROUP)
            set(CPACK_COMPONENT_${UPPER_COMPONENT}_GROUP ${COMPONENT})
        endif()
        list(APPEND CPACK_GROUPS ${CPACK_COMPONENT_${UPPER_COMPONENT}_GROUP})
        list(APPEND CPACK_GROUP_${CPACK_COMPONENT_${UPPER_COMPONENT}_GROUP}_COMPONENTS ${COMPONENT})
        list(APPEND CPACK_GROUP_${CPACK_COMPONENT_${UPPER_COMPONENT}_GROUP}_DEPENDS
                    ${CPACK_COMPONENT_${UPPER_COMPONENT}_DEPENDS})
        list(APPEND CPACK_DEBIAN_TOTAL_BUILD_DEPENDS ${CPACK_DEBIAN_${UPPER_COMPONENT}_BUILD_DEPENDS})
    endforeach()
    ## Remove duplicates
    if(CPACK_GROUPS)
        list(REMOVE_DUPLICATES CPACK_GROUPS)
    endif()
    list(APPEND CPACK_DEBIAN_TOTAL_BUILD_DEPENDS debhelper cmake)
    list(REMOVE_DUPLICATES CPACK_DEBIAN_TOTAL_BUILD_DEPENDS)
    ## Dependecies handling: "remove depend on myself" and make new names "project-component"
    foreach(GROUP ${CPACK_GROUPS})
        if(CPACK_GROUP_${GROUP}_DEPENDS)
            list(REMOVE_DUPLICATES CPACK_GROUP_${GROUP}_DEPENDS)
            list(REMOVE_ITEM CPACK_GROUP_${GROUP}_DEPENDS ${CPACK_GROUP_${GROUP}_COMPONENTS})
            unset(NEW_DEPENDS)
            foreach(DEPENDS ${CPACK_GROUP_${GROUP}_DEPENDS})
                list(APPEND NEW_DEPENDS ${CMAKE_PROJECT_NAME}-${DEPENDS})
            endforeach()
            set(CPACK_GROUP_${GROUP}_DEPENDS ${NEW_DEPENDS})
        endif()
    endforeach()

    #### Check distibution names
    if(NOT CPACK_DEBIAN_DISTRIBUTION_NAMES)
        set(CPACK_DEBIAN_DISTRIBUTION_NAMES debian)
    endif()

    #### Check package revision
    if(NOT CPACK_DEBIAN_DISTRIB_REVISION)
        set(CPACK_DEBIAN_DISTRIB_REVISION 1)
    endif()

    #### Check changelog
    if(NOT CPACK_DEBIAN_CHANGELOG)
        set(CPACK_DEBIAN_CHANGELOG "  * Nothing there")
    endif()

    #### Use last commit date from git or current time if no git
    if(GIT)
        execute_process(COMMAND ${GIT} -C ${PROJECT_SOURCE_DIR} log -n 1 --pretty=format:%aD
                        OUTPUT_VARIABLE BUILD_DATE)
    else()
        execute_process(COMMAND date -R OUTPUT_VARIABLE BUILD_DATE)
    endif()
    set(LAST_MODIFIED " -- ${CPACK_PACKAGE_CONTACT}  ${BUILD_DATE}")

    #### Architecture
    if(${COMPILED_ARCH} STREQUAL all)
        set(ARCH all)
    else()
        set(ARCH any)
    endif()

    #### Working directory and original sources
    file(APPEND ${TARGET_FILE}
            "if(EXISTS \${CMAKE_CURRENT_LIST_DIR}/CPackConfig.cmake)\n"
            "    include(\${CMAKE_CURRENT_LIST_DIR}/CPackConfig.cmake)\n"
            "else()\n"
            "    message(FATAL_ERROR \"Need 'CPackConfig.cmake' to process\")\n"
            "endif()\n"
            "file(MAKE_DIRECTORY \${CMAKE_CURRENT_LIST_DIR}/Debian)\n"
            "set(DEBIAN_SOURCE_ORIG_PATH \${CMAKE_CURRENT_LIST_DIR}/Debian/${CMAKE_PROJECT_NAME}_${V_VERSION})\n"
            "if(NOT CPACK_DEBIAN_DISTRIB_REVISION EQUAL 1 AND EXISTS \${DEBIAN_SOURCE_ORIG_PATH})\n"
            "    file(REMOVE_RECURSE \${DEBIAN_SOURCE_ORIG_PATH})\n"
            "    execute_process(COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR} \${DEBIAN_SOURCE_ORIG_PATH}.orig)\n"
            "    string(REPLACE \"\\\\\" \"\" IGNORING_ENTRIES \"\${CPACK_SOURCE_IGNORE_FILES}\")\n"
            "    foreach(IGNORING_ENTRY \${IGNORING_ENTRIES})\n"
            "        set(IGNORING_ENTRY \${DEBIAN_SOURCE_ORIG_PATH}.orig\${IGNORING_ENTRY})\n"
            "        if(IS_DIRECTORY \${IGNORING_ENTRY})\n"
            "            file(REMOVE_RECURSE \${IGNORING_ENTRY})\n"
            "        else()\n"
            "            file(GLOB IGNORING_ENTRY \${IGNORING_ENTRY}*)\n"
            "            if(IGNORING_ENTRY)\n"
            "                file(REMOVE \${IGNORING_ENTRY})\n"
            "            endif()\n"
            "        endif()\n"
            "    endforeach()\n"
            "endif()\n\n"
    )

    #### Create the original source tar
    file(APPEND ${TARGET_FILE}
            "if(NOT EXISTS \${DEBIAN_SOURCE_ORIG_PATH}.orig.tar.gz)\n"
            "    execute_process(COMMAND ${CMAKE_COMMAND} -E tar czf \${DEBIAN_SOURCE_ORIG_PATH}.orig.tar.gz \${DEBIAN_SOURCE_ORIG_PATH}.orig\n"
            "                    WORKING_DIRECTORY \${CMAKE_CURRENT_LIST_DIR}/Debian)\n"
            "endif()\n\n"
    )

    #### Start distributions loop
    file(APPEND ${TARGET_FILE}
            "foreach(DISTR \${CPACK_DEBIAN_DISTRIBUTION_NAMES})\n\n"
            "    set(RELEASE_PACKAGE_VERSION -1~\${DISTR}\${CPACK_DEBIAN_DISTRIB_REVISION})\n"
            "    set(DEBIAN_SOURCE_DIR \${DEBIAN_SOURCE_ORIG_PATH}\${RELEASE_PACKAGE_VERSION})\n"
            "    set(RELEASE_PACKAGE_VERSION ${V_VERSION}\${RELEASE_PACKAGE_VERSION})\n"
            "    file(REMOVE_RECURSE \${DEBIAN_SOURCE_DIR})\n"
            "    file(MAKE_DIRECTORY \${DEBIAN_SOURCE_DIR}/debian)\n\n"
    )

    #### File: debian/control
    file(APPEND ${TARGET_FILE}
            "    set(DEBIAN_CONTROL \${DEBIAN_SOURCE_DIR}/debian/control)\n"
            "    string(REPLACE \";\" \", \" SUGGESTS \"\${CPACK_DEBIAN_BUILD_SUGGESTS}\")\n"
            "    string(REPLACE \";\" \", \" DEPENDS \"\${CPACK_DEBIAN_TOTAL_BUILD_DEPENDS}\")\n"
            "    file(WRITE \${DEBIAN_CONTROL}\n"
            "           \"Source: ${CMAKE_PROJECT_NAME}\\n\"\n"
            "           \"Section: devel\\n\"\n"
            "           \"Priority: optional\\n\"\n"
            "           \"Maintainer: ${CPACK_PACKAGE_CONTACT}\\n\"\n"
            "           \"Build-Depends: \${DEPENDS}\\n\"\n"
#            "           \"Standards-Version: 3.8.4\\n\"\n"
            "           \"Homepage: ${WEB}\\n\\n\"\n"
            "    )\n"
    )
    if(NOT CPACK_DEBIAN_COMPONENT_INSTALL)
        file(APPEND ${TARGET_FILE}
                "    set(DEPENDS \"\\\${shlibs:Depends}\" \${CPACK_DEBIAN_PACKAGE_DEPENDS})\n"
                "    string(REPLACE \";\" \", \" DEPENDS \"\${DEPENDS}\")\n"
                "    file(APPEND \${DEBIAN_CONTROL}\n"
                "            \"Package: ${CMAKE_PROJECT_NAME}\\n\"\n"
                "            \"Architecture: ${ARCH}\\n\"\n"
                "            \"Suggests: \${SUGGESTS}\\n\"\n"
                "            \"Depends: \${DEPENDS}\\n\"\n"
                "            \"Description: \${CPACK_PACKAGE_DESCRIPTION_SUMMARY}\\n\"\n"
                "            \"\${CPACK_DEBIAN_PACKAGE_DESCRIPTION}\\n\"\n"
                "    )\n"
        )
    else()
        file(APPEND ${TARGET_FILE}
                "    foreach(GROUP \${CPACK_GROUPS})\n"
                "    unset(DESCRIPTION)\n"
                "        set(DEPENDS \"\\\${shlibs:Depends}\" \${CPACK_GROUP_\${GROUP}_DEPENDS})\n"
                "        string(REPLACE \";\" \", \" DEPENDS \"\${DEPENDS}\")\n"
                "        if(\${GROUP} STREQUAL ${CMAKE_PROJECT_NAME})\n"
                "            set(DEB_COMPONENT ${CMAKE_PROJECT_NAME})\n"
                "        else()\n"
                "            set(DEB_COMPONENT ${CMAKE_PROJECT_NAME}-\${GROUP})\n"
                "        endif()\n"
                "        foreach(COMPONENT \${CPACK_GROUP_\${GROUP}_COMPONENTS})\n"
                "            string(TOUPPER \${COMPONENT} UPPER_COMPONENT)\n"
                "            if(CPACK_COMPONENT_\${UPPER_COMPONENT}_DISPLAY_NAME)\n"
                "                set(DESCRIPTION \"\${DESCRIPTION} - \${CPACK_COMPONENT_\${UPPER_COMPONENT}_DISPLAY_NAME}\")\n"
                "            else()\n"
                "                set(DESCRIPTION \"\${DESCRIPTION} - Component '\${COMPONENT}'\")\n"
                "            endif()\n"
                "            if(CPACK_COMPONENT_\${UPPER_COMPONENT}_DESCRIPTION)\n"
                "                set(DESCRIPTION \"\${DESCRIPTION} - \${CPACK_COMPONENT_\${UPPER_COMPONENT}_DESCRIPTION}\")\n"
                "            endif()\n"
                "            set(DESCRIPTION \"\${DESCRIPTION}\\n\")\n"
                "        endforeach()\n"
                "        file(APPEND \${DEBIAN_CONTROL}\n"
                "                \"Package: \${DEB_COMPONENT}\\n\"\n"
                "                \"Architecture: ${ARCH}\\n\"\n"
                "                \"Suggests: \${SUGGESTS}\\n\"\n"
                "                \"Depends: \${DEPENDS}\\n\"\n"
                "                \"Description: \${CPACK_PACKAGE_DESCRIPTION_SUMMARY}\\n\"\n"
                "                \"\${CPACK_DEBIAN_PACKAGE_DESCRIPTION}\"\n"
                "                \" This package constains:\\n\${DESCRIPTION}\\n\"\n"
                "        )\n"
                "    endforeach()\n\n"
        )
    endif()

    #### File: debian/rules
    file(APPEND ${TARGET_FILE}
            "    set(DEBIAN_RULES \${DEBIAN_SOURCE_DIR}/debian/rules)\n"
            "    file(WRITE \${DEBIAN_RULES}\n"
            "            \"#!/usr/bin/make -f\\n\\n\"\n"
            "            \"BUILDDIR = build_dir\\n\\n\"\n"
            "            \"build:\\n\"\n"
            "    )\n"
            "    foreach(PREBUILD_LINE \${CPACK_DEBIAN_PREBUILD})\n"
            "        file(APPEND \${DEBIAN_RULES}\n"
            "            \"\t\${PREBUILD_LINE}\\n\"\n"
            "    )\n"
            "    endforeach()\n"
            "    string(REPLACE \";\" \" \" CMAKE_ARGUMENTS \"\${CPACK_DEBIAN_CMAKE_ARGUMENTS}\")\n"
            "    file(APPEND \${DEBIAN_RULES}\n"
            "            \"\tmkdir $(BUILDDIR)\\n\"\n"
            "            \"\tcd $(BUILDDIR); cmake \${CMAKE_ARGUMENTS} "
                                                  "-DCMAKE_BUILD_TYPE=Release "
                                                  "-DCPACK_PACKAGE_VERSION_MAJOR=\\\"\${CPACK_PACKAGE_VERSION_MAJOR}\\\" "
                                                  "-DCPACK_PACKAGE_VERSION_MINOR=\\\"\${CPACK_PACKAGE_VERSION_MINOR}\\\" "
                                                  "-DCPACK_PACKAGE_VERSION_PATCH=\\\"\${CPACK_PACKAGE_VERSION_PATCH}\\\" "
                                                  "-DCMAKE_INSTALL_PREFIX=../debian/tmp/usr ..\\n\"\n"
            "            \"\t$(MAKE) -C $(BUILDDIR) preinstall\\n\"\n"
            "            \"\ttouch build\\n\\n\"\n"
            "            \"binary: binary-indep binary-arch\\n\\n\"\n"
            "            \"binary-indep: build\\n\\n\"\n"
            "            \"binary-arch: build\\n\"\n"
            "    )\n"
    )
    if(NOT CPACK_DEBIAN_COMPONENT_INSTALL)
        file(APPEND ${TARGET_FILE}
                "    file(APPEND \${DEBIAN_RULES}\n"
                "            \"\t$(MAKE) -C $(BUILDDIR) install\\n\"\n"
                "            \"\tmkdir -p debian/tmp/DEBIAN\\n\"\n"
                "            \"\tdpkg-gensymbols -p${CMAKE_PROJECT_NAME}\\n\"\n"
                "    )\n"
        )
    else()
        file(APPEND ${TARGET_FILE}
                "    foreach(GROUP \${CPACK_GROUPS})\n"
                "        if(\${GROUP} STREQUAL ${CMAKE_PROJECT_NAME})\n"
                "            set(DEB_COMPONENT ${CMAKE_PROJECT_NAME})\n"
                "        else()\n"
                "            set(DEB_COMPONENT ${CMAKE_PROJECT_NAME}-\${GROUP})\n"
                "        endif()\n"
                "        set(PATH debian/\${DEB_COMPONENT})\n"
                "        unset(COMPONENTS)\n"
                "        foreach(COMPONENT \${CPACK_GROUP_\${GROUP}_COMPONENTS})\n"
#                "            set(COMPONENTS \"\${COMPONENTS} -DCOMPONENT=\${COMPONENT} \")\n"
                "            file(APPEND \${DEBIAN_RULES}\n"
                "                   \"\tcd $(BUILDDIR); cmake -DCOMPONENT=\${COMPONENT} "
                                                             "-DCMAKE_INSTALL_PREFIX=../\${PATH}/usr "
                                                             "-P cmake_install.cmake\\n\"\n"
                "                   \"\tmkdir -p \${PATH}/DEBIAN\\n\"\n"
                "                   \"\tdpkg-gensymbols -p\${DEB_COMPONENT} -P\${PATH}\\n\"\n"
                "            )\n"
                "        endforeach()\n"
                "    endforeach()\n"
        )
    endif()
    file(APPEND ${TARGET_FILE}
            "    file(APPEND \${DEBIAN_RULES}\n"
            "            \"\tdh_shlibdeps\\n\"\n"
            "            \"\tdh_strip\\n\"\n"
            "    )\n"
    )
    if(NOT CPACK_DEBIAN_COMPONENT_INSTALL)
        file(APPEND ${TARGET_FILE}
                "    file(APPEND \${DEBIAN_RULES}\n"
                "            \"\tdpkg-gencontrol -p${CMAKE_PROJECT_NAME}\\n\"\n"
                "            \"\tdpkg --build debian/tmp ..\\n\"\n"
                "    )\n"
        )
    else()
        file(APPEND ${TARGET_FILE}
                "    foreach(GROUP \${CPACK_GROUPS})\n"
                "        if(\${GROUP} STREQUAL ${CMAKE_PROJECT_NAME})\n"
                "            set(DEB_COMPONENT ${CMAKE_PROJECT_NAME})\n"
                "        else()\n"
                "            set(DEB_COMPONENT ${CMAKE_PROJECT_NAME}-\${GROUP})\n"
                "        endif()\n"
                "        set(PATH debian/\${DEB_COMPONENT})\n"
                "        file(APPEND \${DEBIAN_RULES}\n"
                "                \"\tdpkg-gencontrol -p\${DEB_COMPONENT} -P\${PATH} -Tdebian/\${DEB_COMPONENT}.substvars\\n\"\n"
                "                \"\tdpkg --build \${PATH} ..\\n\"\n"
                "        )\n"
                "    endforeach()\n"
        )
    endif()
    file(APPEND ${TARGET_FILE}
            "    file(APPEND \${DEBIAN_RULES}\n"
            "            \"\\nclean:\\n\"\n"
            "            \"\trm -f build\\n\"\n"
            "            \"\trm -rf $(BUILDDIR)\\n\\n\"\n"
            "            \".PHONY: binary binary-arch binary-indep clean\\n\"\n"
            "    )\n"
            "    execute_process(COMMAND chmod +x \${DEBIAN_RULES})\n"
    )

    #### File: debian/copyright
    file(APPEND ${TARGET_FILE}
            "    set(DEBIAN_COPYRIGHT \${DEBIAN_SOURCE_DIR}/debian/copyright)\n"
            "    configure_file(\${CPACK_RESOURCE_FILE_LICENSE} \${DEBIAN_COPYRIGHT} COPYONLY)\n\n"
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
            "    if(DEB_SOURCE_CHANGES OR NOT CPACK_DEBIAN_DISTRIB_REVISION EQUAL 1)\n"
            "        set(DEBUILD_OPTIONS -sd)\n"
            "    else()\n"
            "        set(DEBUILD_OPTIONS -sa)\n"
            "    endif()\n"
            "    set(SOURCE_CHANGES_FILE ${CMAKE_PROJECT_NAME}_\${RELEASE_PACKAGE_VERSION}_source.changes)\n"
            "    list(APPEND DEB_SOURCE_CHANGES \${SOURCE_CHANGES_FILE})\n"
            "    execute_process(COMMAND ${DEBUILD_EXECUTABLE} -S \${DEBUILD_OPTIONS} WORKING_DIRECTORY \${DEBIAN_SOURCE_DIR})\n\n"
            "endforeach()\n\n"
            "file(WRITE \${CMAKE_CURRENT_LIST_DIR}/Debian/source.changes.lst \"\${DEB_SOURCE_CHANGES}\")\n"
    )

    add_custom_target(debian_source_package
                      COMMAND ${CMAKE_COMMAND} -P BuildDebSource.cmake
                      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                      COMMENT "Debian source package")

    add_custom_target(clear_debian_source_packages
                      COMMAND ${CMAKE_COMMAND} -E remove_directory Debian
                      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                      COMMENT "Clear debian source packages")

    if(DPUT_EXECUTABLE)
        add_custom_target(upload_debian_source_package
                          COMMAND ${DPUT_EXECUTABLE} ${CPACK_DEBIAN_PPA} "$(cat source.changes.lst)"
                          DEPENDS debian_source_package
                          WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/Debian
                          COMMENT "Upload debian source package")
    else()
        message(AUTHOR_WARNING "Could not find 'dput' executable. Upload target would not be created.")
    endif()

else()

        message(AUTHOR_WARNING "Could not find 'debuild' executable. Debian source package would not be built.")

endif()
