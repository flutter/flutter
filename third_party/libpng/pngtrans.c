
/* pngtrans.c - transforms the data in a row (used by both readers and writers)
 *
 * Last changed in libpng 1.2.41 [December 3, 2009]
 * Copyright (c) 1998-2009 Glenn Randers-Pehrson
 * (Version 0.96 Copyright (c) 1996, 1997 Andreas Dilger)
 * (Version 0.88 Copyright (c) 1995, 1996 Guy Eric Schalnat, Group 42, Inc.)
 *
 * This code is released under the libpng license.
 * For conditions of distribution and use, see the disclaimer
 * and license in png.h
 */

#define PNG_INTERNAL
#define PNG_NO_PEDANTIC_WARNINGS
#include "png.h"
#if defined(PNG_READ_SUPPORTED) || defined(PNG_WRITE_SUPPORTED)

#if defined(PNG_READ_BGR_SUPPORTED) || defined(PNG_WRITE_BGR_SUPPORTED)
/* Turn on BGR-to-RGB mapping */
void PNGAPI
png_set_bgr(png_structp png_ptr)
{
   png_debug(1, "in png_set_bgr");

   if (png_ptr == NULL)
      return;
   png_ptr->transformations |= PNG_BGR;
}
#endif

#if defined(PNG_READ_SWAP_SUPPORTED) || defined(PNG_WRITE_SWAP_SUPPORTED)
/* Turn on 16 bit byte swapping */
void PNGAPI
png_set_swap(png_structp png_ptr)
{
   png_debug(1, "in png_set_swap");

   if (png_ptr == NULL)
      return;
   if (png_ptr->bit_depth == 16)
      png_ptr->transformations |= PNG_SWAP_BYTES;
}
#endif

#if defined(PNG_READ_PACK_SUPPORTED) || defined(PNG_WRITE_PACK_SUPPORTED)
/* Turn on pixel packing */
void PNGAPI
png_set_packing(png_structp png_ptr)
{
   png_debug(1, "in png_set_packing");

   if (png_ptr == NULL)
      return;
   if (png_ptr->bit_depth < 8)
   {
      png_ptr->transformations |= PNG_PACK;
      png_ptr->usr_bit_depth = 8;
   }
}
#endif

#if defined(PNG_READ_PACKSWAP_SUPPORTED)||defined(PNG_WRITE_PACKSWAP_SUPPORTED)
/* Turn on packed pixel swapping */
void PNGAPI
png_set_packswap(png_structp png_ptr)
{
   png_debug(1, "in png_set_packswap");

   if (png_ptr == NULL)
      return;
   if (png_ptr->bit_depth < 8)
      png_ptr->transformations |= PNG_PACKSWAP;
}
#endif

#if defined(PNG_READ_SHIFT_SUPPORTED) || defined(PNG_WRITE_SHIFT_SUPPORTED)
void PNGAPI
png_set_shift(png_structp png_ptr, png_color_8p true_bits)
{
   png_debug(1, "in png_set_shift");

   if (png_ptr == NULL)
      return;
   png_ptr->transformations |= PNG_SHIFT;
   png_ptr->shift = *true_bits;
}
#endif

#if defined(PNG_READ_INTERLACING_SUPPORTED) || \
    defined(PNG_WRITE_INTERLACING_SUPPORTED)
int PNGAPI
png_set_interlace_handling(png_structp png_ptr)
{
   png_debug(1, "in png_set_interlace handling");

   if (png_ptr && png_ptr->interlaced)
   {
      png_ptr->transformations |= PNG_INTERLACE;
      return (7);
   }

   return (1);
}
#endif

#if defined(PNG_READ_FILLER_SUPPORTED) || defined(PNG_WRITE_FILLER_SUPPORTED)
/* Add a filler byte on read, or remove a filler or alpha byte on write.
 * The filler type has changed in v0.95 to allow future 2-byte fillers
 * for 48-bit input data, as well as to avoid problems with some compilers
 * that don't like bytes as parameters.
 */
void PNGAPI
png_set_filler(png_structp png_ptr, png_uint_32 filler, int filler_loc)
{
   png_debug(1, "in png_set_filler");

   if (png_ptr == NULL)
      return;
   png_ptr->transformations |= PNG_FILLER;
#ifdef PNG_LEGACY_SUPPORTED
   png_ptr->filler = (png_byte)filler;
#else
   png_ptr->filler = (png_uint_16)filler;
#endif
   if (filler_loc == PNG_FILLER_AFTER)
      png_ptr->flags |= PNG_FLAG_FILLER_AFTER;
   else
      png_ptr->flags &= ~PNG_FLAG_FILLER_AFTER;

   /* This should probably go in the "do_read_filler" routine.
    * I attempted to do that in libpng-1.0.1a but that caused problems
    * so I restored it in libpng-1.0.2a
   */

   if (png_ptr->color_type == PNG_COLOR_TYPE_RGB)
   {
      png_ptr->usr_channels = 4;
   }

   /* Also I added this in libpng-1.0.2a (what happens when we expand
    * a less-than-8-bit grayscale to GA? */

   if (png_ptr->color_type == PNG_COLOR_TYPE_GRAY && png_ptr->bit_depth >= 8)
   {
      png_ptr->usr_channels = 2;
   }
}

#ifndef PNG_1_0_X
/* Added to libpng-1.2.7 */
void PNGAPI
png_set_add_alpha(png_structp png_ptr, png_uint_32 filler, int filler_loc)
{
   png_debug(1, "in png_set_add_alpha");

   if (png_ptr == NULL)
      return;
   png_set_filler(png_ptr, filler, filler_loc);
   png_ptr->transformations |= PNG_ADD_ALPHA;
}
#endif

#endif

#if defined(PNG_READ_SWAP_ALPHA_SUPPORTED) || \
    defined(PNG_WRITE_SWAP_ALPHA_SUPPORTED)
void PNGAPI
png_set_swap_alpha(png_structp png_ptr)
{
   png_debug(1, "in png_set_swap_alpha");

   if (png_ptr == NULL)
      return;
   png_ptr->transformations |= PNG_SWAP_ALPHA;
}
#endif

#if defined(PNG_READ_INVERT_ALPHA_SUPPORTED) || \
    defined(PNG_WRITE_INVERT_ALPHA_SUPPORTED)
void PNGAPI
png_set_invert_alpha(png_structp png_ptr)
{
   png_debug(1, "in png_set_invert_alpha");

   if (png_ptr == NULL)
      return;
   png_ptr->transformations |= PNG_INVERT_ALPHA;
}
#endif

#if defined(PNG_READ_INVERT_SUPPORTED) || defined(PNG_WRITE_INVERT_SUPPORTED)
void PNGAPI
png_set_invert_mono(png_structp png_ptr)
{
   png_debug(1, "in png_set_invert_mono");

   if (png_ptr == NULL)
      return;
   png_ptr->transformations |= PNG_INVERT_MONO;
}

/* Invert monochrome grayscale data */
void /* PRIVATE */
png_do_invert(png_row_infop row_info, png_bytep row)
{
   png_debug(1, "in png_do_invert");

  /* This test removed from libpng version 1.0.13 and 1.2.0:
   *   if (row_info->bit_depth == 1 &&
   */
#ifdef PNG_USELESS_TESTS_SUPPORTED
   if (row == NULL || row_info == NULL)
     return;
#endif
   if (row_info->color_type == PNG_COLOR_TYPE_GRAY)
   {
      png_bytep rp = row;
      png_uint_32 i;
      png_uint_32 istop = row_info->rowbytes;

      for (i = 0; i < istop; i++)
      {
         *rp = (png_byte)(~(*rp));
         rp++;
      }
   }
   else if (row_info->color_type == PNG_COLOR_TYPE_GRAY_ALPHA &&
      row_info->bit_depth == 8)
   {
      png_bytep rp = row;
      png_uint_32 i;
      png_uint_32 istop = row_info->rowbytes;

      for (i = 0; i < istop; i+=2)
      {
         *rp = (png_byte)(~(*rp));
         rp+=2;
      }
   }
   else if (row_info->color_type == PNG_COLOR_TYPE_GRAY_ALPHA &&
      row_info->bit_depth == 16)
   {
      png_bytep rp = row;
      png_uint_32 i;
      png_uint_32 istop = row_info->rowbytes;

      for (i = 0; i < istop; i+=4)
      {
         *rp = (png_byte)(~(*rp));
         *(rp+1) = (png_byte)(~(*(rp+1)));
         rp+=4;
      }
   }
}
#endif

#if defined(PNG_READ_SWAP_SUPPORTED) || defined(PNG_WRITE_SWAP_SUPPORTED)
/* Swaps byte order on 16 bit depth images */
void /* PRIVATE */
png_do_swap(png_row_infop row_info, png_bytep row)
{
   png_debug(1, "in png_do_swap");

   if (
#ifdef PNG_USELESS_TESTS_SUPPORTED
       row != NULL && row_info != NULL &&
#endif
       row_info->bit_depth == 16)
   {
      png_bytep rp = row;
      png_uint_32 i;
      png_uint_32 istop= row_info->width * row_info->channels;

      for (i = 0; i < istop; i++, rp += 2)
      {
         png_byte t = *rp;
         *rp = *(rp + 1);
         *(rp + 1) = t;
      }
   }
}
#endif

#if defined(PNG_READ_PACKSWAP_SUPPORTED)||defined(PNG_WRITE_PACKSWAP_SUPPORTED)
static PNG_CONST png_byte onebppswaptable[256] = {
   0x00, 0x80, 0x40, 0xC0, 0x20, 0xA0, 0x60, 0xE0,
   0x10, 0x90, 0x50, 0xD0, 0x30, 0xB0, 0x70, 0xF0,
   0x08, 0x88, 0x48, 0xC8, 0x28, 0xA8, 0x68, 0xE8,
   0x18, 0x98, 0x58, 0xD8, 0x38, 0xB8, 0x78, 0xF8,
   0x04, 0x84, 0x44, 0xC4, 0x24, 0xA4, 0x64, 0xE4,
   0x14, 0x94, 0x54, 0xD4, 0x34, 0xB4, 0x74, 0xF4,
   0x0C, 0x8C, 0x4C, 0xCC, 0x2C, 0xAC, 0x6C, 0xEC,
   0x1C, 0x9C, 0x5C, 0xDC, 0x3C, 0xBC, 0x7C, 0xFC,
   0x02, 0x82, 0x42, 0xC2, 0x22, 0xA2, 0x62, 0xE2,
   0x12, 0x92, 0x52, 0xD2, 0x32, 0xB2, 0x72, 0xF2,
   0x0A, 0x8A, 0x4A, 0xCA, 0x2A, 0xAA, 0x6A, 0xEA,
   0x1A, 0x9A, 0x5A, 0xDA, 0x3A, 0xBA, 0x7A, 0xFA,
   0x06, 0x86, 0x46, 0xC6, 0x26, 0xA6, 0x66, 0xE6,
   0x16, 0x96, 0x56, 0xD6, 0x36, 0xB6, 0x76, 0xF6,
   0x0E, 0x8E, 0x4E, 0xCE, 0x2E, 0xAE, 0x6E, 0xEE,
   0x1E, 0x9E, 0x5E, 0xDE, 0x3E, 0xBE, 0x7E, 0xFE,
   0x01, 0x81, 0x41, 0xC1, 0x21, 0xA1, 0x61, 0xE1,
   0x11, 0x91, 0x51, 0xD1, 0x31, 0xB1, 0x71, 0xF1,
   0x09, 0x89, 0x49, 0xC9, 0x29, 0xA9, 0x69, 0xE9,
   0x19, 0x99, 0x59, 0xD9, 0x39, 0xB9, 0x79, 0xF9,
   0x05, 0x85, 0x45, 0xC5, 0x25, 0xA5, 0x65, 0xE5,
   0x15, 0x95, 0x55, 0xD5, 0x35, 0xB5, 0x75, 0xF5,
   0x0D, 0x8D, 0x4D, 0xCD, 0x2D, 0xAD, 0x6D, 0xED,
   0x1D, 0x9D, 0x5D, 0xDD, 0x3D, 0xBD, 0x7D, 0xFD,
   0x03, 0x83, 0x43, 0xC3, 0x23, 0xA3, 0x63, 0xE3,
   0x13, 0x93, 0x53, 0xD3, 0x33, 0xB3, 0x73, 0xF3,
   0x0B, 0x8B, 0x4B, 0xCB, 0x2B, 0xAB, 0x6B, 0xEB,
   0x1B, 0x9B, 0x5B, 0xDB, 0x3B, 0xBB, 0x7B, 0xFB,
   0x07, 0x87, 0x47, 0xC7, 0x27, 0xA7, 0x67, 0xE7,
   0x17, 0x97, 0x57, 0xD7, 0x37, 0xB7, 0x77, 0xF7,
   0x0F, 0x8F, 0x4F, 0xCF, 0x2F, 0xAF, 0x6F, 0xEF,
   0x1F, 0x9F, 0x5F, 0xDF, 0x3F, 0xBF, 0x7F, 0xFF
};

static PNG_CONST png_byte twobppswaptable[256] = {
   0x00, 0x40, 0x80, 0xC0, 0x10, 0x50, 0x90, 0xD0,
   0x20, 0x60, 0xA0, 0xE0, 0x30, 0x70, 0xB0, 0xF0,
   0x04, 0x44, 0x84, 0xC4, 0x14, 0x54, 0x94, 0xD4,
   0x24, 0x64, 0xA4, 0xE4, 0x34, 0x74, 0xB4, 0xF4,
   0x08, 0x48, 0x88, 0xC8, 0x18, 0x58, 0x98, 0xD8,
   0x28, 0x68, 0xA8, 0xE8, 0x38, 0x78, 0xB8, 0xF8,
   0x0C, 0x4C, 0x8C, 0xCC, 0x1C, 0x5C, 0x9C, 0xDC,
   0x2C, 0x6C, 0xAC, 0xEC, 0x3C, 0x7C, 0xBC, 0xFC,
   0x01, 0x41, 0x81, 0xC1, 0x11, 0x51, 0x91, 0xD1,
   0x21, 0x61, 0xA1, 0xE1, 0x31, 0x71, 0xB1, 0xF1,
   0x05, 0x45, 0x85, 0xC5, 0x15, 0x55, 0x95, 0xD5,
   0x25, 0x65, 0xA5, 0xE5, 0x35, 0x75, 0xB5, 0xF5,
   0x09, 0x49, 0x89, 0xC9, 0x19, 0x59, 0x99, 0xD9,
   0x29, 0x69, 0xA9, 0xE9, 0x39, 0x79, 0xB9, 0xF9,
   0x0D, 0x4D, 0x8D, 0xCD, 0x1D, 0x5D, 0x9D, 0xDD,
   0x2D, 0x6D, 0xAD, 0xED, 0x3D, 0x7D, 0xBD, 0xFD,
   0x02, 0x42, 0x82, 0xC2, 0x12, 0x52, 0x92, 0xD2,
   0x22, 0x62, 0xA2, 0xE2, 0x32, 0x72, 0xB2, 0xF2,
   0x06, 0x46, 0x86, 0xC6, 0x16, 0x56, 0x96, 0xD6,
   0x26, 0x66, 0xA6, 0xE6, 0x36, 0x76, 0xB6, 0xF6,
   0x0A, 0x4A, 0x8A, 0xCA, 0x1A, 0x5A, 0x9A, 0xDA,
   0x2A, 0x6A, 0xAA, 0xEA, 0x3A, 0x7A, 0xBA, 0xFA,
   0x0E, 0x4E, 0x8E, 0xCE, 0x1E, 0x5E, 0x9E, 0xDE,
   0x2E, 0x6E, 0xAE, 0xEE, 0x3E, 0x7E, 0xBE, 0xFE,
   0x03, 0x43, 0x83, 0xC3, 0x13, 0x53, 0x93, 0xD3,
   0x23, 0x63, 0xA3, 0xE3, 0x33, 0x73, 0xB3, 0xF3,
   0x07, 0x47, 0x87, 0xC7, 0x17, 0x57, 0x97, 0xD7,
   0x27, 0x67, 0xA7, 0xE7, 0x37, 0x77, 0xB7, 0xF7,
   0x0B, 0x4B, 0x8B, 0xCB, 0x1B, 0x5B, 0x9B, 0xDB,
   0x2B, 0x6B, 0xAB, 0xEB, 0x3B, 0x7B, 0xBB, 0xFB,
   0x0F, 0x4F, 0x8F, 0xCF, 0x1F, 0x5F, 0x9F, 0xDF,
   0x2F, 0x6F, 0xAF, 0xEF, 0x3F, 0x7F, 0xBF, 0xFF
};

static PNG_CONST png_byte fourbppswaptable[256] = {
   0x00, 0x10, 0x20, 0x30, 0x40, 0x50, 0x60, 0x70,
   0x80, 0x90, 0xA0, 0xB0, 0xC0, 0xD0, 0xE0, 0xF0,
   0x01, 0x11, 0x21, 0x31, 0x41, 0x51, 0x61, 0x71,
   0x81, 0x91, 0xA1, 0xB1, 0xC1, 0xD1, 0xE1, 0xF1,
   0x02, 0x12, 0x22, 0x32, 0x42, 0x52, 0x62, 0x72,
   0x82, 0x92, 0xA2, 0xB2, 0xC2, 0xD2, 0xE2, 0xF2,
   0x03, 0x13, 0x23, 0x33, 0x43, 0x53, 0x63, 0x73,
   0x83, 0x93, 0xA3, 0xB3, 0xC3, 0xD3, 0xE3, 0xF3,
   0x04, 0x14, 0x24, 0x34, 0x44, 0x54, 0x64, 0x74,
   0x84, 0x94, 0xA4, 0xB4, 0xC4, 0xD4, 0xE4, 0xF4,
   0x05, 0x15, 0x25, 0x35, 0x45, 0x55, 0x65, 0x75,
   0x85, 0x95, 0xA5, 0xB5, 0xC5, 0xD5, 0xE5, 0xF5,
   0x06, 0x16, 0x26, 0x36, 0x46, 0x56, 0x66, 0x76,
   0x86, 0x96, 0xA6, 0xB6, 0xC6, 0xD6, 0xE6, 0xF6,
   0x07, 0x17, 0x27, 0x37, 0x47, 0x57, 0x67, 0x77,
   0x87, 0x97, 0xA7, 0xB7, 0xC7, 0xD7, 0xE7, 0xF7,
   0x08, 0x18, 0x28, 0x38, 0x48, 0x58, 0x68, 0x78,
   0x88, 0x98, 0xA8, 0xB8, 0xC8, 0xD8, 0xE8, 0xF8,
   0x09, 0x19, 0x29, 0x39, 0x49, 0x59, 0x69, 0x79,
   0x89, 0x99, 0xA9, 0xB9, 0xC9, 0xD9, 0xE9, 0xF9,
   0x0A, 0x1A, 0x2A, 0x3A, 0x4A, 0x5A, 0x6A, 0x7A,
   0x8A, 0x9A, 0xAA, 0xBA, 0xCA, 0xDA, 0xEA, 0xFA,
   0x0B, 0x1B, 0x2B, 0x3B, 0x4B, 0x5B, 0x6B, 0x7B,
   0x8B, 0x9B, 0xAB, 0xBB, 0xCB, 0xDB, 0xEB, 0xFB,
   0x0C, 0x1C, 0x2C, 0x3C, 0x4C, 0x5C, 0x6C, 0x7C,
   0x8C, 0x9C, 0xAC, 0xBC, 0xCC, 0xDC, 0xEC, 0xFC,
   0x0D, 0x1D, 0x2D, 0x3D, 0x4D, 0x5D, 0x6D, 0x7D,
   0x8D, 0x9D, 0xAD, 0xBD, 0xCD, 0xDD, 0xED, 0xFD,
   0x0E, 0x1E, 0x2E, 0x3E, 0x4E, 0x5E, 0x6E, 0x7E,
   0x8E, 0x9E, 0xAE, 0xBE, 0xCE, 0xDE, 0xEE, 0xFE,
   0x0F, 0x1F, 0x2F, 0x3F, 0x4F, 0x5F, 0x6F, 0x7F,
   0x8F, 0x9F, 0xAF, 0xBF, 0xCF, 0xDF, 0xEF, 0xFF
};

/* Swaps pixel packing order within bytes */
void /* PRIVATE */
png_do_packswap(png_row_infop row_info, png_bytep row)
{
   png_debug(1, "in png_do_packswap");

   if (
#ifdef PNG_USELESS_TESTS_SUPPORTED
       row != NULL && row_info != NULL &&
#endif
       row_info->bit_depth < 8)
   {
      png_bytep rp, end, table;

      end = row + row_info->rowbytes;

      if (row_info->bit_depth == 1)
         table = (png_bytep)onebppswaptable;
      else if (row_info->bit_depth == 2)
         table = (png_bytep)twobppswaptable;
      else if (row_info->bit_depth == 4)
         table = (png_bytep)fourbppswaptable;
      else
         return;

      for (rp = row; rp < end; rp++)
         *rp = table[*rp];
   }
}
#endif /* PNG_READ_PACKSWAP_SUPPORTED or PNG_WRITE_PACKSWAP_SUPPORTED */

#if defined(PNG_WRITE_FILLER_SUPPORTED) || \
    defined(PNG_READ_STRIP_ALPHA_SUPPORTED)
/* Remove filler or alpha byte(s) */
void /* PRIVATE */
png_do_strip_filler(png_row_infop row_info, png_bytep row, png_uint_32 flags)
{
   png_debug(1, "in png_do_strip_filler");

#ifdef PNG_USELESS_TESTS_SUPPORTED
   if (row != NULL && row_info != NULL)
#endif
   {
      png_bytep sp=row;
      png_bytep dp=row;
      png_uint_32 row_width=row_info->width;
      png_uint_32 i;

      if ((row_info->color_type == PNG_COLOR_TYPE_RGB ||
          (row_info->color_type == PNG_COLOR_TYPE_RGB_ALPHA &&
          (flags & PNG_FLAG_STRIP_ALPHA))) &&
          row_info->channels == 4)
      {
         if (row_info->bit_depth == 8)
         {
            /* This converts from RGBX or RGBA to RGB */
            if (flags & PNG_FLAG_FILLER_AFTER)
            {
               dp+=3; sp+=4;
               for (i = 1; i < row_width; i++)
               {
                  *dp++ = *sp++;
                  *dp++ = *sp++;
                  *dp++ = *sp++;
                  sp++;
               }
            }
            /* This converts from XRGB or ARGB to RGB */
            else
            {
               for (i = 0; i < row_width; i++)
               {
                  sp++;
                  *dp++ = *sp++;
                  *dp++ = *sp++;
                  *dp++ = *sp++;
               }
            }
            row_info->pixel_depth = 24;
            row_info->rowbytes = row_width * 3;
         }
         else /* if (row_info->bit_depth == 16) */
         {
            if (flags & PNG_FLAG_FILLER_AFTER)
            {
               /* This converts from RRGGBBXX or RRGGBBAA to RRGGBB */
               sp += 8; dp += 6;
               for (i = 1; i < row_width; i++)
               {
                  /* This could be (although png_memcpy is probably slower):
                  png_memcpy(dp, sp, 6);
                  sp += 8;
                  dp += 6;
                  */

                  *dp++ = *sp++;
                  *dp++ = *sp++;
                  *dp++ = *sp++;
                  *dp++ = *sp++;
                  *dp++ = *sp++;
                  *dp++ = *sp++;
                  sp += 2;
               }
            }
            else
            {
               /* This converts from XXRRGGBB or AARRGGBB to RRGGBB */
               for (i = 0; i < row_width; i++)
               {
                  /* This could be (although png_memcpy is probably slower):
                  png_memcpy(dp, sp, 6);
                  sp += 8;
                  dp += 6;
                  */

                  sp+=2;
                  *dp++ = *sp++;
                  *dp++ = *sp++;
                  *dp++ = *sp++;
                  *dp++ = *sp++;
                  *dp++ = *sp++;
                  *dp++ = *sp++;
               }
            }
            row_info->pixel_depth = 48;
            row_info->rowbytes = row_width * 6;
         }
         row_info->channels = 3;
      }
      else if ((row_info->color_type == PNG_COLOR_TYPE_GRAY ||
         (row_info->color_type == PNG_COLOR_TYPE_GRAY_ALPHA &&
         (flags & PNG_FLAG_STRIP_ALPHA))) &&
          row_info->channels == 2)
      {
         if (row_info->bit_depth == 8)
         {
            /* This converts from GX or GA to G */
            if (flags & PNG_FLAG_FILLER_AFTER)
            {
               for (i = 0; i < row_width; i++)
               {
                  *dp++ = *sp++;
                  sp++;
               }
            }
            /* This converts from XG or AG to G */
            else
            {
               for (i = 0; i < row_width; i++)
               {
                  sp++;
                  *dp++ = *sp++;
               }
            }
            row_info->pixel_depth = 8;
            row_info->rowbytes = row_width;
         }
         else /* if (row_info->bit_depth == 16) */
         {
            if (flags & PNG_FLAG_FILLER_AFTER)
            {
               /* This converts from GGXX or GGAA to GG */
               sp += 4; dp += 2;
               for (i = 1; i < row_width; i++)
               {
                  *dp++ = *sp++;
                  *dp++ = *sp++;
                  sp += 2;
               }
            }
            else
            {
               /* This converts from XXGG or AAGG to GG */
               for (i = 0; i < row_width; i++)
               {
                  sp += 2;
                  *dp++ = *sp++;
                  *dp++ = *sp++;
               }
            }
            row_info->pixel_depth = 16;
            row_info->rowbytes = row_width * 2;
         }
         row_info->channels = 1;
      }
      if (flags & PNG_FLAG_STRIP_ALPHA)
        row_info->color_type &= ~PNG_COLOR_MASK_ALPHA;
   }
}
#endif

#if defined(PNG_READ_BGR_SUPPORTED) || defined(PNG_WRITE_BGR_SUPPORTED)
/* Swaps red and blue bytes within a pixel */
void /* PRIVATE */
png_do_bgr(png_row_infop row_info, png_bytep row)
{
   png_debug(1, "in png_do_bgr");

   if (
#ifdef PNG_USELESS_TESTS_SUPPORTED
       row != NULL && row_info != NULL &&
#endif
       (row_info->color_type & PNG_COLOR_MASK_COLOR))
   {
      png_uint_32 row_width = row_info->width;
      if (row_info->bit_depth == 8)
      {
         if (row_info->color_type == PNG_COLOR_TYPE_RGB)
         {
            png_bytep rp;
            png_uint_32 i;

            for (i = 0, rp = row; i < row_width; i++, rp += 3)
            {
               png_byte save = *rp;
               *rp = *(rp + 2);
               *(rp + 2) = save;
            }
         }
         else if (row_info->color_type == PNG_COLOR_TYPE_RGB_ALPHA)
         {
            png_bytep rp;
            png_uint_32 i;

            for (i = 0, rp = row; i < row_width; i++, rp += 4)
            {
               png_byte save = *rp;
               *rp = *(rp + 2);
               *(rp + 2) = save;
            }
         }
      }
      else if (row_info->bit_depth == 16)
      {
         if (row_info->color_type == PNG_COLOR_TYPE_RGB)
         {
            png_bytep rp;
            png_uint_32 i;

            for (i = 0, rp = row; i < row_width; i++, rp += 6)
            {
               png_byte save = *rp;
               *rp = *(rp + 4);
               *(rp + 4) = save;
               save = *(rp + 1);
               *(rp + 1) = *(rp + 5);
               *(rp + 5) = save;
            }
         }
         else if (row_info->color_type == PNG_COLOR_TYPE_RGB_ALPHA)
         {
            png_bytep rp;
            png_uint_32 i;

            for (i = 0, rp = row; i < row_width; i++, rp += 8)
            {
               png_byte save = *rp;
               *rp = *(rp + 4);
               *(rp + 4) = save;
               save = *(rp + 1);
               *(rp + 1) = *(rp + 5);
               *(rp + 5) = save;
            }
         }
      }
   }
}
#endif /* PNG_READ_BGR_SUPPORTED or PNG_WRITE_BGR_SUPPORTED */

#if defined(PNG_READ_USER_TRANSFORM_SUPPORTED) || \
    defined(PNG_LEGACY_SUPPORTED) || \
    defined(PNG_WRITE_USER_TRANSFORM_SUPPORTED)
void PNGAPI
png_set_user_transform_info(png_structp png_ptr, png_voidp
   user_transform_ptr, int user_transform_depth, int user_transform_channels)
{
   png_debug(1, "in png_set_user_transform_info");

   if (png_ptr == NULL)
      return;
#ifdef PNG_USER_TRANSFORM_PTR_SUPPORTED
   png_ptr->user_transform_ptr = user_transform_ptr;
   png_ptr->user_transform_depth = (png_byte)user_transform_depth;
   png_ptr->user_transform_channels = (png_byte)user_transform_channels;
#else
   if (user_transform_ptr || user_transform_depth || user_transform_channels)
      png_warning(png_ptr,
        "This version of libpng does not support user transform info");
#endif
}
#endif

/* This function returns a pointer to the user_transform_ptr associated with
 * the user transform functions.  The application should free any memory
 * associated with this pointer before png_write_destroy and png_read_destroy
 * are called.
 */
png_voidp PNGAPI
png_get_user_transform_ptr(png_structp png_ptr)
{
   if (png_ptr == NULL)
      return (NULL);
#ifdef PNG_USER_TRANSFORM_PTR_SUPPORTED
   return ((png_voidp)png_ptr->user_transform_ptr);
#else
   return (NULL);
#endif
}
#endif /* PNG_READ_SUPPORTED || PNG_WRITE_SUPPORTED */
