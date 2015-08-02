cmake_minimum_required(VERSION 3.0)

project("omzmodules")
set(PROJECT_NAME "CMakeOMZModules")


####################### Setting paths ######################

if(WIN32)
    set(INSTALL_PATH_CMAKE NTsOMZ/cmake)
else()
    set(INSTALL_PATH_CMAKE share/NTsOMZ/cmake)
endif()


############### Setting additional variables ###############

set(COMPILED_ARCH "all")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "NTs OMZ CMake modules")
set(CPACK_PACKAGE_DESCRIPTION_FILE ${CMAKE_SOURCE_DIR}/doc/description.txt)
set(CPACK_PACKAGE_VENDOR  "NTs OMZ")
set(CPACK_PACKAGE_CONTACT "Petr Tsymbarovich <petr@tsymbarovich.ru>")
set(WEB                   "https://github.com/mentaljam/cmake_modules")

set(CPACK_DEBIAN_BUILD_DEPENDS debhelper cmake)
set(CPACK_DEBIAN_DISTRIBUTION_NAMES vivid)
set(CPACK_DEBIAN_CHANGELOG "  * Read on project page ${WEB}")

set(CPACK_SOURCE_IGNORE_FILES "/\\\\.git/"
                              "/\\\\.tx/"
                              "/\\\\.gitignore"
                              "/\\\\CMakeLists.txt.user")

###################### CMake modules #######################

include(Modules/OMZProjectPreConf.cmake)
include(Modules/OMZDoxyConf.cmake)
include(Modules/OMZFunctions.cmake)
include(Modules/OMZDebuildConf.cmake)


########################## Install #########################

configure_file(NTsOMZConfig.cmake.in
               ${CMAKE_BINARY_DIR}/NTsOMZConfig.cmake
               @ONLY)
install(DIRECTORY   Modules
        DESTINATION ${INSTALL_PATH_CMAKE})
install(FILES       ${CMAKE_BINARY_DIR}/NTsOMZConfig.cmake
        DESTINATION ${INSTALL_PATH_CMAKE})

##################### Post configuration ###################

include(Modules/OMZProjectPostConf.cmake)
