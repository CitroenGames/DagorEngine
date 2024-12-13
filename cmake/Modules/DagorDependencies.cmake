set(EABASE_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/third_party/EABase/include/Common")
set(EASTL_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/third_party/EASTL/include")
set(EASTL_LIBRARY_DIR "${CMAKE_SOURCE_DIR}/third_party/EASTL/build")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/third_party/EASTL/cmake")
include_directories(${EABASE_INCLUDE_DIR})
include_directories(${EASTL_INCLUDE_DIR})
link_directories(${EASTL_LIBRARY_DIR})

if(NOT TARGET EASTL)
    add_subdirectory(${CMAKE_SOURCE_DIR}/third_party/EASTL EXCLUDE_FROM_ALL)
endif()
