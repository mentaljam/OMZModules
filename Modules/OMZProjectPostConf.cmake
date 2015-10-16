####################### Project Files ######################

add_custom_target(project_files
                  COMMENT "Project files"
                  SOURCES ${PROJECT_FILES})


###################### Generated Files #####################

set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${GENERATED_FILES}")
