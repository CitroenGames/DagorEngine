# Generated from Jam files
cmake_minimum_required(VERSION 3.20)
project(ShaderCompiler2 LANGUAGES CXX)

# Include Dagor dependencies
include(DagorDependencies)

# Compiler flags
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    add_compile_options(-Wno-comment -Wno-int-to-pointer-cast -Wno-writable-strings )
endif()

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
        ${CMAKE_CURRENT_SOURCE_DIR}/shlex.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shlexterm.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shLocVar.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shMacro.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shsem.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/shsyn.cpp
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
        ${CMAKE_SOURCE_DIR}/prog/tools/ShaderCompiler2
        ${CMAKE_SOURCE_DIR}/prog/tools/sharedInclude
        ${CMAKE_SOURCE_DIR}/prog/engine/sharedInclude
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
        $<$<BOOL:${DAGOR_PLATFORM} STREQUAL "windows" AND ${DAGOR_ARCH} IN_LIST "x86;x86_64">:gameLibs/breakpad/binder>
        $<$<BOOL:NOT ${DAGOR_PLATFORM} IN_LIST "macOS;linux" AND NOT ${DAGOR_SANITIZE} STREQUAL "address" AND NOT ${CMAKE_BUILD_TYPE} STREQUAL "Dbg">:engine/memory/mimallocMem>
        $<$<BOOL:${DAGOR_PLATFORM} STREQUAL "linux">:engine/osApiWrappers/messageBox/stub>
)
