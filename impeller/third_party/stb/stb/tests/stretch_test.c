// check that stb_truetype compiles with no stb_rect_pack.h
#define STB_TRUETYPE_IMPLEMENTATION
#include "stb_truetype.h"

#include "stretchy_buffer.h"
#include <assert.h>

int main(int arg, char **argv)
{
   int i;
   int *arr = NULL;

   for (i=0; i < 1000000; ++i)
      sb_push(arr, i);

   assert(sb_count(arr) == 1000000);
   for (i=0; i < 1000000; ++i)
      assert(arr[i] == i);

   sb_free(arr);
   arr = NULL;

   for (i=0; i < 1000; ++i)
      sb_add(arr, 1000);
   assert(sb_count(arr) == 1000000);

   return 0;
}