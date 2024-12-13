# Test shader compilation
set(TEST_SHADER_DIR ${CMAKE_CURRENT_SOURCE_DIR})

# Add shader compilation target
dagor_add_shader_variants(
    TARGET test_shader
    SOURCES
        ${TEST_SHADER_DIR}/test.hlsl
    INCLUDES
        ${CMAKE_SOURCE_DIR}/prog/tools/ShaderCompiler2/include
)

# Add test to build
add_custom_target(shader_test ALL
    DEPENDS
        test_shader_dx11
        test_shader_dx12
        test_shader_spirv
)

if(DAGOR_PLATFORM STREQUAL "macOS")
    add_dependencies(shader_test test_shader_metal)
endif()
