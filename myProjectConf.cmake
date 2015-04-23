######################### General ##########################

include_directories(${CMAKE_BINARY_DIR})

if(NOT ARCH)
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(ARCH 64)
    else()
        set(ARCH 32)
    endif()
endif()


##################### Scanning files #######################

file(GLOB_RECURSE SOURCE_FILES src/*.cpp)
source_group("Source Files" FILES ${SOURCE_FILES})

file(GLOB_RECURSE HEADER_FILES src/*.h)
source_group("Headers" FILES ${HEADER_FILES})

file(GLOB_RECURSE UI_FILES src/*.ui)
source_group("UI Files" FILES ${UI_FILES})

file(GLOB_RECURSE TS_FILES i18n/*.ts)
source_group("Translation" FILES ${TS_FILES})

file(GLOB_RECURSE QRC ${RESOURCES_DIR}/*.qrc)
source_group("Resources" FILES ${QRC})


######################## Build type ########################

if(QT)

    if(UNIX)
        set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} "/opt/Qt/5.4/gcc_64/lib/cmake")
    endif(UNIX)

    find_package(Qt5Widgets REQUIRED)
    find_package(Qt5LinguistTools)

    include_directories(${Qt5Widgets_INCLUDE_DIRS})
    set(CMAKE_AUTOMOC ON)
    
    if(Qt5LinguistTools_FOUND)
        message(STATUS "To update translations run \"make update_translations\"")
        set_property(SOURCE ${TS_FILES} PROPERTY OUTPUT_LOCATION ${CMAKE_BINARY_DIR}/i18n)
        add_custom_target(update_translations
                          COMMAND lupdate ${PROJECT_SOURCE_DIR}/src/ -ts ${TS_FILES}
                          COMMENT "Run lupdate to update translations files")
        add_custom_target(update_translations_clean
                          COMMAND lupdate ${PROJECT_SOURCE_DIR}/src/ -ts ${TS_FILES} -no-obsolete
                          COMMENT "Run lupdate with \"-no-obsolete\" key to update and clean translations files")
        qt5_add_translation(QM_FILES ${TS_FILES})
    else()
        message(AUTHOR_WARNING "Qt5LinguistTools were not found, translations will not be generated")
    endif()

endif(QT)

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    if(QT)
        add_definitions(-DQT_NO_DEBUG)
        add_definitions(-DQT_NO_DEBUG_OUTPUT)
        add_definitions(-DQT_NO_WARNING)
        add_definitions(-DQT_NO_WARNING_OUTPUT)
    endif(QT)
    if(CMAKE_COMPILER_IS_GNUCC)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -s")
        if(WIN32 AND QT)
            set(QT_CXX_FLAGS "-mwindows")
        endif(WIN32 AND QT)
    endif(CMAKE_COMPILER_IS_GNUCC)
endif(CMAKE_BUILD_TYPE STREQUAL "Release")


################ Architecture and compiler #################

if(ARCH EQUAL 64)
    message(STATUS "Configuring 64 bit version")
    if(CMAKE_COMPILER_IS_GNUCC)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${GCC_FLAGS} -m64")
        set(DLL_ARCH ${THIRD_PARTY_DIR}/dll_gcc_x64.tar.gz)
    endif(CMAKE_COMPILER_IS_GNUCC)
    set(COMPILED_ARCH "amd64")
else(ARCH EQUAL 32)
    message(STATUS "Configuring 32 bit version")
    if(CMAKE_COMPILER_IS_GNUCC)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${GCC_FLAGS} -m32")
        set(DLL_ARCH ${THIRD_PARTY_DIR}/dll_gcc_x32.tar.gz)
    endif(CMAKE_COMPILER_IS_GNUCC)
    set(COMPILED_ARCH "i386")
endif()

###################### Unpacking dlls ######################

if(CMAKE_COMPILER_IS_GNUCC AND EXISTS ${DLL_ARCH})
    message(STATUS "Unpacking precompiled dlls")
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/runtime)
    execute_process(COMMAND ${CMAKE_COMMAND} -E tar xzf ${DLL_ARCH}
                    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/runtime)
    file(GLOB DLLS ${CMAKE_BINARY_DIR}/runtime/*.dll)
endif(CMAKE_COMPILER_IS_GNUCC AND EXISTS ${DLL_ARCH})


######################## Versions ##########################

set(CPACK_PACKAGE_VERSION_MAJOR "0")
set(CPACK_PACKAGE_VERSION_MINOR "0")
set(CPACK_PACKAGE_VERSION_PATCH "0")
set(V_VERSION "unknown_version")
set(V_DATE "unknown_build")

if(NOT GIT)
    unset(GIT CACHE)
    find_program(GIT git)
endif(NOT GIT)
if(GIT)

    execute_process(COMMAND ${GIT} -C ${PROJECT_SOURCE_DIR} describe --tags --always
                    OUTPUT_VARIABLE VERSION)
    execute_process(COMMAND ${GIT} -C ${PROJECT_SOURCE_DIR} log -n 1 --pretty=format:%ad --date=short
                    OUTPUT_VARIABLE V_DATE)
    if(VERSION)
        string(STRIP ${VERSION} VERSION)
        message(STATUS "Using git tag ${VERSION} as version number")
        string(REGEX REPLACE "[-.]" ";" VERSION ${VERSION})
        list(LENGTH VERSION VERSION_LENGTH)
        if(NOT ${VERSION_LENGTH} EQUAL 0)
            if(${VERSION_LENGTH} EQUAL 1)
                set(CPACK_PACKAGE_VERSION_MAJOR ${VERSION})
                set(V_VERSION ${VERSION})
            elseif(${VERSION_LENGTH} GREATER 1)
                list(GET VERSION 0 CPACK_PACKAGE_VERSION_MAJOR)
                list(GET VERSION 1 CPACK_PACKAGE_VERSION_MINOR)
                set(V_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}")
                if(VERSION_STATUS)
                    set(V_VERSION "${V_VERSION}~${VERSION_STATUS}")
                endif(VERSION_STATUS)
                if(${VERSION_LENGTH} EQUAL 4)
                    list(GET VERSION 2 CPACK_PACKAGE_VERSION_PATCH)
                    set(V_VERSION "${V_VERSION}-${CPACK_PACKAGE_VERSION_PATCH}")
                endif(${VERSION_LENGTH} EQUAL 4)
            endif(${VERSION_LENGTH} EQUAL 1)
        endif(NOT ${VERSION_LENGTH} EQUAL 0)
    endif(VERSION)

##################### File versions ########################

    file(REMOVE ${CMAKE_BINARY_DIR}/sources.h)
    file(GLOB_RECURSE S_FILES RELATIVE ${PROJECT_SOURCE_DIR} ${PROJECT_SOURCE_DIR}/src/*)
    foreach(FILE ${S_FILES})
        execute_process(COMMAND ${GIT} -C ${PROJECT_SOURCE_DIR} log -n 1 --pretty=format:%ci ${FILE} OUTPUT_VARIABLE F_DATE)
        if(NOT ${F_DATE} MATCHES "/\\b(fatal)\\b/i")
            string(STRIP ${F_DATE} F_DATE)
            execute_process(COMMAND ${GIT} -C ${PROJECT_SOURCE_DIR} log -n 1 --pretty=format:%h ${FILE} OUTPUT_VARIABLE F_VERSION)
            string(STRIP ${F_VERSION} F_VERSION)
            file(APPEND ${CMAKE_BINARY_DIR}/sources.h
                 "/**\n * @file ${FILE}\n * @version ${F_VERSION}\n * @date ${F_DATE}\n */\n\n")
        endif(NOT ${F_DATE} MATCHES "/\\b(fatal)\\b/i")
    endforeach()

else(GIT)
    message(AUTHOR_WARNING "Git not found - version can not be defined")
endif(GIT)

file(WRITE ${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}_version.h
     "#define VERSION \"${V_VERSION}\"\n#define V_DATE \"${V_DATE}\"\n#define V_ARCH \"${COMPILED_ARCH}\"")


####################### CPack options ######################

set(CPACK_RESOURCE_FILE_LICENSE ${CMAKE_BINARY_DIR}/LICENSE.txt)
file(REMOVE ${CPACK_RESOURCE_FILE_LICENSE})
file(GLOB LICENSE_FILES ${PROJECT_SOURCE_DIR}/LICENSE*)
list(FIND LICENSE_FILES ${CMAKE_PROJECT_NAME} IND)
list(GET LICENSE_FILES ${IND} FILE)
file(READ ${FILE} LICENSE_TEXT)
string(REPLACE "." ";" FILE ${FILE})
list(GET FILE 1 FILE)
file(APPEND ${CPACK_RESOURCE_FILE_LICENSE} "Contents:\n1) ${FILE}\n")
set(FULL_LICENSE_TEXT "1) ${FILE} license:\n${LICENSE_TEXT}\n\n")
list(REMOVE_AT LICENSE_FILES ${IND})
set(IND 2)
foreach(FILE ${LICENSE_FILES})
    file(READ ${FILE} LICENSE_TEXT)
    string(REPLACE "." ";" FILE ${FILE})
    list(GET FILE 1 FILE)
    set(FULL_LICENSE_TEXT "${FULL_LICENSE_TEXT}${IND}) ${FILE} license:\n${LICENSE_TEXT}\n\n")
    file(APPEND ${CPACK_RESOURCE_FILE_LICENSE} "${IND}) ${FILE}\n")
    MATH(EXPR IND "${IND} + 1")
endforeach()
file(APPEND ${CPACK_RESOURCE_FILE_LICENSE} "\n\n${FULL_LICENSE_TEXT}")

set(CPACK_SOURCE_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}_${V_VERSION}")
if(WIN32)
    message(STATUS "CPack generator type is set to \"WIX\", for building package use \"make package\"")
    message(STATUS "For building other packages use \"cpack -G ...\"")
    set(CPACK_GENERATOR "WIX")
    set(CPACK_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}_${V_VERSION}_win32_${COMPILED_ARCH}")
    set(CPACK_PACKAGE_VERSION ${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR})
    if(CPACK_PACKAGE_VERSION_PATCH)
        set(CPACK_PACKAGE_VERSION ${CPACK_PACKAGE_VERSION}.${CPACK_PACKAGE_VERSION_PATCH})
    endif(CPACK_PACKAGE_VERSION_PATCH)
    set(CPACK_WIX_PROGRAM_MENU_FOLDER ${CMAKE_PROJECT_NAME})
    if(EXISTS ${RESOURCES_DIR}/win32/${CMAKE_PROJECT_NAME}.ico)
        set(CPACK_WIX_PRODUCT_ICON ${RESOURCES_DIR}/win32/${CMAKE_PROJECT_NAME}.ico)
    endif(EXISTS ${RESOURCES_DIR}/win32/${CMAKE_PROJECT_NAME}.ico)
    set(CPACK_WIX_CULTURES "ru-RU")
    file(READ ${RESOURCES_DIR}/win32/update_guid.txt CPACK_WIX_UPGRADE_GUID)
    set(CPACK_PACKAGE_INSTALL_DIRECTORY ${CMAKE_PROJECT_NAME})
elseif(UNIX)
    message(STATUS "For building packages use \"cpack -G ...\"")
    set(CPACK_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}_${V_VERSION}_linux_${COMPILED_ARCH}")
    set(CPACK_DEBIAN_PACKAGE_VERSION ${V_VERSION})
    set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
    set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${COMPILED_ARCH})
endif(WIN32)
