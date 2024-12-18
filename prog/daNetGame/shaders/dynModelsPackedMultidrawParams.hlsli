#ifndef PACKED_MULTIDRAW_PARAMS_INCLUDED
#define PACKED_MULTIDRAW_PARAMS_INCLUDED

#define MATERIAL_OFFSET_BITS 12
#define MATRICES_OFFSET_BITS (32 - MATERIAL_OFFSET_BITS)

#define MATERIAL_OFFSET_MASK ((1 << MATERIAL_OFFSET_BITS) - 1)
#define MATRICES_OFFSET_MASK ((1 << MATRICES_OFFSET_BITS) - 1)

#define MATRICES_OFFSET_SHIFT MATERIAL_OFFSET_BITS

#define MAX_MATERIAL_OFFSET (1 << MATERIAL_OFFSET_BITS)
#define MAX_MATRIX_OFFSET (1 << MATRICES_OFFSET_BITS)

#endif // PACKED_MULTIDRAW_PARAMS_INCLUDED
