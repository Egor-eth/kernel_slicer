
macro(attach_kslicer_command ARG_TARGET)

    add_custom_command(OUTPUT ${ARGN}
                       COMMAND ${KSLICER_EXECUTABLE}
                       ARGS $<TARGET_PROPERTY:${ARG_TARGET},KSLICER_SOURCES>
                            $<LIST:TRANSFORM,$<TARGET_PROPERTY:${ARG_TARGET},COMPILE_DEFINITIONS>,PREPEND,-D>
                            $<LIST:TRANSFORM,$<TARGET_PROPERTY:${ARG_TARGET},INCLUDE_DIRECTORIES>,PREPEND,-I>
                            $<TARGET_PROPERTY:${ARG_TARGET},KSLICER_OPTIONS>
                       DEPENDS $<TARGET_PROPERTY:${ARG_TARGET},KSLICER_SOURCES>
                       COMMENT "Generating GPU code with Kernel Slicer")
    
    add_custom_target(${ARG_TARGET}_kslicer DEPENDS ${ARGN})
    add_dependencies(${ARG_TARGET} ${ARG_TARGET}_kslicer)

endmacro(attach_kslicer_command ARG_TARGET)

macro(target_kslicer_sources ARG_TARGET)

    target_compile_definitions(${ARG_TARGET} PRIVATE KERNEL_SLICER)

    set_property(TARGET ${ARG_TARGET}
                 PROPERTY KSLICER_SOURCES
                 ${ARGN} APPEND)
    get_property(VAR_HAS_MAINFILE 
                 TARGET ${ARG_TARGET}
                 PROPERTY KSLICER_MAIN_OUTPUTS DEFINED)

    if(NOT ${VAR_HAS_MAINFILE})
        list(GET ${ARGN} 0 VAR_MAIN_FILE)
        message(STATUS ${ARG_TARGET} )
        message(STATUS ${ARGN} )
        message(STATUS "--->  ${VAR_MAIN_FILE}" )
        get_filename_component(VAR_MAINGEN_WE ${VAR_MAIN_FILE} NAME_WE)
        set(VAR_MAIN_GENERATED_FILES 
            "${CMAKE_CURRENT_SOURCE_DIR}/${VAR_MAINGEN_WE}_generated.cpp"
           # "${CMAKE_CURRENT_SOURCE_DIR}/${VAR_MAINGEN_WE}_generated.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/${VAR_MAINGEN_WE}_generated_ds.cpp"
            "${CMAKE_CURRENT_SOURCE_DIR}/${VAR_MAINGEN_WE}_generated_init.cpp")


        set_property(TARGET ${ARG_TARGET} 
                     PROPERTY KSLICER_MAIN_OUTPUTS
                     ${VAR_MAIN_GENERATED_FILES})
        attach_kslicer_command(${ARG_TARGET} ${VAR_MAIN_GENERATED_FILES})

        target_sources(${ARG_TARGET} PRIVATE ${VAR_MAIN_GENERATED_FILES})
    endif()

endmacro(target_kslicer_sources ARG_TARGET)

macro(target_kslicer_options ARG_TARGET)
    set_property(TARGET ${ARG_TARGET}
                 PROPERTY KSLICER_OPTIONS
                 ${ARGN} APPEND)
endmacro(target_kslicer_options ARG_TARGET)