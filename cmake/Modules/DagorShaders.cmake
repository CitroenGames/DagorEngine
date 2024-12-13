# Shader compilation module for Dagor Engine
include_guard(GLOBAL)

# Shader predefines list (from jamfile-common)
set(DAGOR_SHADER_PREDEFINES
    predefines_dx11.hlsl
    predefines_dx12.hlsl
    predefines_ps4.hlsl
    predefines_ps5.hlsl
    predefines_ps5pro.diff.hlsl
    predefines_xboxOne.hlsl
    predefines_spirv.hlsl
    predefines_metal.hlsl
    predefines_dx12x.hlsl
    predefines_dx12xs.hlsl
)

# Shader compiler configuration
set(DAGOR_SHADER_COMPILER_OPTIONS
    CPPStd=20
    Exceptions=yes
    MimDebug=0
)

# Shader optimization levels
set(DAGOR_SHADER_OPTIMIZATION_LEVEL "3" CACHE STRING "Shader optimization level (0-3)")
set_property(CACHE DAGOR_SHADER_OPTIMIZATION_LEVEL PROPERTY STRINGS 0 1 2 3)

# Shader debug options
if(DAGOR_SHADER_DEBUG)
    set(DAGOR_SHADER_DEBUG_FLAGS "-g -Zi")
else()
    set(DAGOR_SHADER_DEBUG_FLAGS "")
endif()

# Platform-specific shader configurations
set(DAGOR_SHADER_PLATFORM_CONFIGS
    dx11
    dx12
    dx12x
    dx12xs
    metal
    spirv
)

if(DAGOR_ENABLE_CONSOLE_TARGETS)
    list(APPEND DAGOR_SHADER_PLATFORM_CONFIGS
        ps4
        ps5
        ps5pro
        xboxOne
    )
endif()

# Function to stringify shader files (equivalent to StringifySourceFile rule)
function(dagor_stringify_shader_file source_file output_file dependent_file)
    set(full_source_path "${CMAKE_CURRENT_SOURCE_DIR}/${source_file}")
    set(full_output_path "${CMAKE_CURRENT_BINARY_DIR}/${output_file}")

    add_custom_command(
        OUTPUT "${full_output_path}"
        COMMAND ${CMAKE_COMMAND}
            -DINPUT_FILE="${full_source_path}"
            -DOUTPUT_FILE="${full_output_path}"
            -P "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/StringifyFile.cmake"
        DEPENDS "${full_source_path}"
        COMMENT "Stringifying ${source_file}"
    )

    # Add dependency if specified
    if(dependent_file)
        set_source_files_properties(
            ${dependent_file}
            PROPERTIES OBJECT_DEPENDS "${full_output_path}"
        )
    endif()
endfunction()

# Function to compile shaders
function(dagor_compile_shaders)
    cmake_parse_arguments(PARSE_ARGV 0
        ARGS
        ""
        "TARGET;OUTPUT;SHADER_TYPE"
        "SOURCES;INCLUDES"
    )

    # Validate shader type
    if(NOT ARGS_SHADER_TYPE)
        message(FATAL_ERROR "Shader type must be specified")
    endif()

    # Set compiler executable based on shader type
    set(compiler_name "dsc2-${ARGS_SHADER_TYPE}-dev")

    # Common compiler flags
    set(common_flags -shaderOn -q)

    # Set optimization level
    list(APPEND common_flags "-O${DAGOR_SHADER_OPTIMIZATION_LEVEL}")

    # Add debug flags if enabled
    if(DAGOR_SHADER_DEBUG)
        list(APPEND common_flags ${DAGOR_SHADER_DEBUG_FLAGS})
    endif()

    # Platform-specific compiler flags
    if(ARGS_SHADER_TYPE STREQUAL "hlsl11")
        list(APPEND common_flags "-t s_5_0" "-DDIRECTX11=1")
    elseif(ARGS_SHADER_TYPE STREQUAL "hlsl12")
        list(APPEND common_flags "-t s_6_0" "-DDIRECTX12=1")
    elseif(ARGS_SHADER_TYPE STREQUAL "metal")
        list(APPEND common_flags "-DMETAL=1")
    elseif(ARGS_SHADER_TYPE STREQUAL "spirv")
        list(APPEND common_flags "-DVULKAN=1")
    endif()

    # Create custom target for shader compilation
    add_custom_command(
        OUTPUT "${ARGS_OUTPUT}"
        COMMAND ${compiler_name}
        ARGS ${ARGS_OUTPUT} ${common_flags}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        DEPENDS ${ARGS_SOURCES}
        COMMENT "Compiling ${ARGS_SHADER_TYPE} shaders"
    )

    # Create target if specified
    if(ARGS_TARGET)
        add_custom_target(${ARGS_TARGET}
            DEPENDS "${ARGS_OUTPUT}"
        )
    endif()
endfunction()

# Helper function to add shader variants
function(dagor_add_shader_variants)
    cmake_parse_arguments(PARSE_ARGV 0
        ARGS
        ""
        "TARGET"
        "SOURCES;INCLUDES"
    )

    # DirectX variants
    if(DAGOR_PLATFORM STREQUAL "windows")
        foreach(dx_version IN ITEMS dx11 dx12 dx12x dx12xs)
            if(dx_version IN_LIST DAGOR_SHADER_PLATFORM_CONFIGS)
                dagor_compile_shaders(
                    TARGET ${ARGS_TARGET}_${dx_version}
                    OUTPUT "shaders_${dx_version}.blk"
                    SHADER_TYPE "hlsl${dx_version}"
                    SOURCES ${ARGS_SOURCES}
                    INCLUDES ${ARGS_INCLUDES}
                )
            endif()
        endforeach()
    endif()

    # Metal variant
    if(DAGOR_PLATFORM STREQUAL "macOS" AND "metal" IN_LIST DAGOR_SHADER_PLATFORM_CONFIGS)
        dagor_compile_shaders(
            TARGET ${ARGS_TARGET}_metal
            OUTPUT "shaders_metal.blk"
            SHADER_TYPE "metal"
            SOURCES ${ARGS_SOURCES}
            INCLUDES ${ARGS_INCLUDES}
        )
    endif()

    # SPIRV variant
    if(DAGOR_PLATFORM STREQUAL "linux" AND "spirv" IN_LIST DAGOR_SHADER_PLATFORM_CONFIGS)
        dagor_compile_shaders(
            TARGET ${ARGS_TARGET}_spirv
            OUTPUT "shaders_spirv.blk"
            SHADER_TYPE "spirv"
            SOURCES ${ARGS_SOURCES}
            INCLUDES ${ARGS_INCLUDES}
        )
    endif()

    # Console variants
    if(DAGOR_ENABLE_CONSOLE_TARGETS)
        foreach(console IN ITEMS ps4 ps5 ps5pro xboxOne)
            if(console IN_LIST DAGOR_SHADER_PLATFORM_CONFIGS)
                dagor_compile_shaders(
                    TARGET ${ARGS_TARGET}_${console}
                    OUTPUT "shaders_${console}.blk"
                    SHADER_TYPE ${console}
                    SOURCES ${ARGS_SOURCES}
                    INCLUDES ${ARGS_INCLUDES}
                )
            endif()
        endforeach()
    endif()
endfunction()
