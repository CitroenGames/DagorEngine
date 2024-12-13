# Import from GitHub EASTL's scripts/CMake/CommonCppFlags.cmake
# Provides common compiler flag checking and warning flag configuration

include(CheckCXXCompilerFlag)

# Function to safely check and add compiler flags
function(dagor_add_cxx_compiler_flag FLAG)
    string(REGEX REPLACE "[^A-Za-z0-9]" "_" FLAG_VAR "${FLAG}")
    check_cxx_compiler_flag("${FLAG}" HAVE_FLAG_${FLAG_VAR})
    if(HAVE_FLAG_${FLAG_VAR})
        add_compile_options(${FLAG})
    endif()
endfunction()

# Add common warning flags based on compiler
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang|AppleClang")
    dagor_add_cxx_compiler_flag(-Wall)
    dagor_add_cxx_compiler_flag(-Wextra)
    dagor_add_cxx_compiler_flag(-Wno-unused-parameter)
    dagor_add_cxx_compiler_flag(-Wno-unused-variable)
    dagor_add_cxx_compiler_flag(-Wno-unused-function)
elseif(MSVC)
    dagor_add_cxx_compiler_flag(/W4)
    dagor_add_cxx_compiler_flag(/wd4100) # Unused parameter
    dagor_add_cxx_compiler_flag(/wd4505) # Unused function
endif()

# Function to set common C++ standard requirements
function(dagor_set_cpp_standard TARGET)
    if(CMAKE_VERSION VERSION_LESS 3.8)
        target_compile_features(${TARGET} PUBLIC cxx_range_for)
    else()
        target_compile_features(${TARGET} PUBLIC cxx_std_14)
    endif()
endfunction()
