cmake_minimum_required(VERSION 3.0)

project("omzmodules" NONE)
set(PROJECT_NAME "OMZModules")
set(CMAKE_PROJECT_NAME_UPPER "OMZMODULES")


####################### Setting paths ######################

if(WIN32)
    set(INSTALL_PATH_CMAKE cmake)
else()
    set(INSTALL_PATH_CMAKE share/${PROJECT_NAME}/cmake)
endif()


############### Setting additional variables ###############

set(VERSION_FROM_GIT ON)
set(COMPILED_ARCH "all")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "NTs OMZ CMake modules")
set(CPACK_PACKAGE_DESCRIPTION_FILE ${CMAKE_SOURCE_DIR}/doc/description.txt)
set(CPACK_PACKAGE_VENDOR      "NTs OMZ")
set(CPACK_PACKAGE_CONTACT     "Petr Tsymbarovich <petr@tsymbarovich.ru>")
set(WEB                       "https://github.com/mentaljam/cmake_modules")
set(CPACK_SOURCE_IGNORE_FILES "/\\\\.git/"
                              "/\\\\.tx/"
                              "/\\\\.gitignore"
                              "/\\\\CMakeLists.txt.user")


###################### CMake modules #######################

include(Modules/OMZFunctions.cmake)
include(Modules/OMZProjectPreConf.cmake)
include(Modules/OMZDoxyConf.cmake)


#################### Packaging options #####################

if(BUILD_PPA_PACKAGE)
  set(CPACK_DEBIAN_BUILD_DEPENDS debhelper cmake
      CACHE STRING "Common debian source build dependencies")
  set(CPACK_DEBIAN_DISTRIBUTION_NAMES vivid wily
      CACHE STRING "PPA distributions names")
  set(CPACK_DEBIAN_PPA "ppa:mentaljam/amigos"
      CACHE STRING "PPA name")
  set(CPACK_DEBIAN_CHANGELOG "  * Read on project page ${WEB}")
  set(CPACK_DEBIAN_CMAKE_ARGUMENTS
      -D${CMAKE_PROJECT_NAME_UPPER}_VERSION_DATE=${${CMAKE_PROJECT_NAME_UPPER}_VERSION_DATE})
    include(Modules/OMZDebuildConf.cmake)
endif()


########################## Install #########################

configure_file(${PROJECT_NAME}Config.cmake.in
               ${CMAKE_BINARY_DIR}/${PROJECT_NAME}Config.cmake
               @ONLY)
install(DIRECTORY   Modules
        DESTINATION ${INSTALL_PATH_CMAKE})
install(FILES       ${CMAKE_BINARY_DIR}/${PROJECT_NAME}Config.cmake
        DESTINATION ${INSTALL_PATH_CMAKE})

##################### Post configuration ###################

file(GLOB_RECURSE MODULES_FILES *.cmake)
list(APPEND PROJECT_FILES ${MODULES_FILES})
include(Modules/OMZProjectPostConf.cmake)
include(CPack)
