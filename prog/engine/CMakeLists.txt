# Engine libraries CMake configuration
cmake_minimum_required(VERSION 3.20)

# Include Dagor platform and dependencies
include(DagorPlatform)
include(DagorDependencies)

# Add subdirectories for engine components
add_subdirectory(kernel)
add_subdirectory(baseUtil)
