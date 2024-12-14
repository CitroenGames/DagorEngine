cmake_minimum_required(VERSION 3.20)

# Define valid build configurations first
set(DAGOR_BUILD_CONFIGS
    Dev     # Development build with debug info
    Rel     # Release build
    IRel    # Internal release build
    Dbg     # Debug build
)

# Include custom modules early
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Platform)

# EASTL configuration options first
option(EASTL_EXCEPTIONS "Enable exception handling in EASTL" ${DAGOR_EXCEPTIONS})
option(EASTL_RTTI "Enable RTTI in EASTL" ON)
option(EASTL_STACK_PROTECTION "Enable stack protection in EASTL" ${DAGOR_STACK_PROTECTION})

# Include platform detection and configuration early
include(DagorPlatform)

project(DagorEngine
    VERSION 1.0.0
    DESCRIPTION "Dagor Game Engine"
    LANGUAGES C CXX)

# Include additional configuration modules
include(CommonCppFlags)
include(DagorShaders)
include(DagorDependencies)
include(DagorFunctions)

# Force include platform header for all targets
if(DAGOR_PLATFORM STREQUAL "linux")
    add_compile_options(-include ${CMAKE_BINARY_DIR}/include/platform/linux_platform.h)
    include_directories(SYSTEM /usr/lib/gcc/x86_64-linux-gnu/11/include)
elseif(DAGOR_PLATFORM STREQUAL "windows")
    add_compile_options(/FI${CMAKE_BINARY_DIR}/include/platform/windows_platform.h)
elseif(DAGOR_PLATFORM STREQUAL "macOS")
    add_compile_options(-include ${CMAKE_BINARY_DIR}/include/platform/macos_platform.h)
endif()

# Apply global settings from DagorDependencies
set(CMAKE_CXX_STANDARD ${DAGOR_CPP_STD})
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Default configuration
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Dev" CACHE STRING "Choose the type of build (Dev;Rel;IRel;Dbg)" FORCE)
endif()

# Validate build type
if(NOT CMAKE_BUILD_TYPE IN_LIST DAGOR_BUILD_CONFIGS)
    message(FATAL_ERROR "Invalid build type: ${CMAKE_BUILD_TYPE}. Must be one of: ${DAGOR_BUILD_CONFIGS}")
endif()

# Output directory configuration
if(DEFINED ENV{GOUT_ROOT})
    set(DAGOR_OUTPUT_ROOT $ENV{GOUT_ROOT})
else()
    set(DAGOR_OUTPUT_ROOT "${CMAKE_SOURCE_DIR}/_output")
endif()

# Platform-specific definitions
if(DAGOR_PLATFORM STREQUAL "windows")
    add_compile_definitions(
        _TARGET_PC=1
        _TARGET_PC_WIN=1
        WIN32_LEAN_AND_MEAN
        _TARGET_64BIT=1
    )
elseif(DAGOR_PLATFORM STREQUAL "linux")
    add_compile_definitions(
        _TARGET_PC=3
        _TARGET_PC_LINUX=3
        _TARGET_64BIT=1
        __LINUX__=64
    )
elseif(DAGOR_PLATFORM STREQUAL "macOS")
    add_compile_definitions(
        _TARGET_PC=2
        _TARGET_PC_MACOSX=2
        _TARGET_APPLE=1
        _TARGET_64BIT=1
        __MACOSX__=1
    )
endif()

# Conditional settings based on build type
if(CMAKE_BUILD_TYPE STREQUAL "Dbg")
    set(DAGOR_EXCEPTIONS "ON")
    set(DAGOR_STACK_PROTECTION "ON")
    add_compile_definitions(DAGOR_DBGLEVEL=2)
elseif(CMAKE_BUILD_TYPE STREQUAL "Dev")
    set(DAGOR_EXCEPTIONS "ON")
    add_compile_definitions(DAGOR_DBGLEVEL=1)
elseif(CMAKE_BUILD_TYPE STREQUAL "Rel")
    set(DAGOR_EXCEPTIONS "OFF")
    set(DAGOR_STACK_PROTECTION "OFF")
    add_compile_definitions(DAGOR_DBGLEVEL=0 NDEBUG=1)
elseif(CMAKE_BUILD_TYPE STREQUAL "IRel")
    set(DAGOR_EXCEPTIONS "OFF")
    set(DAGOR_STACK_PROTECTION "OFF")
    add_compile_definitions(DAGOR_DBGLEVEL=-1 NDEBUG=1)
endif()

# Stack protection configuration
if(DAGOR_STACK_PROTECTION)
    add_compile_definitions(_STACK_PROTECTION=1)
endif()

# Shader compilation configuration
set(DAGOR_DXC_VERSION "1.7.2207" CACHE STRING "DXC compiler version")
set(DAGOR_SHADER_DEBUG OFF CACHE BOOL "Enable shader debug information")
set(DAGOR_COPY_DXC_LIB OFF CACHE BOOL "Copy DXC library to output directory")

if(DAGOR_COPY_DXC_LIB AND DAGOR_PLATFORM STREQUAL "windows")
    set(DXC_DIR "$ENV{DEVTOOL}/DXC-${DAGOR_DXC_VERSION}/lib/${DAGOR_PLATFORM_SUFFIX}")
    if(NOT EXISTS "${DXC_DIR}")
        message(FATAL_ERROR "DXC directory not found: ${DXC_DIR}")
    endif()

    set(DXC_LIBRARY "dxcompiler.dll")
    if(DAGOR_PLATFORM STREQUAL "macOS")
        set(DXC_LIBRARY "libdxcompiler.dylib")
    endif()

    configure_file(
        "${DXC_DIR}/${DXC_LIBRARY}"
        "${CMAKE_BINARY_DIR}/bin/${DXC_LIBRARY}"
        COPYONLY
    )
endif()

# Add subdirectories
add_subdirectory(prog/engine/kernel)
add_subdirectory(prog/engine/baseUtil)
add_subdirectory(prog/tools/ShaderCompiler2)
