cmake_minimum_required(VERSION 3.20)

set(SKIES_SAMPLE_SOURCES
    test_app.cpp
    test_main.cpp
)

# Platform-specific sources
if(DAGOR_PLATFORM STREQUAL "macOS")
    list(APPEND SKIES_SAMPLE_SOURCES macosx_main.mm)
elseif(DAGOR_PLATFORM MATCHES "^(iOS|tvOS)$")
    list(APPEND SKIES_SAMPLE_SOURCES ios_main.mm)
endif()

# Common dependencies for all platforms
set(SKIES_SAMPLE_LIBS
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
    gameRes
    perfMon
    commonFramework
    webui
    daSkies2
    render
    visualConsole
    fftWater
    heightmap
    consoleProc
    render_daBfg
    folders
)

# Platform-specific dependencies
if(DAGOR_PLATFORM STREQUAL "windows")
    list(APPEND SKIES_SAMPLE_LIBS
        hid_mouse
        hid_keyboard
        hid_nulldrv
        drv3d_pc_multi
    )
    list(APPEND DAGOR_LINK_LIBRARIES Ws2_32)
elseif(DAGOR_PLATFORM STREQUAL "linux")
    list(APPEND SKIES_SAMPLE_LIBS
        drv3d_pc_multi
        hid_mouse
        hid_keyboard
        hid_nulldrv
        messageBox
    )
elseif(DAGOR_PLATFORM STREQUAL "macOS")
    list(APPEND SKIES_SAMPLE_LIBS
        hid_mouse
        hid_keyboard
        hid_nulldrv
    )
elseif(DAGOR_PLATFORM STREQUAL "ps4")
    list(APPEND SKIES_SAMPLE_LIBS
        hid_sony
        drv3d_ps4
        hid_nulldrv
    )
elseif(DAGOR_PLATFORM STREQUAL "ps5")
    list(APPEND SKIES_SAMPLE_LIBS
        hid_sony
        hid_nulldrv
        drv3d_ps5
    )
elseif(DAGOR_PLATFORM MATCHES "^(xboxOne|scarlett)$")
    list(APPEND SKIES_SAMPLE_LIBS
        drv3d_DX12
        hid_gamepad_xinput
        hid_keyboard
        hid_nulldrv
    )

    # Xbox title configuration
    set(XBOX_TITLE_NAME "SkiesSample")
    set(XBOX_TITLE_PUBLISHER "CN=Anton Yudintsev, OU=Gaijin Distribution Kft, O=Gaijin Entertainment Holdings, L=Budapest, S=Budapest, C=HU")
    set(XBOX_TITLE_DISPLAY_NAME "SkiesSample")
    set(XBOX_TITLE_PUBLISHER_DISPLAY_NAME "Gaijin Distribution Kft")
    set(XBOX_TITLE_DESC "Test bed for skies")

    # Set output directory for Xbox platforms
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../game/../${DAGOR_PLATFORM}.loose")
elseif(DAGOR_PLATFORM MATCHES "^(iOS|tvOS)$")
    list(APPEND SKIES_SAMPLE_LIBS
        hid_${DAGOR_PLATFORM}
        hid_nulldrv
        appstorekit
        appstorekit_stub
        drv3d_Metal
    )
elseif(DAGOR_PLATFORM STREQUAL "android")
    list(APPEND SKIES_SAMPLE_LIBS
        drv3d_vulkan
        hid_android
        hid_nulldrv
        statsd
    )
elseif(DAGOR_PLATFORM STREQUAL "nswitch")
    list(APPEND SKIES_SAMPLE_LIBS
        drv3d_vulkan
        hid_nswitch
        hid_nulldrv
        jsonUtils
        nswitch_kit
        nswitch_assets
        nswitch_account
        nswitch_journalizedMount
        nswitch_mounts
        nswitch_tempdata
        messageBox
    )

    # Additional includes for Switch
    list(APPEND SKIES_SAMPLE_INCLUDES
        ${CMAKE_SOURCE_DIR}/prog/3rdPartyLibs/math
    )

    # Nintendo Switch specific libraries
    if(EXISTS "${_OASIS_LIBS_DIR}")
        list(APPEND DAGOR_LINK_LIBRARIES
            ${_OASIS_LIBS_DIR}/libnn_init_memory.a
            ${_OASIS_LIBS_DIR}/libnn_gfx.a
            ${_OASIS_LIBS_DIR}/libnn_mii_draw.a
        )
    endif()

    # Switch bundle configuration
    set(NMETA_HOME_MENU_IMAGE_PREFIX "nintendosdk")
    set(NMETA_VERSION "1.0.0")
    set(BUNDLE_NAME "skiesSample")
    set(NMETA_GAME_NAME "skiesSample")

    # Resource files for Switch
    set(SWITCH_RESOURCE_FILES
        settings.blk
        ui/cursor.blk
        ui/fonts.blk
        ui/all.dynFont.blk
        ui/avanteNrBook_eu.ttf
        ui/button00.tga
        ui/button01.tga
        ui/button02.tga
        ui/checkbox00.tga
        ui/checkbox01.tga
        ui/checkbox02.tga
        ui/checkbox04.tga
        ui/checkbox06.tga
        ui/cursor_normal.tga
        ui/slider00.tga
        ui/sliderBack.tga
        heightmap.raw
        scripts/cursors.nut
        scripts/library.nut
        scripts/script.nut
        scripts/style.nut
        scripts/components/accordion.nut
        scripts/components/boolButton.nut
        scripts/components/checkbox.nut
        scripts/components/combobox.nut
        scripts/components/label.nut
        scripts/components/panel.nut
        scripts/components/panel_if.nut
        scripts/components/slider.nut
        compiledShaders/gameSpirV.ps40.shdump.bin
        res/fx.dxp.bin
        res/tree.dxp.bin
        res/water.dxp.bin
        res/tree.grp
        res/grp_hdr.vromfs.bin
    )

    # Copy Switch resources
    foreach(res ${SWITCH_RESOURCE_FILES})
        configure_file(
            "${CMAKE_CURRENT_SOURCE_DIR}/../game/${res}"
            "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${res}"
            COPYONLY
        )
    endforeach()
endif()

# Add executable target
dagor_add_executable(
    NAME skiesSample
    SOURCES ${SKIES_SAMPLE_SOURCES}
    INCLUDES
        ${CMAKE_SOURCE_DIR}/prog/samples/commonFramework
        ${CMAKE_SOURCE_DIR}/prog/gameLibs/publicInclude
    DEPENDENCIES ${SKIES_SAMPLE_LIBS}
)

# Set output directory
set_target_properties(skiesSample PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../game"
)

# Platform-specific bundle configuration
if(DAGOR_PLATFORM MATCHES "^(iOS|tvOS)$")
    set(BUNDLE_NAME "SkiesSample")
    set(BUNDLE_TITLE "Skies sample")

    # Resource files to copy
    set(RESOURCE_FILES
        settings.blk
        ui/cursor.blk
        ui/fonts.blk
        ui/all.dynFont.blk
        ui/avanteNrBook_eu.ttf
        ui/button00.tga
        ui/button01.tga
        ui/button02.tga
        ui/checkbox00.tga
        ui/checkbox01.tga
        ui/checkbox02.tga
        ui/checkbox04.tga
        ui/checkbox06.tga
        ui/cursor_normal.tga
        ui/slider00.tga
        ui/sliderBack.tga
        heightmap.raw
        scripts/cursors.nut
        scripts/library.nut
        scripts/script.nut
        scripts/style.nut
        scripts/components/accordion.nut
        scripts/components/boolButton.nut
        scripts/components/checkbox.nut
        scripts/components/combobox.nut
        scripts/components/label.nut
        scripts/components/panel.nut
        scripts/components/panel_if.nut
        scripts/components/slider.nut
    )

    # Copy resources to bundle
    foreach(res ${RESOURCE_FILES})
        configure_file(
            "${CMAKE_CURRENT_SOURCE_DIR}/../game/${res}"
            "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/game/${res}"
            COPYONLY
        )
    endforeach()

    # Copy platform-specific resources
    configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/../game/compiledShaders/iOS/gameMTL.ps50.shdump.bin"
        "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/game/compiledShaders/gameMTL.ps50.shdump.bin"
        COPYONLY
    )
endif()

# Release configuration
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    set(FORCE_LOGS "yes")
endif()
