#ifndef INCLUDE_CAVEVIEW_H
#define INCLUDE_CAVEVIEW_H

#include "stb.h"

#include "stb_voxel_render.h"

typedef struct
{
   int cx,cy;

   stbvox_mesh_maker mm;

   uint8 *build_buffer;
   uint8 *face_buffer;

   int num_quads;
   float transform[3][3];
   float bounds[2][3];

   uint8 sv_blocktype[34][34][18];
   uint8 sv_lighting [34][34][18];
} raw_mesh;

// a 3D checkerboard of empty,solid would be: 32x32x255x6/2 ~= 800000
// an all-leaf qchunk would be: 32 x 32 x 255 x 6 ~= 1,600,000

#define BUILD_QUAD_MAX     400000
#define BUILD_BUFFER_SIZE  (4*4*BUILD_QUAD_MAX) // 4 bytes per vertex, 4 vertices per quad
#define FACE_BUFFER_SIZE   (  4*BUILD_QUAD_MAX) // 4 bytes per quad


extern void mesh_init(void);
extern void render_init(void);
extern void world_init(void);
extern void ods(char *fmt, ...); // output debug string
extern void reset_cache_size(int size);


extern void render_caves(float pos[3]);


#include "cave_parse.h"  // fast_chunk

extern fast_chunk *get_converted_fastchunk(int chunk_x, int chunk_y);
extern void build_chunk(int chunk_x, int chunk_y, fast_chunk *fc_table[4][4], raw_mesh *rm);
extern void reset_cache_size(int size);
extern void deref_fastchunk(fast_chunk *fc);

#endif