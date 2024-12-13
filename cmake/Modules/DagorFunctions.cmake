# Core Dagor Engine CMake functions
include_guard(GLOBAL)

# Function to add an executable with Dagor-specific settings
function(dagor_add_executable)
    cmake_parse_arguments(PARSE_ARGV 0 ARG
        "CONSOLE;NO_PCH"
        "NAME;OUTPUT_NAME;PCH_HEADER"
        "SOURCES;WIN_SOURCES;UNIX_SOURCES;INCLUDES;DEFINES;LIBRARIES;DEPENDENCIES;USE_PROG_LIBS"
    )

    if(NOT ARG_NAME)
        message(FATAL_ERROR "dagor_add_executable: NAME parameter is required")
    endif()

    # Combine platform-specific sources
    set(ALL_SOURCES ${ARG_SOURCES})
    if(DAGOR_PLATFORM STREQUAL "windows" AND ARG_WIN_SOURCES)
        list(APPEND ALL_SOURCES ${ARG_WIN_SOURCES})
    elseif(UNIX AND ARG_UNIX_SOURCES)
        list(APPEND ALL_SOURCES ${ARG_UNIX_SOURCES})
    endif()

    add_executable(${ARG_NAME} ${ALL_SOURCES})

    if(ARG_INCLUDES)
        target_include_directories(${ARG_NAME} PRIVATE ${ARG_INCLUDES})
    endif()

    if(ARG_DEFINES)
        target_compile_definitions(${ARG_NAME} PRIVATE ${ARG_DEFINES})
    endif()

    if(ARG_LIBRARIES)
        target_link_libraries(${ARG_NAME} PRIVATE ${ARG_LIBRARIES})
    endif()

    if(ARG_USE_PROG_LIBS)
        foreach(lib ${ARG_USE_PROG_LIBS})
            target_link_libraries(${ARG_NAME} PRIVATE ${lib})
        endforeach()
    endif()

    if(ARG_DEPENDENCIES)
        add_dependencies(${ARG_NAME} ${ARG_DEPENDENCIES})
    endif()

    if(ARG_OUTPUT_NAME)
        set_target_properties(${ARG_NAME} PROPERTIES OUTPUT_NAME ${ARG_OUTPUT_NAME})
    endif()

    # Platform-specific settings
    if(DAGOR_PLATFORM STREQUAL "windows")
        if(NOT ARG_CONSOLE)
            set_target_properties(${ARG_NAME} PROPERTIES WIN32_EXECUTABLE TRUE)
        endif()
    endif()

    # Set output directories
    set_target_properties(${ARG_NAME} PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/${DAGOR_PLATFORM}/${CMAKE_BUILD_TYPE}"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/${DAGOR_PLATFORM}/${CMAKE_BUILD_TYPE}"
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/${DAGOR_PLATFORM}/${CMAKE_BUILD_TYPE}"
    )
endfunction()

# Function to add a library with Dagor-specific settings
function(dagor_add_library)
    cmake_parse_arguments(PARSE_ARGV 0 ARG
        "STATIC;SHARED;NO_PCH"
        "NAME;OUTPUT_NAME;PCH_HEADER"
        "SOURCES;WIN_SOURCES;UNIX_SOURCES;INCLUDES;DEFINES;LIBRARIES;DEPENDENCIES;USE_PROG_LIBS"
    )

    if(NOT ARG_NAME)
        message(FATAL_ERROR "dagor_add_library: NAME parameter is required")
    endif()

    # Combine platform-specific sources
    set(ALL_SOURCES ${ARG_SOURCES})
    if(DAGOR_PLATFORM STREQUAL "windows" AND ARG_WIN_SOURCES)
        list(APPEND ALL_SOURCES ${ARG_WIN_SOURCES})
    elseif(UNIX AND ARG_UNIX_SOURCES)
        list(APPEND ALL_SOURCES ${ARG_UNIX_SOURCES})
    endif()

    if(ARG_SHARED)
        add_library(${ARG_NAME} SHARED ${ALL_SOURCES})
    else()
        add_library(${ARG_NAME} STATIC ${ALL_SOURCES})
    endif()

    if(ARG_INCLUDES)
        target_include_directories(${ARG_NAME} PRIVATE ${ARG_INCLUDES})
    endif()

    if(ARG_DEFINES)
        target_compile_definitions(${ARG_NAME} PRIVATE ${ARG_DEFINES})
    endif()

    if(ARG_LIBRARIES)
        target_link_libraries(${ARG_NAME} PRIVATE ${ARG_LIBRARIES})
    endif()

    if(ARG_USE_PROG_LIBS)
        foreach(lib ${ARG_USE_PROG_LIBS})
            target_link_libraries(${ARG_NAME} PRIVATE ${lib})
        endforeach()
    endif()

    if(ARG_DEPENDENCIES)
        add_dependencies(${ARG_NAME} ${ARG_DEPENDENCIES})
    endif()

    if(ARG_OUTPUT_NAME)
        set_target_properties(${ARG_NAME} PROPERTIES OUTPUT_NAME ${ARG_OUTPUT_NAME})
    endif()

    # Add C++14 requirement for EASTL
    if(${ARG_NAME} STREQUAL "EASTL")
        target_compile_features(${ARG_NAME} PUBLIC cxx_std_14)
    endif()

    # Set output directories
    set_target_properties(${ARG_NAME} PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/${DAGOR_PLATFORM}/${CMAKE_BUILD_TYPE}"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/${DAGOR_PLATFORM}/${CMAKE_BUILD_TYPE}"
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/${DAGOR_PLATFORM}/${CMAKE_BUILD_TYPE}"
    )
endfunction()
