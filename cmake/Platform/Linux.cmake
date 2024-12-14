# Platform specific configuration for Linux
include_guard(GLOBAL)

# Compiler settings
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    # Add compiler-specific include paths first
    include_directories(SYSTEM
        /usr/lib/gcc/x86_64-linux-gnu/11/include  # For intrinsics
        /usr/include/x86_64-linux-gnu            # For system headers
        /usr/include                             # For standard headers
    )

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

    # Platform definitions
    add_compile_definitions(
        _POSIX_C_SOURCE=200809L
        _GNU_SOURCE
        __STDC_CONSTANT_MACROS
    )

    # Configure platform header
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/include/platform)
    configure_file(
        ${CMAKE_CURRENT_LIST_DIR}/linux_platform.h
        ${CMAKE_BINARY_DIR}/include/platform/linux_platform.h
        COPYONLY
    )
    include_directories(BEFORE SYSTEM ${CMAKE_BINARY_DIR}/include/platform)

    # C++ specific flags
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fconserve-space -Wno-invalid-offsetof")

    # Sanitizer support (from gcc-sets.jam)
    if(DEFINED DAGOR_SANITIZE AND NOT "${DAGOR_SANITIZE}" STREQUAL "disabled")
        if(NOT "${DAGOR_SANITIZE}" STREQUAL "")
            add_compile_options(-fsanitize=${DAGOR_SANITIZE})
            if("${DAGOR_SANITIZE}" STREQUAL "thread")
                add_compile_definitions(__SANITIZE_THREAD__)
            endif()
            string(APPEND CMAKE_EXE_LINKER_FLAGS " -fsanitize=${DAGOR_SANITIZE}")
            string(APPEND CMAKE_SHARED_LINKER_FLAGS " -fsanitize=${DAGOR_SANITIZE}")
        endif()
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

    # Static linkage
    if(DAGOR_KERNEL_LINKAGE STREQUAL "static")
        add_compile_definitions(_TARGET_STATIC_LIB=1)
    endif()

    # Debug symbols and section garbage collection
    if(NOT DAGOR_STRIP_TYPE STREQUAL "all")
        string(APPEND CMAKE_EXE_LINKER_FLAGS " -rdynamic")
    endif()

    if(NOT DAGOR_CHECK_ONLY)
        string(APPEND CMAKE_EXE_LINKER_FLAGS " -Wl,--gc-sections")
    endif()
endif()
