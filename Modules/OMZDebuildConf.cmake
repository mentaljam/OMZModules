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
# - CPACK_DEBIAN_PACKAGE_REVISION
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

    #### Check distibution names
    if(NOT CPACK_DEBIAN_DISTRIBUTION_NAMES)
        set(CPACK_DEBIAN_DISTRIBUTION_NAMES debian)
    endif()

    #### Check package revision
    if(NOT CPACK_DEBIAN_DISTRIB_REVISION)
        set(CPACK_DEBIAN_DISTRIB_REVISION 0)
    endif()
    if(NOT CPACK_DEBIAN_PACKAGE_REVISION)
        set(CPACK_DEBIAN_PACKAGE_REVISION 0)
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
    set(CPACK_DEBIAN_CHANGELOG_END " -- ${CPACK_PACKAGE_CONTACT}  ${BUILD_DATE}")

    #### Architecture
    if(${COMPILED_ARCH} STREQUAL "all")
        set(CPACK_DEBIAN_ARCH "all")
    else()
        set(CPACK_DEBIAN_ARCH "any")
    endif()

    #### Target script file
    configure_file("${OMZModules_PATH}/Templates/BuildDebSource.cmake.in"
                   "${CMAKE_BINARY_DIR}/BuildDebSource.cmake" @ONLY)

    #### Targets
    add_custom_target(debian_source_packages
                      COMMAND ${CMAKE_COMMAND} -P BuildDebSource.cmake
                      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                      COMMENT "Preparing debian source packages")

    add_custom_target(remove_debian_packages_dir
                      COMMAND ${CMAKE_COMMAND} -E remove_directory Debian
                      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                      COMMENT "Removing debian source packages directory")

    if(DPUT_EXECUTABLE)
        add_custom_target(upload_debian_source_packages
                          COMMAND ${DPUT_EXECUTABLE} ${CPACK_DEBIAN_PPA} \$\$\(cat last.changes.lst\)
                          DEPENDS debian_source_packages
                          WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/Debian
                          COMMENT "Uploading debian source packages")
    else()
        message(AUTHOR_WARNING "Could not find 'dput' executable. Upload target would not be created.")
    endif()

else()

        message(AUTHOR_WARNING "Could not find 'debuild' executable. Debian source package would not be built.")

endif()
