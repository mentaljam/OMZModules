#################### Including modules #####################

include(CMakeParseArguments)
include(${CMAKE_CURRENT_LIST_DIR}/Modules/common/OMZInitVars.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/Modules/common/OMZFunctions.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/Modules/common/OMZVersion.cmake)


#################### PAckage information ###################

get_version_from_git(OMZModules_VERSION OMZModules_VERSION_DATE)
set(OMZModules_PATH "${CMAKE_CURRENT_LIST_DIR}")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/Modules")

message(STATUS "Found OMZ CMake modules v${OMZModules_VERSION}")


##################### Uninstall target #####################

configure_file(${CMAKE_CURRENT_LIST_DIR}/Templates/cmake_uninstall.cmake.in
               ${CMAKE_BINARY_DIR}/cmake_uninstall.cmake @ONLY)
add_custom_target(uninstall
                  COMMAND ${CMAKE_COMMAND} -P cmake_uninstall.cmake
                  WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
