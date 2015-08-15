####################### Project Files ######################

add_custom_target(project_files
                  COMMENT "Project files"
                  SOURCES ${PROJECT_FILES})


###################### Generated Files #####################

set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${GENERATED_FILES}")


########################### CPack ##########################

include(CPack)


######################### Versions #########################

file(APPEND ${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}_version.h
     "\n#endif // ${NAME_UP}_VERSION_H\n\n")
