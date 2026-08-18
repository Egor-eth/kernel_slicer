function(_attach_kslicer_command_vulkan ARG_TARGET ARG_MAINCLASS ARG_SHADER ARG_SOURCES ARG_DEFINES ARG_INCLUDES ARG_OPTIONS)
   
    target_compile_definitions(${ARG_TARGET} PRIVATE USE_KERNEL_SLICER KSLICER_VULKAN)

    set(generated_files 
        "${CMAKE_CURRENT_BINARY_DIR}/${KSLICER_GENERATES_DIRECTORY_NAME}/${ARG_MAINCLASS}_generated.cpp"
        "${CMAKE_CURRENT_BINARY_DIR}/${KSLICER_GENERATES_DIRECTORY_NAME}/${ARG_MAINCLASS}_generated_ds.cpp"
        "${CMAKE_CURRENT_BINARY_DIR}/${KSLICER_GENERATES_DIRECTORY_NAME}/${ARG_MAINCLASS}_generated_init.cpp")

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

    set(shaders_path "${CMAKE_CURRENT_BINARY_DIR}/${KSLICER_GENERATES_DIRECTORY_NAME}/shaders_generated")
    set(build_script_path "${shaders_path}/${build_script_name}${build_script_suffix}")

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
                       WORKING_DIRECTORY ${shaders_path}
                       DEPENDS ${build_script_path}
                       COMMENT "Building generated shaders")

    add_custom_target(${ARG_TARGET}_kslicer DEPENDS ${generated_files})
    add_dependencies(${ARG_TARGET} ${ARG_TARGET}_kslicer)


    target_sources(${ARG_TARGET} PRIVATE ${generated_files})

endfunction()

#macro(_kslicer_skipped_includes_comma_sep ARG_OUT)
#    set(${ARG_OUT} ${CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES} ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES})
#    list(JOIN ${ARG_OUT} "," ${ARG_OUT})
#endmacro()

macro(_kslicer_transform_pathes ARG_PATHES ARG_OUT)
    set(${ARG_OUT} $<PATH:ABSOLUTE_PATH,${ARG_PATHES},${CMAKE_CURRENT_SOURCE_DIR}>)
    set(${ARG_OUT} $<LIST:REMOVE_DUPLICATES,${${ARG_OUT}}>)
endmacro()

macro(_kslicer_transform_include_dirs ARG_OUT ARG_TYPE ARG_PATHES)
    _kslicer_transform_pathes(${ARG_PATHES} ${ARG_OUT})
    set(${ARG_OUT} $<LIST:TRANSFORM,${${ARG_OUT}},PREPEND,-I>)    
    set(${ARG_OUT} $<$<BOOL:${${ARG_OUT}}>:$<JOIN:${${ARG_OUT}},$<SEMICOLON>${ARG_TYPE}$<SEMICOLON>>$<SEMICOLON>${ARG_TYPE}>)
endmacro()

macro(_kslicer_transform_include_exceptions ARG_OUT ARG_TYPE ARG_PATHES)
    _kslicer_transform_pathes(${ARG_PATHES} ${ARG_OUT})
    set(${ARG_OUT} $<$<BOOL:${${ARG_OUT}}>:-${ARG_TYPE}$<SEMICOLON>$<JOIN:${${ARG_OUT}},$<SEMICOLON>-${ARG_TYPE}$<SEMICOLON>>>)
endmacro()

function(_attach_kslicer_command ARG_TARGET ARG_MAINCLASS ARG_SHADER)
    set(a_sources_list $<TARGET_PROPERTY:${ARG_TARGET},KSLICER_SOURCES>)
    set(a_sources_abs_pathes $<PATH:ABSOLUTE_PATH,${a_sources_list},${CMAKE_CURRENT_SOURCE_DIR}>)

    set(a_defines_list $<LIST:TRANSFORM,$<TARGET_PROPERTY:${ARG_TARGET},COMPILE_DEFINITIONS>,PREPEND,-D> "-DKERNEL_SLICER")

    set(ignored_includes $<TARGET_PROPERTY:${ARG_TARGET},KSLICER_IGNORE_DIRECTORIES>)
    _kslicer_transform_include_dirs(ignored_includes "ignore" ${ignored_includes})

    set(processed_includes $<TARGET_PROPERTY:${ARG_TARGET},KSLICER_PROCESS_DIRECTORIES>)
    _kslicer_transform_include_dirs(processed_includes "process" ${processed_includes})

    set(ignored_files $<TARGET_PROPERTY:${ARG_TARGET},KSLICER_IGNORE_FILES>)
    _kslicer_transform_include_exceptions(ignored_files "ignore" ${ignored_files})

    set(processed_files $<TARGET_PROPERTY:${ARG_TARGET},KSLICER_PROCESS_FILES>)
    _kslicer_transform_include_exceptions(processed_files "process" ${processed_files})

    set(a_includes_list
        ${processed_includes}
        ${ignored_includes}
    )

    set(a_include_exceptions
        ${processed_files}
        ${ignored_files}
    )

    set(a_options
        "-mainClass" "${ARG_MAINCLASS}"
        "-generates_output_dir" "${CMAKE_CURRENT_BINARY_DIR}/${KSLICER_GENERATES_DIRECTORY_NAME}"
        "-new_rawname" "1"
        "-suffix" "_generated"
        "-stdlibfolder" "${KSLICER_TINYSTL_PATH}"
        "-shaderCC" "${ARG_SHADER}"
        $<TARGET_PROPERTY:${ARG_TARGET},KSLICER_OPTIONS>
    )

    if(${ARG_SHADER} STREQUAL "glsl" OR ${ARG_SHADER} STREQUAL "slang")
        _attach_kslicer_command_vulkan(${ARG_TARGET} ${ARG_MAINCLASS} ${ARG_SHADER} 
                                       ${a_sources_abs_pathes}
                                       ${a_defines_list}
                                       ${a_includes_list}
                                       ${a_include_exceptions}
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

macro(target_kslicer_ignore_directories ARG_TARGET)
    _kslicer_require_enabled(${ARG_TARGET})
    set_property(TARGET ${ARG_TARGET}
                 PROPERTY KSLICER_IGNORE_DIRECTORIES
                 ${ARGN} APPEND)
endmacro()

macro(target_kslicer_process_files ARG_TARGET)
    _kslicer_require_enabled(${ARG_TARGET})
    set_property(TARGET ${ARG_TARGET}
                 PROPERTY KSLICER_PROCESS_FILES
                 ${ARGN} APPEND)
endmacro()

macro(target_kslicer_ignore_files ARG_TARGET)
    _kslicer_require_enabled(${ARG_TARGET})
    set_property(TARGET ${ARG_TARGET}
                 PROPERTY KSLICER_IGNORE_FILES
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

    target_kslicer_ignore_directories(${ARG_TARGET} ${KSLICER_TINYSTL_PATH})

    _attach_kslicer_command(${ARG_TARGET} ${ARG_MAINCLASS} ${ARG_SHADERTYPE})

endfunction()