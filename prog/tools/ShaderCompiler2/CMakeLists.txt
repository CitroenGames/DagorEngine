# ShaderCompiler2 CMake configuration

# Set target properties
set(TARGET_NAME ShaderCompiler2)
set(CONSOLE_APP ON)

# Source files (from jamfile-common)
set(SOURCES
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
)

# Platform-specific sources
if(DAGOR_PLATFORM STREQUAL "windows")
    list(APPEND SOURCES processes_win.cpp)
else()
    list(APPEND SOURCES processes_unix.cpp)
endif()

# Include directories
set(INCLUDE_DIRS
    ${CMAKE_SOURCE_DIR}/prog/tools/ShaderCompiler2
    ${CMAKE_SOURCE_DIR}/prog/tools/sharedInclude
    ${CMAKE_SOURCE_DIR}/prog/engine/sharedInclude
)

if(NOT DAGOR_PLATFORM MATCHES "^(macOS|linux)$")
    list(APPEND INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/prog/gameLibs/publicInclude/breakpad)
endif()

# Create executable
add_executable(${TARGET_NAME} ${SOURCES})
target_include_directories(${TARGET_NAME} PRIVATE ${INCLUDE_DIRS})

# Process shader predefines
foreach(predefine ${DAGOR_SHADER_PREDEFINES})
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${predefine}")
        dagor_stringify_shader_file(
            ${predefine}
            "${predefine}.inl"
            "namedConst.cpp"
        )
    endif()
endforeach()

# Compiler options
if(DAGOR_PLATFORM_SPEC STREQUAL "clang")
    target_compile_options(${TARGET_NAME} PRIVATE
        -Wno-comment
        -Wno-int-to-pointer-cast
        -Wno-writable-strings
    )
endif()

if(DAGOR_PLATFORM_SPEC STREQUAL "gcc")
    set_source_files_properties(
        shlex.cpp
        PROPERTIES COMPILE_FLAGS "-Wno-write-strings"
    )
endif()

# DirectX specific settings for Windows
if(DAGOR_PLATFORM STREQUAL "windows")
    target_compile_definitions(${TARGET_NAME} PRIVATE
        _CROSS_TARGET_DX11=1
        BINDUMP_TARGET_BE=0
    )
    target_link_libraries(${TARGET_NAME} PRIVATE D3dcompiler)
endif()

# Link libraries
target_link_libraries(${TARGET_NAME} PRIVATE
    eastl
    osApiWrappers
    kernel
    ioSys
    startup
    baseUtil
    math
    daProfilerStub
    perfTimerStub
    BLAKE3
    libTools
)

if(DAGOR_PLATFORM STREQUAL "windows" AND DAGOR_ARCH MATCHES "^(x86|x86_64)$")
    target_link_libraries(${TARGET_NAME} PRIVATE breakpad_binder)
endif()

if(NOT DAGOR_PLATFORM MATCHES "^(macOS|linux)$" AND NOT DAGOR_SANITIZE STREQUAL "address" AND NOT CMAKE_BUILD_TYPE STREQUAL "Dbg")
    target_link_libraries(${TARGET_NAME} PRIVATE mimallocMem)
else()
    target_link_libraries(${TARGET_NAME} PRIVATE memory)
endif()

if(DAGOR_PLATFORM STREQUAL "linux")
    target_link_libraries(${TARGET_NAME} PRIVATE messageBox_stub)
endif()

# Add test directory
add_subdirectory(test)
