include(ExternalProject)

function(_ec_parse_arguments f name ns args)
  # Transfer the arguments to this function into target properties for the
  # new custom target we just added so that we can set up all the build steps
  # correctly based on target properties.
  #
  # We loop through ARGN and consider the namespace starting with an
  # upper-case letter followed by at least two more upper-case letters,
  # numbers or underscores to be keywords.
  set(key)

  foreach(arg IN LISTS args)
    set(is_value 1)

    if(arg MATCHES "^[A-Z][A-Z0-9_][A-Z0-9_]+$" AND
        NOT (("x${arg}x" STREQUAL "x${key}x") AND ("x${key}x" STREQUAL "xCOMMANDx")) AND
        NOT arg MATCHES "^(TRUE|FALSE)$")
      if(_ec_keywords_${f} AND arg MATCHES "${_ec_keywords_${f}}")
        set(is_value 0)
      endif()
    endif()

    if(is_value)
      if(key)
        # Value
        if(NOT arg STREQUAL "")
          set_property(TARGET ${name} APPEND PROPERTY ${ns}${key} "${arg}")
        else()
          get_property(have_key TARGET ${name} PROPERTY ${ns}${key} SET)
          if(have_key)
            get_property(value TARGET ${name} PROPERTY ${ns}${key})
            set_property(TARGET ${name} PROPERTY ${ns}${key} "${value};${arg}")
          else()
            set_property(TARGET ${name} PROPERTY ${ns}${key} "${arg}")
          endif()
        endif()
      else()
        # Missing Keyword
        message(AUTHOR_WARNING "value '${arg}' with no previous keyword in ${f}")
      endif()
    else()
      set(key "${arg}")
    endif()
  endforeach()
endfunction()

function(ExternalConfig_Add name)
  _ep_get_configuration_subdir_suffix(cfgdir)

  # Add a custom target for the external project.
  set(cmf_dir ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles)
  set(complete_stamp_file "${cmf_dir}${cfgdir}/${name}-complete")

  # The "ALL" option to add_custom_target just tells it to not set the
  # EXCLUDE_FROM_ALL target property. Later, if the EXCLUDE_FROM_ALL
  # argument was passed, we explicitly set it for the target.
  add_custom_target(${name} DEPENDS ${complete_stamp_file})
  set_property(TARGET ${name} PROPERTY _EC_IS_EXTERNAL_CONFIG 1)
  set_property(TARGET ${name} PROPERTY LABELS ${name})
  set_property(TARGET ${name} PROPERTY FOLDER "ExternalConfigTargets/${name}")
  #set_property(TARGET ${name} PROPERTY EXCLUDE_FROM_ALL TRUE)

  _ep_set_directories(${name})
  _ep_get_step_stampfile(${name} "done" done_stamp_file)
  #_ep_get_step_stampfile(${name} "install" install_stamp_file)

  # The 'complete' step depends on all other steps and creates a
  # 'done' mark.  A dependent external project's 'configure' step
  # depends on the 'done' mark so that it rebuilds when this project
  # rebuilds.  It is important that 'done' is not the output of any
  # custom command so that CMake does not propagate build rules to
  # other external project targets, which may cause problems during
  # parallel builds.  However, the Ninja generator needs to see the entire
  # dependency graph, and can cope with custom commands belonging to
  # multiple targets, so we add the 'done' mark as an output for Ninja only.
  set(complete_outputs ${complete_stamp_file})
  if(${CMAKE_GENERATOR} MATCHES "Ninja")
    set(complete_outputs ${complete_outputs} ${done_stamp_file})
  endif()

  add_custom_command(
    OUTPUT ${complete_outputs}
    COMMENT "Completed '${name}'"
    COMMAND ${CMAKE_COMMAND} -E make_directory ${cmf_dir}${cfgdir}
    COMMAND ${CMAKE_COMMAND} -E touch ${complete_stamp_file}
    COMMAND ${CMAKE_COMMAND} -E touch ${done_stamp_file}
    DEPENDS ${install_stamp_file}
    VERBATIM
    )


  # Depend on other external projects (target-level).
  get_property(deps TARGET ${name} PROPERTY _EC_DEPENDS)
  foreach(arg IN LISTS deps)
    add_dependencies(${name} ${arg})
  endforeach()

  # Set up custom build steps based on the target properties.
  # Each step depends on the previous one.
  #
  # The target depends on the output of the final step.
  # (Already set up above in the DEPENDS of the add_custom_target command.)
  #
  _ep_add_mkdir_command(${name})
  _ep_add_download_command(${name})
  _ep_add_update_command(${name})
  _ep_add_patch_command(${name})
  _ep_add_configure_command(${name})
  _ep_add_build_command(${name})
  _ep_add_install_command(${name})

  # Test is special in that it might depend on build, or it might depend
  # on install.
  #
  _ep_add_test_command(${name})
endfunction()

