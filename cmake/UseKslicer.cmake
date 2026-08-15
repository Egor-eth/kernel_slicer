function(_attach_kslicer_command_vulkan ARG_TARGET ARG_MAINCLASS ARG_SHADER ARG_SOURCES ARG_DEFINES ARG_INCLUDES ARG_OPTIONS)
   
    target_compile_definitions(${ARG_TARGET} PRIVATE USE_KERNEL_SLICER KSLICER_VULKAN)

    set(generated_files 
        "${CMAKE_CURRENT_SOURCE_DIR}/${ARG_MAINCLASS}_generated.cpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/${ARG_MAINCLASS}_generated_ds.cpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/${ARG_MAINCLASS}_generated_init.cpp")



    if(${ARG_SHADER} STREQUAL "slang")
        set(build_script_name "build_slang")
    else()
        set(build_script_name "build")
    endif()

    if(WIN32)
        set(build_script_suffix ".bat")
        set(shell cmd /C)
    else()
        set(build_script_suffix ".sh")
        set(shell bash)
    endif()

    set(build_script_path "${CMAKE_CURRENT_SOURCE_DIR}/shaders_generated/${build_script_name}${build_script_suffix}")

    add_custom_command(OUTPUT ${build_script_path}
                       COMMAND ${KSLICER_EXECUTABLE}
                               ${a_sources_abs_pathes}
                               ${a_defines_list}
                               ${a_includes_list}
                               ${a_options}
                       DEPENDS ${a_sources_list}
                       COMMENT "Generating GPU code with Kernel Slicer"
                       COMMAND_EXPAND_LISTS)


    add_custom_command(OUTPUT ${generated_files}
                       COMMAND ${shell} ${build_script_path}
                       WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/shaders_generated"
                       DEPENDS ${build_script_path}
                       COMMENT "Building generated shaders")

    add_custom_target(${ARG_TARGET}_kslicer DEPENDS ${generated_files})
    add_dependencies(${ARG_TARGET} ${ARG_TARGET}_kslicer)


    target_sources(${ARG_TARGET} PRIVATE ${generated_files})

endfunction()

macro(_kslicer_skipped_includes_comma_sep ARG_OUT)
    set(${ARG_OUT} ${CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES} ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES})
    list(JOIN ${ARG_OUT} "," ${ARG_OUT})
endmacro()

function(_attach_kslicer_command ARG_TARGET ARG_MAINCLASS ARG_SHADER)
    set(a_sources_list $<TARGET_PROPERTY:${ARG_TARGET},KSLICER_SOURCES>)
    set(a_sources_abs_pathes $<PATH:ABSOLUTE_PATH,${a_sources_list},${CMAKE_CURRENT_SOURCE_DIR}>)

    set(a_defines_list $<LIST:TRANSFORM,$<TARGET_PROPERTY:${ARG_TARGET},COMPILE_DEFINITIONS>,PREPEND,-D> "-DKERNEL_SLICER")

    set(includes $<TARGET_PROPERTY:${ARG_TARGET},INCLUDE_DIRECTORIES>)
    _kslicer_skipped_includes_comma_sep(skipped_includes)
    set(includes $<LIST:REMOVE_ITEM,${includes},${skipped_includes}>)

    set(processed_includes $<TARGET_PROPERTY:${ARG_TARGET},KSLICER_PROCESS_DIRECTORIES>)
    set(processed_includes $<LIST:REMOVE_DUPLICATES,${processed_includes}>)

    set(includes_abs $<PATH:ABSOLUTE_PATH,${includes},${CMAKE_CURRENT_SOURCE_DIR}>)
    set(includes_abs $<LIST:REMOVE_DUPLICATES,${includes_abs}>)

    set(processed_includes_abs $<PATH:ABSOLUTE_PATH,${processed_includes},${CMAKE_CURRENT_SOURCE_DIR}>)
    set(ignored_includes_abs $<LIST:REMOVE_ITEM,${includes_abs},${processed_includes_abs}>)

    set(processed_includes_abs $<LIST:TRANSFORM,${processed_includes_abs},PREPEND,-I>)    
    set(ignored_includes_abs $<LIST:TRANSFORM,${ignored_includes_abs},PREPEND,-I>)

    set(a_processed_includes $<JOIN:${processed_includes_abs},$<SEMICOLON>process$<SEMICOLON>> process)
    set(a_ignored_includes $<JOIN:${ignored_includes_abs},$<SEMICOLON>ignore$<SEMICOLON>> ignore)

    set(a_includes_list
        ${a_processed_includes}
        ${a_ignored_includes}
    )

    set(a_options
        "-I${KSLICER_TINYSTL_PATH}" "ignore"
        "-stdlibfolder" "${KSLICER_TINYSTL_PATH}"
        "-shaderCC" "${ARG_SHADER}"
        $<TARGET_PROPERTY:${ARG_TARGET},KSLICER_OPTIONS>
    )

    if(${ARG_SHADER} STREQUAL "glsl" OR ${ARG_SHADER} STREQUAL "slang")
        _attach_kslicer_command_vulkan(${ARG_TARGET} ${ARG_MAINCLASS} ${ARG_SHADER} 
                                       ${a_sources_abs_pathes}
                                       ${a_defines_list}
                                       ${a_includes_list}
                                       ${a_options})
    endif()

endfunction()

function(_kslicer_require_enabled ARG_TARGET)
    get_property(kslicer_enabled 
                 TARGET ${ARG_TARGET}
                 PROPERTY KSLICER_SHADER DEFINED)

    if(${kslicer_enabled})
        message(FATAL_ERROR "Kernel Slicer was not enabled for target ${ARG_TARGET}")
    endif()
endfunction()


function(target_kslicer_sources ARG_TARGET)
    _kslicer_require_enabled(${ARG_TARGET})

    set(files ${ARGN})
    if("${files}" STREQUAL "")
        message(FATAL_ERROR "target_kslicer_sources(...) called with no sources list")
    endif()

    set_property(TARGET ${ARG_TARGET}
                 PROPERTY KSLICER_SOURCES
                 ${files} APPEND)
    #get_property(has_mainfile 
    #             TARGET ${ARG_TARGET}
    #             PROPERTY KSLICER_MAIN_OUTPUTS DEFINED)

    #if(NOT ${has_mainfile})
    #    list(GET files 0 main_file)
    #    get_filename_component(maingen_we ${main_file} NAME_WE)
    #    set(main_generated_files 
    #        "${CMAKE_CURRENT_SOURCE_DIR}/${maingen_we}_generated.cpp"
    #        "${CMAKE_CURRENT_SOURCE_DIR}/${maingen_we}_generated_ds.cpp"
    #        "${CMAKE_CURRENT_SOURCE_DIR}/${maingen_we}_generated_init.cpp")


    #    set_property(TARGET ${ARG_TARGET} 
    #                 PROPERTY KSLICER_MAIN_OUTPUTS
    #                 ${main_generated_files})

    #endif()

endfunction()

macro(target_kslicer_options ARG_TARGET)
    _kslicer_require_enabled(${ARG_TARGET})
    set_property(TARGET ${ARG_TARGET}
                 PROPERTY KSLICER_OPTIONS
                 ${ARGN} APPEND)
endmacro()

macro(target_kslicer_process_directories ARG_TARGET)
    _kslicer_require_enabled(${ARG_TARGET})
    set_property(TARGET ${ARG_TARGET}
                 PROPERTY KSLICER_PROCESS_DIRECTORIES
                 ${ARGN} APPEND)
endmacro()

function(target_enable_kslicer ARG_TARGET ARG_MAINCLASS ARG_SHADERTYPE)
    set(sources, ${ARG_UNPARSED_ARGUMENTS})

    get_property(already_enabled 
                 TARGET ${ARG_TARGET}
                 PROPERTY KSLICER_SHADER DEFINED)

    if(${already_enabled})
        message(WARNING "target_enable_kslicer was already called for target ${ARG_TARGET}")
    endif()

    if(NOT "${sources}" STREQUAL "")
        target_kslicer_sources(${ARG_TARGET} ${sources})
    endif()

    target_kslicer_options(hydra 
                           "-mainClass" "${ARG_MAINCLASS}"
                           "-new_rawname" "1"
                           "-suffix" "_generated")

    _attach_kslicer_command(${ARG_TARGET} ${ARG_MAINCLASS} ${ARG_SHADERTYPE})

endfunction()