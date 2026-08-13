#ifndef KSLICER_BASE_API_H_
#define KSLICER_BASE_API_H_
#include <memory>

namespace kslicer {

    template<typename T, typename... Args>
    concept IsConstuctorCompatible = requires(Args ...args)
    {
        T(args...);
    };

    template<typename T, typename ...Args> 
    requires IsConstuctorCompatible<T, Args...>
    std::unique_ptr<T> make_gpu(unsigned nThreads, Args ...args);

}

#endif