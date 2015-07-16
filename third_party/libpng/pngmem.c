
/* pngmem.c - stub functions for memory allocation
 *
 * Last changed in libpng 1.2.41 [February 25, 2010]
 * Copyright (c) 1998-2010 Glenn Randers-Pehrson
 * (Version 0.96 Copyright (c) 1996, 1997 Andreas Dilger)
 * (Version 0.88 Copyright (c) 1995, 1996 Guy Eric Schalnat, Group 42, Inc.)
 *
 * This code is released under the libpng license.
 * For conditions of distribution and use, see the disclaimer
 * and license in png.h
 *
 * This file provides a location for all memory allocation.  Users who
 * need special memory handling are expected to supply replacement
 * functions for png_malloc() and png_free(), and to use
 * png_create_read_struct_2() and png_create_write_struct_2() to
 * identify the replacement functions.
 */

#define PNG_INTERNAL
#define PNG_NO_PEDANTIC_WARNINGS
#include "png.h"
#if defined(PNG_READ_SUPPORTED) || defined(PNG_WRITE_SUPPORTED)

/* Borland DOS special memory handler */
#if defined(__TURBOC__) && !defined(_Windows) && !defined(__FLAT__)
/* If you change this, be sure to change the one in png.h also */

/* Allocate memory for a png_struct.  The malloc and memset can be replaced
   by a single call to calloc() if this is thought to improve performance. */
png_voidp /* PRIVATE */
png_create_struct(int type)
{
#ifdef PNG_USER_MEM_SUPPORTED
   return (png_create_struct_2(type, png_malloc_ptr_NULL, png_voidp_NULL));
}

/* Alternate version of png_create_struct, for use with user-defined malloc. */
png_voidp /* PRIVATE */
png_create_struct_2(int type, png_malloc_ptr malloc_fn, png_voidp mem_ptr)
{
#endif /* PNG_USER_MEM_SUPPORTED */
   png_size_t size;
   png_voidp struct_ptr;

   if (type == PNG_STRUCT_INFO)
      size = png_sizeof(png_info);
   else if (type == PNG_STRUCT_PNG)
      size = png_sizeof(png_struct);
   else
      return (png_get_copyright(NULL));

#ifdef PNG_USER_MEM_SUPPORTED
   if (malloc_fn != NULL)
   {
      png_struct dummy_struct;
      png_structp png_ptr = &dummy_struct;
      png_ptr->mem_ptr=mem_ptr;
      struct_ptr = (*(malloc_fn))(png_ptr, (png_uint_32)size);
   }
   else
#endif /* PNG_USER_MEM_SUPPORTED */
   struct_ptr = (png_voidp)farmalloc(size);
   if (struct_ptr != NULL)
      png_memset(struct_ptr, 0, size);
   return (struct_ptr);
}

/* Free memory allocated by a png_create_struct() call */
void /* PRIVATE */
png_destroy_struct(png_voidp struct_ptr)
{
#ifdef PNG_USER_MEM_SUPPORTED
   png_destroy_struct_2(struct_ptr, png_free_ptr_NULL, png_voidp_NULL);
}

/* Free memory allocated by a png_create_struct() call */
void /* PRIVATE */
png_destroy_struct_2(png_voidp struct_ptr, png_free_ptr free_fn,
    png_voidp mem_ptr)
{
#endif
   if (struct_ptr != NULL)
   {
#ifdef PNG_USER_MEM_SUPPORTED
      if (free_fn != NULL)
      {
         png_struct dummy_struct;
         png_structp png_ptr = &dummy_struct;
         png_ptr->mem_ptr=mem_ptr;
         (*(free_fn))(png_ptr, struct_ptr);
         return;
      }
#endif /* PNG_USER_MEM_SUPPORTED */
      farfree (struct_ptr);
   }
}

/* Allocate memory.  For reasonable files, size should never exceed
 * 64K.  However, zlib may allocate more then 64K if you don't tell
 * it not to.  See zconf.h and png.h for more information. zlib does
 * need to allocate exactly 64K, so whatever you call here must
 * have the ability to do that.
 *
 * Borland seems to have a problem in DOS mode for exactly 64K.
 * It gives you a segment with an offset of 8 (perhaps to store its
 * memory stuff).  zlib doesn't like this at all, so we have to
 * detect and deal with it.  This code should not be needed in
 * Windows or OS/2 modes, and only in 16 bit mode.  This code has
 * been updated by Alexander Lehmann for version 0.89 to waste less
 * memory.
 *
 * Note that we can't use png_size_t for the "size" declaration,
 * since on some systems a png_size_t is a 16-bit quantity, and as a
 * result, we would be truncating potentially larger memory requests
 * (which should cause a fatal error) and introducing major problems.
 */
png_voidp /* PRIVATE */
png_calloc(png_structp png_ptr, png_uint_32 size)
{
   png_voidp ret;

   ret = (png_malloc(png_ptr, size));
   if (ret != NULL)
      png_memset(ret,0,(png_size_t)size);
   return (ret);
}

png_voidp PNGAPI
png_malloc(png_structp png_ptr, png_uint_32 size)
{
   png_voidp ret;

   if (png_ptr == NULL || size == 0)
      return (NULL);

#ifdef PNG_USER_MEM_SUPPORTED
   if (png_ptr->malloc_fn != NULL)
      ret = ((png_voidp)(*(png_ptr->malloc_fn))(png_ptr, (png_size_t)size));
   else
      ret = (png_malloc_default(png_ptr, size));
   if (ret == NULL && (png_ptr->flags&PNG_FLAG_MALLOC_NULL_MEM_OK) == 0)
       png_error(png_ptr, "Out of memory!");
   return (ret);
}

png_voidp PNGAPI
png_malloc_default(png_structp png_ptr, png_uint_32 size)
{
   png_voidp ret;
#endif /* PNG_USER_MEM_SUPPORTED */

   if (png_ptr == NULL || size == 0)
      return (NULL);

#ifdef PNG_MAX_MALLOC_64K
   if (size > (png_uint_32)65536L)
   {
      png_warning(png_ptr, "Cannot Allocate > 64K");
      ret = NULL;
   }
   else
#endif

   if (size != (size_t)size)
      ret = NULL;
   else if (size == (png_uint_32)65536L)
   {
      if (png_ptr->offset_table == NULL)
      {
         /* Try to see if we need to do any of this fancy stuff */
         ret = farmalloc(size);
         if (ret == NULL || ((png_size_t)ret & 0xffff))
         {
            int num_blocks;
            png_uint_32 total_size;
            png_bytep table;
            int i;
            png_byte huge * hptr;

            if (ret != NULL)
            {
               farfree(ret);
               ret = NULL;
            }

            if (png_ptr->zlib_window_bits > 14)
               num_blocks = (int)(1 << (png_ptr->zlib_window_bits - 14));
            else
               num_blocks = 1;
            if (png_ptr->zlib_mem_level >= 7)
               num_blocks += (int)(1 << (png_ptr->zlib_mem_level - 7));
            else
               num_blocks++;

            total_size = ((png_uint_32)65536L) * (png_uint_32)num_blocks+16;

            table = farmalloc(total_size);

            if (table == NULL)
            {
#ifndef PNG_USER_MEM_SUPPORTED
               if ((png_ptr->flags&PNG_FLAG_MALLOC_NULL_MEM_OK) == 0)
                  png_error(png_ptr, "Out Of Memory."); /* Note "O", "M" */
               else
                  png_warning(png_ptr, "Out Of Memory.");
#endif
               return (NULL);
            }

            if ((png_size_t)table & 0xfff0)
            {
#ifndef PNG_USER_MEM_SUPPORTED
               if ((png_ptr->flags&PNG_FLAG_MALLOC_NULL_MEM_OK) == 0)
                  png_error(png_ptr,
                    "Farmalloc didn't return normalized pointer");
               else
                  png_warning(png_ptr,
                    "Farmalloc didn't return normalized pointer");
#endif
               return (NULL);
            }

            png_ptr->offset_table = table;
            png_ptr->offset_table_ptr = farmalloc(num_blocks *
               png_sizeof(png_bytep));

            if (png_ptr->offset_table_ptr == NULL)
            {
#ifndef PNG_USER_MEM_SUPPORTED
               if ((png_ptr->flags&PNG_FLAG_MALLOC_NULL_MEM_OK) == 0)
                  png_error(png_ptr, "Out Of memory."); /* Note "O", "m" */
               else
                  png_warning(png_ptr, "Out Of memory.");
#endif
               return (NULL);
            }

            hptr = (png_byte huge *)table;
            if ((png_size_t)hptr & 0xf)
            {
               hptr = (png_byte huge *)((long)(hptr) & 0xfffffff0L);
               hptr = hptr + 16L;  /* "hptr += 16L" fails on Turbo C++ 3.0 */
            }
            for (i = 0; i < num_blocks; i++)
            {
               png_ptr->offset_table_ptr[i] = (png_bytep)hptr;
               hptr = hptr + (png_uint_32)65536L;  /* "+=" fails on TC++3.0 */
            }

            png_ptr->offset_table_number = num_blocks;
            png_ptr->offset_table_count = 0;
            png_ptr->offset_table_count_free = 0;
         }
      }

      if (png_ptr->offset_table_count >= png_ptr->offset_table_number)
      {
#ifndef PNG_USER_MEM_SUPPORTED
         if ((png_ptr->flags&PNG_FLAG_MALLOC_NULL_MEM_OK) == 0)
            png_error(png_ptr, "Out of Memory."); /* Note "o" and "M" */
         else
            png_warning(png_ptr, "Out of Memory.");
#endif
         return (NULL);
      }

      ret = png_ptr->offset_table_ptr[png_ptr->offset_table_count++];
   }
   else
      ret = farmalloc(size);

#ifndef PNG_USER_MEM_SUPPORTED
   if (ret == NULL)
   {
      if ((png_ptr->flags&PNG_FLAG_MALLOC_NULL_MEM_OK) == 0)
         png_error(png_ptr, "Out of memory."); /* Note "o" and "m" */
      else
         png_warning(png_ptr, "Out of memory."); /* Note "o" and "m" */
   }
#endif

   return (ret);
}

/* Free a pointer allocated by png_malloc().  In the default
 * configuration, png_ptr is not used, but is passed in case it
 * is needed.  If ptr is NULL, return without taking any action.
 */
void PNGAPI
png_free(png_structp png_ptr, png_voidp ptr)
{
   if (png_ptr == NULL || ptr == NULL)
      return;

#ifdef PNG_USER_MEM_SUPPORTED
   if (png_ptr->free_fn != NULL)
   {
      (*(png_ptr->free_fn))(png_ptr, ptr);
      return;
   }
   else
      png_free_default(png_ptr, ptr);
}

void PNGAPI
png_free_default(png_structp png_ptr, png_voidp ptr)
{
#endif /* PNG_USER_MEM_SUPPORTED */

   if (png_ptr == NULL || ptr == NULL)
      return;

   if (png_ptr->offset_table != NULL)
   {
      int i;

      for (i = 0; i < png_ptr->offset_table_count; i++)
      {
         if (ptr == png_ptr->offset_table_ptr[i])
         {
            ptr = NULL;
            png_ptr->offset_table_count_free++;
            break;
         }
      }
      if (png_ptr->offset_table_count_free == png_ptr->offset_table_count)
      {
         farfree(png_ptr->offset_table);
         farfree(png_ptr->offset_table_ptr);
         png_ptr->offset_table = NULL;
         png_ptr->offset_table_ptr = NULL;
      }
   }

   if (ptr != NULL)
   {
      farfree(ptr);
   }
}

#else /* Not the Borland DOS special memory handler */

/* Allocate memory for a png_struct or a png_info.  The malloc and
   memset can be replaced by a single call to calloc() if this is thought
   to improve performance noticably. */
png_voidp /* PRIVATE */
png_create_struct(int type)
{
#ifdef PNG_USER_MEM_SUPPORTED
   return (png_create_struct_2(type, png_malloc_ptr_NULL, png_voidp_NULL));
}

/* Allocate memory for a png_struct or a png_info.  The malloc and
   memset can be replaced by a single call to calloc() if this is thought
   to improve performance noticably. */
png_voidp /* PRIVATE */
png_create_struct_2(int type, png_malloc_ptr malloc_fn, png_voidp mem_ptr)
{
#endif /* PNG_USER_MEM_SUPPORTED */
   png_size_t size;
   png_voidp struct_ptr;

   if (type == PNG_STRUCT_INFO)
      size = png_sizeof(png_info);
   else if (type == PNG_STRUCT_PNG)
      size = png_sizeof(png_struct);
   else
      return (NULL);

#ifdef PNG_USER_MEM_SUPPORTED
   if (malloc_fn != NULL)
   {
      png_struct dummy_struct;
      png_structp png_ptr = &dummy_struct;
      png_ptr->mem_ptr=mem_ptr;
      struct_ptr = (*(malloc_fn))(png_ptr, size);
      if (struct_ptr != NULL)
         png_memset(struct_ptr, 0, size);
      return (struct_ptr);
   }
#endif /* PNG_USER_MEM_SUPPORTED */

#if defined(__TURBOC__) && !defined(__FLAT__)
   struct_ptr = (png_voidp)farmalloc(size);
#else
# if defined(_MSC_VER) && defined(MAXSEG_64K)
   struct_ptr = (png_voidp)halloc(size, 1);
# else
   struct_ptr = (png_voidp)malloc(size);
# endif
#endif
   if (struct_ptr != NULL)
      png_memset(struct_ptr, 0, size);

   return (struct_ptr);
}


/* Free memory allocated by a png_create_struct() call */
void /* PRIVATE */
png_destroy_struct(png_voidp struct_ptr)
{
#ifdef PNG_USER_MEM_SUPPORTED
   png_destroy_struct_2(struct_ptr, png_free_ptr_NULL, png_voidp_NULL);
}

/* Free memory allocated by a png_create_struct() call */
void /* PRIVATE */
png_destroy_struct_2(png_voidp struct_ptr, png_free_ptr free_fn,
    png_voidp mem_ptr)
{
#endif /* PNG_USER_MEM_SUPPORTED */
   if (struct_ptr != NULL)
   {
#ifdef PNG_USER_MEM_SUPPORTED
      if (free_fn != NULL)
      {
         png_struct dummy_struct;
         png_structp png_ptr = &dummy_struct;
         png_ptr->mem_ptr=mem_ptr;
         (*(free_fn))(png_ptr, struct_ptr);
         return;
      }
#endif /* PNG_USER_MEM_SUPPORTED */
#if defined(__TURBOC__) && !defined(__FLAT__)
      farfree(struct_ptr);
#else
# if defined(_MSC_VER) && defined(MAXSEG_64K)
      hfree(struct_ptr);
# else
      free(struct_ptr);
# endif
#endif
   }
}

/* Allocate memory.  For reasonable files, size should never exceed
 * 64K.  However, zlib may allocate more then 64K if you don't tell
 * it not to.  See zconf.h and png.h for more information.  zlib does
 * need to allocate exactly 64K, so whatever you call here must
 * have the ability to do that.
 */

png_voidp /* PRIVATE */
png_calloc(png_structp png_ptr, png_uint_32 size)
{
   png_voidp ret;

   ret = (png_malloc(png_ptr, size));
   if (ret != NULL)
      png_memset(ret,0,(png_size_t)size);
   return (ret);
}

png_voidp PNGAPI
png_malloc(png_structp png_ptr, png_uint_32 size)
{
   png_voidp ret;

#ifdef PNG_USER_MEM_SUPPORTED
   if (png_ptr == NULL || size == 0)
      return (NULL);

   if (png_ptr->malloc_fn != NULL)
      ret = ((png_voidp)(*(png_ptr->malloc_fn))(png_ptr, (png_size_t)size));
   else
      ret = (png_malloc_default(png_ptr, size));
   if (ret == NULL && (png_ptr->flags&PNG_FLAG_MALLOC_NULL_MEM_OK) == 0)
       png_error(png_ptr, "Out of Memory!");
   return (ret);
}

png_voidp PNGAPI
png_malloc_default(png_structp png_ptr, png_uint_32 size)
{
   png_voidp ret;
#endif /* PNG_USER_MEM_SUPPORTED */

   if (png_ptr == NULL || size == 0)
      return (NULL);

#ifdef PNG_MAX_MALLOC_64K
   if (size > (png_uint_32)65536L)
   {
#ifndef PNG_USER_MEM_SUPPORTED
      if ((png_ptr->flags&PNG_FLAG_MALLOC_NULL_MEM_OK) == 0)
         png_error(png_ptr, "Cannot Allocate > 64K");
      else
#endif
         return NULL;
   }
#endif

   /* Check for overflow */
#if defined(__TURBOC__) && !defined(__FLAT__)
   if (size != (unsigned long)size)
      ret = NULL;
   else
      ret = farmalloc(size);
#else
# if defined(_MSC_VER) && defined(MAXSEG_64K)
   if (size != (unsigned long)size)
      ret = NULL;
   else
      ret = halloc(size, 1);
# else
   if (size != (size_t)size)
      ret = NULL;
   else
      ret = malloc((size_t)size);
# endif
#endif

#ifndef PNG_USER_MEM_SUPPORTED
   if (ret == NULL && (png_ptr->flags&PNG_FLAG_MALLOC_NULL_MEM_OK) == 0)
      png_error(png_ptr, "Out of Memory");
#endif

   return (ret);
}

/* Free a pointer allocated by png_malloc().  If ptr is NULL, return
 * without taking any action.
 */
void PNGAPI
png_free(png_structp png_ptr, png_voidp ptr)
{
   if (png_ptr == NULL || ptr == NULL)
      return;

#ifdef PNG_USER_MEM_SUPPORTED
   if (png_ptr->free_fn != NULL)
   {
      (*(png_ptr->free_fn))(png_ptr, ptr);
      return;
   }
   else
      png_free_default(png_ptr, ptr);
}
void PNGAPI
png_free_default(png_structp png_ptr, png_voidp ptr)
{
   if (png_ptr == NULL || ptr == NULL)
      return;

#endif /* PNG_USER_MEM_SUPPORTED */

#if defined(__TURBOC__) && !defined(__FLAT__)
   farfree(ptr);
#else
# if defined(_MSC_VER) && defined(MAXSEG_64K)
   hfree(ptr);
# else
   free(ptr);
# endif
#endif
}

#endif /* Not Borland DOS special memory handler */

#ifdef PNG_1_0_X
#  define png_malloc_warn png_malloc
#else
/* This function was added at libpng version 1.2.3.  The png_malloc_warn()
 * function will set up png_malloc() to issue a png_warning and return NULL
 * instead of issuing a png_error, if it fails to allocate the requested
 * memory.
 */
png_voidp PNGAPI
png_malloc_warn(png_structp png_ptr, png_uint_32 size)
{
   png_voidp ptr;
   png_uint_32 save_flags;
   if (png_ptr == NULL)
      return (NULL);

   save_flags = png_ptr->flags;
   png_ptr->flags|=PNG_FLAG_MALLOC_NULL_MEM_OK;
   ptr = (png_voidp)png_malloc((png_structp)png_ptr, size);
   png_ptr->flags=save_flags;
   return(ptr);
}
#endif

png_voidp PNGAPI
png_memcpy_check (png_structp png_ptr, png_voidp s1, png_voidp s2,
   png_uint_32 length)
{
   png_size_t size;

   size = (png_size_t)length;
   if ((png_uint_32)size != length)
      png_error(png_ptr, "Overflow in png_memcpy_check.");

   return(png_memcpy (s1, s2, size));
}

png_voidp PNGAPI
png_memset_check (png_structp png_ptr, png_voidp s1, int value,
   png_uint_32 length)
{
   png_size_t size;

   size = (png_size_t)length;
   if ((png_uint_32)size != length)
      png_error(png_ptr, "Overflow in png_memset_check.");

   return (png_memset (s1, value, size));

}

#ifdef PNG_USER_MEM_SUPPORTED
/* This function is called when the application wants to use another method
 * of allocating and freeing memory.
 */
void PNGAPI
png_set_mem_fn(png_structp png_ptr, png_voidp mem_ptr, png_malloc_ptr
  malloc_fn, png_free_ptr free_fn)
{
   if (png_ptr != NULL)
   {
      png_ptr->mem_ptr = mem_ptr;
      png_ptr->malloc_fn = malloc_fn;
      png_ptr->free_fn = free_fn;
   }
}

/* This function returns a pointer to the mem_ptr associated with the user
 * functions.  The application should free any memory associated with this
 * pointer before png_write_destroy and png_read_destroy are called.
 */
png_voidp PNGAPI
png_get_mem_ptr(png_structp png_ptr)
{
   if (png_ptr == NULL)
      return (NULL);
   return ((png_voidp)png_ptr->mem_ptr);
}
#endif /* PNG_USER_MEM_SUPPORTED */
#endif /* PNG_READ_SUPPORTED || PNG_WRITE_SUPPORTED */
