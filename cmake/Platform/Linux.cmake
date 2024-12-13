# Linux platform-specific configuration
include_guard(GLOBAL)

# Compiler settings
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    # Common compiler flags (from gcc-sets.jam)
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
        -ffunction-sections
        -fdata-sections
        -fno-omit-frame-pointer
        -ffast-math
        -ffinite-math-only
        -mno-recip
        -minline-all-stringops
        -Wuninitialized
        -Werror=uninitialized
        -Wno-deprecated-declarations
        -Wno-maybe-uninitialized
        -Wno-stringop-overflow
        -Wno-stringop-overread
    )

    # Definitions
    add_compile_definitions(
        __forceinline=inline\ __attribute__\(\(always_inline\)\)
        __cdecl=
        __stdcall=
        __fastcall=
        _POSIX_C_SOURCE=200809L
        _GNU_SOURCE
        _snprintf=snprintf
        _vsnprintf=vsnprintf
        stricmp=strcasecmp
        strnicmp=strncasecmp
        i_strlen=(int)strlen
        __STDC_CONSTANT_MACROS
    )

    # C++ specific flags
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fconserve-space -Wno-invalid-offsetof")

    # Sanitizer support
    if(NOT DAGOR_SANITIZE STREQUAL "disabled")
        add_compile_options(-fsanitize=${DAGOR_SANITIZE})
        if(DAGOR_SANITIZE STREQUAL "thread")
            add_compile_definitions(__SANITIZE_THREAD__)
        endif()
        string(APPEND CMAKE_EXE_LINKER_FLAGS " -fsanitize=${DAGOR_SANITIZE}")
        string(APPEND CMAKE_SHARED_LINKER_FLAGS " -fsanitize=${DAGOR_SANITIZE}")
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

    # Link-time optimization
    if(DAGOR_USE_LTO_JOBS)
        add_compile_options(-flto=${DAGOR_USE_LTO_JOBS})
        string(APPEND CMAKE_EXE_LINKER_FLAGS " -flto=${DAGOR_USE_LTO_JOBS}")
        string(APPEND CMAKE_SHARED_LINKER_FLAGS " -flto=${DAGOR_USE_LTO_JOBS}")
    endif()
endif()
