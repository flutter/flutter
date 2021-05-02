#ifndef INCLUDE_CAVE_PARSE_H
#define INCLUDE_CAVE_PARSE_H

typedef struct
{
   unsigned char block;
   unsigned char data;
   unsigned char light:4;
   unsigned char skylight:4;
} raw_block;

// this is the old fully-decoded chunk
typedef struct
{
   int xpos, zpos, max_y;
   int height[16][16];
   raw_block rb[16][16][256]; // [z][x][y] which becomes [y][x][z] in stb
} chunk;

chunk *get_decoded_chunk(int chunk_x, int chunk_z);

#define NUM_SEGMENTS  16
typedef struct
{
   int max_y, xpos, zpos;

   unsigned char *blockdata[NUM_SEGMENTS];
   unsigned char *data[NUM_SEGMENTS];
   unsigned char *skylight[NUM_SEGMENTS];
   unsigned char *light[NUM_SEGMENTS];
   
   void *pointer_to_free;   

   int refcount; // this allows multi-threaded building without wrapping in ANOTHER struct
} fast_chunk;

fast_chunk *get_decoded_fastchunk(int chunk_x, int chunk_z); // cache, never call free()

fast_chunk *get_decoded_fastchunk_uncached(int chunk_x, int chunk_z);

#endif
