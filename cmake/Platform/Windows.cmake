# Windows platform-specific configuration
include_guard(GLOBAL)

# Compiler settings
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    # Common compiler flags (from clang-sets.jam)
    add_compile_options(
        -fms-compatibility
        -fms-extensions
        -fdiagnostics-absolute-paths
        -Xclang
        -mrecip=none
        -Wno-c++11-narrowing
        -Wno-trigraphs
        -Wno-argument-outside-range
        -Wno-nonportable-include-path
        -Wno-ignored-attributes
        -Wno-invalid-offsetof
        -Wno-multichar
        -Wno-unused-function
        -Wno-inconsistent-missing-override
        -Wno-invalid-token-paste
        -Wno-ignored-pragma-intrinsic
        -Wno-pragma-pack
        -Wno-microsoft
        -Wno-int-to-void-pointer-cast
        -Wno-expansion-to-defined
        -Wno-deprecated-declarations
        -Wno-constant-conversion
        -Wno-unused-local-typedef
        -Wno-ignored-pragmas
        -Wno-switch
        -Werror=invalid-noreturn
        -Werror=return-type
    )

    # Definitions
    add_compile_definitions(
        _TARGET_PC=1
        _TARGET_PC_WIN=1
        asm=__asm
        WIN32_LEAN_AND_MEAN
        NOMINMAX
        _USE_MATH_DEFINES
        _ALLOW_KEYWORD_MACROS
        _USING_V110_SDK71_
        i_strlen=(int)strlen
        DELAYIMP_INSECURE_WRITABLE_HOOKS
    )

    # Architecture-specific settings
    if(DAGOR_ARCH STREQUAL "x86")
        add_compile_definitions(
            WIN32
            __IA32__=1
            _TARGET_CPU_IA32=1
        )
        add_compile_options(-m32)
    elseif(DAGOR_ARCH STREQUAL "x86_64")
        add_compile_definitions(
            WIN64
            _TARGET_64BIT=1
            _TARGET_SIMD_SSE=${DAGOR_SSE_VERSION}
        )
        if(DAGOR_SSE_VERSION EQUAL 4)
            add_compile_options(-msse4.1 -mpopcnt)
        else()
            add_compile_options(-msse2)
        endif()
    elseif(DAGOR_ARCH STREQUAL "arm64")
        add_compile_options(--target=aarch64-pc-windows-msvc)
        add_compile_definitions(
            WIN64
            _TARGET_64BIT=1
            _TARGET_SIMD_NEON
        )
    endif()

    # Sanitizer support
    if(NOT DAGOR_SANITIZE STREQUAL "disabled")
        add_compile_options(-fsanitize=${DAGOR_SANITIZE})
        if(DAGOR_ARCH STREQUAL "x86")
            add_compile_options(-mllvm -asan-use-private-alias=1)
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

    # Include paths configuration
    set(DAGOR_WINDOWS_INCLUDE_PATHS
        "${DAGOR_CLANG_DIR}/lib/clang/${DAGOR_CLANG_LIB_FOLDER}/include"
        "${CMAKE_SOURCE_DIR}/prog/dagorInclude"
        "${CMAKE_SOURCE_DIR}/prog/1stPartyLibs"
        "${CMAKE_SOURCE_DIR}/prog/3rdPartyLibs"
        "${CMAKE_SOURCE_DIR}/prog/3rdPartyLibs/eastl/include"
    )

    # Library paths configuration
    set(DAGOR_WINDOWS_LIB_PATHS
        "${DAGOR_CLANG_DIR}/lib/clang/${DAGOR_CLANG_LIB_FOLDER}/lib/windows"
        "${DAGOR_VC_DIR}/lib/${DAGOR_WIN_SDK_TARGET_SUFFIX}"
        "${DAGOR_WIN_SDK_LIB}"
        "${DAGOR_UCRT_LIB}"
        "${DAGOR_UM_LIB}"
    )

    # Add MSVC-style includes
    foreach(inc ${DAGOR_WINDOWS_INCLUDE_PATHS})
        add_compile_options(-imsvc ${inc})
    endforeach()

    # Add library paths to linker
    foreach(lib ${DAGOR_WINDOWS_LIB_PATHS})
        string(APPEND CMAKE_EXE_LINKER_FLAGS " -libpath:${lib}")
        string(APPEND CMAKE_SHARED_LINKER_FLAGS " -libpath:${lib}")
        string(APPEND CMAKE_STATIC_LINKER_FLAGS " -libpath:${lib}")
    endforeach()

    # LLD linker configuration
    if(DAGOR_USE_LLD_LINK)
        set(CMAKE_LINKER "${DAGOR_CLANG_DIR}/bin/lld-link.exe")
        set(CMAKE_AR "${DAGOR_CLANG_DIR}/bin/lld-link.exe")
        set(CMAKE_NM "${DAGOR_CLANG_DIR}/bin/lld-link.exe")
        set(CMAKE_RANLIB "${DAGOR_CLANG_DIR}/bin/lld-link.exe")
    endif()

    # Resource compiler configuration
    set(CMAKE_RC_COMPILER "${DAGOR_WIN_SDK_BIN}/rc.exe")
    set(CMAKE_RC_FLAGS "/x /nologo")

    # Architecture-specific tools
    if(DAGOR_ARCH STREQUAL "x86")
        set(CMAKE_ASM_NASM_COMPILER "${DAGOR_DEVTOOL}/nasm/nasm.exe")
        set(CMAKE_ASM_NASM_FLAGS "-f win32")
        set(CMAKE_ASM_MASM_COMPILER "${DAGOR_VC_DIR}/bin/Hostx64/x86/ml.exe")
        set(CMAKE_ASM_MASM_FLAGS "-c -nologo")
    elseif(DAGOR_ARCH STREQUAL "x86_64")
        set(CMAKE_ASM_NASM_COMPILER "${DAGOR_DEVTOOL}/nasm/nasm.exe")
        set(CMAKE_ASM_NASM_FLAGS "-f win64")
        set(CMAKE_ASM_MASM_COMPILER "${DAGOR_VC_DIR}/bin/Hostx64/x64/ml64.exe")
        set(CMAKE_ASM_MASM_FLAGS "-c -nologo")
    elseif(DAGOR_ARCH STREQUAL "arm64")
        set(CMAKE_ASM_NASM_COMPILER "${DAGOR_DEVTOOL}/nasm/nasm.exe")
        set(CMAKE_ASM_NASM_FLAGS "-f arm64")
        set(CMAKE_ASM_MASM_COMPILER "${DAGOR_VC_DIR}/bin/Hostx64/arm64/ml64.exe")
        set(CMAKE_ASM_MASM_FLAGS "-c -nologo")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --target=aarch64-pc-windows-msvc")
    endif()
endif()
