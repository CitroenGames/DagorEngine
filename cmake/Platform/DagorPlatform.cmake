# Platform detection module for Dagor Engine
include_guard(GLOBAL)

# Detect host system
if(WIN32)
    set(DAGOR_PLATFORM "windows")
elseif(APPLE)
    set(DAGOR_PLATFORM "macOS")
elseif(UNIX AND NOT APPLE)
    set(DAGOR_PLATFORM "linux")
else()
    message(FATAL_ERROR "Unsupported platform")
endif()

# Detect architecture
if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64)$")
    set(DAGOR_ARCH "x86_64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(i386|i686)$")
    set(DAGOR_ARCH "x86")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)$")
    set(DAGOR_ARCH "arm64")
else()
    message(FATAL_ERROR "Unsupported architecture: ${CMAKE_SYSTEM_PROCESSOR}")
endif()

# Include platform-specific configuration
include("${CMAKE_CURRENT_LIST_DIR}/${DAGOR_PLATFORM}.cmake")
