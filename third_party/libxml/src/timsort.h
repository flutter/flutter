/*
 * taken from https://github.com/swenson/sort
 * Kept as is for the moment to be able to apply upstream patches for that
 * code, currently used only to speed up XPath node sorting, see xpath.c
 */

/*
 * All code in this header, unless otherwise specified, is hereby licensed under the MIT Public License:

Copyright (c) 2010 Christopher Swenson

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#ifdef HAVE_STDINT_H
#include <stdint.h>
#else
#ifdef HAVE_INTTYPES_H
#include <inttypes.h>
#elif defined(WIN32)
typedef __int64 int64_t;
typedef unsigned __int64 uint64_t;
#endif
#endif

#ifndef MK_UINT64
#if defined(WIN32) && defined(_MSC_VER) && _MSC_VER < 1300
#define MK_UINT64(x) ((uint64_t)(x))
#else
#define MK_UINT64(x) x##ULL
#endif
#endif

#ifndef MAX
#define MAX(x,y) (((x) > (y) ? (x) : (y)))
#endif
#ifndef MIN
#define MIN(x,y) (((x) < (y) ? (x) : (y)))
#endif

int compute_minrun(uint64_t);

#ifndef CLZ
#if defined(__GNUC__) && ((__GNUC__ == 3 && __GNUC_MINOR__ >= 4) || (__GNUC__ > 3))
#define CLZ __builtin_clzll
#else

int clzll(uint64_t);

/* adapted from Hacker's Delight */
int clzll(uint64_t x) /* {{{ */
{
  int n;

  if (x == 0) return(64);
  n = 0;
  if (x <= MK_UINT64(0x00000000FFFFFFFF)) {n = n + 32; x = x << 32;}
  if (x <= MK_UINT64(0x0000FFFFFFFFFFFF)) {n = n + 16; x = x << 16;}
  if (x <= MK_UINT64(0x00FFFFFFFFFFFFFF)) {n = n + 8; x = x << 8;}
  if (x <= MK_UINT64(0x0FFFFFFFFFFFFFFF)) {n = n + 4; x = x << 4;}
  if (x <= MK_UINT64(0x3FFFFFFFFFFFFFFF)) {n = n + 2; x = x << 2;}
  if (x <= MK_UINT64(0x7FFFFFFFFFFFFFFF)) {n = n + 1;}
  return n;
}
/* }}} */

#define CLZ clzll
#endif
#endif

int compute_minrun(uint64_t size) /* {{{ */
{
  const int top_bit = 64 - CLZ(size);
  const int shift = MAX(top_bit, 6) - 6;
  const int minrun = size >> shift;
  const uint64_t mask = (MK_UINT64(1) << shift) - 1;
  if (mask & size) return minrun + 1;
  return minrun;
}
/* }}} */

#ifndef SORT_NAME
#error "Must declare SORT_NAME"
#endif

#ifndef SORT_TYPE
#error "Must declare SORT_TYPE"
#endif

#ifndef SORT_CMP
#define SORT_CMP(x, y)  ((x) < (y) ? -1 : ((x) == (y) ? 0 : 1))
#endif


#define SORT_SWAP(x,y) {SORT_TYPE __SORT_SWAP_t = (x); (x) = (y); (y) = __SORT_SWAP_t;}

#define SORT_CONCAT(x, y) x ## _ ## y
#define SORT_MAKE_STR1(x, y) SORT_CONCAT(x,y)
#define SORT_MAKE_STR(x) SORT_MAKE_STR1(SORT_NAME,x)

#define BINARY_INSERTION_FIND  SORT_MAKE_STR(binary_insertion_find)
#define BINARY_INSERTION_SORT_START SORT_MAKE_STR(binary_insertion_sort_start)
#define BINARY_INSERTION_SORT  SORT_MAKE_STR(binary_insertion_sort)
#define REVERSE_ELEMENTS       SORT_MAKE_STR(reverse_elements)
#define COUNT_RUN              SORT_MAKE_STR(count_run)
#define CHECK_INVARIANT        SORT_MAKE_STR(check_invariant)
#define TIM_SORT               SORT_MAKE_STR(tim_sort)
#define TIM_SORT_RESIZE        SORT_MAKE_STR(tim_sort_resize)
#define TIM_SORT_MERGE         SORT_MAKE_STR(tim_sort_merge)
#define TIM_SORT_COLLAPSE      SORT_MAKE_STR(tim_sort_collapse)

#define TIM_SORT_RUN_T         SORT_MAKE_STR(tim_sort_run_t)
#define TEMP_STORAGE_T         SORT_MAKE_STR(temp_storage_t)

typedef struct {
  int64_t start;
  int64_t length;
} TIM_SORT_RUN_T;

void BINARY_INSERTION_SORT(SORT_TYPE *dst, const size_t size);
void TIM_SORT(SORT_TYPE *dst, const size_t size);

/* Function used to do a binary search for binary insertion sort */
static int64_t BINARY_INSERTION_FIND(SORT_TYPE *dst, const SORT_TYPE x, const size_t size)
{
  int64_t l, c, r;
  SORT_TYPE lx;
  SORT_TYPE cx;
  l = 0;
  r = size - 1;
  c = r >> 1;
  lx = dst[l];

  /* check for beginning conditions */
  if (SORT_CMP(x, lx) < 0)
    return 0;
  else if (SORT_CMP(x, lx) == 0)
  {
    int64_t i = 1;
    while (SORT_CMP(x, dst[i]) == 0) i++;
    return i;
  }

  cx = dst[c];
  while (1)
  {
    const int val = SORT_CMP(x, cx);
    if (val < 0)
    {
      if (c - l <= 1) return c;
      r = c;
    }
    else if (val > 0)
    {
      if (r - c <= 1) return c + 1;
      l = c;
      lx = cx;
    }
    else
    {
      do
      {
        cx = dst[++c];
      } while (SORT_CMP(x, cx) == 0);
      return c;
    }
    c = l + ((r - l) >> 1);
    cx = dst[c];
  }
}

/* Binary insertion sort, but knowing that the first "start" entries are sorted.  Used in timsort. */
static void BINARY_INSERTION_SORT_START(SORT_TYPE *dst, const size_t start, const size_t size)
{
  int64_t i;
  for (i = start; i < (int64_t) size; i++)
  {
    int64_t j;
    SORT_TYPE x;
    int64_t location;
    /* If this entry is already correct, just move along */
    if (SORT_CMP(dst[i - 1], dst[i]) <= 0) continue;

    /* Else we need to find the right place, shift everything over, and squeeze in */
    x = dst[i];
    location = BINARY_INSERTION_FIND(dst, x, i);
    for (j = i - 1; j >= location; j--)
    {
      dst[j + 1] = dst[j];
    }
    dst[location] = x;
  }
}

/* Binary insertion sort */
void BINARY_INSERTION_SORT(SORT_TYPE *dst, const size_t size)
{
  BINARY_INSERTION_SORT_START(dst, 1, size);
}

/* timsort implementation, based on timsort.txt */

static void REVERSE_ELEMENTS(SORT_TYPE *dst, int64_t start, int64_t end)
{
  while (1)
  {
    if (start >= end) return;
    SORT_SWAP(dst[start], dst[end]);
    start++;
    end--;
  }
}

static int64_t COUNT_RUN(SORT_TYPE *dst, const int64_t start, const size_t size)
{
  int64_t curr;
  if (size - start == 1) return 1;
  if (start >= (int64_t) size - 2)
  {
    if (SORT_CMP(dst[size - 2], dst[size - 1]) > 0)
      SORT_SWAP(dst[size - 2], dst[size - 1]);
    return 2;
  }

  curr = start + 2;

  if (SORT_CMP(dst[start], dst[start + 1]) <= 0)
  {
    /* increasing run */
    while (1)
    {
      if (curr == (int64_t) size - 1) break;
      if (SORT_CMP(dst[curr - 1], dst[curr]) > 0) break;
      curr++;
    }
    return curr - start;
  }
  else
  {
    /* decreasing run */
    while (1)
    {
      if (curr == (int64_t) size - 1) break;
      if (SORT_CMP(dst[curr - 1], dst[curr]) <= 0) break;
      curr++;
    }
    /* reverse in-place */
    REVERSE_ELEMENTS(dst, start, curr - 1);
    return curr - start;
  }
}

#define PUSH_NEXT() do {\
len = COUNT_RUN(dst, curr, size);\
run = minrun;\
if (run < minrun) run = minrun;\
if (run > (int64_t) size - curr) run = size - curr;\
if (run > len)\
{\
  BINARY_INSERTION_SORT_START(&dst[curr], len, run);\
  len = run;\
}\
{\
run_stack[stack_curr].start = curr;\
run_stack[stack_curr].length = len;\
stack_curr++;\
}\
curr += len;\
if (curr == (int64_t) size)\
{\
  /* finish up */ \
  while (stack_curr > 1) \
  { \
    TIM_SORT_MERGE(dst, run_stack, stack_curr, store); \
    run_stack[stack_curr - 2].length += run_stack[stack_curr - 1].length; \
    stack_curr--; \
  } \
  if (store->storage != NULL)\
  {\
    free(store->storage);\
    store->storage = NULL;\
  }\
  return;\
}\
}\
while (0)

static int CHECK_INVARIANT(TIM_SORT_RUN_T *stack, const int stack_curr)
{
  int64_t A, B, C;
  if (stack_curr < 2) return 1;
  if (stack_curr == 2)
  {
    const int64_t A1 = stack[stack_curr - 2].length;
    const int64_t B1 = stack[stack_curr - 1].length;
    if (A1 <= B1) return 0;
    return 1;
  }
  A = stack[stack_curr - 3].length;
  B = stack[stack_curr - 2].length;
  C = stack[stack_curr - 1].length;
  if ((A <= B + C) || (B <= C)) return 0;
  return 1;
}

typedef struct {
  size_t alloc;
  SORT_TYPE *storage;
} TEMP_STORAGE_T;


static void TIM_SORT_RESIZE(TEMP_STORAGE_T *store, const size_t new_size)
{
  if (store->alloc < new_size)
  {
    SORT_TYPE *tempstore = (SORT_TYPE *)realloc(store->storage, new_size * sizeof(SORT_TYPE));
    if (tempstore == NULL)
    {
      fprintf(stderr, "Error allocating temporary storage for tim sort: need %llu bytes", (unsigned long long)(sizeof(SORT_TYPE) * new_size));
      exit(1);
    }
    store->storage = tempstore;
    store->alloc = new_size;
  }
}

static void TIM_SORT_MERGE(SORT_TYPE *dst, const TIM_SORT_RUN_T *stack, const int stack_curr, TEMP_STORAGE_T *store)
{
  const int64_t A = stack[stack_curr - 2].length;
  const int64_t B = stack[stack_curr - 1].length;
  const int64_t curr = stack[stack_curr - 2].start;
  SORT_TYPE *storage;
  int64_t i, j, k;

  TIM_SORT_RESIZE(store, MIN(A, B));
  storage = store->storage;

  /* left merge */
  if (A < B)
  {
    memcpy(storage, &dst[curr], A * sizeof(SORT_TYPE));
    i = 0;
    j = curr + A;

    for (k = curr; k < curr + A + B; k++)
    {
      if ((i < A) && (j < curr + A + B))
      {
        if (SORT_CMP(storage[i], dst[j]) <= 0)
          dst[k] = storage[i++];
        else
          dst[k] = dst[j++];
      }
      else if (i < A)
      {
        dst[k] = storage[i++];
      }
      else
        dst[k] = dst[j++];
    }
  }
  /* right merge */
  else
  {
    memcpy(storage, &dst[curr + A], B * sizeof(SORT_TYPE));
    i = B - 1;
    j = curr + A - 1;

    for (k = curr + A + B - 1; k >= curr; k--)
    {
      if ((i >= 0) && (j >= curr))
      {
          if (SORT_CMP(dst[j], storage[i]) > 0)
            dst[k] = dst[j--];
          else
            dst[k] = storage[i--];
      }
      else if (i >= 0)
        dst[k] = storage[i--];
      else
        dst[k] = dst[j--];
    }
  }
}

static int TIM_SORT_COLLAPSE(SORT_TYPE *dst, TIM_SORT_RUN_T *stack, int stack_curr, TEMP_STORAGE_T *store, const size_t size)
{
  while (1)
  {
    int64_t A, B, C;
    /* if the stack only has one thing on it, we are done with the collapse */
    if (stack_curr <= 1) break;
    /* if this is the last merge, just do it */
    if ((stack_curr == 2) &&
        (stack[0].length + stack[1].length == (int64_t) size))
    {
      TIM_SORT_MERGE(dst, stack, stack_curr, store);
      stack[0].length += stack[1].length;
      stack_curr--;
      break;
    }
    /* check if the invariant is off for a stack of 2 elements */
    else if ((stack_curr == 2) && (stack[0].length <= stack[1].length))
    {
      TIM_SORT_MERGE(dst, stack, stack_curr, store);
      stack[0].length += stack[1].length;
      stack_curr--;
      break;
    }
    else if (stack_curr == 2)
      break;

    A = stack[stack_curr - 3].length;
    B = stack[stack_curr - 2].length;
    C = stack[stack_curr - 1].length;

    /* check first invariant */
    if (A <= B + C)
    {
      if (A < C)
      {
        TIM_SORT_MERGE(dst, stack, stack_curr - 1, store);
        stack[stack_curr - 3].length += stack[stack_curr - 2].length;
        stack[stack_curr - 2] = stack[stack_curr - 1];
        stack_curr--;
      }
      else
      {
        TIM_SORT_MERGE(dst, stack, stack_curr, store);
        stack[stack_curr - 2].length += stack[stack_curr - 1].length;
        stack_curr--;
      }
    }
    /* check second invariant */
    else if (B <= C)
    {
      TIM_SORT_MERGE(dst, stack, stack_curr, store);
      stack[stack_curr - 2].length += stack[stack_curr - 1].length;
      stack_curr--;
    }
    else
      break;
  }
  return stack_curr;
}

void TIM_SORT(SORT_TYPE *dst, const size_t size)
{
  int minrun;
  TEMP_STORAGE_T _store, *store;
  TIM_SORT_RUN_T run_stack[128];
  int stack_curr = 0;
  int64_t len, run;
  int64_t curr = 0;

  if (size < 64)
  {
    BINARY_INSERTION_SORT(dst, size);
    return;
  }

  /* compute the minimum run length */
  minrun = compute_minrun(size);

  /* temporary storage for merges */
  store = &_store;
  store->alloc = 0;
  store->storage = NULL;

  PUSH_NEXT();
  PUSH_NEXT();
  PUSH_NEXT();

  while (1)
  {
    if (!CHECK_INVARIANT(run_stack, stack_curr))
    {
      stack_curr = TIM_SORT_COLLAPSE(dst, run_stack, stack_curr, store, size);
      continue;
    }
    PUSH_NEXT();
  }
}

#undef SORT_CONCAT
#undef SORT_MAKE_STR1
#undef SORT_MAKE_STR
#undef SORT_NAME
#undef SORT_TYPE
#undef SORT_CMP
#undef TEMP_STORAGE_T
#undef TIM_SORT_RUN_T
#undef PUSH_NEXT
#undef SORT_SWAP
#undef SORT_CONCAT
#undef SORT_MAKE_STR1
#undef SORT_MAKE_STR
#undef BINARY_INSERTION_FIND
#undef BINARY_INSERTION_SORT_START
#undef BINARY_INSERTION_SORT
#undef REVERSE_ELEMENTS
#undef COUNT_RUN
#undef TIM_SORT
#undef TIM_SORT_RESIZE
#undef TIM_SORT_COLLAPSE
#undef TIM_SORT_RUN_T
#undef TEMP_STORAGE_T
