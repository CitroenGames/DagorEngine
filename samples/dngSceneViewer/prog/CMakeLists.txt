cmake_minimum_required(VERSION 3.20)

# Game configuration
set(GAME_NAME "dng_scene_viewer")
set(TARGET_TYPE "exe")

# Source directories
set(CPP_SRC_FOLDERS
    main
    render
)

set(DAS_SRC_FOLDERS
    scripts/das
    scripts/das/character_controller
    scripts/das/effects
)

# Add sound folder if sound is enabled
if(DAGOR_HAVE_SOUND)
    list(APPEND DAS_SRC_FOLDERS scripts/das/sound)
endif()

# Common dependencies
set(COMMON_LIBS
    daNetGame
    dm_stub
    ecs_delayedAct
)

# Include paths
list(APPEND DAGOR_INCLUDES
    ${CMAKE_SOURCE_DIR}/prog/daNetGameLibs
)

# Platform-specific configuration
if(DAGOR_PLATFORM STREQUAL "windows")
    if(NOT DAGOR_PLATFORM_ARCH MATCHES "^(x86_64|arm64)$")
        message(FATAL_ERROR "${DAGOR_PLATFORM}-${DAGOR_PLATFORM_ARCH} is not supported!")
    endif()

    # VR device support for x86_64
    if(DAGOR_PLATFORM_ARCH STREQUAL "x86_64")
        option(VR_DEVICE_SUPPORT "Enable VR device support" ON)
    endif()

    # Resource configuration
    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/platform/windows/${GAME_NAME}.exe.manifest
        ${CMAKE_CURRENT_BINARY_DIR}/${GAME_NAME}.exe.manifest
        COPYONLY
    )

    # FMOD configuration
    if(DAGOR_HAVE_SOUND AND NOT FMOD_STUDIO STREQUAL "src")
        list(APPEND DAGOR_LINK_LIBRARIES ${FMOD_STATIC_LIBS})
        foreach(dll ${FMOD_STUDIO_SHARED_LIBS})
            configure_file(${dll} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${dll} COPYONLY)
        endforeach()
    endif()

elseif(DAGOR_PLATFORM STREQUAL "linux")
    set(IMPORTS_RELATIVE_DIR ".")

    # FMOD configuration for Linux
    if(DAGOR_HAVE_SOUND AND NOT FMOD_STUDIO STREQUAL "src")
        list(APPEND DAGOR_LINK_LIBRARIES ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${FMOD_STATIC_LIBS})
        foreach(dll ${FMOD_STUDIO_SHARED_LIBS})
            configure_file(${dll} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${dll} COPYONLY)
        endforeach()
    endif()

elseif(DAGOR_PLATFORM STREQUAL "macOS")
    # Bundle configuration
    set(BUNDLE_NAME "DngSceneViewer")
    set(BUNDLE_ID "com.gaijinent.${BUNDLE_NAME}")

    # Bundle resources
    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/platform/macOS/${GAME_NAME}.icns
        ${CMAKE_CURRENT_BINARY_DIR}/../Resources/${BUNDLE_NAME}.icns
        COPYONLY
    )

    # Output directory configuration
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        set(COPY_TO "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${BUNDLE_NAME}")
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/../../rel-build/${BUNDLE_NAME}.app/Contents/MacOS")
    else()
        set(COPY_TO "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/../${BUNDLE_NAME}.app/Contents/MacOS")
    endif()

    # FMOD configuration for macOS
    if(DAGOR_HAVE_SOUND AND NOT FMOD_STUDIO STREQUAL "src")
        list(APPEND DAGOR_LINK_LIBRARIES ${FMOD_STATIC_LIBS})
        list(APPEND DAGOR_SHARED_LIBS ${FMOD_STUDIO_SHARED_LIBS})
        list(APPEND DAGOR_LINK_FLAGS
            "-framework CoreAudio"
            "-framework AudioUnit"
        )
    endif()
else()
    message(FATAL_ERROR "Unsupported platform: ${DAGOR_PLATFORM}")
endif()

# Collect source files
file(GLOB_RECURSE CPP_SOURCES)
foreach(dir ${CPP_SRC_FOLDERS})
    file(GLOB_RECURSE DIR_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/${dir}/*.cpp")
    list(APPEND CPP_SOURCES ${DIR_SOURCES})
endforeach()

if(DAS_AOT_COMPILER)
    foreach(dir ${DAS_SRC_FOLDERS})
        file(GLOB_RECURSE DIR_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/${dir}/*.das")
        list(APPEND DAS_SOURCES ${DIR_SOURCES})
    endforeach()
endif()

# Version information
if(NOT CHECK_ONLY)
    list(APPEND DAGOR_COMPILE_DEFINITIONS
        VERSION_DOT=${VERSION_DOT}
        BUILD_NUMBER=${BUILD_NUMBER}
        VERSION_NUM=${VERSION_NUM}
    )
endif()

# VR support configuration
if(VR_DEVICE_SUPPORT)
    configure_file(
        ${OpenXrSdkPath}/${LEGACY_PLATFORM_SUFFIX}/bin/openxr_loader.dll
        ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/openxr_loader.dll
        COPYONLY
    )
    configure_file(
        ${OpenXrSdkPath}/${LEGACY_PLATFORM_SUFFIX}/bin/openxr_loader.pdb
        ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/openxr_loader.pdb
        COPYONLY
    )
endif()

# Create executable
dagor_add_executable(
    NAME ${GAME_NAME}
    SOURCES ${CPP_SOURCES} ${DAS_SOURCES}
    INCLUDES ${DAGOR_INCLUDES}
    DEPENDENCIES ${COMMON_LIBS}
)

# Set output directory
set_target_properties(${GAME_NAME} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}"
)
