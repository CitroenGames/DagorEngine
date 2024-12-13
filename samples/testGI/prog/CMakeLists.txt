cmake_minimum_required(VERSION 3.20)

# Platform architecture configuration
if(NOT DEFINED DAGOR_PLATFORM_ARCH AND DAGOR_PLATFORM STREQUAL "windows")
    set(DAGOR_PLATFORM_ARCH "x86_64")
endif()

if(NOT DEFINED DAGOR_PLATFORM_SPEC AND DAGOR_PLATFORM STREQUAL "windows")
    set(DAGOR_PLATFORM_SPEC "clang")
endif()

# Target configuration
set(TARGET_NAME "testGI-${LEGACY_PLATFORM_SUFFIX}")
set(TARGET_TYPE "exe")

# BVH Support configuration
if((DAGOR_PLATFORM STREQUAL "windows" AND DAGOR_PLATFORM_ARCH STREQUAL "x86_64") OR
   (DAGOR_PLATFORM STREQUAL "linux" AND DAGOR_PLATFORM_ARCH STREQUAL "x86_64") OR
    DAGOR_PLATFORM STREQUAL "ps5")
    set(BVH_SUPPORT ON)
    set(BVH_RI OFF)
    set(BVH_RANDOM_GRASS OFF)
    set(BVH_GPU_OBJECTS OFF)
    set(BVH_DYN_REND OFF)
    set(BVH_FX OFF)
    set(BVH_CABLES OFF)
endif()

# Output directory configuration
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../game")

# Include directories
list(APPEND DAGOR_INCLUDES
    ${CMAKE_SOURCE_DIR}/prog/samples/commonFramework
    ${CMAKE_SOURCE_DIR}/prog/gameLibs/publicInclude
)

# Source files
set(SOURCES
    test_app.cpp
    test_main.cpp
)

# Common libraries
set(COMMON_LIBS
    osApiWrappers
    kernel
    memory
    ioSys
    startup
    baseUtil
    coreUtil
    math
    lib3d
    image
    shaders
    workCycle
    guiBase
    scene
    sceneRay
    gameRes
    perfMon
    streaming
    commonFramework
    lruCollision
    webui
    daSkies2
    render
    visualConsole
    fftWater
    heightmap
    consoleProc
    daEditorE
    daGI2
    voxelizationTarget
    daGI
    bvh
    rtsm
    denoiser
    upscale
    profileEventsGUI
)

# Platform-specific configuration
if(DAGOR_PLATFORM STREQUAL "windows")
    list(APPEND COMMON_LIBS
        hid_mouse
        hid_keyboard
        hid_nulldrv
        drv3d_pc_multi
    )

    list(APPEND DAGOR_LINK_LIBRARIES Ws2_32.lib)

    # Include DX12 bundle copy configuration
    include(${CMAKE_SOURCE_DIR}/prog/engine/drv/drv3d_DX12/copy_bundles.cmake)

elseif(DAGOR_PLATFORM STREQUAL "linux")
    set(BUNDLE_NAME "SkiesSample")
    list(APPEND COMMON_LIBS
        drv3d_pc_multi
        hid_mouse
        hid_keyboard
        hid_nulldrv
        messageBox
    )

elseif(DAGOR_PLATFORM STREQUAL "macOS")
    set(BUNDLE_NAME "testGI")
    list(APPEND SOURCES macosx_main.mm)
    list(APPEND COMMON_LIBS
        hid_mouse
        hid_keyboard
        hid_nulldrv
    )

    include(${CMAKE_SOURCE_DIR}/prog/samples/macOS-testApp-res/macOS-common.cmake)

elseif(DAGOR_PLATFORM STREQUAL "ps4")
    list(APPEND COMMON_LIBS
        hid_sony
        drv3d_ps4
    )

elseif(DAGOR_PLATFORM STREQUAL "ps5")
    list(APPEND COMMON_LIBS
        hid_sony
        drv3d_ps5
    )

elseif(DAGOR_PLATFORM MATCHES "^(xboxOne|scarlett)$")
    list(APPEND COMMON_LIBS
        drv3d_DX12
        hid_gamepad_xinput
        hid_keyboard
        hid_nulldrv
    )

    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/../game/${DAGOR_PLATFORM}.loose")

    # Xbox title configuration
    set(XBOX_TITLE_NAME "testGI")
    set(XBOX_TITLE_PUBLISHER "CN=Anton Yudintsev, OU=Gaijin Distribution Kft, O=Gaijin Entertainment Holdings, L=Budapest, S=Budapest, C=HU")
    set(XBOX_TITLE_DISPLAY_NAME "testGI")
    set(XBOX_TITLE_PUBLISHER_DISPLAY_NAME "Gaijin Distribution Kft")
    set(XBOX_TITLE_DESC "Test bed for GI")

elseif(DAGOR_PLATFORM STREQUAL "android")
    list(APPEND COMMON_LIBS
        drv3d_vulkan
        hid_android
        hid_nulldrv
        statsd
        folders
    )

    # Android configuration
    set(ANDROID_APP_ID "com.gaijinent.testApp.testGI")
    set(ANDROID_ICON "${CMAKE_SOURCE_DIR}/prog/samples/Android-testApp-res/icon.png")
    set(ANDROID_APP_ICON_NAME "Test Gl")
    set(ANDROID_COPY_TO_DEVICE "default")

else()
    message(FATAL_ERROR "Unsupported platform: ${DAGOR_PLATFORM}")
endif()

# Memory debug configuration
if(DAGOR_PLATFORM STREQUAL "windows" AND
   NOT CMAKE_BUILD_TYPE STREQUAL "Release" AND
   NOT SANITIZE STREQUAL "address")
    set(USE_MEMORY_DEBUG_LEVEL "dbg")
endif()

# Create executable
dagor_add_executable(
    NAME ${TARGET_NAME}
    SOURCES ${SOURCES}
    INCLUDES ${DAGOR_INCLUDES}
    DEPENDENCIES ${COMMON_LIBS}
)

# Set output directory
set_target_properties(${TARGET_NAME} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}"
)
