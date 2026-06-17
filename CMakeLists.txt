cmake_minimum_required(VERSION 3.12)
project(kernel_slicer)

set(LLVM_LINK_COMPONENTS support)
  
set(LLVM_LIB "LLVM")

find_package(LLVM 22.1...<23 REQUIRED CONFIG)
find_package(Clang 22.1...<23 CONFIG REQUIRED)
set(LLVM_LINK_COMPONENTS support)

option(KSLICER_LLVM_BUILD "Build kernel_slicer as a LLVM project module" OFF)

#set_if_undefined(KSLICER_INSTALL_CMAKEDIR 
#    "${CMAKE_INSTALL_LIBDIR}/cmake/mylib-${PROJECT_VERSION}" CACHE STRING
#    "Install path for mylib package-related CMake files")

set(KSLICER_SRC_DIR src)
set(KSLICER_SOURCE_FILES
    ${KSLICER_SRC_DIR}/kslicer_main.cpp
    ${KSLICER_SRC_DIR}/kslicer_utils.cpp
    ${KSLICER_SRC_DIR}/kslicer_warnings.cpp
    ${KSLICER_SRC_DIR}/kslicer_def.cpp
    ${KSLICER_SRC_DIR}/attributes.cpp
    ${KSLICER_SRC_DIR}/block_expansion.cpp
    ${KSLICER_SRC_DIR}/initial_pass.cpp
    ${KSLICER_SRC_DIR}/initial_pass_compos.cpp
    ${KSLICER_SRC_DIR}/extractor.cpp
    ${KSLICER_SRC_DIR}/ast_matchers.cpp
    ${KSLICER_SRC_DIR}/class_gen.cpp
    ${KSLICER_SRC_DIR}/class_gen_ipv.cpp
    ${KSLICER_SRC_DIR}/class_gen_rtv.cpp
    ${KSLICER_SRC_DIR}/class_gen_vfh.cpp
    ${KSLICER_SRC_DIR}/class_data.cpp
    ${KSLICER_SRC_DIR}/template_rendering.cpp
    ${KSLICER_SRC_DIR}/template_rendering_host.cpp
    ${KSLICER_SRC_DIR}/rewrite_functions.cpp
    ${KSLICER_SRC_DIR}/rewrite_kernel.cpp
    ${KSLICER_SRC_DIR}/rewrite_kernel2.cpp
    ${KSLICER_SRC_DIR}/rewrite_kernel_info.cpp
    ${KSLICER_SRC_DIR}/setter_process.cpp
    ${KSLICER_SRC_DIR}/reduction.cpp
    ${KSLICER_SRC_DIR}/shaders_clspv.cpp
    ${KSLICER_SRC_DIR}/shaders_glsl.cpp
    ${KSLICER_SRC_DIR}/shaders_ispc.cpp
    ${KSLICER_SRC_DIR}/shaders_slang.cpp
    ${KSLICER_SRC_DIR}/shaders_cuda.cpp
    ${KSLICER_SRC_DIR}/tr_host_vulkan.cpp
    ${KSLICER_SRC_DIR}/tr_host_cuda.cpp
    ${KSLICER_SRC_DIR}/tr_host_ispc.cpp
    ${KSLICER_SRC_DIR}/tr_host_wgpu.cpp)

if(WIN32)
#...
else()
include(GNUInstallDirs)
endif()

if(KSLICER_INSTALL AND NOT CMAKE_SKIP_INSTALL_RULES)
  set(KSLICER_INSTALL_DATADIR ${CMAKE_INSTALL_DATADIR}/kslicer/)
  set(KSLICER_INSTALL_FULL_DATADIR ${CMAKE_INSTALL_PREFIX}/${KSLICER_INSTALL_DATADIR})
else()
  set(KSLICER_INSTALL_DATADIR ${CMAKE_CURRENT_SOURCE_DIR}/)
  set(KSLICER_INSTALL_FULL_DATADIR ${KSLICER_INSTALL_DATADIR})
endif()



message(STATUS ${KSLICER_DATADIR})

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/template_files.h.in" "gen/template_files.h")
#configure_file("${CMAKE_CURRENT_SOURCE_DIR}/template_files.cpp.in" "gen/template_files.cpp")

if(NOT KSLICER_LLVM_BUILD)


  if(WIN32)
    if(MSVC)
      add_compile_options(/bigobj)
    endif()
  else()
    set(PLATFORM_DEPENDENT_LIBS clang ${LLVM_LIB})
  endif()


  message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
  message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")



  message("LLVM_INCLUDE_DIRS = ${LLVM_INCLUDE_DIRS}")
  message("LLVM_LIBRARY_DIRS = ${LLVM_LIBRARY_DIRS}")
  # message("CLANG_INCLUDE_DIRS = ${CLANG_INCLUDE_DIRS}")
  # message("CLANG_LIBRARY_DIRS = ${CLANG_LIBRARY_DIRS}") set(CMAKE_MODULE_PATH
  # ${CMAKE_MODULE_PATH} "${LLVM_CMAKE_DIR}")

  add_executable(kslicer ${KSLICER_SOURCE_FILES})

  target_include_directories(kslicer PUBLIC ${LLVM_INCLUDE_DIRS} ${CLANG_INCLUDE_DIRS})
  target_include_directories(kslicer PRIVATE include)
  target_include_directories(kslicer PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/gen)
  target_link_directories(kslicer PUBLIC ${LLVM_LIBRARY_DIRS})
  add_definitions(${LLVM_DEFINITIONS})
  add_definitions(${CLANG_DEFINITIONS})
  target_compile_features(kslicer PUBLIC cxx_std_17)

  target_link_libraries(kslicer
    PRIVATE
    clang-cpp
    ${PLATFORM_DEPENDENT_LIBS})

else() # NOT DEFINED KSLICER_LLVM_BUILD
  message(STATUS "kernel_slicer build with LLVM")

  # file(GLOB_RECURSE SRC_DIR "include/*.h" "include/nlohmann/*.h" )
  # set_source_files_properties(${SRC_DIR} PROPERTIES COMPILE_FLAGS "-w")
  set(LLVM_LINK_COMPONENTS support)
  add_clang_executable(kslicer ${KSLICER_SOURCE_FILES})

  target_compile_features(kslicer PUBLIC cxx_std_17)

  target_compile_options(kslicer PRIVATE -fexceptions)

  target_link_libraries(kslicer PRIVATE clang clangTooling clangBasic
                                        clangASTMatchers)

  target_include_directories(kslicer PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/gen)
endif() # DEFINED KSLICER_LLVM_BUILD


set(KSLICER_TEMPLATE_DIRS
  templates
  templates_cuda
  templates_glsl
  templates_ispc
  templates_slang
  templates_wk
  TINYSTL)


if(KSLICER_INSTALL AND NOT CMAKE_SKIP_INSTALL_RULES)
  install(TARGETS kslicer)
  foreach(dir_i ${KSLICER_TEMPLATE_DIRS})
    install(DIRECTORY ${dir_i} DESTINATION ${KSLICER_INSTALL_DATADIR})
  endforeach(dir_i)

endif()