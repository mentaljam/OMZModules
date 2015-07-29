##################### Configuring Icons ####################

if(EXISTS ${RESOURCES_DIR}/icons/icons.qrc.in)
    set(PNG_QRC ${CMAKE_BINARY_DIR}/res/icons/icons.qrc)
    configure_file(${RESOURCES_DIR}/icons/icons.qrc.in ${PNG_QRC})
endif()

if(NOT CONVERT)
    unset(CONVERT CACHE)
    find_program(CONVERT convert)
endif()

if(CONVERT)
    message(STATUS "Found Imagemagick - ${CONVERT}")
    file(GLOB_RECURSE SVG_FILES ${RESOURCES_DIR}/icons/*.svg)
    foreach(SVG ${SVG_FILES})
        get_filename_component(ICON ${SVG} NAME)
        string(REPLACE "svg" "png" PNG ${ICON})
        add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/res/icons/${PNG}
                           COMMAND ${CONVERT} -background none -quantize transparent ${SVG} ${PNG}
                           WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/res/icons
                           COMMENT "Generating ${PNG}")
        list(APPEND PROJECT_ICONS ${CMAKE_BINARY_DIR}/res/icons/${PNG})
    endforeach()
    if(WIN32 AND WIN_ICONS)
        foreach(WIN_ICO ${WIN_ICONS})
        add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/res/win32/${WIN_ICO}.ico
                           COMMAND ${CONVERT} -background none -quantize transparent ${RESOURCES_DIR}/icons/${WIN_ICO}.svg
                                   ( -clone 0 -resize 256 )
                                   ( -clone 0 -resize 96 )
                                   ( -clone 0 -resize 48 )
                                   ( -clone 0 -resize 32 )
                                   ( -clone 0 -resize 16 )
                                   -background none -quantize transparent ${WIN_ICO}.ico
                           WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/res/win32
                           COMMENT "Generating ${WIN_ICO}.ico")
        list(APPEND PROJECT_ICONS ${CMAKE_BINARY_DIR}/res/win32/${WIN_ICO}.ico)
        endforeach()
    endif()
    add_custom_target(update_icons
                      DEPENDS ${PROJECT_ICONS}
                      COMMENT "Generating project icons")
else()
    message(WARNING "Imagemagick convert utility was not found. "
                    "Convert SVG icons to PNG manually and put them to '${CMAKE_BINARY_DIR}/res/icons'")
endif()
