
function(attach_kslicer_command ARG_TARGET)
    set(a_sources_list $<TARGET_PROPERTY:${ARG_TARGET},KSLICER_SOURCES>)
    set(a_sources_abs_pathes $<PATH:ABSOLUTE_PATH,${a_sources_list},${CMAKE_CURRENT_SOURCE_DIR}>)

    set(a_defines_list $<LIST:TRANSFORM,$<TARGET_PROPERTY:${ARG_TARGET},COMPILE_DEFINITIONS>,PREPEND,-D> "-DKERNEL_SLICER")

    set(includes $<TARGET_PROPERTY:${ARG_TARGET},INCLUDE_DIRECTORIES>)
    set(processed_includes $<TARGET_PROPERTY:${ARG_TARGET},KSLICER_PROCESS_DIRECTORIES>)
    set(processed_includes $<LIST:REMOVE_DUPLICATES,${processed_includes}>)

    set(includes_abs $<PATH:ABSOLUTE_PATH,${includes},${CMAKE_CURRENT_SOURCE_DIR}>)
    set(includes_abs $<LIST:REMOVE_DUPLICATES,${includes_abs}>)

    set(processed_includes_abs $<PATH:ABSOLUTE_PATH,${processed_includes},${CMAKE_CURRENT_SOURCE_DIR}>)
    set(ignored_includes_abs $<LIST:REMOVE_ITEM,${includes_abs},${processed_includes_abs}>)

    
    set(a_includes_list
        $<LIST:TRANSFORM,${processed_includes_abs},PREPEND,-IP>
        $<LIST:TRANSFORM,${ignored_includes_abs},PREPEND,-II>
    )

    set(a_options
        "-stdlibfolder" "${KSLICER_TINYSTL_PATH}"
    )

    set(a_options 
        ${a_options} 
        $<TARGET_PROPERTY:${ARG_TARGET},KSLICER_OPTIONS>)

    message(STATUS ${KSLICER_EXECUTABLE})
    add_custom_command(OUTPUT ${ARGN}
                       COMMAND ${KSLICER_EXECUTABLE}
                             ${a_sources_abs_pathes}
                             ${a_defines_list}
                             ${a_includes_list}
                             ${a_options}
                       DEPENDS ${a_sources_list}
                       COMMENT "Generating GPU code with Kernel Slicer"
                       COMMAND_EXPAND_LISTS)
    
    add_custom_target(${ARG_TARGET}_kslicer DEPENDS ${ARGN})
    add_dependencies(${ARG_TARGET} ${ARG_TARGET}_kslicer)

endfunction(attach_kslicer_command ARG_TARGET)

function(target_kslicer_sources ARG_TARGET)
    set(files ${ARGN})

    if("${files}" STREQUAL "")
        message(FATAL_ERROR "target_kslicer_sources(...) should contain sources")
    endif()

    target_compile_definitions(${ARG_TARGET} PRIVATE USE_KERNEL_SLICER)

    set_property(TARGET ${ARG_TARGET}
                 PROPERTY KSLICER_SOURCES
                 ${files} APPEND)
    get_property(has_mainfile 
                 TARGET ${ARG_TARGET}
                 PROPERTY KSLICER_MAIN_OUTPUTS DEFINED)

    if(NOT ${has_mainfile})
        list(GET files 0 main_file)
      #  message(STATUS ${ARG_TARGET} )
      #  message(STATUS "${files}" )
      #  message(STATUS "--->  ${main_file}" )
        get_filename_component(maingen_we ${main_file} NAME_WE)
        set(main_generated_files 
            "${CMAKE_CURRENT_SOURCE_DIR}/${maingen_we}_generated.cpp"
           # "${CMAKE_CURRENT_SOURCE_DIR}/${maingen_we}_generated.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/${maingen_we}_generated_ds.cpp"
            "${CMAKE_CURRENT_SOURCE_DIR}/${maingen_we}_generated_init.cpp")


        set_property(TARGET ${ARG_TARGET} 
                     PROPERTY KSLICER_MAIN_OUTPUTS
                     ${main_generated_files})
        attach_kslicer_command(${ARG_TARGET} ${main_generated_files})

        target_sources(${ARG_TARGET} PRIVATE ${main_generated_files})
    endif()

endfunction(target_kslicer_sources ARG_TARGET)

macro(target_kslicer_options ARG_TARGET)
    set_property(TARGET ${ARG_TARGET}
                 PROPERTY KSLICER_OPTIONS
                 ${ARGN} APPEND)
endmacro(target_kslicer_options ARG_TARGET)

macro(target_kslicer_process_directories ARG_TARGET)
    set_property(TARGET ${ARG_TARGET}
                 PROPERTY KSLICER_PROCESS_DIRECTORIES
                 ${ARGN} APPEND)
endmacro(target_kslicer_process_directories ARG_TARGET)