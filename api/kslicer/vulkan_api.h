#ifndef KSLICER_VULKAN_API_H_
#define KSLICER_VULKAN_API_H_

#include <string>
#include "base_api.h"

namespace kslicer {

    struct VulkanCreateContext
    {
        int prefferedDeviceId = 0;
        size_t auxBufferMemory = 0;
        bool enableValidationLayers = false;
    };

    template<typename T>
    void megakernel_set_pipeline_enable_flag(const std::string &name, bool flag);
    
    template<typename T, typename... Args> requires IsConstuctorCompatible<T, Args...>
    std::unique_ptr<T> make_gpu_from_context(const VulkanCreateContext &ctx, unsigned nThreads, Args ...args);


    template<typename T, typename... Args>
    std::unique_ptr<T> make_gpu(unsigned nThreads, Args ...args)
    {
        return make_gpu_from_context({}, nThreads, args...);
    }


}

#endif