# macOS platform-specific configuration
include_guard(GLOBAL)

# Compiler settings
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    # Common compiler flags (from clang-sets.jam)
    add_compile_options(
        -pipe
        -arch ${DAGOR_ARCH}
        -mmacosx-version-min=${DAGOR_MACOSX_MIN_VER}
        -MD
        -Werror
        -Wno-trigraphs
        -Wno-multichar
        -Wformat
        -Wno-unused-value
        -Wno-uninitialized
        -Wno-inline-new-delete
        -Wno-unknown-warning-option
        -Wno-deprecated-register
        -Wno-invalid-offsetof
        -Wno-nonportable-include-path
        -Wno-null-dereference
        -Wno-undefined-var-template
        -Wno-constant-conversion
        -Wno-inconsistent-missing-override
        -Wno-deprecated-builtins
        -Wno-unused-command-line-argument
        -ffunction-sections
        -fdata-sections
        -ffast-math
        -ffinite-math-only
        -mrecip=none
    )

    # Definitions
    add_compile_definitions(
        __forceinline=inline\ __attribute__\(\(always_inline\)\)
        __cdecl=
        __stdcall=
        __fastcall=
        _snprintf=snprintf
        _vsnprintf=vsnprintf
        stricmp=strcasecmp
        strnicmp=strncasecmp
        i_strlen=strlen
    )

    # Architecture-specific settings
    if(DAGOR_ARCH STREQUAL "x86_64")
        add_compile_options(-msse4.1)
        add_compile_definitions(_TARGET_SIMD_SSE=${DAGOR_SSE_VERSION})
    elseif(DAGOR_ARCH STREQUAL "arm64")
        add_compile_definitions(
            _TARGET_SIMD_NEON=1
            ARM_NEON_GCC_COMPATIBILITY=1
        )
    endif()

    # Exception handling
    if(NOT DAGOR_EXCEPTIONS)
        add_compile_options(-fno-exceptions)
    else()
        add_compile_options(-fexceptions)
        add_compile_definitions(DAGOR_EXCEPTIONS_ENABLED=1)
    endif()

    # RTTI
    if(NOT DAGOR_RTTI)
        add_compile_options(-fno-rtti)
    else()
        add_compile_options(-frtti)
    endif()

    # Sanitizer support
    if(NOT DAGOR_SANITIZE STREQUAL "disabled")
        add_compile_options(-fsanitize=${DAGOR_SANITIZE})
        string(APPEND CMAKE_EXE_LINKER_FLAGS " -fsanitize=${DAGOR_SANITIZE}")
        string(APPEND CMAKE_SHARED_LINKER_FLAGS " -fsanitize=${DAGOR_SANITIZE}")
    endif()

    # Framework dependencies
    set(DAGOR_MACOS_FRAMEWORKS
        Foundation
        QuartzCore
        CoreLocation
        Cocoa
        IOKit
        CoreFoundation
        Security
        Carbon
        SystemConfiguration
        Metal
    )

    foreach(framework ${DAGOR_MACOS_FRAMEWORKS})
        string(APPEND CMAKE_EXE_LINKER_FLAGS " -framework ${framework}")
        string(APPEND CMAKE_SHARED_LINKER_FLAGS " -framework ${framework}")
    endforeach()
endif()
