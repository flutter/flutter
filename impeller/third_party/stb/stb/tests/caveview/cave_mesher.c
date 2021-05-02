// This file takes minecraft chunks (decoded by cave_parse) and
// uses stb_voxel_render to turn them into vertex buffers.

#define STB_GLEXT_DECLARE "glext_list.h"
#include "stb_gl.h"
#include "stb_image.h"
#include "stb_glprog.h"

#include "caveview.h"
#include "cave_parse.h"
#include "stb.h"
#include "sdl.h"
#include "sdl_thread.h"
#include <math.h>

//#define VHEIGHT_TEST
//#define STBVOX_OPTIMIZED_VHEIGHT

#define STBVOX_CONFIG_MODE  1
#define STBVOX_CONFIG_OPENGL_MODELVIEW
#define STBVOX_CONFIG_PREFER_TEXBUFFER
//#define STBVOX_CONFIG_LIGHTING_SIMPLE
#define STBVOX_CONFIG_FOG_SMOOTHSTEP
//#define STBVOX_CONFIG_PREMULTIPLIED_ALPHA  // this doesn't work properly alpha test without next #define
//#define STBVOX_CONFIG_UNPREMULTIPLY  // slower, fixes alpha test makes windows & fancy leaves look better
//#define STBVOX_CONFIG_TEX1_EDGE_CLAMP
#define STBVOX_CONFIG_DISABLE_TEX2
//#define STBVOX_CONFIG_DOWN_TEXLERP_PACKED
#define STBVOX_CONFIG_ROTATION_IN_LIGHTING

#define STB_VOXEL_RENDER_IMPLEMENTATION
#include "stb_voxel_render.h"

extern void ods(char *fmt, ...);

//#define FANCY_LEAVES  // nearly 2x the triangles when enabled (if underground is filled)
#define FAST_CHUNK
#define IN_PLACE

#define SKIP_TERRAIN   48 // use to avoid building underground stuff
                          // allows you to see what perf would be like if underground was efficiently culled,
                          // or if you were making a game without underground

enum
{
   C_empty,
   C_solid,
   C_trans,
   C_cross,
   C_water,
   C_slab,
   C_stair,
   C_force,
};

unsigned char geom_map[] =
{
   STBVOX_GEOM_empty,
   STBVOX_GEOM_solid,
   STBVOX_GEOM_transp,
   STBVOX_GEOM_crossed_pair,
   STBVOX_GEOM_solid,
   STBVOX_GEOM_slab_lower,
   STBVOX_GEOM_floor_slope_north_is_top,
   STBVOX_GEOM_force,
};

unsigned char minecraft_info[256][7] =
{
   { C_empty, 0,0,0,0,0,0 },
   { C_solid, 1,1,1,1,1,1 },
   { C_solid, 3,3,3,3,40,2 },
   { C_solid, 2,2,2,2,2,2 },
   { C_solid, 16,16,16,16,16,16 },
   { C_solid, 4,4,4,4,4,4 },
   { C_cross, 15,15,15,15 },
   { C_solid, 17,17,17,17,17,17 },

   // 8
   { C_water, 223,223,223,223,223,223 },
   { C_water, 223,223,223,223,223,223 },
   { C_solid, 255,255,255,255,255,255 },
   { C_solid, 255,255,255,255,255,255 },
   { C_solid, 18,18,18,18,18,18 },
   { C_solid, 19,19,19,19,19,19 },
   { C_solid, 32,32,32,32,32,32 },
   { C_solid, 33,33,33,33,33,33 },

   // 16
   { C_solid, 34,34,34,34,34,34 },
   { C_solid, 20,20,20,20,21,21 },
#ifdef FANCY_LEAVES
   { C_force, 52,52,52,52,52,52 }, // leaves
#else
   { C_solid, 53,53,53,53,53,53 }, // leaves
#endif
   { C_solid, 24,24,24,24,24,24 },
   { C_trans, 49,49,49,49,49,49 }, // glass
   { C_solid, 160,160,160,160,160,160 },
   { C_solid, 144,144,144,144,144,144 },
   { C_solid, 46,45,45,45,62,62 },

   // 24
   { C_solid, 192,192,192,192, 176,176 },
   { C_solid, 74,74,74,74,74,74 },
   { C_empty }, // bed
   { C_empty }, // powered rail
   { C_empty }, // detector rail
   { C_solid, 106,108,109,108,108,108 },
   { C_empty }, // cobweb=11
   { C_cross, 39,39,39,39 },

   // 32
   { C_cross, 55,55,55,55,0,0 },
   { C_solid, 107,108,109,108,108,108 },
   { C_empty }, // piston head
   { C_solid, 64,64,64,64,64,64 }, // various colors
   { C_empty }, // unused
   { C_cross, 13,13,13,13,0,0 },
   { C_cross, 12,12,12,12,0,0 },
   { C_cross, 29,29,29,29,0,0 },

   // 40
   { C_cross, 28,28,28,28,0,0 },
   { C_solid, 23,23,23,23,23,23 },
   { C_solid, 22,22,22,22,22,22 },
   { C_solid, 5,5,5,5,6,6, },
   { C_slab , 5,5,5,5,6,6, },
   { C_solid, 7,7,7,7,7,7, },
   { C_solid, 8,8,8,8,9,10 },
   { C_solid, 35,35,35,35,4,4, },

   // 48
   { C_solid, 36,36,36,36,36,36 },
   { C_solid, 37,37,37,37,37,37 },
   { C_cross, 80,80,80,80,80,80 }, // torch
   { C_empty }, // fire
   { C_trans, 65,65,65,65,65,65 },
   { C_stair, 4,4,4,4,4,4 },
   { C_solid, 26,26,26,27,25,25 },
   { C_empty }, // redstone

   // 56
   { C_solid, 50,50,50,50,50,50 },
   { C_solid, 26,26,26,26,26,26 },
   { C_solid, 60,59,59,59,43,43 },
   { C_cross, 95,95,95,95 },
   { C_solid, 2,2,2,2,86,2 },
   { C_solid, 44,45,45,45,62,62 },
   { C_solid, 61,45,45,45,62,62 },
   { C_empty }, // sign

   // 64
   { C_empty }, // door
   { C_empty }, // ladder
   { C_empty }, // rail
   { C_stair, 16,16,16,16,16,16 }, // cobblestone stairs
   { C_empty }, // sign
   { C_empty }, // lever
   { C_empty }, // stone pressure plate
   { C_empty }, // iron door

   // 72
   { C_empty }, // wooden pressure
   { C_solid, 51,51,51,51,51,51 },
   { C_solid, 51,51,51,51,51,51 },
   { C_empty },
   { C_empty },
   { C_empty },
   { C_empty }, // snow on block below, do as half slab?
   { C_solid, 67,67,67,67,67,67 },

   // 80
   { C_solid, 66,66,66,66,66,66 },
   { C_solid, 70,70,70,70,69,71 },
   { C_solid, 72,72,72,72,72,72 },
   { C_cross, 73,73,73,73,73,73 },
   { C_solid, 74,74,74,74,75,74 },
   { C_empty }, // fence
   { C_solid,119,118,118,118,102,102 },
   { C_solid,103,103,103,103,103,103 },

   // 88
   { C_solid, 104,104,104,104,104,104 },
   { C_solid, 105,105,105,105,105,105 },
   { C_solid, 167,167,167,167,167,167 },
   { C_solid, 120,118,118,118,102,102 },
   { C_empty }, // cake
   { C_empty }, // repeater
   { C_empty }, // repeater
   { C_solid, 49,49,49,49,49,49 }, // colored glass

   // 96
   { C_empty },
   { C_empty },
   { C_solid, 54,54,54,54,54,54 },
   { C_solid, 125,125,125,125,125,125 },
   { C_solid, 126,126,126,126,126,126 },
   { C_empty }, // bars
   { C_trans, 49,49,49,49,49,49 }, // glass pane
   { C_solid, 136,136,136,136,137,137 }, // melon

   // 104
   { C_empty }, // pumpkin stem
   { C_empty }, // melon stem
   { C_empty }, // vines
   { C_empty }, // gate
   { C_stair, 7,7,7,7,7,7, }, // brick stairs
   { C_stair, 54,54,54,54,54,54 }, // stone brick stairs
   { C_empty }, // mycelium
   { C_empty }, // lily pad

   // 112
   { C_solid, 224,224,224,224,224,224 },
   { C_empty }, // nether brick fence
   { C_stair, 224,224,224,224,224,224 }, // nether brick stairs
   { C_empty }, // nether wart
   { C_solid, 182,182,182,182,166,183 },
   { C_empty }, // brewing stand
   { C_empty }, // cauldron
   { C_empty }, // end portal

   // 120
   { C_solid, 159,159,159,159,158,158 },
   { C_solid, 175,175,175,175,175,175 },
   { C_empty }, // dragon egg
   { C_solid, 211,211,211,211,211,211 },
   { C_solid, 212,212,212,212,212,212 },
   { C_solid, 4,4,4,4,4,4, }, // wood double-slab
   { C_slab , 4,4,4,4,4,4, }, // wood slab
   { C_empty }, // cocoa

   // 128
   { C_solid, 192,192,192,192,176,176 }, // sandstone stairs
   { C_solid, 32,32,32,32,32,32 }, // emerald ore
   { C_solid, 26,26,26,27,25,25 }, // ender chest
   { C_empty },
   { C_empty },
   { C_solid, 23,23,23,23,23,23 }, // emerald block
   { C_solid, 198,198,198,198,198,198 }, // spruce stairs
   { C_solid, 214,214,214,214,214,214 }, // birch stairs

   // 136
   { C_stair, 199,199,199,199,199,199 }, // jungle stairs
   { C_empty }, // command block
   { C_empty }, // beacon
   { C_slab, 16,16,16,16,16,16 }, // cobblestone wall
   { C_empty }, // flower pot
   { C_empty }, // carrot
   { C_empty }, // potatoes
   { C_empty }, // wooden button

   // 144
   { C_empty }, // mob head
   { C_empty }, // anvil
   { C_solid, 26,26,26,27,25,25 }, // trapped chest
   { C_empty }, // weighted pressure plate light
   { C_empty }, // weighted pressure plat eheavy
   { C_empty }, // comparator inactive
   { C_empty }, // comparator active
   { C_empty }, // daylight sensor

   // 152
   { C_solid, 135,135,135,135,135,135 }, // redstone block
   { C_solid, 0,0,0,0,0,0, }, // nether quartz ore
   { C_empty }, // hopper
   { C_solid, 22,22,22,22,22,22 }, // quartz block
   { C_stair, 22,22,22,22,22,22 }, // quartz stairs
   { C_empty }, // activator rail
   { C_solid, 46,45,45,45,62,62 }, // dropper
   { C_solid, 72,72,72,72,72,72 }, // stained clay

   // 160
   { C_trans, 49,49,49,49,49,49 }, // stained glass pane
   #ifdef FANCY_LEAVES
   { C_force, 52,52,52,52,52,52 }, // leaves
   #else
   { C_solid, 53,53,53,53,53,53 }, // acacia leaves
   #endif
   { C_solid, 20,20,20,20,21,21 }, // acacia tree
   { C_solid, 199,199,199,199,199,199 }, // acacia wood stairs
   { C_solid, 198,198,198,198,198,198 }, // dark oak stairs
   { C_solid, 146,146,146,146,146,146 }, // slime block

   { C_solid, 176,176,176,176,176,176 }, // red sandstone
   { C_solid, 176,176,176,176,176,176 }, // red sandstone

   // 168
   { C_empty },
   { C_empty },
   { C_empty },
   { C_empty },
   { C_solid, 72,72,72,72,72,72 }, // hardened clay
   { C_empty },
   { C_empty },
   { C_empty },

   // 176
   { C_empty },
   { C_empty },
   { C_solid, 176,176,176,176,176,176 }, // red sandstone
};

unsigned char minecraft_tex1_for_blocktype[256][6];
unsigned char effective_blocktype[256];
unsigned char minecraft_color_for_blocktype[256][6];
unsigned char minecraft_geom_for_blocktype[256];

uint8 build_buffer[BUILD_BUFFER_SIZE];
uint8 face_buffer[FACE_BUFFER_SIZE];

//GLuint vbuf, fbuf, fbuf_tex;

//unsigned char tex1_for_blocktype[256][6];

//unsigned char blocktype[34][34][257];
//unsigned char lighting[34][34][257];

// a superchunk is 64x64x256, with the border blocks computed as well,
// which means we need 4x4 chunks plus 16 border chunks plus 4 corner chunks

#define SUPERCHUNK_X   4
#define SUPERCHUNK_Y   4

unsigned char remap_data[16][16];
unsigned char remap[256];
unsigned char rotate_data[4] = { 1,3,2,0 };

void convert_fastchunk_inplace(fast_chunk *fc)
{
   int i;
   int num_blocks=0, step=0;
   unsigned char rot[4096];
   #ifndef IN_PLACE
   unsigned char *storage;
   #endif

   memset(rot, 0, 4096);

   for (i=0; i < 16; ++i)
      num_blocks += fc->blockdata[i] != NULL;

   #ifndef IN_PLACE
   storage = malloc(16*16*16*2 * num_blocks);
   #endif

   for (i=0; i < 16; ++i) {
      if (fc->blockdata[i]) {
         int o=0;
         unsigned char *bd,*dd,*lt,*sky;
         unsigned char *out, *outb;

         // this ordering allows us to determine which data we can safely overwrite for in-place processing
         bd = fc->blockdata[i];
         dd = fc->data[i];
         lt = fc->light[i];
         sky = fc->skylight[i];

         #ifdef IN_PLACE
         out = bd;
         #else
         out = storage + 16*16*16*2*step;
         #endif

         // bd is written in place, but also reads from dd
         for (o=0; o < 16*16*16/2; o += 1) {
            unsigned char v1,v2;
            unsigned char d = dd[o];
            v1 = bd[o*2+0];
            v2 = bd[o*2+1];

            if (remap[v1])
            {
               //unsigned char d = bd[o] & 15;
               v1 = remap_data[remap[v1]][d&15];
               rot[o*2+0] = rotate_data[d&3];
            } else
               v1 = effective_blocktype[v1];

            if (remap[v2])
            {
               //unsigned char d = bd[o] >> 4;
               v2 = remap_data[remap[v2]][d>>4];
               rot[o*2+1] = rotate_data[(d>>4)&3];
            } else
               v2 = effective_blocktype[v2];

            out[o*2+0] = v1;
            out[o*2+1] = v2;
         }

         // this reads from lt & sky
         #ifndef IN_PLACE
         outb = out + 16*16*16;
         ++step;
         #endif

         // MC used to write in this order and it makes it possible to compute in-place
         if (dd < sky && sky < lt) {
            // @TODO go this path always if !IN_PLACE
            #ifdef IN_PLACE
            outb = dd;
            #endif

            for (o=0; o < 16*16*16/2; ++o) {
               int bright;
               bright = (lt[o]&15)*12 + 15 + (sky[o]&15)*16;
               if (bright > 255) bright = 255;
               if (bright <  32) bright =  32;
               outb[o*2+0] = STBVOX_MAKE_LIGHTING_EXT((unsigned char) bright, (rot[o*2+0]&3));

               bright = (lt[o]>>4)*12 + 15 + (sky[o]>>4)*16;
               if (bright > 255) bright = 255;
               if (bright <  32) bright =  32;
               outb[o*2+1] = STBVOX_MAKE_LIGHTING_EXT((unsigned char) bright, (rot[o*2+1]&3));
            }
         } else {
            // @TODO: if blocktype is in between others, this breaks; need to find which side has two pointers, and use that
            // overwrite rot[] array, then copy out
            #ifdef IN_PLACE
            outb = (dd < sky) ? dd : sky;
            if (lt < outb) lt = outb;
            #endif

            for (o=0; o < 16*16*16/2; ++o) {
               int bright;
               bright = (lt[o]&15)*12 + 15 + (sky[o]&15)*16;
               if (bright > 255) bright = 255;
               if (bright <  32) bright =  32;
               rot[o*2+0] = STBVOX_MAKE_LIGHTING_EXT((unsigned char) bright, (rot[o*2+0]&3));

               bright = (lt[o]>>4)*12 + 15 + (sky[o]>>4)*16;
               if (bright > 255) bright = 255;
               if (bright <  32) bright =  32;
               rot[o*2+1] = STBVOX_MAKE_LIGHTING_EXT((unsigned char) bright, (rot[o*2+1]&3));
            }

            memcpy(outb, rot, 4096);
            fc->data[i] = outb;
         }

         #ifndef IN_PLACE
         fc->blockdata[i] = out;
         fc->data[i] = outb;
         #endif
      }
   }

   #ifndef IN_PLACE
   free(fc->pointer_to_free);
   fc->pointer_to_free = storage;
   #endif
}

void make_converted_fastchunk(fast_chunk *fc, int x, int y, int segment, uint8 *sv_blocktype, uint8 *sv_lighting)
{
   int z;
   assert(fc == NULL || (fc->refcount > 0 && fc->refcount < 64));
   if (fc == NULL || fc->blockdata[segment] == NULL) {
      for (z=0; z < 16; ++z) {
         sv_blocktype[z] = C_empty;
         sv_lighting[z] = 255;
      }
   } else {
      unsigned char *block = fc->blockdata[segment];
      unsigned char *data  = fc->data[segment];
      y = 15-y;
      for (z=0; z < 16; ++z) {
         sv_blocktype[z] = block[z*256 + y*16 + x];
         sv_lighting [z] = data [z*256 + y*16 + x];
      }
   }
}


#define CHUNK_CACHE   64
typedef struct
{
   int valid;
   int chunk_x, chunk_y;
   fast_chunk *fc;
} cached_converted_chunk;

cached_converted_chunk chunk_cache[CHUNK_CACHE][CHUNK_CACHE];
int cache_size = CHUNK_CACHE;

void reset_cache_size(int size)
{
   int i,j;
   for (j=size; j < cache_size; ++j) {
      for (i=size; i < cache_size; ++i) {
         cached_converted_chunk *ccc = &chunk_cache[j][i];
         if (ccc->valid) {
            if (ccc->fc) {
               free(ccc->fc->pointer_to_free);
               free(ccc->fc);
               ccc->fc = NULL;
            }
            ccc->valid = 0;
         }
      }
   }
   cache_size = size;
}

// this must be called inside mutex
void deref_fastchunk(fast_chunk *fc)
{
   if (fc) {
      assert(fc->refcount > 0);
      --fc->refcount;
      if (fc->refcount == 0) {
         free(fc->pointer_to_free);
         free(fc);
      }
   }
}

SDL_mutex * chunk_cache_mutex;
SDL_mutex * chunk_get_mutex;

void lock_chunk_get_mutex(void)
{
   SDL_LockMutex(chunk_get_mutex);
}
void unlock_chunk_get_mutex(void)
{
   SDL_UnlockMutex(chunk_get_mutex);
}

fast_chunk *get_converted_fastchunk(int chunk_x, int chunk_y)
{
   int slot_x = (chunk_x & (cache_size-1));
   int slot_y = (chunk_y & (cache_size-1));
   fast_chunk *fc;
   cached_converted_chunk *ccc;
   SDL_LockMutex(chunk_cache_mutex);
   ccc = &chunk_cache[slot_y][slot_x];
   if (ccc->valid) {
      if (ccc->chunk_x == chunk_x && ccc->chunk_y == chunk_y) {
         fast_chunk *fc = ccc->fc;
         if (fc)
            ++fc->refcount;
         SDL_UnlockMutex(chunk_cache_mutex);
         return fc;
      }
      if (ccc->fc) {
         deref_fastchunk(ccc->fc);
         ccc->fc = NULL;
         ccc->valid = 0;
      }
   }
   SDL_UnlockMutex(chunk_cache_mutex);

   fc = get_decoded_fastchunk_uncached(chunk_x, -chunk_y);
   if (fc)
      convert_fastchunk_inplace(fc);

   SDL_LockMutex(chunk_cache_mutex);
   // another thread might have updated it, so before we overwrite it...
   if (ccc->fc) {
      deref_fastchunk(ccc->fc);
      ccc->fc = NULL;
   }

   if (fc)
      fc->refcount = 1; // 1 in the cache

   ccc->chunk_x = chunk_x;
   ccc->chunk_y = chunk_y;
   ccc->valid = 1;
   if (fc)
      ++fc->refcount;
   ccc->fc = fc;
   SDL_UnlockMutex(chunk_cache_mutex);
   return fc;
}

void make_map_segment_for_superchunk_preconvert(int chunk_x, int chunk_y, int segment, fast_chunk *fc_table[4][4], uint8 sv_blocktype[34][34][18], uint8 sv_lighting[34][34][18])
{
   int a,b;
   assert((chunk_x & 1) == 0);
   assert((chunk_y & 1) == 0);
   for (b=-1; b < 3; ++b) {
      for (a=-1; a < 3; ++a) {
         int xo = a*16+1;
         int yo = b*16+1;
         int x,y;
         fast_chunk *fc = fc_table[b+1][a+1];
         for (y=0; y < 16; ++y)
            for (x=0; x < 16; ++x)
               if (xo+x >= 0 && xo+x < 34 && yo+y >= 0 && yo+y < 34)
                  make_converted_fastchunk(fc,x,y, segment, sv_blocktype[xo+x][yo+y], sv_lighting[xo+x][yo+y]);
      }
   }
}

// build 1 mesh covering 2x2 chunks
void build_chunk(int chunk_x, int chunk_y, fast_chunk *fc_table[4][4], raw_mesh *rm)
{
   int a,b,z;
   stbvox_input_description *map;

   #ifdef VHEIGHT_TEST
   unsigned char vheight[34][34][18];
   #endif

   #ifndef STBVOX_CONFIG_DISABLE_TEX2
   unsigned char tex2_choice[34][34][18];
   #endif

   assert((chunk_x & 1) == 0);
   assert((chunk_y & 1) == 0);

   rm->cx = chunk_x;
   rm->cy = chunk_y;

   stbvox_set_input_stride(&rm->mm, 34*18, 18);

   assert(rm->mm.input.geometry == NULL);

   map = stbvox_get_input_description(&rm->mm);
   map->block_tex1_face = minecraft_tex1_for_blocktype;
   map->block_color_face = minecraft_color_for_blocktype;
   map->block_geometry = minecraft_geom_for_blocktype;

   stbvox_reset_buffers(&rm->mm);
   stbvox_set_buffer(&rm->mm, 0, 0, rm->build_buffer, BUILD_BUFFER_SIZE);
   stbvox_set_buffer(&rm->mm, 0, 1, rm->face_buffer , FACE_BUFFER_SIZE);

   map->blocktype = &rm->sv_blocktype[1][1][1]; // this is (0,0,0), but we need to be able to query off the edges
   map->lighting = &rm->sv_lighting[1][1][1];

   // fill in the top two rows of the buffer
   for (a=0; a < 34; ++a) {
      for (b=0; b < 34; ++b) {
         rm->sv_blocktype[a][b][16] = 0;
         rm->sv_lighting [a][b][16] = 255;
         rm->sv_blocktype[a][b][17] = 0;
         rm->sv_lighting [a][b][17] = 255;
      }
   }

   #ifndef STBVOX_CONFIG_DISABLE_TEX2
   for (a=0; a < 34; ++a) {
      for (b=0; b < 34; ++b) {
         int px = chunk_x*16 + a - 1;
         int py = chunk_y*16 + b - 1;
         float dist = (float) sqrt(px*px + py*py);
         float s1 = (float) sin(dist / 16), s2, s3;
         dist = (float) sqrt((px-80)*(px-80) + (py-50)*(py-50));
         s2 = (float) sin(dist / 11);
         for (z=0; z < 18; ++z) {
            s3 = (float) sin(z * 3.141592 / 8);

            s3 = s1*s2*s3;
            tex2_choice[a][b][z] = 63 & (int) stb_linear_remap(s3,-1,1, -20,83);
         }
      }
   }
   #endif

   for (z=256-16; z >= SKIP_TERRAIN; z -= 16)
   {
      int z0 = z;
      int z1 = z+16;
      if (z1 == 256) z1 = 255;

      make_map_segment_for_superchunk_preconvert(chunk_x, chunk_y, z >> 4, fc_table, rm->sv_blocktype, rm->sv_lighting);

      map->blocktype = &rm->sv_blocktype[1][1][1-z]; // specify location of 0,0,0 so that accessing z0..z1 gets right data
      map->lighting = &rm->sv_lighting[1][1][1-z];
      #ifndef STBVOX_CONFIG_DISABLE_TEX2
      map->tex2 = &tex2_choice[1][1][1-z];
      #endif

      #ifdef VHEIGHT_TEST
      // hacky test of vheight
      for (a=0; a < 34; ++a) {
         for (b=0; b < 34; ++b) {
            int c;
            for (c=0; c < 17; ++c) {
               if (rm->sv_blocktype[a][b][c] != 0 && rm->sv_blocktype[a][b][c+1] == 0) {
                  // topmost block
                  vheight[a][b][c] = rand() & 255;
                  rm->sv_blocktype[a][b][c] = 168;
               } else if (c > 0 && rm->sv_blocktype[a][b][c] != 0 && rm->sv_blocktype[a][b][c-1] == 0) {
                  // bottommost block
                  vheight[a][b][c] = ((rand() % 3) << 6) + ((rand() % 3) << 4) + ((rand() % 3) << 2) + (rand() % 3);
                  rm->sv_blocktype[a][b][c] = 169;
               }
            }
            vheight[a][b][c] = STBVOX_MAKE_VHEIGHT(2,2,2,2); // flat top
         }
      }
      map->vheight = &vheight[1][1][1-z];
      #endif

      {
         stbvox_set_input_range(&rm->mm, 0,0,z0, 32,32,z1);
         stbvox_set_default_mesh(&rm->mm, 0);
         stbvox_make_mesh(&rm->mm);
      }

      // copy the bottom two rows of data up to the top
      for (a=0; a < 34; ++a) {
         for (b=0; b < 34; ++b) {
            rm->sv_blocktype[a][b][16] = rm->sv_blocktype[a][b][0];
            rm->sv_blocktype[a][b][17] = rm->sv_blocktype[a][b][1];
            rm->sv_lighting [a][b][16] = rm->sv_lighting [a][b][0];
            rm->sv_lighting [a][b][17] = rm->sv_lighting [a][b][1];
         }
      }
   }

   stbvox_set_mesh_coordinates(&rm->mm, chunk_x*16, chunk_y*16, 0);
   stbvox_get_transform(&rm->mm, rm->transform);

   stbvox_set_input_range(&rm->mm, 0,0,0, 32,32,255);
   stbvox_get_bounds(&rm->mm, rm->bounds);

   rm->num_quads = stbvox_get_quad_count(&rm->mm, 0);
}

int next_blocktype = 255;

unsigned char mc_rot[4] = { 1,3,2,0 };

// create blocktypes with rotation baked into type...
// @TODO we no longer need this now that we store rotations
// in lighting
void build_stair_rotations(int blocktype, unsigned char *map)
{
   int i;

   // use the existing block type for floor stairs; allocate a new type for ceil stairs
   for (i=0; i < 6; ++i) {
      minecraft_color_for_blocktype[next_blocktype][i] = minecraft_color_for_blocktype[blocktype][i];
      minecraft_tex1_for_blocktype [next_blocktype][i] = minecraft_tex1_for_blocktype [blocktype][i];
   }
   minecraft_geom_for_blocktype[next_blocktype] = (unsigned char) STBVOX_MAKE_GEOMETRY(STBVOX_GEOM_ceil_slope_north_is_bottom, 0, 0);
   minecraft_geom_for_blocktype[     blocktype] = (unsigned char) STBVOX_MAKE_GEOMETRY(STBVOX_GEOM_floor_slope_north_is_top, 0, 0);

   for (i=0; i < 4; ++i) {
      map[0+i+8] = map[0+i] =      blocktype;
      map[4+i+8] = map[4+i] = next_blocktype;
   }
   --next_blocktype;
}

void build_wool_variations(int bt, unsigned char *map)
{
   int i,k;
   unsigned char tex[16] = { 64, 210, 194, 178,  162, 146, 130, 114,  225, 209, 193, 177,  161, 145, 129, 113 };
   for (i=0; i < 16; ++i) {
      if (i == 0)
         map[i] = bt;
      else {
         map[i] = next_blocktype;
         for (k=0; k < 6; ++k) {
            minecraft_tex1_for_blocktype[next_blocktype][k] = tex[i];
         }
         minecraft_geom_for_blocktype[next_blocktype] = minecraft_geom_for_blocktype[bt];
         --next_blocktype;
      }
   }
}

void build_wood_variations(int bt, unsigned char *map)
{
   int i,k;
   unsigned char tex[4] = { 5, 198, 214, 199 };
   for (i=0; i < 4; ++i) {
      if (i == 0)
         map[i] = bt;
      else {
         map[i] = next_blocktype;
         for (k=0; k < 6; ++k) {
            minecraft_tex1_for_blocktype[next_blocktype][k] = tex[i];
         }
         minecraft_geom_for_blocktype[next_blocktype] = minecraft_geom_for_blocktype[bt];
         --next_blocktype;
      }
   }
   map[i] = map[i-1];
   ++i;
   for (; i < 16; ++i)
      map[i] = bt;
}

void remap_in_place(int bt, int rm)
{
   int i;
   remap[bt] = rm;
   for (i=0; i < 16; ++i)
      remap_data[rm][i] = bt;
}


void mesh_init(void)
{
   int i;

   chunk_cache_mutex = SDL_CreateMutex();
   chunk_get_mutex   = SDL_CreateMutex();

   for (i=0; i < 256; ++i) {
      memcpy(minecraft_tex1_for_blocktype[i], minecraft_info[i]+1, 6);
      effective_blocktype[i] = (minecraft_info[i][0] == C_empty ? 0 : i);
      minecraft_geom_for_blocktype[i] = geom_map[minecraft_info[i][0]];
   }
   //effective_blocktype[50] = 0; // delete torches

   for (i=0; i < 6*256; ++i) {
      if (minecraft_tex1_for_blocktype[0][i] == 40)
         minecraft_color_for_blocktype[0][i] = 38 | 64; // apply to tex1
      if (minecraft_tex1_for_blocktype[0][i] == 39)
         minecraft_color_for_blocktype[0][i] = 39 | 64; // apply to tex1
      if (minecraft_tex1_for_blocktype[0][i] == 105)
         minecraft_color_for_blocktype[0][i] = 63; // emissive
      if (minecraft_tex1_for_blocktype[0][i] == 212)
         minecraft_color_for_blocktype[0][i] = 63; // emissive
      if (minecraft_tex1_for_blocktype[0][i] == 80)
         minecraft_color_for_blocktype[0][i] = 63; // emissive
   }

   for (i=0; i < 6; ++i) {
      minecraft_color_for_blocktype[172][i] = 47 | 64; // apply to tex1
      minecraft_color_for_blocktype[178][i] = 47 | 64; // apply to tex1
      minecraft_color_for_blocktype[18][i] = 39 | 64; // green
      minecraft_color_for_blocktype[161][i] = 37 | 64; // green
      minecraft_color_for_blocktype[10][i] = 63; // emissive lava
      minecraft_color_for_blocktype[11][i] = 63; // emissive
   }

   #ifdef VHEIGHT_TEST
   effective_blocktype[168] = 168;
   minecraft_tex1_for_blocktype[168][0] = 1;
   minecraft_tex1_for_blocktype[168][1] = 1;
   minecraft_tex1_for_blocktype[168][2] = 1;
   minecraft_tex1_for_blocktype[168][3] = 1;
   minecraft_tex1_for_blocktype[168][4] = 1;
   minecraft_tex1_for_blocktype[168][5] = 1;
   minecraft_geom_for_blocktype[168] = STBVOX_GEOM_floor_vheight_12;
   effective_blocktype[169] = 169;
   minecraft_tex1_for_blocktype[169][0] = 1;
   minecraft_tex1_for_blocktype[169][1] = 1;
   minecraft_tex1_for_blocktype[169][2] = 1;
   minecraft_tex1_for_blocktype[169][3] = 1;
   minecraft_tex1_for_blocktype[169][4] = 1;
   minecraft_tex1_for_blocktype[169][5] = 1;
   minecraft_geom_for_blocktype[169] = STBVOX_GEOM_ceil_vheight_03;
   #endif

   remap[53] = 1;
   remap[67] = 2;
   remap[108] = 3;
   remap[109] = 4;
   remap[114] = 5;
   remap[136] = 6;
   remap[156] = 7;
   for (i=0; i < 256; ++i)
      if (remap[i])
         build_stair_rotations(i, remap_data[remap[i]]);
   remap[35]  = 8;
   build_wool_variations(35, remap_data[remap[35]]);
   remap[5] = 11;
   build_wood_variations(5, remap_data[remap[5]]);

   // set the remap flags for these so they write the rotation values
   remap_in_place(54, 9);
   remap_in_place(146, 10);
}

// Timing stats while optimizing the single-threaded builder

// 32..-32, 32..-32, SKIP_TERRAIN=0, !FANCY_LEAVES on 'mcrealm' data set

// 6.27s  - reblocked to do 16 z at a time instead of 256 (still using 66x66x258), 4 meshes in parallel
// 5.96s  - reblocked to use FAST_CHUNK (no intermediate data structure)
// 5.45s  - unknown change, or previous measurement was wrong

// 6.12s  - use preconverted data, not in-place
// 5.91s  - use preconverted, in-place
// 5.34s  - preconvert, in-place, avoid dependency chain (suggested by ryg)
// 5.34s  - preconvert, in-place, avoid dependency chain, use bit-table instead of byte-table
// 5.50s  - preconvert, in-place, branchless

// 6.42s  - non-preconvert, avoid dependency chain (not an error)
// 5.40s  - non-preconvert, w/dependency chain (same as earlier)

// 5.50s  - non-FAST_CHUNK, reblocked outer loop for better cache reuse
// 4.73s  - FAST_CHUNK non-preconvert, reblocked outer loop
// 4.25s  - preconvert, in-place, reblocked outer loop
// 4.18s  - preconvert, in-place, unrolled again
// 4.10s  - 34x34 1 mesh instead of 66x66 and 4 meshes (will make it easier to do multiple threads)

// 4.83s  - building bitmasks but not using them (2 bits per block, one if empty, one if solid)

// 5.16s  - using empty bitmasks to early out
// 5.01s  - using solid & empty bitmasks to early out - "foo"
// 4.64s  - empty bitmask only, test 8 at a time, then test geom
// 4.72s  - empty bitmask only, 8 at a time, then test bits
// 4.46s  - split bitmask building into three loops (each byte is separate)
// 4.42s  - further optimize computing bitmask

// 4.58s  - using solid & empty bitmasks to early out, same as "foo" but faster bitmask building
// 4.12s  - using solid & empty bitmasks to efficiently test neighbors
// 4.04s  - using 16-bit fetches (not endian-independent)
//        - note this is first place that beats previous best '4.10s - 34x34 1 mesh'

// 4.30s  - current time with bitmasks disabled again (note was 4.10s earlier)
// 3.95s  - bitmasks enabled again, no other changes
// 4.00s  - current time with bitmasks disabled again, no other changes -- wide variation that is time dependent?
//          (note that most of the numbers listed here are median of 3 values already)
// 3.98s  - bitmasks enabled

// Bitmasks removed from the code as not worth the complexity increase



// Raw data for Q&A:
//
//   26% parsing & loading minecraft files (4/5ths of which is zlib decode)
//   39% building mesh from stb input format
//   18% converting from minecraft blocks to stb blocks
//    9% reordering from minecraft axis order to stb axis order
//    7% uploading vertex buffer to OpenGL
