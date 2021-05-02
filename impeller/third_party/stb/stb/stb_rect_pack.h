// stb_rect_pack.h - v0.08 - public domain - rectangle packing
// Sean Barrett 2014
//
// Useful for e.g. packing rectangular textures into an atlas.
// Does not do rotation.
//
// Not necessarily the awesomest packing method, but better than
// the totally naive one in stb_truetype (which is primarily what
// this is meant to replace).
//
// Has only had a few tests run, may have issues.
//
// More docs to come.
//
// No memory allocations; uses qsort() and assert() from stdlib.
// Can override those by defining STBRP_SORT and STBRP_ASSERT.
//
// This library currently uses the Skyline Bottom-Left algorithm.
//
// Please note: better rectangle packers are welcome! Please
// implement them to the same API, but with a different init
// function.
//
// Credits
//
//  Library
//    Sean Barrett
//  Minor features
//    Martins Mozeiko
//  Bugfixes / warning fixes
//    Jeremy Jaussaud
//
// Version history:
//
//     0.08  (2015-09-13)  really fix bug with empty rects (w=0 or h=0)
//     0.07  (2015-09-13)  fix bug with empty rects (w=0 or h=0)
//     0.06  (2015-04-15)  added STBRP_SORT to allow replacing qsort
//     0.05:  added STBRP_ASSERT to allow replacing assert
//     0.04:  fixed minor bug in STBRP_LARGE_RECTS support
//     0.01:  initial release
//
// LICENSE
//
//   This software is dual-licensed to the public domain and under the following
//   license: you are granted a perpetual, irrevocable license to copy, modify,
//   publish, and distribute this file as you see fit.

//////////////////////////////////////////////////////////////////////////////
//
//       INCLUDE SECTION
//

#ifndef STB_INCLUDE_STB_RECT_PACK_H
#define STB_INCLUDE_STB_RECT_PACK_H

#define STB_RECT_PACK_VERSION  1

#ifdef STBRP_STATIC
#define STBRP_DEF static
#else
#define STBRP_DEF extern
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct stbrp_context stbrp_context;
typedef struct stbrp_node    stbrp_node;
typedef struct stbrp_rect    stbrp_rect;

#ifdef STBRP_LARGE_RECTS
typedef int            stbrp_coord;
#else
typedef unsigned short stbrp_coord;
#endif

STBRP_DEF void stbrp_pack_rects (stbrp_context *context, stbrp_rect *rects, int num_rects);
// Assign packed locations to rectangles. The rectangles are of type
// 'stbrp_rect' defined below, stored in the array 'rects', and there
// are 'num_rects' many of them.
//
// Rectangles which are successfully packed have the 'was_packed' flag
// set to a non-zero value and 'x' and 'y' store the minimum location
// on each axis (i.e. bottom-left in cartesian coordinates, top-left
// if you imagine y increasing downwards). Rectangles which do not fit
// have the 'was_packed' flag set to 0.
//
// You should not try to access the 'rects' array from another thread
// while this function is running, as the function temporarily reorders
// the array while it executes.
//
// To pack into another rectangle, you need to call stbrp_init_target
// again. To continue packing into the same rectangle, you can call
// this function again. Calling this multiple times with multiple rect
// arrays will probably produce worse packing results than calling it
// a single time with the full rectangle array, but the option is
// available.

struct stbrp_rect
{
   // reserved for your use:
   int            id;

   // input:
   stbrp_coord    w, h;

   // output:
   stbrp_coord    x, y;
   int            was_packed;  // non-zero if valid packing

}; // 16 bytes, nominally


STBRP_DEF void stbrp_init_target (stbrp_context *context, int width, int height, stbrp_node *nodes, int num_nodes);
// Initialize a rectangle packer to:
//    pack a rectangle that is 'width' by 'height' in dimensions
//    using temporary storage provided by the array 'nodes', which is 'num_nodes' long
//
// You must call this function every time you start packing into a new target.
//
// There is no "shutdown" function. The 'nodes' memory must stay valid for
// the following stbrp_pack_rects() call (or calls), but can be freed after
// the call (or calls) finish.
//
// Note: to guarantee best results, either:
//       1. make sure 'num_nodes' >= 'width'
//   or  2. call stbrp_allow_out_of_mem() defined below with 'allow_out_of_mem = 1'
//
// If you don't do either of the above things, widths will be quantized to multiples
// of small integers to guarantee the algorithm doesn't run out of temporary storage.
//
// If you do #2, then the non-quantized algorithm will be used, but the algorithm
// may run out of temporary storage and be unable to pack some rectangles.

STBRP_DEF void stbrp_setup_allow_out_of_mem (stbrp_context *context, int allow_out_of_mem);
// Optionally call this function after init but before doing any packing to
// change the handling of the out-of-temp-memory scenario, described above.
// If you call init again, this will be reset to the default (false).


STBRP_DEF void stbrp_setup_heuristic (stbrp_context *context, int heuristic);
// Optionally select which packing heuristic the library should use. Different
// heuristics will produce better/worse results for different data sets.
// If you call init again, this will be reset to the default.

enum
{
   STBRP_HEURISTIC_Skyline_default=0,
   STBRP_HEURISTIC_Skyline_BL_sortHeight = STBRP_HEURISTIC_Skyline_default,
   STBRP_HEURISTIC_Skyline_BF_sortHeight,
};


//////////////////////////////////////////////////////////////////////////////
//
// the details of the following structures don't matter to you, but they must
// be visible so you can handle the memory allocations for them

struct stbrp_node
{
   stbrp_coord  x,y;
   stbrp_node  *next;
};

struct stbrp_context
{
   int width;
   int height;
   int align;
   int init_mode;
   int heuristic;
   int num_nodes;
   stbrp_node *active_head;
   stbrp_node *free_head;
   stbrp_node extra[2]; // we allocate two extra nodes so optimal user-node-count is 'width' not 'width+2'
};

#ifdef __cplusplus
}
#endif

#endif

//////////////////////////////////////////////////////////////////////////////
//
//     IMPLEMENTATION SECTION
//

#ifdef STB_RECT_PACK_IMPLEMENTATION
#ifndef STBRP_SORT
#include <stdlib.h>
#define STBRP_SORT qsort
#endif

#ifndef STBRP_ASSERT
#include <assert.h>
#define STBRP_ASSERT assert
#endif

enum
{
   STBRP__INIT_skyline = 1,
};

STBRP_DEF void stbrp_setup_heuristic(stbrp_context *context, int heuristic)
{
   switch (context->init_mode) {
      case STBRP__INIT_skyline:
         STBRP_ASSERT(heuristic == STBRP_HEURISTIC_Skyline_BL_sortHeight || heuristic == STBRP_HEURISTIC_Skyline_BF_sortHeight);
         context->heuristic = heuristic;
         break;
      default:
         STBRP_ASSERT(0);
   }
}

STBRP_DEF void stbrp_setup_allow_out_of_mem(stbrp_context *context, int allow_out_of_mem)
{
   if (allow_out_of_mem)
      // if it's ok to run out of memory, then don't bother aligning them;
      // this gives better packing, but may fail due to OOM (even though
      // the rectangles easily fit). @TODO a smarter approach would be to only
      // quantize once we've hit OOM, then we could get rid of this parameter.
      context->align = 1;
   else {
      // if it's not ok to run out of memory, then quantize the widths
      // so that num_nodes is always enough nodes.
      //
      // I.e. num_nodes * align >= width
      //                  align >= width / num_nodes
      //                  align = ceil(width/num_nodes)

      context->align = (context->width + context->num_nodes-1) / context->num_nodes;
   }
}

STBRP_DEF void stbrp_init_target(stbrp_context *context, int width, int height, stbrp_node *nodes, int num_nodes)
{
   int i;
#ifndef STBRP_LARGE_RECTS
   STBRP_ASSERT(width <= 0xffff && height <= 0xffff);
#endif

   for (i=0; i < num_nodes-1; ++i)
      nodes[i].next = &nodes[i+1];
   nodes[i].next = NULL;
   context->init_mode = STBRP__INIT_skyline;
   context->heuristic = STBRP_HEURISTIC_Skyline_default;
   context->free_head = &nodes[0];
   context->active_head = &context->extra[0];
   context->width = width;
   context->height = height;
   context->num_nodes = num_nodes;
   stbrp_setup_allow_out_of_mem(context, 0);

   // node 0 is the full width, node 1 is the sentinel (lets us not store width explicitly)
   context->extra[0].x = 0;
   context->extra[0].y = 0;
   context->extra[0].next = &context->extra[1];
   context->extra[1].x = (stbrp_coord) width;
#ifdef STBRP_LARGE_RECTS
   context->extra[1].y = (1<<30);
#else
   context->extra[1].y = 65535;
#endif
   context->extra[1].next = NULL;
}

// find minimum y position if it starts at x1
static int stbrp__skyline_find_min_y(stbrp_context *c, stbrp_node *first, int x0, int width, int *pwaste)
{
   stbrp_node *node = first;
   int x1 = x0 + width;
   int min_y, visited_width, waste_area;
   STBRP_ASSERT(first->x <= x0);

   #if 0
   // skip in case we're past the node
   while (node->next->x <= x0)
      ++node;
   #else
   STBRP_ASSERT(node->next->x > x0); // we ended up handling this in the caller for efficiency
   #endif

   STBRP_ASSERT(node->x <= x0);

   min_y = 0;
   waste_area = 0;
   visited_width = 0;
   while (node->x < x1) {
      if (node->y > min_y) {
         // raise min_y higher.
         // we've accounted for all waste up to min_y,
         // but we'll now add more waste for everything we've visted
         waste_area += visited_width * (node->y - min_y);
         min_y = node->y;
         // the first time through, visited_width might be reduced
         if (node->x < x0)
            visited_width += node->next->x - x0;
         else
            visited_width += node->next->x - node->x;
      } else {
         // add waste area
         int under_width = node->next->x - node->x;
         if (under_width + visited_width > width)
            under_width = width - visited_width;
         waste_area += under_width * (min_y - node->y);
         visited_width += under_width;
      }
      node = node->next;
   }

   *pwaste = waste_area;
   return min_y;
}

typedef struct
{
   int x,y;
   stbrp_node **prev_link;
} stbrp__findresult;

static stbrp__findresult stbrp__skyline_find_best_pos(stbrp_context *c, int width, int height)
{
   int best_waste = (1<<30), best_x, best_y = (1 << 30);
   stbrp__findresult fr;
   stbrp_node **prev, *node, *tail, **best = NULL;

   // align to multiple of c->align
   width = (width + c->align - 1);
   width -= width % c->align;
   STBRP_ASSERT(width % c->align == 0);

   node = c->active_head;
   prev = &c->active_head;
   while (node->x + width <= c->width) {
      int y,waste;
      y = stbrp__skyline_find_min_y(c, node, node->x, width, &waste);
      if (c->heuristic == STBRP_HEURISTIC_Skyline_BL_sortHeight) { // actually just want to test BL
         // bottom left
         if (y < best_y) {
            best_y = y;
            best = prev;
         }
      } else {
         // best-fit
         if (y + height <= c->height) {
            // can only use it if it first vertically
            if (y < best_y || (y == best_y && waste < best_waste)) {
               best_y = y;
               best_waste = waste;
               best = prev;
            }
         }
      }
      prev = &node->next;
      node = node->next;
   }

   best_x = (best == NULL) ? 0 : (*best)->x;

   // if doing best-fit (BF), we also have to try aligning right edge to each node position
   //
   // e.g, if fitting
   //
   //     ____________________
   //    |____________________|
   //
   //            into
   //
   //   |                         |
   //   |             ____________|
   //   |____________|
   //
   // then right-aligned reduces waste, but bottom-left BL is always chooses left-aligned
   //
   // This makes BF take about 2x the time

   if (c->heuristic == STBRP_HEURISTIC_Skyline_BF_sortHeight) {
      tail = c->active_head;
      node = c->active_head;
      prev = &c->active_head;
      // find first node that's admissible
      while (tail->x < width)
         tail = tail->next;
      while (tail) {
         int xpos = tail->x - width;
         int y,waste;
         STBRP_ASSERT(xpos >= 0);
         // find the left position that matches this
         while (node->next->x <= xpos) {
            prev = &node->next;
            node = node->next;
         }
         STBRP_ASSERT(node->next->x > xpos && node->x <= xpos);
         y = stbrp__skyline_find_min_y(c, node, xpos, width, &waste);
         if (y + height < c->height) {
            if (y <= best_y) {
               if (y < best_y || waste < best_waste || (waste==best_waste && xpos < best_x)) {
                  best_x = xpos;
                  STBRP_ASSERT(y <= best_y);
                  best_y = y;
                  best_waste = waste;
                  best = prev;
               }
            }
         }
         tail = tail->next;
      }         
   }

   fr.prev_link = best;
   fr.x = best_x;
   fr.y = best_y;
   return fr;
}

static stbrp__findresult stbrp__skyline_pack_rectangle(stbrp_context *context, int width, int height)
{
   // find best position according to heuristic
   stbrp__findresult res = stbrp__skyline_find_best_pos(context, width, height);
   stbrp_node *node, *cur;

   // bail if:
   //    1. it failed
   //    2. the best node doesn't fit (we don't always check this)
   //    3. we're out of memory
   if (res.prev_link == NULL || res.y + height > context->height || context->free_head == NULL) {
      res.prev_link = NULL;
      return res;
   }

   // on success, create new node
   node = context->free_head;
   node->x = (stbrp_coord) res.x;
   node->y = (stbrp_coord) (res.y + height);

   context->free_head = node->next;

   // insert the new node into the right starting point, and
   // let 'cur' point to the remaining nodes needing to be
   // stiched back in

   cur = *res.prev_link;
   if (cur->x < res.x) {
      // preserve the existing one, so start testing with the next one
      stbrp_node *next = cur->next;
      cur->next = node;
      cur = next;
   } else {
      *res.prev_link = node;
   }

   // from here, traverse cur and free the nodes, until we get to one
   // that shouldn't be freed
   while (cur->next && cur->next->x <= res.x + width) {
      stbrp_node *next = cur->next;
      // move the current node to the free list
      cur->next = context->free_head;
      context->free_head = cur;
      cur = next;
   }

   // stitch the list back in
   node->next = cur;

   if (cur->x < res.x + width)
      cur->x = (stbrp_coord) (res.x + width);

#ifdef _DEBUG
   cur = context->active_head;
   while (cur->x < context->width) {
      STBRP_ASSERT(cur->x < cur->next->x);
      cur = cur->next;
   }
   STBRP_ASSERT(cur->next == NULL);

   {
      stbrp_node *L1 = NULL, *L2 = NULL;
      int count=0;
      cur = context->active_head;
      while (cur) {
         L1 = cur;
         cur = cur->next;
         ++count;
      }
      cur = context->free_head;
      while (cur) {
         L2 = cur;
         cur = cur->next;
         ++count;
      }
      STBRP_ASSERT(count == context->num_nodes+2);
   }
#endif

   return res;
}

static int rect_height_compare(const void *a, const void *b)
{
   stbrp_rect *p = (stbrp_rect *) a;
   stbrp_rect *q = (stbrp_rect *) b;
   if (p->h > q->h)
      return -1;
   if (p->h < q->h)
      return  1;
   return (p->w > q->w) ? -1 : (p->w < q->w);
}

static int rect_width_compare(const void *a, const void *b)
{
   stbrp_rect *p = (stbrp_rect *) a;
   stbrp_rect *q = (stbrp_rect *) b;
   if (p->w > q->w)
      return -1;
   if (p->w < q->w)
      return  1;
   return (p->h > q->h) ? -1 : (p->h < q->h);
}

static int rect_original_order(const void *a, const void *b)
{
   stbrp_rect *p = (stbrp_rect *) a;
   stbrp_rect *q = (stbrp_rect *) b;
   return (p->was_packed < q->was_packed) ? -1 : (p->was_packed > q->was_packed);
}

#ifdef STBRP_LARGE_RECTS
#define STBRP__MAXVAL  0xffffffff
#else
#define STBRP__MAXVAL  0xffff
#endif

STBRP_DEF void stbrp_pack_rects(stbrp_context *context, stbrp_rect *rects, int num_rects)
{
   int i;

   // we use the 'was_packed' field internally to allow sorting/unsorting
   for (i=0; i < num_rects; ++i) {
      rects[i].was_packed = i;
      #ifndef STBRP_LARGE_RECTS
      STBRP_ASSERT(rects[i].w <= 0xffff && rects[i].h <= 0xffff);
      #endif
   }

   // sort according to heuristic
   STBRP_SORT(rects, num_rects, sizeof(rects[0]), rect_height_compare);

   for (i=0; i < num_rects; ++i) {
      if (rects[i].w == 0 || rects[i].h == 0) {
         rects[i].x = rects[i].y = 0;  // empty rect needs no space
      } else {
         stbrp__findresult fr = stbrp__skyline_pack_rectangle(context, rects[i].w, rects[i].h);
         if (fr.prev_link) {
            rects[i].x = (stbrp_coord) fr.x;
            rects[i].y = (stbrp_coord) fr.y;
         } else {
            rects[i].x = rects[i].y = STBRP__MAXVAL;
         }
      }
   }

   // unsort
   STBRP_SORT(rects, num_rects, sizeof(rects[0]), rect_original_order);

   // set was_packed flags
   for (i=0; i < num_rects; ++i)
      rects[i].was_packed = !(rects[i].x == STBRP__MAXVAL && rects[i].y == STBRP__MAXVAL);
}
#endif
