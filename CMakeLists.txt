cmake_minimum_required(VERSION 3.0)

project("omzmodules" NONE)
set(PROJECT_NAME "OMZModules")


####################### Setting paths ######################

if(WIN32)
    set(INSTALL_PATH_CMAKE cmake)
else()
    set(INSTALL_PATH_CMAKE share/${PROJECT_NAME}/cmake)
endif()


###################### CMake modules #######################

include(CMakeParseArguments)
include(Modules/common/OMZInitVars.cmake)
include(Modules/common/OMZFunctions.cmake)
include(Modules/common/OMZVersion.cmake)
include(Modules/OMZCPack.cmake)

if(VERSION_MAJOR)
    set_project_version(MAJOR ${VERSION_MAJOR}
                        MINOR ${VERSION_MINOR}
                        PATCH ${VERSION_PATCH}
                        TWEAK ${VERSION_TWEAK})
else()
    set_project_version(GIT)
endif()
configure_cpack()


#################### Packaging options #####################

set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "NTs OMZ CMake modules")
set(CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_SOURCE_DIR}/doc/description.txt")
set(CPACK_RESOURCE_FILE_LICENSE    "${CMAKE_SOURCE_DIR}/LICENSE.OMZModules.txt")
set(CPACK_PACKAGE_VENDOR      "NTs OMZ")
set(CPACK_PACKAGE_CONTACT     "Petr Tsymbarovich <petr@tsymbarovich.ru>")
set(WEB                       "https://github.com/mentaljam/OMZModules")
set(CPACK_SOURCE_IGNORE_FILES "/\\\\.git/"
                              "/\\\\.tx/"
                              "/\\\\.gitignore"
                              "/\\\\CMakeLists.txt.user")

if(BUILD_PPA_PACKAGE)
    read_debian_description()
    set(CPACK_DEBIAN_BUILD_DEPENDS debhelper cmake)
    set(CPACK_DEBIAN_DISTRIBUTION_NAMES vivid wily)
    set(CPACK_DEBIAN_PPA "ppa:mentaljam/amigos")
    set(CPACK_DEBIAN_CHANGELOG "  * Read on project page ${WEB}")
    set(OMZModules_PATH "${PROJECT_SOURCE_DIR}")
    include(Modules/OMZDebuildConf.cmake)
endif()


########################## Install #########################

configure_file(OMZModulesConfig.cmake.in
               ${CMAKE_BINARY_DIR}/OMZModulesConfig.cmake
               @ONLY)
install(FILES       ${CMAKE_BINARY_DIR}/OMZModulesConfig.cmake
        DESTINATION ${INSTALL_PATH_CMAKE})
install(DIRECTORY   Modules
        DESTINATION ${INSTALL_PATH_CMAKE})
install(DIRECTORY   Templates
        DESTINATION ${INSTALL_PATH_CMAKE})


##################### Post configuration ###################

file(GLOB_RECURSE MODULES_FILES   Modules/*)
file(GLOB_RECURSE TEMPLATES_FILES Templates/*)
list(APPEND PROJECT_FILES ${MODULES_FILES} ${TEMPLATES_FILES})
postconfig()
include(CPack)
