
# Including modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/Modules")
set(OMZModules_PATH "${CMAKE_CURRENT_LIST_DIR}")
include(CMakeParseArguments)
include(OMZFunctions)


# Package information
if(NOT DEFINED OMZModules_VERSION)
    omz_git_version_tag(OMZModules_VERSION)
    message(STATUS "Found OMZModules v${OMZModules_VERSION}")
    set(OMZModules_PATH "${CMAKE_CURRENT_LIST_DIR}" CACHE STRING "Path to the OMZModules dir")
endif()
