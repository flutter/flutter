
/* png.c - location for general purpose libpng functions
 *
 * Last changed in libpng 1.2.43 [February 25, 2010]
 * Copyright (c) 1998-2010 Glenn Randers-Pehrson
 * (Version 0.96 Copyright (c) 1996, 1997 Andreas Dilger)
 * (Version 0.88 Copyright (c) 1995, 1996 Guy Eric Schalnat, Group 42, Inc.)
 *
 * This code is released under the libpng license.
 * For conditions of distribution and use, see the disclaimer
 * and license in png.h
 */

#define PNG_INTERNAL
#define PNG_NO_EXTERN
#define PNG_NO_PEDANTIC_WARNINGS
#include "png.h"

/* Generate a compiler error if there is an old png.h in the search path. */
typedef version_1_2_45 Your_png_h_is_not_version_1_2_45;

/* Version information for C files.  This had better match the version
 * string defined in png.h.
 */

#ifdef PNG_USE_GLOBAL_ARRAYS
/* png_libpng_ver was changed to a function in version 1.0.5c */
PNG_CONST char png_libpng_ver[18] = PNG_LIBPNG_VER_STRING;

#ifdef PNG_READ_SUPPORTED

/* png_sig was changed to a function in version 1.0.5c */
/* Place to hold the signature string for a PNG file. */
PNG_CONST png_byte FARDATA png_sig[8] = {137, 80, 78, 71, 13, 10, 26, 10};
#endif /* PNG_READ_SUPPORTED */

/* Invoke global declarations for constant strings for known chunk types */
PNG_IHDR;
PNG_IDAT;
PNG_IEND;
PNG_PLTE;
PNG_bKGD;
PNG_cHRM;
PNG_gAMA;
PNG_hIST;
PNG_iCCP;
PNG_iTXt;
PNG_oFFs;
PNG_pCAL;
PNG_sCAL;
PNG_pHYs;
PNG_sBIT;
PNG_sPLT;
PNG_sRGB;
PNG_tEXt;
PNG_tIME;
PNG_tRNS;
PNG_zTXt;

#ifdef PNG_READ_SUPPORTED
/* Arrays to facilitate easy interlacing - use pass (0 - 6) as index */

/* Start of interlace block */
PNG_CONST int FARDATA png_pass_start[] = {0, 4, 0, 2, 0, 1, 0};

/* Offset to next interlace block */
PNG_CONST int FARDATA png_pass_inc[] = {8, 8, 4, 4, 2, 2, 1};

/* Start of interlace block in the y direction */
PNG_CONST int FARDATA png_pass_ystart[] = {0, 0, 4, 0, 2, 0, 1};

/* Offset to next interlace block in the y direction */
PNG_CONST int FARDATA png_pass_yinc[] = {8, 8, 8, 4, 4, 2, 2};

/* Height of interlace block.  This is not currently used - if you need
 * it, uncomment it here and in png.h
PNG_CONST int FARDATA png_pass_height[] = {8, 8, 4, 4, 2, 2, 1};
*/

/* Mask to determine which pixels are valid in a pass */
PNG_CONST int FARDATA png_pass_mask[] =
    {0x80, 0x08, 0x88, 0x22, 0xaa, 0x55, 0xff};

/* Mask to determine which pixels to overwrite while displaying */
PNG_CONST int FARDATA png_pass_dsp_mask[]
   = {0xff, 0x0f, 0xff, 0x33, 0xff, 0x55, 0xff};

#endif /* PNG_READ_SUPPORTED */
#endif /* PNG_USE_GLOBAL_ARRAYS */

/* Tells libpng that we have already handled the first "num_bytes" bytes
 * of the PNG file signature.  If the PNG data is embedded into another
 * stream we can set num_bytes = 8 so that libpng will not attempt to read
 * or write any of the magic bytes before it starts on the IHDR.
 */

#ifdef PNG_READ_SUPPORTED
void PNGAPI
png_set_sig_bytes(png_structp png_ptr, int num_bytes)
{
   png_debug(1, "in png_set_sig_bytes");

   if (png_ptr == NULL)
      return;

   if (num_bytes > 8)
      png_error(png_ptr, "Too many bytes for PNG signature.");

   png_ptr->sig_bytes = (png_byte)(num_bytes < 0 ? 0 : num_bytes);
}

/* Checks whether the supplied bytes match the PNG signature.  We allow
 * checking less than the full 8-byte signature so that those apps that
 * already read the first few bytes of a file to determine the file type
 * can simply check the remaining bytes for extra assurance.  Returns
 * an integer less than, equal to, or greater than zero if sig is found,
 * respectively, to be less than, to match, or be greater than the correct
 * PNG signature (this is the same behaviour as strcmp, memcmp, etc).
 */
int PNGAPI
png_sig_cmp(png_bytep sig, png_size_t start, png_size_t num_to_check)
{
   png_byte png_signature[8] = {137, 80, 78, 71, 13, 10, 26, 10};
   if (num_to_check > 8)
      num_to_check = 8;
   else if (num_to_check < 1)
      return (-1);

   if (start > 7)
      return (-1);

   if (start + num_to_check > 8)
      num_to_check = 8 - start;

   return ((int)(png_memcmp(&sig[start], &png_signature[start], num_to_check)));
}

#if defined(PNG_1_0_X) || defined(PNG_1_2_X)
/* (Obsolete) function to check signature bytes.  It does not allow one
 * to check a partial signature.  This function might be removed in the
 * future - use png_sig_cmp().  Returns true (nonzero) if the file is PNG.
 */
int PNGAPI
png_check_sig(png_bytep sig, int num)
{
  return ((int)!png_sig_cmp(sig, (png_size_t)0, (png_size_t)num));
}
#endif
#endif /* PNG_READ_SUPPORTED */

#if defined(PNG_READ_SUPPORTED) || defined(PNG_WRITE_SUPPORTED)
/* Function to allocate memory for zlib and clear it to 0. */
#ifdef PNG_1_0_X
voidpf PNGAPI
#else
voidpf /* PRIVATE */
#endif
png_zalloc(voidpf png_ptr, uInt items, uInt size)
{
   png_voidp ptr;
   png_structp p=(png_structp)png_ptr;
   png_uint_32 save_flags=p->flags;
   png_uint_32 num_bytes;

   if (png_ptr == NULL)
      return (NULL);
   if (items > PNG_UINT_32_MAX/size)
   {
     png_warning (p, "Potential overflow in png_zalloc()");
     return (NULL);
   }
   num_bytes = (png_uint_32)items * size;

   p->flags|=PNG_FLAG_MALLOC_NULL_MEM_OK;
   ptr = (png_voidp)png_malloc((png_structp)png_ptr, num_bytes);
   p->flags=save_flags;

#if defined(PNG_1_0_X) && !defined(PNG_NO_ZALLOC_ZERO)
   if (ptr == NULL)
       return ((voidpf)ptr);

   if (num_bytes > (png_uint_32)0x8000L)
   {
      png_memset(ptr, 0, (png_size_t)0x8000L);
      png_memset((png_bytep)ptr + (png_size_t)0x8000L, 0,
         (png_size_t)(num_bytes - (png_uint_32)0x8000L));
   }
   else
   {
      png_memset(ptr, 0, (png_size_t)num_bytes);
   }
#endif
   return ((voidpf)ptr);
}

/* Function to free memory for zlib */
#ifdef PNG_1_0_X
void PNGAPI
#else
void /* PRIVATE */
#endif
png_zfree(voidpf png_ptr, voidpf ptr)
{
   png_free((png_structp)png_ptr, (png_voidp)ptr);
}

/* Reset the CRC variable to 32 bits of 1's.  Care must be taken
 * in case CRC is > 32 bits to leave the top bits 0.
 */
void /* PRIVATE */
png_reset_crc(png_structp png_ptr)
{
   png_ptr->crc = crc32(0, Z_NULL, 0);
}

/* Calculate the CRC over a section of data.  We can only pass as
 * much data to this routine as the largest single buffer size.  We
 * also check that this data will actually be used before going to the
 * trouble of calculating it.
 */
void /* PRIVATE */
png_calculate_crc(png_structp png_ptr, png_bytep ptr, png_size_t length)
{
   int need_crc = 1;

   if (png_ptr->chunk_name[0] & 0x20)                     /* ancillary */
   {
      if ((png_ptr->flags & PNG_FLAG_CRC_ANCILLARY_MASK) ==
          (PNG_FLAG_CRC_ANCILLARY_USE | PNG_FLAG_CRC_ANCILLARY_NOWARN))
         need_crc = 0;
   }
   else                                                    /* critical */
   {
      if (png_ptr->flags & PNG_FLAG_CRC_CRITICAL_IGNORE)
         need_crc = 0;
   }

   if (need_crc)
      png_ptr->crc = crc32(png_ptr->crc, ptr, (uInt)length);
}

/* Allocate the memory for an info_struct for the application.  We don't
 * really need the png_ptr, but it could potentially be useful in the
 * future.  This should be used in favour of malloc(png_sizeof(png_info))
 * and png_info_init() so that applications that want to use a shared
 * libpng don't have to be recompiled if png_info changes size.
 */
png_infop PNGAPI
png_create_info_struct(png_structp png_ptr)
{
   png_infop info_ptr;

   png_debug(1, "in png_create_info_struct");

   if (png_ptr == NULL)
      return (NULL);

#ifdef PNG_USER_MEM_SUPPORTED
   info_ptr = (png_infop)png_create_struct_2(PNG_STRUCT_INFO,
      png_ptr->malloc_fn, png_ptr->mem_ptr);
#else
   info_ptr = (png_infop)png_create_struct(PNG_STRUCT_INFO);
#endif
   if (info_ptr != NULL)
      png_info_init_3(&info_ptr, png_sizeof(png_info));

   return (info_ptr);
}

/* This function frees the memory associated with a single info struct.
 * Normally, one would use either png_destroy_read_struct() or
 * png_destroy_write_struct() to free an info struct, but this may be
 * useful for some applications.
 */
void PNGAPI
png_destroy_info_struct(png_structp png_ptr, png_infopp info_ptr_ptr)
{
   png_infop info_ptr = NULL;

   png_debug(1, "in png_destroy_info_struct");

   if (png_ptr == NULL)
      return;

   if (info_ptr_ptr != NULL)
      info_ptr = *info_ptr_ptr;

   if (info_ptr != NULL)
   {
      png_info_destroy(png_ptr, info_ptr);

#ifdef PNG_USER_MEM_SUPPORTED
      png_destroy_struct_2((png_voidp)info_ptr, png_ptr->free_fn,
          png_ptr->mem_ptr);
#else
      png_destroy_struct((png_voidp)info_ptr);
#endif
      *info_ptr_ptr = NULL;
   }
}

/* Initialize the info structure.  This is now an internal function (0.89)
 * and applications using it are urged to use png_create_info_struct()
 * instead.
 */
#if defined(PNG_1_0_X) || defined(PNG_1_2_X)
#undef png_info_init
void PNGAPI
png_info_init(png_infop info_ptr)
{
   /* We only come here via pre-1.0.12-compiled applications */
   png_info_init_3(&info_ptr, 0);
}
#endif

void PNGAPI
png_info_init_3(png_infopp ptr_ptr, png_size_t png_info_struct_size)
{
   png_infop info_ptr = *ptr_ptr;

   png_debug(1, "in png_info_init_3");

   if (info_ptr == NULL)
      return;

   if (png_sizeof(png_info) > png_info_struct_size)
   {
      png_destroy_struct(info_ptr);
      info_ptr = (png_infop)png_create_struct(PNG_STRUCT_INFO);
      *ptr_ptr = info_ptr;
   }

   /* Set everything to 0 */
   png_memset(info_ptr, 0, png_sizeof(png_info));
}

#ifdef PNG_FREE_ME_SUPPORTED
void PNGAPI
png_data_freer(png_structp png_ptr, png_infop info_ptr,
   int freer, png_uint_32 mask)
{
   png_debug(1, "in png_data_freer");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   if (freer == PNG_DESTROY_WILL_FREE_DATA)
      info_ptr->free_me |= mask;
   else if (freer == PNG_USER_WILL_FREE_DATA)
      info_ptr->free_me &= ~mask;
   else
      png_warning(png_ptr,
         "Unknown freer parameter in png_data_freer.");
}
#endif

void PNGAPI
png_free_data(png_structp png_ptr, png_infop info_ptr, png_uint_32 mask,
   int num)
{
   png_debug(1, "in png_free_data");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

#ifdef PNG_TEXT_SUPPORTED
   /* Free text item num or (if num == -1) all text items */
#ifdef PNG_FREE_ME_SUPPORTED
   if ((mask & PNG_FREE_TEXT) & info_ptr->free_me)
#else
   if (mask & PNG_FREE_TEXT)
#endif
   {
      if (num != -1)
      {
         if (info_ptr->text && info_ptr->text[num].key)
         {
            png_free(png_ptr, info_ptr->text[num].key);
            info_ptr->text[num].key = NULL;
         }
      }
      else
      {
         int i;
         for (i = 0; i < info_ptr->num_text; i++)
             png_free_data(png_ptr, info_ptr, PNG_FREE_TEXT, i);
         png_free(png_ptr, info_ptr->text);
         info_ptr->text = NULL;
         info_ptr->num_text=0;
      }
   }
#endif

#ifdef PNG_tRNS_SUPPORTED
   /* Free any tRNS entry */
#ifdef PNG_FREE_ME_SUPPORTED
   if ((mask & PNG_FREE_TRNS) & info_ptr->free_me)
#else
   if ((mask & PNG_FREE_TRNS) && (png_ptr->flags & PNG_FLAG_FREE_TRNS))
#endif
   {
      png_free(png_ptr, info_ptr->trans);
      info_ptr->trans = NULL;
      info_ptr->valid &= ~PNG_INFO_tRNS;
#ifndef PNG_FREE_ME_SUPPORTED
      png_ptr->flags &= ~PNG_FLAG_FREE_TRNS;
#endif
   }
#endif

#ifdef PNG_sCAL_SUPPORTED
   /* Free any sCAL entry */
#ifdef PNG_FREE_ME_SUPPORTED
   if ((mask & PNG_FREE_SCAL) & info_ptr->free_me)
#else
   if (mask & PNG_FREE_SCAL)
#endif
   {
#if defined(PNG_FIXED_POINT_SUPPORTED) && !defined(PNG_FLOATING_POINT_SUPPORTED)
      png_free(png_ptr, info_ptr->scal_s_width);
      png_free(png_ptr, info_ptr->scal_s_height);
      info_ptr->scal_s_width = NULL;
      info_ptr->scal_s_height = NULL;
#endif
      info_ptr->valid &= ~PNG_INFO_sCAL;
   }
#endif

#ifdef PNG_pCAL_SUPPORTED
   /* Free any pCAL entry */
#ifdef PNG_FREE_ME_SUPPORTED
   if ((mask & PNG_FREE_PCAL) & info_ptr->free_me)
#else
   if (mask & PNG_FREE_PCAL)
#endif
   {
      png_free(png_ptr, info_ptr->pcal_purpose);
      png_free(png_ptr, info_ptr->pcal_units);
      info_ptr->pcal_purpose = NULL;
      info_ptr->pcal_units = NULL;
      if (info_ptr->pcal_params != NULL)
         {
            int i;
            for (i = 0; i < (int)info_ptr->pcal_nparams; i++)
            {
               png_free(png_ptr, info_ptr->pcal_params[i]);
               info_ptr->pcal_params[i] = NULL;
            }
            png_free(png_ptr, info_ptr->pcal_params);
            info_ptr->pcal_params = NULL;
         }
      info_ptr->valid &= ~PNG_INFO_pCAL;
   }
#endif

#ifdef PNG_iCCP_SUPPORTED
   /* Free any iCCP entry */
#ifdef PNG_FREE_ME_SUPPORTED
   if ((mask & PNG_FREE_ICCP) & info_ptr->free_me)
#else
   if (mask & PNG_FREE_ICCP)
#endif
   {
      png_free(png_ptr, info_ptr->iccp_name);
      png_free(png_ptr, info_ptr->iccp_profile);
      info_ptr->iccp_name = NULL;
      info_ptr->iccp_profile = NULL;
      info_ptr->valid &= ~PNG_INFO_iCCP;
   }
#endif

#ifdef PNG_sPLT_SUPPORTED
   /* Free a given sPLT entry, or (if num == -1) all sPLT entries */
#ifdef PNG_FREE_ME_SUPPORTED
   if ((mask & PNG_FREE_SPLT) & info_ptr->free_me)
#else
   if (mask & PNG_FREE_SPLT)
#endif
   {
      if (num != -1)
      {
         if (info_ptr->splt_palettes)
         {
            png_free(png_ptr, info_ptr->splt_palettes[num].name);
            png_free(png_ptr, info_ptr->splt_palettes[num].entries);
            info_ptr->splt_palettes[num].name = NULL;
            info_ptr->splt_palettes[num].entries = NULL;
         }
      }
      else
      {
         if (info_ptr->splt_palettes_num)
         {
            int i;
            for (i = 0; i < (int)info_ptr->splt_palettes_num; i++)
               png_free_data(png_ptr, info_ptr, PNG_FREE_SPLT, i);

            png_free(png_ptr, info_ptr->splt_palettes);
            info_ptr->splt_palettes = NULL;
            info_ptr->splt_palettes_num = 0;
         }
         info_ptr->valid &= ~PNG_INFO_sPLT;
      }
   }
#endif

#ifdef PNG_UNKNOWN_CHUNKS_SUPPORTED
   if (png_ptr->unknown_chunk.data)
   {
      png_free(png_ptr, png_ptr->unknown_chunk.data);
      png_ptr->unknown_chunk.data = NULL;
   }

#ifdef PNG_FREE_ME_SUPPORTED
   if ((mask & PNG_FREE_UNKN) & info_ptr->free_me)
#else
   if (mask & PNG_FREE_UNKN)
#endif
   {
      if (num != -1)
      {
          if (info_ptr->unknown_chunks)
          {
             png_free(png_ptr, info_ptr->unknown_chunks[num].data);
             info_ptr->unknown_chunks[num].data = NULL;
          }
      }
      else
      {
         int i;

         if (info_ptr->unknown_chunks_num)
         {
            for (i = 0; i < (int)info_ptr->unknown_chunks_num; i++)
               png_free_data(png_ptr, info_ptr, PNG_FREE_UNKN, i);

            png_free(png_ptr, info_ptr->unknown_chunks);
            info_ptr->unknown_chunks = NULL;
            info_ptr->unknown_chunks_num = 0;
         }
      }
   }
#endif

#ifdef PNG_hIST_SUPPORTED
   /* Free any hIST entry */
#ifdef PNG_FREE_ME_SUPPORTED
   if ((mask & PNG_FREE_HIST)  & info_ptr->free_me)
#else
   if ((mask & PNG_FREE_HIST) && (png_ptr->flags & PNG_FLAG_FREE_HIST))
#endif
   {
      png_free(png_ptr, info_ptr->hist);
      info_ptr->hist = NULL;
      info_ptr->valid &= ~PNG_INFO_hIST;
#ifndef PNG_FREE_ME_SUPPORTED
      png_ptr->flags &= ~PNG_FLAG_FREE_HIST;
#endif
   }
#endif

   /* Free any PLTE entry that was internally allocated */
#ifdef PNG_FREE_ME_SUPPORTED
   if ((mask & PNG_FREE_PLTE) & info_ptr->free_me)
#else
   if ((mask & PNG_FREE_PLTE) && (png_ptr->flags & PNG_FLAG_FREE_PLTE))
#endif
   {
      png_zfree(png_ptr, info_ptr->palette);
      info_ptr->palette = NULL;
      info_ptr->valid &= ~PNG_INFO_PLTE;
#ifndef PNG_FREE_ME_SUPPORTED
      png_ptr->flags &= ~PNG_FLAG_FREE_PLTE;
#endif
      info_ptr->num_palette = 0;
   }

#ifdef PNG_INFO_IMAGE_SUPPORTED
   /* Free any image bits attached to the info structure */
#ifdef PNG_FREE_ME_SUPPORTED
   if ((mask & PNG_FREE_ROWS) & info_ptr->free_me)
#else
   if (mask & PNG_FREE_ROWS)
#endif
   {
      if (info_ptr->row_pointers)
      {
         int row;
         for (row = 0; row < (int)info_ptr->height; row++)
         {
            png_free(png_ptr, info_ptr->row_pointers[row]);
            info_ptr->row_pointers[row] = NULL;
         }
         png_free(png_ptr, info_ptr->row_pointers);
         info_ptr->row_pointers = NULL;
      }
      info_ptr->valid &= ~PNG_INFO_IDAT;
   }
#endif

#ifdef PNG_FREE_ME_SUPPORTED
   if (num == -1)
      info_ptr->free_me &= ~mask;
   else
      info_ptr->free_me &= ~(mask & ~PNG_FREE_MUL);
#endif
}

/* This is an internal routine to free any memory that the info struct is
 * pointing to before re-using it or freeing the struct itself.  Recall
 * that png_free() checks for NULL pointers for us.
 */
void /* PRIVATE */
png_info_destroy(png_structp png_ptr, png_infop info_ptr)
{
   png_debug(1, "in png_info_destroy");

   png_free_data(png_ptr, info_ptr, PNG_FREE_ALL, -1);

#ifdef PNG_HANDLE_AS_UNKNOWN_SUPPORTED
   if (png_ptr->num_chunk_list)
   {
      png_free(png_ptr, png_ptr->chunk_list);
      png_ptr->chunk_list = NULL;
      png_ptr->num_chunk_list = 0;
   }
#endif

   png_info_init_3(&info_ptr, png_sizeof(png_info));
}
#endif /* defined(PNG_READ_SUPPORTED) || defined(PNG_WRITE_SUPPORTED) */

/* This function returns a pointer to the io_ptr associated with the user
 * functions.  The application should free any memory associated with this
 * pointer before png_write_destroy() or png_read_destroy() are called.
 */
png_voidp PNGAPI
png_get_io_ptr(png_structp png_ptr)
{
   if (png_ptr == NULL)
      return (NULL);
   return (png_ptr->io_ptr);
}

#if defined(PNG_READ_SUPPORTED) || defined(PNG_WRITE_SUPPORTED)
#ifdef PNG_STDIO_SUPPORTED
/* Initialize the default input/output functions for the PNG file.  If you
 * use your own read or write routines, you can call either png_set_read_fn()
 * or png_set_write_fn() instead of png_init_io().  If you have defined
 * PNG_NO_STDIO, you must use a function of your own because "FILE *" isn't
 * necessarily available.
 */
void PNGAPI
png_init_io(png_structp png_ptr, png_FILE_p fp)
{
   png_debug(1, "in png_init_io");

   if (png_ptr == NULL)
      return;

   png_ptr->io_ptr = (png_voidp)fp;
}
#endif

#ifdef PNG_TIME_RFC1123_SUPPORTED
/* Convert the supplied time into an RFC 1123 string suitable for use in
 * a "Creation Time" or other text-based time string.
 */
png_charp PNGAPI
png_convert_to_rfc1123(png_structp png_ptr, png_timep ptime)
{
   static PNG_CONST char short_months[12][4] =
        {"Jan", "Feb", "Mar", "Apr", "May", "Jun",
         "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};

   if (png_ptr == NULL)
      return (NULL);
   if (png_ptr->time_buffer == NULL)
   {
      png_ptr->time_buffer = (png_charp)png_malloc(png_ptr, (png_uint_32)(29*
         png_sizeof(char)));
   }

#ifdef _WIN32_WCE
   {
      wchar_t time_buf[29];
      wsprintf(time_buf, TEXT("%d %S %d %02d:%02d:%02d +0000"),
          ptime->day % 32, short_months[(ptime->month - 1) % 12],
        ptime->year, ptime->hour % 24, ptime->minute % 60,
          ptime->second % 61);
      WideCharToMultiByte(CP_ACP, 0, time_buf, -1, png_ptr->time_buffer,
          29, NULL, NULL);
   }
#else
#ifdef USE_FAR_KEYWORD
   {
      char near_time_buf[29];
      png_snprintf6(near_time_buf, 29, "%d %s %d %02d:%02d:%02d +0000",
          ptime->day % 32, short_months[(ptime->month - 1) % 12],
          ptime->year, ptime->hour % 24, ptime->minute % 60,
          ptime->second % 61);
      png_memcpy(png_ptr->time_buffer, near_time_buf,
          29*png_sizeof(char));
   }
#else
   png_snprintf6(png_ptr->time_buffer, 29, "%d %s %d %02d:%02d:%02d +0000",
       ptime->day % 32, short_months[(ptime->month - 1) % 12],
       ptime->year, ptime->hour % 24, ptime->minute % 60,
       ptime->second % 61);
#endif
#endif /* _WIN32_WCE */
   return ((png_charp)png_ptr->time_buffer);
}
#endif /* PNG_TIME_RFC1123_SUPPORTED */

#endif /* defined(PNG_READ_SUPPORTED) || defined(PNG_WRITE_SUPPORTED) */

png_charp PNGAPI
png_get_copyright(png_structp png_ptr)
{
   png_ptr = png_ptr;  /* Silence compiler warning about unused png_ptr */
#ifdef PNG_STRING_COPYRIGHT
      return PNG_STRING_COPYRIGHT
#else
#ifdef __STDC__
   return ((png_charp) PNG_STRING_NEWLINE \
     "libpng version 1.2.45 - July 7, 2011" PNG_STRING_NEWLINE \
     "Copyright (c) 1998-2010 Glenn Randers-Pehrson" PNG_STRING_NEWLINE \
     "Copyright (c) 1996-1997 Andreas Dilger" PNG_STRING_NEWLINE \
     "Copyright (c) 1995-1996 Guy Eric Schalnat, Group 42, Inc." \
     PNG_STRING_NEWLINE);
#else
      return ((png_charp) "libpng version 1.2.45 - July 7, 2011\
      Copyright (c) 1998-2010 Glenn Randers-Pehrson\
      Copyright (c) 1996-1997 Andreas Dilger\
      Copyright (c) 1995-1996 Guy Eric Schalnat, Group 42, Inc.");
#endif
#endif
}

/* The following return the library version as a short string in the
 * format 1.0.0 through 99.99.99zz.  To get the version of *.h files
 * used with your application, print out PNG_LIBPNG_VER_STRING, which
 * is defined in png.h.
 * Note: now there is no difference between png_get_libpng_ver() and
 * png_get_header_ver().  Due to the version_nn_nn_nn typedef guard,
 * it is guaranteed that png.c uses the correct version of png.h.
 */
png_charp PNGAPI
png_get_libpng_ver(png_structp png_ptr)
{
   /* Version of *.c files used when building libpng */
   png_ptr = png_ptr;  /* Silence compiler warning about unused png_ptr */
   return ((png_charp) PNG_LIBPNG_VER_STRING);
}

png_charp PNGAPI
png_get_header_ver(png_structp png_ptr)
{
   /* Version of *.h files used when building libpng */
   png_ptr = png_ptr;  /* Silence compiler warning about unused png_ptr */
   return ((png_charp) PNG_LIBPNG_VER_STRING);
}

png_charp PNGAPI
png_get_header_version(png_structp png_ptr)
{
   /* Returns longer string containing both version and date */
   png_ptr = png_ptr;  /* Silence compiler warning about unused png_ptr */
#ifdef __STDC__
   return ((png_charp) PNG_HEADER_VERSION_STRING
#ifndef PNG_READ_SUPPORTED
   "     (NO READ SUPPORT)"
#endif
   PNG_STRING_NEWLINE);
#else
   return ((png_charp) PNG_HEADER_VERSION_STRING);
#endif
}

#if defined(PNG_READ_SUPPORTED) || defined(PNG_WRITE_SUPPORTED)
#ifdef PNG_HANDLE_AS_UNKNOWN_SUPPORTED
int PNGAPI
png_handle_as_unknown(png_structp png_ptr, png_bytep chunk_name)
{
   /* Check chunk_name and return "keep" value if it's on the list, else 0 */
   int i;
   png_bytep p;
   if (png_ptr == NULL || chunk_name == NULL || png_ptr->num_chunk_list<=0)
      return 0;
   p = png_ptr->chunk_list + png_ptr->num_chunk_list*5 - 5;
   for (i = png_ptr->num_chunk_list; i; i--, p -= 5)
      if (!png_memcmp(chunk_name, p, 4))
        return ((int)*(p + 4));
   return 0;
}
#endif

/* This function, added to libpng-1.0.6g, is untested. */
int PNGAPI
png_reset_zstream(png_structp png_ptr)
{
   if (png_ptr == NULL)
      return Z_STREAM_ERROR;
   return (inflateReset(&png_ptr->zstream));
}
#endif /* defined(PNG_READ_SUPPORTED) || defined(PNG_WRITE_SUPPORTED) */

/* This function was added to libpng-1.0.7 */
png_uint_32 PNGAPI
png_access_version_number(void)
{
   /* Version of *.c files used when building libpng */
   return((png_uint_32) PNG_LIBPNG_VER);
}


#if defined(PNG_READ_SUPPORTED) && defined(PNG_ASSEMBLER_CODE_SUPPORTED)
#ifndef PNG_1_0_X
/* This function was added to libpng 1.2.0 */
int PNGAPI
png_mmx_support(void)
{
   /* Obsolete, to be removed from libpng-1.4.0 */
    return -1;
}
#endif /* PNG_1_0_X */
#endif /* PNG_READ_SUPPORTED && PNG_ASSEMBLER_CODE_SUPPORTED */

#if defined(PNG_READ_SUPPORTED) || defined(PNG_WRITE_SUPPORTED)
#ifdef PNG_SIZE_T
/* Added at libpng version 1.2.6 */
   PNG_EXTERN png_size_t PNGAPI png_convert_size PNGARG((size_t size));
png_size_t PNGAPI
png_convert_size(size_t size)
{
   if (size > (png_size_t)-1)
      PNG_ABORT();  /* We haven't got access to png_ptr, so no png_error() */
   return ((png_size_t)size);
}
#endif /* PNG_SIZE_T */

/* Added at libpng version 1.2.34 and 1.4.0 (moved from pngset.c) */
#ifdef PNG_cHRM_SUPPORTED
#ifdef PNG_CHECK_cHRM_SUPPORTED

/*
 *    Multiply two 32-bit numbers, V1 and V2, using 32-bit
 *    arithmetic, to produce a 64 bit result in the HI/LO words.
 *
 *                  A B
 *                x C D
 *               ------
 *              AD || BD
 *        AC || CB || 0
 *
 *    where A and B are the high and low 16-bit words of V1,
 *    C and D are the 16-bit words of V2, AD is the product of
 *    A and D, and X || Y is (X << 16) + Y.
*/

void /* PRIVATE */
png_64bit_product (long v1, long v2, unsigned long *hi_product,
   unsigned long *lo_product)
{
   int a, b, c, d;
   long lo, hi, x, y;

   a = (v1 >> 16) & 0xffff;
   b = v1 & 0xffff;
   c = (v2 >> 16) & 0xffff;
   d = v2 & 0xffff;

   lo = b * d;                   /* BD */
   x = a * d + c * b;            /* AD + CB */
   y = ((lo >> 16) & 0xffff) + x;

   lo = (lo & 0xffff) | ((y & 0xffff) << 16);
   hi = (y >> 16) & 0xffff;

   hi += a * c;                  /* AC */

   *hi_product = (unsigned long)hi;
   *lo_product = (unsigned long)lo;
}

int /* PRIVATE */
png_check_cHRM_fixed(png_structp png_ptr,
   png_fixed_point white_x, png_fixed_point white_y, png_fixed_point red_x,
   png_fixed_point red_y, png_fixed_point green_x, png_fixed_point green_y,
   png_fixed_point blue_x, png_fixed_point blue_y)
{
   int ret = 1;
   unsigned long xy_hi,xy_lo,yx_hi,yx_lo;

   png_debug(1, "in function png_check_cHRM_fixed");

   if (png_ptr == NULL)
      return 0;

   if (white_x < 0 || white_y <= 0 ||
         red_x < 0 ||   red_y <  0 ||
       green_x < 0 || green_y <  0 ||
        blue_x < 0 ||  blue_y <  0)
   {
      png_warning(png_ptr,
        "Ignoring attempt to set negative chromaticity value");
      ret = 0;
   }
   if (white_x > (png_fixed_point) PNG_UINT_31_MAX ||
       white_y > (png_fixed_point) PNG_UINT_31_MAX ||
         red_x > (png_fixed_point) PNG_UINT_31_MAX ||
         red_y > (png_fixed_point) PNG_UINT_31_MAX ||
       green_x > (png_fixed_point) PNG_UINT_31_MAX ||
       green_y > (png_fixed_point) PNG_UINT_31_MAX ||
        blue_x > (png_fixed_point) PNG_UINT_31_MAX ||
        blue_y > (png_fixed_point) PNG_UINT_31_MAX )
   {
      png_warning(png_ptr,
        "Ignoring attempt to set chromaticity value exceeding 21474.83");
      ret = 0;
   }
   if (white_x > 100000L - white_y)
   {
      png_warning(png_ptr, "Invalid cHRM white point");
      ret = 0;
   }
   if (red_x > 100000L - red_y)
   {
      png_warning(png_ptr, "Invalid cHRM red point");
      ret = 0;
   }
   if (green_x > 100000L - green_y)
   {
      png_warning(png_ptr, "Invalid cHRM green point");
      ret = 0;
   }
   if (blue_x > 100000L - blue_y)
   {
      png_warning(png_ptr, "Invalid cHRM blue point");
      ret = 0;
   }

   png_64bit_product(green_x - red_x, blue_y - red_y, &xy_hi, &xy_lo);
   png_64bit_product(green_y - red_y, blue_x - red_x, &yx_hi, &yx_lo);

   if (xy_hi == yx_hi && xy_lo == yx_lo)
   {
      png_warning(png_ptr,
         "Ignoring attempt to set cHRM RGB triangle with zero area");
      ret = 0;
   }

   return ret;
}
#endif /* PNG_CHECK_cHRM_SUPPORTED */
#endif /* PNG_cHRM_SUPPORTED */

void /* PRIVATE */
png_check_IHDR(png_structp png_ptr,
   png_uint_32 width, png_uint_32 height, int bit_depth,
   int color_type, int interlace_type, int compression_type,
   int filter_type)
{
   int error = 0;

   /* Check for width and height valid values */
   if (width == 0)
   {
      png_warning(png_ptr, "Image width is zero in IHDR");
      error = 1;
   }

   if (height == 0)
   {
      png_warning(png_ptr, "Image height is zero in IHDR");
      error = 1;
   }

#ifdef PNG_SET_USER_LIMITS_SUPPORTED
   if (width > png_ptr->user_width_max || width > PNG_USER_WIDTH_MAX)
#else
   if (width > PNG_USER_WIDTH_MAX)
#endif
   {
      png_warning(png_ptr, "Image width exceeds user limit in IHDR");
      error = 1;
   }

#ifdef PNG_SET_USER_LIMITS_SUPPORTED
   if (height > png_ptr->user_height_max || height > PNG_USER_HEIGHT_MAX)
#else
   if (height > PNG_USER_HEIGHT_MAX)
#endif
   {
      png_warning(png_ptr, "Image height exceeds user limit in IHDR");
      error = 1;
   }

   if (width > PNG_UINT_31_MAX)
   {
      png_warning(png_ptr, "Invalid image width in IHDR");
      error = 1;
   }

   if ( height > PNG_UINT_31_MAX)
   {
      png_warning(png_ptr, "Invalid image height in IHDR");
      error = 1;
   }

   if ( width > (PNG_UINT_32_MAX
                 >> 3)      /* 8-byte RGBA pixels */
                 - 64       /* bigrowbuf hack */
                 - 1        /* filter byte */
                 - 7*8      /* rounding of width to multiple of 8 pixels */
                 - 8)       /* extra max_pixel_depth pad */
      png_warning(png_ptr, "Width is too large for libpng to process pixels");

   /* Check other values */
   if (bit_depth != 1 && bit_depth != 2 && bit_depth != 4 &&
       bit_depth != 8 && bit_depth != 16)
   {
      png_warning(png_ptr, "Invalid bit depth in IHDR");
      error = 1;
   }

   if (color_type < 0 || color_type == 1 ||
       color_type == 5 || color_type > 6)
   {
      png_warning(png_ptr, "Invalid color type in IHDR");
      error = 1;
   }

   if (((color_type == PNG_COLOR_TYPE_PALETTE) && bit_depth > 8) ||
       ((color_type == PNG_COLOR_TYPE_RGB ||
         color_type == PNG_COLOR_TYPE_GRAY_ALPHA ||
         color_type == PNG_COLOR_TYPE_RGB_ALPHA) && bit_depth < 8))
   {
      png_warning(png_ptr, "Invalid color type/bit depth combination in IHDR");
      error = 1;
   }

   if (interlace_type >= PNG_INTERLACE_LAST)
   {
      png_warning(png_ptr, "Unknown interlace method in IHDR");
      error = 1;
   }

   if (compression_type != PNG_COMPRESSION_TYPE_BASE)
   {
      png_warning(png_ptr, "Unknown compression method in IHDR");
      error = 1;
   }

#ifdef PNG_MNG_FEATURES_SUPPORTED
   /* Accept filter_method 64 (intrapixel differencing) only if
    * 1. Libpng was compiled with PNG_MNG_FEATURES_SUPPORTED and
    * 2. Libpng did not read a PNG signature (this filter_method is only
    *    used in PNG datastreams that are embedded in MNG datastreams) and
    * 3. The application called png_permit_mng_features with a mask that
    *    included PNG_FLAG_MNG_FILTER_64 and
    * 4. The filter_method is 64 and
    * 5. The color_type is RGB or RGBA
    */
   if ((png_ptr->mode & PNG_HAVE_PNG_SIGNATURE) &&
       png_ptr->mng_features_permitted)
      png_warning(png_ptr, "MNG features are not allowed in a PNG datastream");

   if (filter_type != PNG_FILTER_TYPE_BASE)
   {
      if (!((png_ptr->mng_features_permitted & PNG_FLAG_MNG_FILTER_64) &&
         (filter_type == PNG_INTRAPIXEL_DIFFERENCING) &&
         ((png_ptr->mode & PNG_HAVE_PNG_SIGNATURE) == 0) &&
         (color_type == PNG_COLOR_TYPE_RGB ||
         color_type == PNG_COLOR_TYPE_RGB_ALPHA)))
      {
         png_warning(png_ptr, "Unknown filter method in IHDR");
         error = 1;
      }

      if (png_ptr->mode & PNG_HAVE_PNG_SIGNATURE)
      {
         png_warning(png_ptr, "Invalid filter method in IHDR");
         error = 1;
      }
   }

#else
   if (filter_type != PNG_FILTER_TYPE_BASE)
   {
      png_warning(png_ptr, "Unknown filter method in IHDR");
      error = 1;
   }
#endif

   if (error == 1)
      png_error(png_ptr, "Invalid IHDR data");
}
#endif /* defined(PNG_READ_SUPPORTED) || defined(PNG_WRITE_SUPPORTED) */
