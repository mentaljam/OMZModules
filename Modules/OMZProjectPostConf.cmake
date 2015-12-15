####################### Project Files ######################

add_custom_target(project_files
                  COMMENT "Project files"
                  SOURCES ${PROJECT_FILES})

#### Version definitions
file(APPEND ${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}_version.h
        "\n#endif // VERSION_${PROJECT_NAME_UPPER}\n"
)


###################### Generated Files #####################

if(NOT NOT_DELETE_TMP)
    file(REMOVE_RECURSE ${CMAKE_BINARY_DIR}/tmp)
endif()
set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${GENERATED_FILES}")
