cmake_minimum_required(VERSION 3.20)

# Source files
set(BASEUTIL_SOURCES
    fastStrMap.cpp
    tabMem.cpp
    tabSorted.cpp
    strImpl.cpp
    dobject.cpp
    fatalCtx.cpp
    bitArray.cpp
    syncExecScheduler.cpp
    hierBitMem.cpp
    restart.cpp
    texMetaData.cpp
    unicodeHlp.cpp
    safeArg.cpp
    threadPool.cpp
    parallelFor.cpp
    watchdog.cpp
    delayedActions.cpp
    treeBitmap.cpp
    lag.cpp
    fnameMap.cpp
    fileMd5Validate.cpp
)

# Add baseUtil library
dagor_add_library(NAME baseUtil
    SOURCES ${BASEUTIL_SOURCES}
    INCLUDES
        ${CMAKE_SOURCE_DIR}/prog/engine/sharedInclude
)

# Add compiler definitions
target_compile_definitions(baseUtil PRIVATE __B_KERNEL_LIB)
