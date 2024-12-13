cmake_minimum_required(VERSION 3.20)
project(ShaderCompiler2 LANGUAGES CXX)

# Include Dagor dependencies and platform configuration
include(DagorFunctions)
include(DagorDependencies)
include(DagorPlatform)

# Add global includes
include_directories(${DAGOR_GLOBAL_INCLUDES})

# Check for parser generators and source files
set(PARSER_GEN_DIR "${CMAKE_SOURCE_DIR}/prog/3rdPartyLibs/legacy_parser")
set(DOLPHIN_EXE "${PARSER_GEN_DIR}/dolphin${CMAKE_EXECUTABLE_SUFFIX}")
set(WHALE_EXE "${PARSER_GEN_DIR}/whale${CMAKE_EXECUTABLE_SUFFIX}")

# Check if we need to build parser generators
if(NOT EXISTS "${DOLPHIN_EXE}" OR NOT EXISTS "${WHALE_EXE}")
    message(STATUS "Parser generators not found. Building from source...")
    # Add parser generator build commands here if source is available
    # For now, we'll use pre-generated files if they exist
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/shlex.cpp" AND
       EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/shlex.h" AND
       EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/shsyn.cpp" AND
       EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/shsyn.h" AND
       EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/shsyntok.h")
        message(STATUS "Using pre-generated parser files")
        set(USING_PREGENERATED_FILES TRUE)
    else()
        message(FATAL_ERROR "Parser generators not found and pre-generated files missing. Please provide parser generators in ${PARSER_GEN_DIR} or pre-generated files.")
    endif()
endif()

if(NOT USING_PREGENERATED_FILES)
    # Custom commands for parser generation
    add_custom_command(
        OUTPUT
            "${CMAKE_CURRENT_SOURCE_DIR}/shlex.cpp"
            "${CMAKE_CURRENT_SOURCE_DIR}/shlex.h"
        COMMAND ${DOLPHIN_EXE} "${CMAKE_CURRENT_SOURCE_DIR}/shlex.dlp"
        DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/shlex.dlp"
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )

    add_custom_command(
        OUTPUT
            "${CMAKE_CURRENT_SOURCE_DIR}/shsyn.cpp"
            "${CMAKE_CURRENT_SOURCE_DIR}/shsyn.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/shsyntok.h"
        COMMAND ${WHALE_EXE} "${CMAKE_CURRENT_SOURCE_DIR}/shsyn.whl"
        DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/shsyn.whl"
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )

    # Add generated files to a custom target
    add_custom_target(parser_gen
        DEPENDS
            "${CMAKE_CURRENT_SOURCE_DIR}/shlex.cpp"
            "${CMAKE_CURRENT_SOURCE_DIR}/shlex.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/shsyn.cpp"
            "${CMAKE_CURRENT_SOURCE_DIR}/shsyn.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/shsyntok.h"
    )
endif()

# Compiler flags
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    add_compile_options(-Wno-comment -Wno-int-to-pointer-cast -Wno-writable-strings)
endif()

# Main executable
dagor_add_executable(
    NAME ShaderCompiler2
    CONSOLE TRUE
    SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/shaderVariantSrc.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/winmain_con.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/main.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/globVarSem.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shSemCode.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/assemblyShader.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/variablesMerger.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/gatherVar.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/semChecker.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/semUtils.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shExpr.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shExprParser.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shlex.cpp  # Generated
        ${CMAKE_CURRENT_SOURCE_DIR}/shlexterm.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shLocVar.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shMacro.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shsem.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shsyn.cpp  # Generated
        ${CMAKE_CURRENT_SOURCE_DIR}/sh_stat.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shCompiler.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/debugSpitfile.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/globalConfig.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shCode.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/cppStcode.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/cppStcodeAssembly.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/globvar.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/intervals.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/samplers.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/boolVar.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shaderVariant.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/varMap.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shLog.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shUtils.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shFunc.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shVerMgr.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/loadShaders.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/binDumpUtils.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/makeShBinDump.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/transcodeShader.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/namedConst.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/codeBlocks.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/condParser.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/ver_obj_spirv.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/ver_obj_dxc.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/linkShaders.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shadervarGenerator.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/parser/bparser.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/gitRunner.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/processes.cpp
    WIN_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/processes_win.cpp
    UNIX_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/processes_unix.cpp
    INCLUDES
        ${CMAKE_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/prog
        ${CMAKE_SOURCE_DIR}/prog/1stPartyLibs
        ${CMAKE_SOURCE_DIR}/prog/1stPartyLibs/dag
        ${CMAKE_SOURCE_DIR}/prog/3rdPartyLibs
        ${CMAKE_SOURCE_DIR}/prog/3rdPartyLibs/vulkan/include
        ${CMAKE_SOURCE_DIR}/prog/dagorInclude
        ${CMAKE_SOURCE_DIR}/prog/engine
        ${CMAKE_SOURCE_DIR}/prog/engine/sharedInclude
        ${CMAKE_SOURCE_DIR}/prog/engine/startup
        ${CMAKE_SOURCE_DIR}/prog/engine/generic
        ${CMAKE_SOURCE_DIR}/prog/engine/drv/3d
        ${CMAKE_SOURCE_DIR}/prog/tools/ShaderCompiler2
        ${CMAKE_SOURCE_DIR}/prog/tools/sharedInclude
    USE_PROG_LIBS
        3rdPartyLibs/eastl
        engine/osApiWrappers
        engine/kernel
        engine/ioSys
        engine/startup
        engine/baseUtil
        engine/math
        engine/perfMon/daProfilerStub
        engine/perfMon/perfTimerStub
        engine/startup
        3rdPartyLibs/hash/BLAKE3
        tools/libTools/util
        engine/generic
        tools/ShaderCompiler2/hlsl2spirv
        3rdPartyLibs/regExp
)

# Add compiler definitions from jamfile-hlsl2spirv
target_compile_definitions(ShaderCompiler2 PRIVATE
    _CROSS_TARGET_SPIRV=1
    BINDUMP_TARGET_BE=0
    _CRT_SECURE_NO_DEPRECATE
    _HAS_EXCEPTIONS=0
    _SECURE_SCL=0
    EXCLUDE_PSTDINT
)

# Platform-specific compiler options
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    target_compile_options(ShaderCompiler2 PRIVATE -Wno-switch -Wno-sometimes-uninitialized)
endif()

# Platform-specific libraries
if(DAGOR_PLATFORM STREQUAL "windows" AND DAGOR_ARCH IN_LIST "x86;x86_64")
    target_link_libraries(ShaderCompiler2 PRIVATE gameLibs/breakpad/binder)
endif()

if(NOT DAGOR_PLATFORM IN_LIST "macOS;linux" AND NOT DAGOR_SANITIZE STREQUAL "address" AND NOT CMAKE_BUILD_TYPE STREQUAL "Dbg")
    target_link_libraries(ShaderCompiler2 PRIVATE engine/memory/mimallocMem)
endif()

if(DAGOR_PLATFORM STREQUAL "linux")
    target_link_libraries(ShaderCompiler2 PRIVATE engine/osApiWrappers/messageBox/stub)
endif()

# Add dependency on parser generation only if we're generating files
if(NOT USING_PREGENERATED_FILES)
    add_dependencies(ShaderCompiler2 parser_gen)
endif()
