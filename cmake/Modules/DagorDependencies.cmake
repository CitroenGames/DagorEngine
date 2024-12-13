# Dependencies configuration module
include_guard(GLOBAL)

# Global C++ settings
set(DAGOR_CPP_STD "17" CACHE STRING "C++ Standard Version")
set(DAGOR_KERNEL_LINKAGE "static" CACHE STRING "Kernel linkage type (static/dynamic)")
set(DAGOR_SANITIZE "disabled" CACHE STRING "Sanitizer type (disabled/address/thread)")
set(DAGOR_EXCEPTIONS "ON" CACHE BOOL "Enable C++ exceptions")
set(DAGOR_RTTI "OFF" CACHE BOOL "Enable C++ RTTI")
set(DAGOR_STACK_PROTECTION "ON" CACHE BOOL "Enable stack protection")

# SSE Configuration
if(DAGOR_PLATFORM STREQUAL "windows" AND DAGOR_ARCH STREQUAL "x86_64")
    set(DAGOR_SSE_VERSION "4" CACHE STRING "SSE Version")
elseif(DAGOR_PLATFORM STREQUAL "linux" AND DAGOR_ARCH STREQUAL "x86_64")
    set(DAGOR_SSE_VERSION "4" CACHE STRING "SSE Version")
else()
    set(DAGOR_SSE_VERSION "2" CACHE STRING "SSE Version")
endif()

# Math precision options
set(DAGOR_MATH_OPTION "fast" CACHE STRING "Math precision (fast/precise/strict)")
set_property(CACHE DAGOR_MATH_OPTION PROPERTY STRINGS fast precise strict)

# EASTL Configuration
set(DAGOR_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/../..")
set(EABASE_INCLUDE_DIR "${DAGOR_ROOT_DIR}/third_party/EABase/include/Common")
set(EASTL_INCLUDE_DIR "${DAGOR_ROOT_DIR}/third_party/EASTL/include")
set(EASTL_LIBRARY_DIR "${DAGOR_ROOT_DIR}/third_party/EASTL/build")

list(APPEND CMAKE_MODULE_PATH "${DAGOR_ROOT_DIR}/third_party/EASTL/cmake")
include_directories(${EABASE_INCLUDE_DIR})
include_directories(${EASTL_INCLUDE_DIR})
link_directories(${EASTL_LIBRARY_DIR})

if(NOT TARGET EASTL)
    add_subdirectory("${DAGOR_ROOT_DIR}/third_party/EASTL" "${CMAKE_BINARY_DIR}/third_party/EASTL" EXCLUDE_FROM_ALL)
endif()

# Platform-specific compiler flags
if(DAGOR_PLATFORM STREQUAL "linux")
    add_compile_options(
        -pipe
        -msse${DAGOR_SSE_VERSION}
        -m64
        -MMD
        -Wno-trigraphs
        -Wno-multichar
        -Wformat
        -Wno-format-extra-args
        -Wno-ignored-attributes
        -Wno-deprecated
        -Wno-format-truncation
        -Wno-nonnull
    )

    # Math precision flags
    if(DAGOR_MATH_OPTION STREQUAL "fast")
        add_compile_options(-ffast-math)
    elseif(DAGOR_MATH_OPTION STREQUAL "precise")
        add_compile_options(-fno-fast-math)
    endif()
endif()
