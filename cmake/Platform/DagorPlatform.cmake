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
