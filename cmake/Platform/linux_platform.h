#pragma once

// Platform-specific intrinsics and vector types
#include <x86intrin.h>
#include <immintrin.h>
#include <xmmintrin.h>
#include <emmintrin.h>

// Standard includes needed for type definitions
#include <stddef.h>
#include <stdint.h>
#include <string.h>

// Platform identification
#define _LINUX 1
#define _POSIX 1
#define LINUX 1
#define __linux__ 1
#define __LINUX__ 64
#define POSIX 1

// Target configuration
#define _TARGET_PC 3
#define _TARGET_PC_LINUX 3
#define _TARGET_64BIT 1

// Compiler attributes
#ifdef __clang__
    #define __forceinline __attribute__((always_inline)) inline
#else
    #define __forceinline inline __attribute__((always_inline))
#endif

#define __cdecl
#define __stdcall
#define __fastcall
#define __vectorcall

// Vector types
#ifdef __clang__
    typedef __m128 __vec4f __attribute__((aligned(16)));
    typedef __m128i __vec4i __attribute__((aligned(16)));
#else
    typedef __m128 __vec4f;
    typedef __m128i __vec4i;
#endif

// Function remapping
#define _snprintf snprintf
#define _vsnprintf vsnprintf
#define stricmp strcasecmp
#define strnicmp strncasecmp
#define i_strlen (int)strlen

// Memory management
#define memfree_anywhere free
#define _aligned_malloc(size, alignment) aligned_alloc(alignment, size)
#define _aligned_free free

// Driver code configuration
#define DRIVERCODE_UNSUPPORTED_DEFAULT_CONSTRUCTIBLE 1

// Additional platform-specific macros
#define DAG_FORCE_INLINE __forceinline
#define DAG_ALIGN(x) __attribute__((aligned(x)))
#define DAG_PACKED __attribute__((packed))
#define DAG_RESTRICT __restrict__
