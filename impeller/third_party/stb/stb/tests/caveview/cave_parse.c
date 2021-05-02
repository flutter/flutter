#include <assert.h>
#include <stdio.h>
#include <limits.h>
#include <stdlib.h>

#define FAST_CHUNK   // disabling this enables the old, slower path that deblocks into a regular form

#include "cave_parse.h"

#include "stb_image.h"
#include "stb.h"

#define NUM_CHUNKS_PER_REGION       32  // only on one axis
#define NUM_CHUNKS_PER_REGION_LOG2   5

#define NUM_COLUMNS_PER_CHUNK       16
#define NUM_COLUMNS_PER_CHUNK_LOG2   4

uint32 read_uint32_be(FILE *f)
{
   unsigned char data[4];
   fread(data, 1, 4, f);
   return (data[0]<<24) + (data[1]<<16) + (data[2]<<8) + data[3];
}

typedef struct
{
   uint8 *data;
   size_t len;
   int x,z; // chunk index
   int refcount; // for multi-threading
} compressed_chunk;

typedef struct
{
   int x,z;
   uint32 sector_data[NUM_CHUNKS_PER_REGION][NUM_CHUNKS_PER_REGION];
} region;

size_t cached_compressed=0;

FILE *last_region;
int last_region_x;
int last_region_z;
int opened=0;

static void open_file(int reg_x, int reg_z)
{
   if (!opened || last_region_x != reg_x || last_region_z != reg_z) {
      char filename[256];
      if (last_region != NULL)
         fclose(last_region);
      sprintf(filename, "r.%d.%d.mca", reg_x, reg_z);
      last_region = fopen(filename, "rb");
      last_region_x = reg_x;
      last_region_z = reg_z;
      opened = 1;
   }
}

static region *load_region(int reg_x, int reg_z)
{
   region *r;
   int x,z;

   open_file(reg_x, reg_z);

   r = malloc(sizeof(*r));

   if (last_region == NULL) {
      memset(r, 0, sizeof(*r));
   } else {
      fseek(last_region, 0, SEEK_SET);
      for (z=0; z < NUM_CHUNKS_PER_REGION; ++z)
         for (x=0; x < NUM_CHUNKS_PER_REGION; ++x)
            r->sector_data[z][x] = read_uint32_be(last_region);
   }
   r->x = reg_x;
   r->z = reg_z;

   return r;
}

void free_region(region *r)
{
   free(r);
}

#define MAX_MAP_REGIONS   64  // in one axis: 64 regions * 32 chunk/region * 16 columns/chunk = 16384 columns
region *regions[MAX_MAP_REGIONS][MAX_MAP_REGIONS];

static region *get_region(int reg_x, int reg_z)
{
   int slot_x = reg_x & (MAX_MAP_REGIONS-1);
   int slot_z = reg_z & (MAX_MAP_REGIONS-1);
   region *r;

   r = regions[slot_z][slot_x];

   if (r) {
      if (r->x == reg_x && r->z == reg_z)
         return r;
      free_region(r);
   }

   r = load_region(reg_x, reg_z);
   regions[slot_z][slot_x] = r;

   return r;
}

// about one region, so size should be ok
#define NUM_CACHED_X 64
#define NUM_CACHED_Z 64

// @TODO: is it really worth caching these? we probably can just
// pull them from the disk cache nearly as efficiently.
// Can test that by setting to 1x1?
compressed_chunk *cached_chunk[NUM_CACHED_Z][NUM_CACHED_X];

static void deref_compressed_chunk(compressed_chunk *cc)
{
   assert(cc->refcount > 0);
   --cc->refcount;
   if (cc->refcount == 0) {
      if (cc->data)
         free(cc->data);
      free(cc);
   }
}

static compressed_chunk *get_compressed_chunk(int chunk_x, int chunk_z)
{
   int slot_x = chunk_x & (NUM_CACHED_X-1);
   int slot_z = chunk_z & (NUM_CACHED_Z-1);
   compressed_chunk *cc = cached_chunk[slot_z][slot_x];

   if (cc && cc->x == chunk_x && cc->z == chunk_z)
      return cc;
   else {
      int reg_x = chunk_x >> NUM_CHUNKS_PER_REGION_LOG2;
      int reg_z = chunk_z >> NUM_CHUNKS_PER_REGION_LOG2;
      region *r = get_region(reg_x, reg_z);
      if (cc) {
         deref_compressed_chunk(cc);
         cached_chunk[slot_z][slot_x] = NULL;
      }
      cc = malloc(sizeof(*cc));
      cc->x = chunk_x;
      cc->z = chunk_z;
      {
         int subchunk_x = chunk_x & (NUM_CHUNKS_PER_REGION-1);
         int subchunk_z = chunk_z & (NUM_CHUNKS_PER_REGION-1);
         uint32 code = r->sector_data[subchunk_z][subchunk_x];

         if (code & 255) {
            open_file(reg_x, reg_z);
            fseek(last_region, (code>>8)*4096, SEEK_SET);
            cc->len = (code&255)*4096;
            cc->data = malloc(cc->len);
            fread(cc->data, 1, cc->len, last_region);
         } else {
            cc->len = 0;
            cc->data = 0;
         }
      }
      cc->refcount = 1;
      cached_chunk[slot_z][slot_x] = cc;
      return cc;
   }
}


// NBT parser -- can automatically parse stuff we don't
// have definitions for, but want to explicitly parse
// stuff we do have definitions for.
//
// option 1: auto-parse everything into data structures,
// then read those
//
// option 2: have a "parse next object" which
// doesn't resolve whether it expands its children
// yet, and then the user either says "expand" or
// "skip" after looking at the name. Anything with
// "children" without names can't go through this
// interface.
//
// Let's try option 2.


typedef struct
{
   unsigned char *buffer_start;
   unsigned char *buffer_end;
   unsigned char *cur;
   int nesting;
   char temp_buffer[256];
} nbt;

enum { TAG_End=0, TAG_Byte=1, TAG_Short=2, TAG_Int=3, TAG_Long=4,
       TAG_Float=5, TAG_Double=6, TAG_Byte_Array=7, TAG_String=8,
       TAG_List=9, TAG_Compound=10, TAG_Int_Array=11 };

static void nbt_get_string_data(unsigned char *data, char *buffer, size_t bufsize)
{
   int len = data[0]*256 + data[1];
   int i;
   for (i=0; i < len && i+1 < (int) bufsize; ++i)
      buffer[i] = (char) data[i+2];
   buffer[i] = 0;
}

static char *nbt_peek(nbt *n)
{
   unsigned char type = *n->cur;
   if (type == TAG_End)
      return NULL;
   nbt_get_string_data(n->cur+1, n->temp_buffer, sizeof(n->temp_buffer));
   return n->temp_buffer;
}

static uint32 nbt_parse_uint32(unsigned char *buffer)
{
   return (buffer[0] << 24) + (buffer[1]<<16) + (buffer[2]<<8) + buffer[3];
}

static void nbt_skip(nbt *n);

// skip an item that doesn't have an id or name prefix (usable in lists)
static void nbt_skip_raw(nbt *n, unsigned char type)
{
   switch (type) {
      case TAG_Byte  : n->cur += 1; break;
      case TAG_Short : n->cur += 2; break;
      case TAG_Int   : n->cur += 4; break;
      case TAG_Long  : n->cur += 8; break;
      case TAG_Float : n->cur += 4; break;
      case TAG_Double: n->cur += 8; break;
      case TAG_Byte_Array: n->cur += 4 + 1*nbt_parse_uint32(n->cur); break;
      case TAG_Int_Array : n->cur += 4 + 4*nbt_parse_uint32(n->cur); break;
      case TAG_String    : n->cur += 2 + (n->cur[0]*256 + n->cur[1]); break;
      case TAG_List      : {
         unsigned char list_type = *n->cur++;
         unsigned int list_len = nbt_parse_uint32(n->cur);
         unsigned int i;
         n->cur += 4; // list_len
         for (i=0; i < list_len; ++i)
            nbt_skip_raw(n, list_type);
         break;
      }
      case TAG_Compound : {
         while (*n->cur != TAG_End)
            nbt_skip(n);
         nbt_skip(n); // skip the TAG_end
         break;
      }
   }
   assert(n->cur <= n->buffer_end);
}

static void nbt_skip(nbt *n)
{
   unsigned char type = *n->cur++;
   if (type == TAG_End)
      return;
   // skip name
   n->cur += (n->cur[0]*256 + n->cur[1]) + 2;
   nbt_skip_raw(n, type);
}

// byteswap
static void nbt_swap(unsigned char *ptr, int len)
{
   int i;
   for (i=0; i < (len>>1); ++i) {
      unsigned char t = ptr[i];
      ptr[i] = ptr[len-1-i];
      ptr[len-1-i] = t;
   }
}

// pass in the expected type, fail if doesn't match
// returns a pointer to the data, byteswapped if appropriate
static void *nbt_get_fromlist(nbt *n, unsigned char type, int *len)
{
   unsigned char *ptr;
   assert(type != TAG_Compound);
   assert(type != TAG_List); // we could support getting lists of primitives as if they were arrays, but eh
   if (len) *len = 1;
   ptr = n->cur;
   switch (type) {
      case TAG_Byte  : break;

      case TAG_Short : nbt_swap(ptr, 2); break;
      case TAG_Int   : nbt_swap(ptr, 4); break;
      case TAG_Long  : nbt_swap(ptr, 8); break;
      case TAG_Float : nbt_swap(ptr, 4); break;
      case TAG_Double: nbt_swap(ptr, 8); break;

      case TAG_Byte_Array:
         *len = nbt_parse_uint32(ptr);
         ptr += 4;
         break;
      case TAG_Int_Array: {
         int i;
         *len = nbt_parse_uint32(ptr);
         ptr += 4;
         for (i=0; i < *len; ++i)
            nbt_swap(ptr + 4*i, 4);
         break;
      }

      default: assert(0); // unhandled case
   }
   nbt_skip_raw(n, type);
   return ptr;
}

static void *nbt_get(nbt *n, unsigned char type, int *len)
{
   assert(n->cur[0] == type);
   n->cur += 3 + (n->cur[1]*256+n->cur[2]);
   return nbt_get_fromlist(n, type, len);
}

static void nbt_begin_compound(nbt *n) // start a compound
{
   assert(*n->cur == TAG_Compound);
   // skip header
   n->cur += 3 + (n->cur[1]*256 + n->cur[2]);
   ++n->nesting;
}

static void nbt_begin_compound_in_list(nbt *n) // start a compound
{
   ++n->nesting;
}

static void nbt_end_compound(nbt *n) // end a compound
{
   assert(*n->cur == TAG_End);
   assert(n->nesting != 0);
   ++n->cur;
   --n->nesting;   
}

// @TODO no interface to get lists from lists
static int nbt_begin_list(nbt *n, unsigned char type)
{
   uint32 len;
   unsigned char *ptr;

   ptr = n->cur + 3 + (n->cur[1]*256 + n->cur[2]);
   if (ptr[0] != type)
      return -1;
   n->cur = ptr;
   len = nbt_parse_uint32(n->cur+1);
   assert(n->cur[0] == type);
   // @TODO keep a stack with the count to make sure they do it right
   ++n->nesting;
   n->cur += 5;
   return (int) len;
}

static void nbt_end_list(nbt *n)
{
   --n->nesting;
}

// raw_block chunk is 16x256x16x4 = 2^(4+8+4+2) = 256KB
//
// if we want to process 64x64x256 at a time, that will be:
//    4*4*256KB => 4MB per area in raw_block
//
// (plus we maybe need to decode adjacent regions)


#ifdef FAST_CHUNK
typedef fast_chunk parse_chunk;
#else
typedef chunk parse_chunk;
#endif

static parse_chunk *minecraft_chunk_parse(unsigned char *data, size_t len)
{
   char *s;
   parse_chunk *c = NULL;

   nbt n_store, *n = &n_store;
   n->buffer_start = data;
   n->buffer_end   = data + len;
   n->cur = n->buffer_start;
   n->nesting = 0;

   nbt_begin_compound(n);
   while ((s = nbt_peek(n)) != NULL) {
      if (!strcmp(s, "Level")) {
         int *height;
         c = malloc(sizeof(*c));
         #ifdef FAST_CHUNK
         memset(c, 0, sizeof(*c));
         c->pointer_to_free = data;
         #else
         c->rb[15][15][255].block = 0;
         #endif
         c->max_y = 0;

         nbt_begin_compound(n);
         while ((s = nbt_peek(n)) != NULL) {
            if (!strcmp(s, "xPos"))
               c->xpos = *(int *) nbt_get(n, TAG_Int, 0);
            else if (!strcmp(s, "zPos"))
               c->zpos = *(int *) nbt_get(n, TAG_Int, 0);
            else if (!strcmp(s, "Sections")) {
               int count = nbt_begin_list(n, TAG_Compound), i;
               if (count == -1) {
                  // this not-a-list case happens in The End and I'm not sure
                  // what it means... possibly one of those silly encodings
                  // where it's not encoded as a list if there's only one?
                  // not worth figuring out
                  nbt_skip(n);
                  count = -1;
               }
               for (i=0; i < count; ++i) {
                  int yi, len;
                  uint8 *light = NULL, *blocks = NULL, *data = NULL, *skylight = NULL;
                  nbt_begin_compound_in_list(n);
                  while ((s = nbt_peek(n)) != NULL) {
                     if (!strcmp(s, "Y"))
                        yi = * (uint8 *) nbt_get(n, TAG_Byte, 0);
                     else if (!strcmp(s, "BlockLight")) {
                        light = nbt_get(n, TAG_Byte_Array, &len);
                        assert(len == 2048);
                     } else if (!strcmp(s, "Blocks")) {
                        blocks = nbt_get(n, TAG_Byte_Array, &len);
                        assert(len == 4096);
                     } else if (!strcmp(s, "Data")) {
                        data = nbt_get(n, TAG_Byte_Array, &len);
                        assert(len == 2048);
                     } else if (!strcmp(s, "SkyLight")) {
                        skylight = nbt_get(n, TAG_Byte_Array, &len);
                        assert(len == 2048);
                     }
                  }
                  nbt_end_compound(n);

                  assert(yi < 16);

                  #ifndef FAST_CHUNK

                  // clear data below current max_y
                  {
                     int x,z;
                     while (c->max_y < yi*16) {
                        for (x=0; x < 16; ++x)
                           for (z=0; z < 16; ++z)
                              c->rb[z][x][c->max_y].block = 0;
                        ++c->max_y;
                     }
                  }

                  // now assemble the data
                  {
                     int x,y,z, o2=0,o4=0;
                     for (y=0; y < 16; ++y) {
                        for (z=0; z < 16; ++z) {
                           for (x=0; x < 16; x += 2) {
                              raw_block *rb = &c->rb[15-z][x][y + yi*16]; // 15-z because switching to z-up will require flipping an axis
                              rb[0].block = blocks[o4];
                              rb[0].light = light[o2] & 15;
                              rb[0].data  = data[o2] & 15;
                              rb[0].skylight = skylight[o2] & 15;

                              rb[256].block = blocks[o4+1];
                              rb[256].light = light[o2] >> 4;
                              rb[256].data  = data[o2] >> 4;
                              rb[256].skylight = skylight[o2] >> 4;

                              o2 += 1;
                              o4 += 2;
                           }
                        }
                     }
                     c->max_y += 16;
                  }
                  #else
                  c->blockdata[yi] = blocks;
                  c->data     [yi] = data;
                  c->light    [yi] = light;
                  c->skylight [yi] = skylight;
                  #endif
               }
               //nbt_end_list(n);
            } else if (!strcmp(s, "HeightMap")) {
               height = nbt_get(n, TAG_Int_Array, &len);
               assert(len == 256);
            } else
               nbt_skip(n);
         }
         nbt_end_compound(n);

      } else
         nbt_skip(n);
   }
   nbt_end_compound(n);
   assert(n->cur == n->buffer_end);
   return c;
}

#define MAX_DECODED_CHUNK_X  64
#define MAX_DECODED_CHUNK_Z  64

typedef struct
{
   int cx,cz;
   fast_chunk *fc;
   int valid;
} decoded_buffer;

static decoded_buffer decoded_buffers[MAX_DECODED_CHUNK_Z][MAX_DECODED_CHUNK_X];
void lock_chunk_get_mutex(void);
void unlock_chunk_get_mutex(void);

#ifdef FAST_CHUNK
fast_chunk *get_decoded_fastchunk_uncached(int chunk_x, int chunk_z)
{
   unsigned char *decoded;
   compressed_chunk *cc;
   int inlen;
   int len;
   fast_chunk *fc;

   lock_chunk_get_mutex();
   cc = get_compressed_chunk(chunk_x, chunk_z);
   if (cc->len != 0)
      ++cc->refcount;
   unlock_chunk_get_mutex();

   if (cc->len == 0)
      return NULL;

   assert(cc != NULL);

   assert(cc->data[4] == 2);

   inlen = nbt_parse_uint32(cc->data);
   decoded = stbi_zlib_decode_malloc_guesssize(cc->data+5, inlen, inlen*3, &len);
   assert(decoded != NULL);
   assert(len != 0);

   lock_chunk_get_mutex();
   deref_compressed_chunk(cc);
   unlock_chunk_get_mutex();

   #ifdef FAST_CHUNK
   fc = minecraft_chunk_parse(decoded, len);
   #else
   fc = NULL;
   #endif
   if (fc == NULL)
      free(decoded);
   return fc;
}


decoded_buffer *get_decoded_buffer(int chunk_x, int chunk_z)
{
   decoded_buffer *db = &decoded_buffers[chunk_z&(MAX_DECODED_CHUNK_Z-1)][chunk_x&(MAX_DECODED_CHUNK_X-1)];
   if (db->valid) {
      if (db->cx == chunk_x && db->cz == chunk_z)
         return db;
      if (db->fc) {
         free(db->fc->pointer_to_free);
         free(db->fc);
      }
   }

   db->cx = chunk_x;
   db->cz = chunk_z;
   db->valid = 1;
   db->fc = 0;

   {
      db->fc = get_decoded_fastchunk_uncached(chunk_x, chunk_z);
      return db;
   }
}

fast_chunk *get_decoded_fastchunk(int chunk_x, int chunk_z)
{
   decoded_buffer *db = get_decoded_buffer(chunk_x, chunk_z);
   return db->fc;
}
#endif

#ifndef FAST_CHUNK
chunk *get_decoded_chunk_raw(int chunk_x, int chunk_z)
{
   unsigned char *decoded;
   compressed_chunk *cc = get_compressed_chunk(chunk_x, chunk_z);
   assert(cc != NULL);
   if (cc->len == 0)
      return NULL;
   else {
      chunk *ch;
      int inlen = nbt_parse_uint32(cc->data);
      int len;
      assert(cc->data[4] == 2);
      decoded = stbi_zlib_decode_malloc_guesssize(cc->data+5, inlen, inlen*3, &len);
      assert(decoded != NULL);
      #ifdef FAST_CHUNK
      ch = NULL;
      #else
      ch = minecraft_chunk_parse(decoded, len);
      #endif
      free(decoded);
      return ch;
   }
}

static chunk *decoded_chunks[MAX_DECODED_CHUNK_Z][MAX_DECODED_CHUNK_X];
chunk *get_decoded_chunk(int chunk_x, int chunk_z)
{
   chunk *c = decoded_chunks[chunk_z&(MAX_DECODED_CHUNK_Z-1)][chunk_x&(MAX_DECODED_CHUNK_X-1)];
   if (c && c->xpos == chunk_x && c->zpos == chunk_z)
      return c;
   if (c) free(c);
   c = get_decoded_chunk_raw(chunk_x, chunk_z);
   decoded_chunks[chunk_z&(MAX_DECODED_CHUNK_Z-1)][chunk_x&(MAX_DECODED_CHUNK_X-1)] = c;
   return c;
}
#endif
