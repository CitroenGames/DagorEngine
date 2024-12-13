cmake_minimum_required(VERSION 3.20)

# Common source files
set(KERNEL_SOURCES
    fatalerr.cpp
    kernelGlobalSetting.cpp
    globalVars/occlusion_map.cpp
    globalVars/hdrMode.cpp
    cdebug.c
    debugDumpStack.cpp
    logimpl.cpp
    writeStream.cpp
    cpuControl.cpp
    perfTimer.cpp
)

# Platform-specific source files
if(DAGOR_PLATFORM STREQUAL "windows")
    list(APPEND KERNEL_SOURCES
        cpuFreq.cpp
        dagorHwExcept.cpp
        debug.cpp
        dagorMinidumpCallback.cpp
    )
elseif(DAGOR_PLATFORM MATCHES "xboxOne|scarlett")
    list(APPEND KERNEL_SOURCES
        cpuFreq.cpp
        dagorHwExcept.cpp
    )
elseif(DAGOR_PLATFORM MATCHES "ps4|ps5")
    list(APPEND KERNEL_SOURCES
        sony/cpuFreq.cpp
        sony/dagorHwExcept.cpp
    )
elseif(DAGOR_PLATFORM STREQUAL "macOS")
    list(APPEND KERNEL_SOURCES
        debug.cpp
        macosx/macCpuFreq.cpp
        macosx/macGlobVars.cpp
        dagorHwExcept.cpp
    )
elseif(DAGOR_PLATFORM STREQUAL "iOS")
    list(APPEND KERNEL_SOURCES
        macosx/macCpuFreq.cpp
        macosx/macGlobVars.cpp
        dagorHwExcept.cpp
    )
elseif(DAGOR_PLATFORM STREQUAL "tvOS")
    list(APPEND KERNEL_SOURCES
        macosx/macCpuFreq.cpp
        dagorHwExcept.cpp
    )
elseif(DAGOR_PLATFORM STREQUAL "linux")
    list(APPEND KERNEL_SOURCES
        debug.cpp
        linux/linuxCpuFreq.cpp
        dagorHwExcept.cpp
    )
elseif(DAGOR_PLATFORM STREQUAL "android")
    list(APPEND KERNEL_SOURCES
        linux/linuxCpuFreq.cpp
        dagorHwExcept.cpp
        and_native_app.c
        and_debug.cpp
        and_native_activity.cpp
    )
elseif(DAGOR_PLATFORM STREQUAL "nswitch")
    list(APPEND KERNEL_SOURCES
        nswitch/nswitchCpuFreq.cpp
        nswitch/oasisDagorHwExcept.cpp
    )
endif()

# Add kernel library
dagor_add_library(NAME kernel
    SOURCES ${KERNEL_SOURCES}
    INCLUDES
        ${CMAKE_SOURCE_DIR}/prog/engine/sharedInclude
)

# Add compiler definitions
target_compile_definitions(kernel PRIVATE
    __B_KERNEL_LIB
    __B_NO_MEM_BASE_INCLUDE
)

# Handle sanitizer configuration
if(DAGOR_SANITIZE AND DAGOR_PLATFORM MATCHES "linux|macOS")
    target_compile_definitions(kernel PRIVATE DAGOR_CAPTURE_STDERR=1)
endif()

# Android-specific configuration
if(DAGOR_PLATFORM STREQUAL "android")
    if(ANDROID_USE_SIGNAL_HANDLER AND NOT ANDROID_UPLOAD_CRASHLYTICS_SYMBOLS)
        target_compile_definitions(kernel PRIVATE ANDROID_ENABLE_SIGNAL_LOG=1)
        set_target_properties(kernel PROPERTIES OUTPUT_NAME "kernel~and-sighandler")
    endif()
    target_include_directories(kernel PRIVATE ${ANDROID_NDK}/sources/android/cpufeatures)
endif()

# Breakpad configuration
if(DAGOR_BREAKPAD_ENABLED)
    target_compile_definitions(kernel PRIVATE __BREAKPAD_ENABLED)
    target_link_libraries(kernel PRIVATE breakpad)
    target_include_directories(kernel PRIVATE ${CMAKE_SOURCE_DIR}/prog/3rdPartyLibs/breakpad)
endif()

# Force logs in release configuration
if(CMAKE_BUILD_TYPE STREQUAL "Release" AND DAGOR_FORCE_LOGS)
    target_sources(kernel PRIVATE def_logCryptKey.cpp)
endif()
