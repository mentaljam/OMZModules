####################### Project Files ######################

add_custom_target(project_files
                  COMMENT "Project files"
                  SOURCES ${PROJECT_FILES})


###################### Generated Files #####################

if(NOT NOT_DELETE_TMP)
    file(REMOVE_RECURSE ${CMAKE_BINARY_DIR}/tmp)
endif()
set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${GENERATED_FILES}")
