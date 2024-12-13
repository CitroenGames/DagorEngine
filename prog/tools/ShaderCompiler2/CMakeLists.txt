# Generated from Jam files
cmake_minimum_required(VERSION 3.20)

# Compiler flags
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    add_compile_options(-Wno-comment -Wno-int-to-pointer-cast -Wno-writable-strings )
endif()

dagor_add_executable(
    NAME ShaderCompiler2
    CONSOLE TRUE
    SOURCES
        shaderVariantSrc.cpp
        winmain_con.cpp
        main.cpp
        globVarSem.cpp
        shSemCode.cpp
        assemblyShader.cpp
        variablesMerger.cpp
        gatherVar.cpp
        semChecker.cpp
        semUtils.cpp
        shExpr.cpp
        shExprParser.cpp
        shlex.cpp
        shlexterm.cpp
        shLocVar.cpp
        shMacro.cpp
        shsem.cpp
        shsyn.cpp
        sh_stat.cpp
        shCompiler.cpp
        debugSpitfile.cpp
        globalConfig.cpp
        shCode.cpp
        cppStcode.cpp
        cppStcodeAssembly.cpp
        globvar.cpp
        intervals.cpp
        samplers.cpp
        boolVar.cpp
        shaderVariant.cpp
        varMap.cpp
        shLog.cpp
        shUtils.cpp
        shFunc.cpp
        shVerMgr.cpp
        loadShaders.cpp
        binDumpUtils.cpp
        makeShBinDump.cpp
        transcodeShader.cpp
        namedConst.cpp
        codeBlocks.cpp
        condParser.cpp
        ver_obj_spirv.cpp
        ver_obj_dxc.cpp
        linkShaders.cpp
        shadervarGenerator.cpp
        parser/bparser.cpp
        gitRunner.cpp
        processes.cpp
    WIN_SOURCES
        processes_win.cpp
    UNIX_SOURCES
        processes_unix.cpp
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
        $<$<BOOL:${DAGOR_PLATFORM}  STREQUAL  windows && $(PlatformArch) in x86 x86_64>:gameLibs/breakpad/binder>
        $<$<BOOL:( ! ${DAGOR_PLATFORM} in macOS linux ) && $(Sanitize) ! STREQUAL  address && $(Config) ! STREQUAL  dbg>:engine/memory/mimallocMem>
        $<$<BOOL:${DAGOR_PLATFORM} in linux>:engine/osApiWrappers/messageBox/stub>
)