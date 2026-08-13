#ifndef KSLICER_API_H_
#define KSLICER_API_H_
#include <memory>

                            #define KSLICER_VULKAN



#if defined(KSLICER_VULKAN)
#include "vulkan_api.h"
#else
#include <stdexcept>

template<typename T, typename ...Args> requires IsConstuctorCompatible<T, Args...>
std::unique_ptr<T> kslicer::make_gpu(unsigned, Args...)
{
    throw std::runtime_error("Cannot create GPU implementation of class: kernel slicer is disabled");
}
#endif



#endif
