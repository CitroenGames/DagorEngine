# Platform detection module for Dagor Engine
include_guard(GLOBAL)

# Valid build configurations
set(DAGOR_BUILD_CONFIGS
    Dev     # Development build with debug info
    Rel     # Release build
    IRel    # Internal release build
    Dbg     # Debug build
)

# Platform specifications
set(DAGOR_PLATFORM_SPECS
    gcc     # GNU Compiler Collection
    clang   # LLVM/Clang Compiler
    msvc    # Microsoft Visual C++
)

# SSE version configuration
if(NOT DEFINED DAGOR_SSE_VERSION)
    set(DAGOR_SSE_VERSION "2" CACHE STRING "SSE version (2/3/4)")
endif()

if(NOT DAGOR_SSE_VERSION MATCHES "^[234]$")
    message(FATAL_ERROR "Invalid SSE version: ${DAGOR_SSE_VERSION}. Must be 2, 3, or 4")
endif()

# Detect host system
if(WIN32)
    set(DAGOR_PLATFORM "windows")
elseif(APPLE)
    set(DAGOR_PLATFORM "macOS")
elseif(UNIX AND NOT APPLE)
    set(DAGOR_PLATFORM "linux")
else()
    message(FATAL_ERROR "Unsupported platform")
endif()

# Detect architecture
if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64)$")
    set(DAGOR_ARCH "x86_64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(i386|i686)$")
    set(DAGOR_ARCH "x86")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)$")
    set(DAGOR_ARCH "arm64")
else()
    message(FATAL_ERROR "Unsupported architecture: ${CMAKE_SYSTEM_PROCESSOR}")
endif()

# Configure platform headers early
set(PLATFORM_HEADER_DIR "${CMAKE_BINARY_DIR}/include")
set(PLATFORM_PLATFORM_DIR "${PLATFORM_HEADER_DIR}/platform")

# Create directories with full paths
execute_process(
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/include"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/include/platform"
)

message(STATUS "Configuring platform headers in ${PLATFORM_PLATFORM_DIR}")
message(STATUS "Source directory: ${CMAKE_SOURCE_DIR}")

if(DAGOR_PLATFORM STREQUAL "linux")
    set(PLATFORM_HEADER_SOURCE "${CMAKE_SOURCE_DIR}/cmake/Platform/linux_platform.h")
    set(PLATFORM_HEADER_DEST "${CMAKE_BINARY_DIR}/include/platform/linux_platform.h")

    if(NOT EXISTS "${PLATFORM_HEADER_SOURCE}")
        message(FATAL_ERROR "Platform header source not found: ${PLATFORM_HEADER_SOURCE}")
    endif()

    execute_process(
        COMMAND ${CMAKE_COMMAND} -E copy "${PLATFORM_HEADER_SOURCE}" "${PLATFORM_HEADER_DEST}"
        RESULT_VARIABLE COPY_RESULT
    )

    if(NOT EXISTS "${PLATFORM_HEADER_DEST}")
        message(FATAL_ERROR "Failed to copy platform header to: ${PLATFORM_HEADER_DEST}, Result: ${COPY_RESULT}")
    endif()

    message(STATUS "Generated linux_platform.h at ${PLATFORM_HEADER_DEST}")
    include_directories(BEFORE SYSTEM
        "${CMAKE_BINARY_DIR}/include"
        /usr/lib/gcc/x86_64-linux-gnu/11/include
        /usr/include/x86_64-linux-gnu
        /usr/include
    )
elseif(DAGOR_PLATFORM STREQUAL "windows")
    set(PLATFORM_HEADER_SOURCE "${CMAKE_SOURCE_DIR}/cmake/Platform/windows_platform.h")
    set(PLATFORM_HEADER_DEST "${CMAKE_BINARY_DIR}/include/platform/windows_platform.h")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E copy "${PLATFORM_HEADER_SOURCE}" "${PLATFORM_HEADER_DEST}"
    )
    message(STATUS "Generated windows_platform.h")
    include_directories(BEFORE SYSTEM "${CMAKE_BINARY_DIR}/include")
elseif(DAGOR_PLATFORM STREQUAL "macOS")
    set(PLATFORM_HEADER_SOURCE "${CMAKE_SOURCE_DIR}/cmake/Platform/macos_platform.h")
    set(PLATFORM_HEADER_DEST "${CMAKE_BINARY_DIR}/include/platform/macos_platform.h")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E copy "${PLATFORM_HEADER_SOURCE}" "${PLATFORM_HEADER_DEST}"
    )
    message(STATUS "Generated macos_platform.h")
    include_directories(BEFORE SYSTEM "${CMAKE_BINARY_DIR}/include")
endif()

# Platform-specific output directory setup
string(TOLOWER "${DAGOR_PLATFORM}" PLATFORM_LOWER)
string(TOLOWER "${DAGOR_PLATFORM_ARCH}" ARCH_LOWER)
string(TOLOWER "${DAGOR_PLATFORM_SPEC}" SPEC_LOWER)
set(DAGOR_PLATFORM_SUFFIX "${PLATFORM_LOWER}/${ARCH_LOWER}/${SPEC_LOWER}")

# Set output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/${DAGOR_PLATFORM_SUFFIX}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/${DAGOR_PLATFORM_SUFFIX}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/${DAGOR_PLATFORM_SUFFIX}")

# Include platform-specific configuration
include("${CMAKE_CURRENT_LIST_DIR}/${DAGOR_PLATFORM}.cmake")

# EASTL Platform-specific configurations
if(MSVC OR (WIN32 AND CMAKE_CXX_COMPILER_ID MATCHES "Clang"))
    if(NOT EASTL_EXCEPTIONS)
        add_compile_definitions(
            _HAS_EXCEPTIONS=0
            EA_COMPILER_NO_NOEXCEPT
        )
    else()
        add_compile_definitions(DAGOR_EXCEPTIONS_ENABLED=1)
    endif()

    if(NOT EASTL_RTTI)
        add_compile_options(/GR-)
    endif()
elseif(UNIX)
    if(NOT EASTL_EXCEPTIONS)
        add_compile_options(-fno-exceptions)
        add_compile_definitions(EA_COMPILER_NO_NOEXCEPT)
    endif()

    if(NOT EASTL_RTTI)
        add_compile_options(-fno-rtti)
    endif()

    if(NOT APPLE)
        if(EASTL_STACK_PROTECTION)
            add_compile_options(-fstack-protector)
        else()
            add_compile_options(-fno-stack-protector)
        endif()
    endif()
endif()
