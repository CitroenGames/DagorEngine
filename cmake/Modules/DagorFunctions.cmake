# Core Dagor Engine CMake functions
include_guard(GLOBAL)

# Function to add an executable with Dagor-specific settings
function(dagor_add_executable target)
    cmake_parse_arguments(PARSE_ARGV 1 ARG
        "CONSOLE;NO_PCH"
        "OUTPUT_NAME;PCH_HEADER"
        "SOURCES;INCLUDES;DEFINES;LIBRARIES;DEPENDENCIES"
    )

    add_executable(${target} ${ARG_SOURCES})

    if(ARG_INCLUDES)
        target_include_directories(${target} PRIVATE ${ARG_INCLUDES})
    endif()

    if(ARG_DEFINES)
        target_compile_definitions(${target} PRIVATE ${ARG_DEFINES})
    endif()

    if(ARG_LIBRARIES)
        target_link_libraries(${target} PRIVATE ${ARG_LIBRARIES})
    endif()

    if(ARG_DEPENDENCIES)
        add_dependencies(${target} ${ARG_DEPENDENCIES})
    endif()

    if(ARG_OUTPUT_NAME)
        set_target_properties(${target} PROPERTIES OUTPUT_NAME ${ARG_OUTPUT_NAME})
    endif()

    # Platform-specific settings
    if(DAGOR_PLATFORM STREQUAL "windows")
        if(NOT ARG_CONSOLE)
            set_target_properties(${target} PROPERTIES WIN32_EXECUTABLE TRUE)
        endif()
    endif()

    # Set output directories
    set_target_properties(${target} PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/${DAGOR_PLATFORM}/${CMAKE_BUILD_TYPE}"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/${DAGOR_PLATFORM}/${CMAKE_BUILD_TYPE}"
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/${DAGOR_PLATFORM}/${CMAKE_BUILD_TYPE}"
    )
endfunction()

# Function to add a library with Dagor-specific settings
function(dagor_add_library target)
    cmake_parse_arguments(PARSE_ARGV 1 ARG
        "STATIC;SHARED;NO_PCH"
        "OUTPUT_NAME;PCH_HEADER"
        "SOURCES;INCLUDES;DEFINES;LIBRARIES;DEPENDENCIES"
    )

    if(ARG_SHARED)
        add_library(${target} SHARED ${ARG_SOURCES})
    else()
        add_library(${target} STATIC ${ARG_SOURCES})
    endif()

    if(ARG_INCLUDES)
        target_include_directories(${target} PRIVATE ${ARG_INCLUDES})
    endif()

    if(ARG_DEFINES)
        target_compile_definitions(${target} PRIVATE ${ARG_DEFINES})
    endif()

    if(ARG_LIBRARIES)
        target_link_libraries(${target} PRIVATE ${ARG_LIBRARIES})
    endif()

    if(ARG_DEPENDENCIES)
        add_dependencies(${target} ${ARG_DEPENDENCIES})
    endif()

    if(ARG_OUTPUT_NAME)
        set_target_properties(${target} PROPERTIES OUTPUT_NAME ${ARG_OUTPUT_NAME})
    endif()

    # Set output directories
    set_target_properties(${target} PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/${DAGOR_PLATFORM}/${CMAKE_BUILD_TYPE}"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/${DAGOR_PLATFORM}/${CMAKE_BUILD_TYPE}"
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/${DAGOR_PLATFORM}/${CMAKE_BUILD_TYPE}"
    )
endfunction()
