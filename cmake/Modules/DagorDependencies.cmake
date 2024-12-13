include_guard(GLOBAL)

set(DAGOR_GLOBAL_INCLUDES
    ${CMAKE_SOURCE_DIR}/prog/dagorInclude
    ${CMAKE_SOURCE_DIR}/prog/1stPartyLibs
    ${CMAKE_SOURCE_DIR}/prog/3rdPartyLibs
)

if(DAGOR_PLATFORM_ARCH STREQUAL "e2k")
    list(APPEND DAGOR_GLOBAL_INCLUDES
        ${CMAKE_SOURCE_DIR}/prog/dagorInclude/supp/elbrus_e2k
    )
endif()

set(DAGOR_LIB_TYPES
    STATIC
    SHARED
    EXECUTABLE
)

# SDK Versions (from defaults.jam)
set(DAGOR_GDK_VERSION "240602" CACHE STRING "GDK Version")
set(DAGOR_GDK_WIN_SDK "22621" CACHE STRING "GDK Windows SDK Version")
set(DAGOR_PS4_SDK_VER "1050" CACHE STRING "PS4 SDK Version")
set(DAGOR_PS5_SDK_VER "900" CACHE STRING "PS5 SDK Version")
set(DAGOR_MACOS_MIN_VER "11.0" CACHE STRING "macOS Minimum Version")
set(DAGOR_IOS_MIN_VER "15.0" CACHE STRING "iOS Minimum Version")
set(DAGOR_TVOS_MIN_VER "11.4" CACHE STRING "tvOS Minimum Version")
set(DAGOR_ANDROID_NDK_VER "r25c" CACHE STRING "Android NDK Version")
set(DAGOR_ANDROID_API_VER "33" CACHE STRING "Android API Version")
set(DAGOR_ANDROID_API_MIN_VER "28" CACHE STRING "Android Minimum API Version")
set(DAGOR_NSWITCH_SDK_VER "1754" CACHE STRING "Nintendo Switch SDK Version")

# Build configuration options
set(DAGOR_BUILD_CONFIGS
    Dev
    Rel
    IRel
    Dbg
)

# Platform-specific library paths
if(DAGOR_PLATFORM STREQUAL "linux")
    set(DAGOR_LIBRARY_PATHS
        /usr/lib
        /usr/lib64
        ${CMAKE_INSTALL_PREFIX}/lib
    )

    # MOLD linker support
    if(DAGOR_USE_MOLD_LINK)
        add_link_options(-B/usr/libexec/mold)
    endif()
endif()

# Tools setup configuration (from tools_setup.jam)
set(DAGOR_SKIP_LICENSE_BUILD "no" CACHE STRING "Skip license build")
set(DAGOR_WIN_SDK_VER "win.sdk.100" CACHE STRING "Windows SDK Version")
set(DAGOR_COPY_DXC_LIB "no" CACHE STRING "Copy DXC library")

function(dagor_set_common_properties target)
    target_include_directories(${target} PUBLIC ${DAGOR_GLOBAL_INCLUDES})

    if(DAGOR_PLATFORM_SPEC STREQUAL "gcc")
        # Common compiler flags from gcc-sets.jam
        target_compile_options(${target} PRIVATE
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

        # Platform-specific definitions
        target_compile_definitions(${target} PRIVATE
            __forceinline=inline\ __attribute__\(\(always_inline\)\)
            __cdecl=
            __stdcall=
            __fastcall=
            _POSIX_C_SOURCE=200809L
            _GNU_SOURCE
            _snprintf=snprintf
            _vsnprintf=vsnprintf
            "stricmp=strcasecmp"
            "strnicmp=strncasecmp"
            _TARGET_PC=3
            _TARGET_PC_LINUX=3
            _TARGET_64BIT=1
            __LINUX__=64
            _TARGET_SIMD_SSE=${DAGOR_SSE_VERSION}
            "i_strlen=(int)strlen"
            __STDC_CONSTANT_MACROS
        )

        # Static library configuration
        if(DAGOR_KERNEL_LINKAGE STREQUAL "static")
            target_compile_definitions(${target} PRIVATE _TARGET_STATIC_LIB=1)
        endif()

        # Exception handling
        if(NOT DAGOR_EXCEPTIONS)
            target_compile_options(${target} PRIVATE -fno-exceptions)
        else()
            target_compile_options(${target} PRIVATE -fexceptions)
            target_compile_definitions(${target} PRIVATE DAGOR_EXCEPTIONS_ENABLED=1)
        endif()

        # RTTI support
        if(NOT DAGOR_RTTI)
            target_compile_options(${target} PRIVATE -fno-rtti)
        else()
            target_compile_options(${target} PRIVATE -frtti)
        endif()

        # Sanitizer support
        if(DAGOR_SANITIZE AND NOT DAGOR_SANITIZE STREQUAL "disabled")
            target_compile_options(${target} PRIVATE -fsanitize=${DAGOR_SANITIZE})
            target_link_options(${target} PRIVATE -fsanitize=${DAGOR_SANITIZE})
            if(DAGOR_SANITIZE STREQUAL "thread")
                target_compile_definitions(${target} PRIVATE __SANITIZE_THREAD__)
            endif()
        endif()

        # Link-time optimization
        if(DAGOR_USE_LTO_JOBS)
            target_compile_options(${target} PRIVATE -flto=${DAGOR_USE_LTO_JOBS})
            target_link_options(${target} PRIVATE -flto=${DAGOR_USE_LTO_JOBS})
        endif()

        # Strip configuration
        if(NOT DAGOR_STRIP_TYPE STREQUAL "all")
            target_link_options(${target} PRIVATE -rdynamic)
        endif()

        # Section garbage collection
        if(NOT DAGOR_CHECK_ONLY)
            target_link_options(${target} PRIVATE -Wl,--gc-sections)
        endif()
    endif()
endfunction()

function(dagor_set_build_config target config)
    string(TOUPPER ${config} config_upper)

    if(config STREQUAL "Dbg")
        target_compile_definitions(${target} PRIVATE DAGOR_DBGLEVEL=2)
        set_target_properties(${target} PROPERTIES
            DAGOR_EXCEPTIONS ON
            DAGOR_STACK_PROTECTION ON
        )
    elseif(config STREQUAL "Dev")
        target_compile_definitions(${target} PRIVATE DAGOR_DBGLEVEL=1)
        set_target_properties(${target} PROPERTIES
            DAGOR_EXCEPTIONS ON
        )
    elseif(config STREQUAL "Rel")
        target_compile_definitions(${target} PRIVATE
            DAGOR_DBGLEVEL=0
            NDEBUG=1
        )
        set_target_properties(${target} PROPERTIES
            DAGOR_EXCEPTIONS OFF
            DAGOR_STACK_PROTECTION OFF
        )
    elseif(config STREQUAL "IRel")
        target_compile_definitions(${target} PRIVATE
            DAGOR_DBGLEVEL=-1
            NDEBUG=1
        )
        set_target_properties(${target} PROPERTIES
            DAGOR_EXCEPTIONS OFF
            DAGOR_STACK_PROTECTION OFF
        )
    endif()
endfunction()

function(dagor_set_platform_properties target)
    if(DAGOR_PLATFORM STREQUAL "linux")
        if(NOT DAGOR_CHECK_ONLY)
            target_link_options(${target} PRIVATE -Wl,--gc-sections)
        endif()

        if(NOT DAGOR_STRIP_TYPE STREQUAL "all")
            target_link_options(${target} PRIVATE -rdynamic)
        endif()
    endif()

    if(DAGOR_PLATFORM STREQUAL "ps4")
        target_compile_definitions(${target} PRIVATE
            PS4_SDK_VER=${DAGOR_PS4_SDK_VER}
        )
    elseif(DAGOR_PLATFORM STREQUAL "ps5")
        target_compile_definitions(${target} PRIVATE
            PS5_SDK_VER=${DAGOR_PS5_SDK_VER}
        )
    elseif(DAGOR_PLATFORM STREQUAL "android")
        target_compile_definitions(${target} PRIVATE
            ANDROID_NDK_VERSION="${DAGOR_ANDROID_NDK_VER}"
            ANDROID_API_LEVEL=${DAGOR_ANDROID_API_VER}
            ANDROID_MIN_API_LEVEL=${DAGOR_ANDROID_API_MIN_VER}
        )
    endif()
endfunction()

function(dagor_add_library)
    cmake_parse_arguments(ARGS
        "STATIC;SHARED"
        "NAME;OUTPUT_NAME"
        "SOURCES;WIN_SOURCES;UNIX_SOURCES;INCLUDES;DEPENDENCIES;USE_PROG_LIBS"
        ${ARGN}
    )

    if(NOT ARGS_NAME)
        message(FATAL_ERROR "Library name must be specified")
    endif()

    if(ARGS_STATIC)
        set(lib_type STATIC)
    elseif(ARGS_SHARED)
        set(lib_type SHARED)
    else()
        set(lib_type STATIC)
    endif()

    add_library(${ARGS_NAME} ${lib_type})

    dagor_add_platform_sources(${ARGS_NAME}
        SOURCES ${ARGS_SOURCES}
        WIN_SOURCES ${ARGS_WIN_SOURCES}
        UNIX_SOURCES ${ARGS_UNIX_SOURCES}
    )

    if(ARGS_OUTPUT_NAME)
        set_target_properties(${ARGS_NAME} PROPERTIES
            OUTPUT_NAME ${ARGS_OUTPUT_NAME}
        )
    endif()

    if(ARGS_INCLUDES)
        target_include_directories(${ARGS_NAME} PUBLIC ${ARGS_INCLUDES})
    endif()

    if(ARGS_DEPENDENCIES)
        target_link_libraries(${ARGS_NAME} PUBLIC ${ARGS_DEPENDENCIES})
    endif()

    dagor_process_conditional_dependencies(${ARGS_NAME}
        INCLUDES ${ARGS_INCLUDES}
        LIBS ${ARGS_USE_PROG_LIBS}
    )

    dagor_set_common_properties(${ARGS_NAME})
    dagor_set_platform_properties(${ARGS_NAME})
endfunction()

function(dagor_add_executable)
    cmake_parse_arguments(ARGS
        "CONSOLE"
        "NAME;OUTPUT_NAME"
        "SOURCES;WIN_SOURCES;UNIX_SOURCES;INCLUDES;DEPENDENCIES;USE_PROG_LIBS"
        ${ARGN}
    )

    if(NOT ARGS_NAME)
        message(FATAL_ERROR "Executable name must be specified")
    endif()

    add_executable(${ARGS_NAME})

    dagor_add_platform_sources(${ARGS_NAME}
        SOURCES ${ARGS_SOURCES}
        WIN_SOURCES ${ARGS_WIN_SOURCES}
        UNIX_SOURCES ${ARGS_UNIX_SOURCES}
    )

    if(ARGS_OUTPUT_NAME)
        set_target_properties(${ARGS_NAME} PROPERTIES
            OUTPUT_NAME ${ARGS_OUTPUT_NAME}
        )
    endif()

    if(ARGS_CONSOLE AND DAGOR_PLATFORM STREQUAL "windows")
        set_target_properties(${ARGS_NAME} PROPERTIES
            WIN32_EXECUTABLE FALSE
        )
    endif()

    if(ARGS_INCLUDES)
        target_include_directories(${ARGS_NAME} PUBLIC ${ARGS_INCLUDES})
    endif()

    if(ARGS_DEPENDENCIES)
        target_link_libraries(${ARGS_NAME} PUBLIC ${ARGS_DEPENDENCIES})
    endif()

    dagor_process_conditional_dependencies(${ARGS_NAME}
        INCLUDES ${ARGS_INCLUDES}
        LIBS ${ARGS_USE_PROG_LIBS}
    )

    dagor_set_common_properties(${ARGS_NAME})
    dagor_set_platform_properties(${ARGS_NAME})
endfunction()

function(dagor_process_dependencies target)
    cmake_parse_arguments(ARGS
        ""
        ""
        "LIBS"
        ${ARGN}
    )

    foreach(lib ${ARGS_LIBS})
        string(REPLACE "/" "_" target_name "${lib}")
        target_link_libraries(${target} PUBLIC ${target_name})
    endforeach()
endfunction()

function(dagor_process_library_paths target)
    foreach(lib_path ${DAGOR_LIBRARY_PATHS})
        target_link_directories(${target} PRIVATE ${lib_path})
    endforeach()
endfunction()

function(dagor_process_conditional_dependencies target)
    cmake_parse_arguments(ARGS
        ""
        ""
        "LIBS;INCLUDES"
        ${ARGN}
    )

    if(ARGS_INCLUDES)
        foreach(inc ${ARGS_INCLUDES})
            if(inc MATCHES "^\\$\\(Root\\)/(.*)")
                set(inc "${CMAKE_SOURCE_DIR}/${CMAKE_MATCH_1}")
            endif()
            target_include_directories(${target} PRIVATE ${inc})
        endforeach()
    endif()

    if(ARGS_LIBS)
        foreach(lib ${ARGS_LIBS})
            if(lib MATCHES "breakpad/binder")
                if(NOT (DAGOR_PLATFORM STREQUAL "windows" AND DAGOR_PLATFORM_ARCH MATCHES "^(x86|x86_64)$"))
                    continue()
                endif()
            endif()

            if(lib MATCHES "^engine/memory")
                if(NOT DAGOR_PLATFORM MATCHES "^(macOS|linux)$" AND
                   NOT DAGOR_SANITIZE STREQUAL "address" AND
                   NOT CMAKE_BUILD_TYPE STREQUAL "Dbg")
                    set(lib "engine/memory/mimallocMem")
                endif()
            endif()

            if(lib MATCHES "messageBox/stub" AND NOT DAGOR_PLATFORM STREQUAL "linux")
                continue()
            endif()

            string(REPLACE "/" "_" target_name "${lib}")
            target_link_libraries(${target} PRIVATE ${target_name})
        endforeach()
    endif()
endfunction()

function(dagor_add_platform_sources target)
    cmake_parse_arguments(ARGS
        ""
        ""
        "SOURCES;WIN_SOURCES;UNIX_SOURCES"
        ${ARGN}
    )

    if(ARGS_SOURCES)
        target_sources(${target} PRIVATE ${ARGS_SOURCES})
    endif()

    if(DAGOR_PLATFORM STREQUAL "windows" AND ARGS_WIN_SOURCES)
        target_sources(${target} PRIVATE ${ARGS_WIN_SOURCES})
    elseif(DAGOR_PLATFORM MATCHES "^(macOS|linux)$" AND ARGS_UNIX_SOURCES)
        target_sources(${target} PRIVATE ${ARGS_UNIX_SOURCES})
    endif()
endfunction()
