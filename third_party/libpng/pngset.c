
/* pngset.c - storage of image information into info struct
 *
 * Last changed in libpng 1.2.43 [February 25, 2010]
 * Copyright (c) 1998-2010 Glenn Randers-Pehrson
 * (Version 0.96 Copyright (c) 1996, 1997 Andreas Dilger)
 * (Version 0.88 Copyright (c) 1995, 1996 Guy Eric Schalnat, Group 42, Inc.)
 *
 * This code is released under the libpng license.
 * For conditions of distribution and use, see the disclaimer
 * and license in png.h
 *
 * The functions here are used during reads to store data from the file
 * into the info struct, and during writes to store application data
 * into the info struct for writing into the file.  This abstracts the
 * info struct and allows us to change the structure in the future.
 */

#define PNG_INTERNAL
#define PNG_NO_PEDANTIC_WARNINGS
#include "png.h"
#if defined(PNG_READ_SUPPORTED) || defined(PNG_WRITE_SUPPORTED)

#ifdef PNG_bKGD_SUPPORTED
void PNGAPI
png_set_bKGD(png_structp png_ptr, png_infop info_ptr, png_color_16p background)
{
   png_debug1(1, "in %s storage function", "bKGD");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   png_memcpy(&(info_ptr->background), background, png_sizeof(png_color_16));
   info_ptr->valid |= PNG_INFO_bKGD;
}
#endif

#ifdef PNG_cHRM_SUPPORTED
#ifdef PNG_FLOATING_POINT_SUPPORTED
void PNGAPI
png_set_cHRM(png_structp png_ptr, png_infop info_ptr,
   double white_x, double white_y, double red_x, double red_y,
   double green_x, double green_y, double blue_x, double blue_y)
{
   png_debug1(1, "in %s storage function", "cHRM");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   info_ptr->x_white = (float)white_x;
   info_ptr->y_white = (float)white_y;
   info_ptr->x_red   = (float)red_x;
   info_ptr->y_red   = (float)red_y;
   info_ptr->x_green = (float)green_x;
   info_ptr->y_green = (float)green_y;
   info_ptr->x_blue  = (float)blue_x;
   info_ptr->y_blue  = (float)blue_y;
#ifdef PNG_FIXED_POINT_SUPPORTED
   info_ptr->int_x_white = (png_fixed_point)(white_x*100000.+0.5);
   info_ptr->int_y_white = (png_fixed_point)(white_y*100000.+0.5);
   info_ptr->int_x_red   = (png_fixed_point)(  red_x*100000.+0.5);
   info_ptr->int_y_red   = (png_fixed_point)(  red_y*100000.+0.5);
   info_ptr->int_x_green = (png_fixed_point)(green_x*100000.+0.5);
   info_ptr->int_y_green = (png_fixed_point)(green_y*100000.+0.5);
   info_ptr->int_x_blue  = (png_fixed_point)( blue_x*100000.+0.5);
   info_ptr->int_y_blue  = (png_fixed_point)( blue_y*100000.+0.5);
#endif
   info_ptr->valid |= PNG_INFO_cHRM;
}
#endif /* PNG_FLOATING_POINT_SUPPORTED */

#ifdef PNG_FIXED_POINT_SUPPORTED
void PNGAPI
png_set_cHRM_fixed(png_structp png_ptr, png_infop info_ptr,
   png_fixed_point white_x, png_fixed_point white_y, png_fixed_point red_x,
   png_fixed_point red_y, png_fixed_point green_x, png_fixed_point green_y,
   png_fixed_point blue_x, png_fixed_point blue_y)
{
   png_debug1(1, "in %s storage function", "cHRM fixed");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

#ifdef PNG_CHECK_cHRM_SUPPORTED
   if (png_check_cHRM_fixed(png_ptr,
      white_x, white_y, red_x, red_y, green_x, green_y, blue_x, blue_y))
#endif
   {
      info_ptr->int_x_white = white_x;
      info_ptr->int_y_white = white_y;
      info_ptr->int_x_red   = red_x;
      info_ptr->int_y_red   = red_y;
      info_ptr->int_x_green = green_x;
      info_ptr->int_y_green = green_y;
      info_ptr->int_x_blue  = blue_x;
      info_ptr->int_y_blue  = blue_y;
#ifdef  PNG_FLOATING_POINT_SUPPORTED
      info_ptr->x_white = (float)(white_x/100000.);
      info_ptr->y_white = (float)(white_y/100000.);
      info_ptr->x_red   = (float)(  red_x/100000.);
      info_ptr->y_red   = (float)(  red_y/100000.);
      info_ptr->x_green = (float)(green_x/100000.);
      info_ptr->y_green = (float)(green_y/100000.);
      info_ptr->x_blue  = (float)( blue_x/100000.);
      info_ptr->y_blue  = (float)( blue_y/100000.);
#endif
      info_ptr->valid |= PNG_INFO_cHRM;
   }
}
#endif /* PNG_FIXED_POINT_SUPPORTED */
#endif /* PNG_cHRM_SUPPORTED */

#ifdef PNG_gAMA_SUPPORTED
#ifdef PNG_FLOATING_POINT_SUPPORTED
void PNGAPI
png_set_gAMA(png_structp png_ptr, png_infop info_ptr, double file_gamma)
{
   double png_gamma;

   png_debug1(1, "in %s storage function", "gAMA");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   /* Check for overflow */
   if (file_gamma > 21474.83)
   {
      png_warning(png_ptr, "Limiting gamma to 21474.83");
      png_gamma=21474.83;
   }
   else
      png_gamma = file_gamma;
   info_ptr->gamma = (float)png_gamma;
#ifdef PNG_FIXED_POINT_SUPPORTED
   info_ptr->int_gamma = (int)(png_gamma*100000.+.5);
#endif
   info_ptr->valid |= PNG_INFO_gAMA;
   if (png_gamma == 0.0)
      png_warning(png_ptr, "Setting gamma=0");
}
#endif
void PNGAPI
png_set_gAMA_fixed(png_structp png_ptr, png_infop info_ptr, png_fixed_point
   int_gamma)
{
   png_fixed_point png_gamma;

   png_debug1(1, "in %s storage function", "gAMA");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   if (int_gamma > (png_fixed_point)PNG_UINT_31_MAX)
   {
      png_warning(png_ptr, "Limiting gamma to 21474.83");
      png_gamma=PNG_UINT_31_MAX;
   }
   else
   {
      if (int_gamma < 0)
      {
         png_warning(png_ptr, "Setting negative gamma to zero");
         png_gamma = 0;
      }
      else
         png_gamma = int_gamma;
   }
#ifdef PNG_FLOATING_POINT_SUPPORTED
   info_ptr->gamma = (float)(png_gamma/100000.);
#endif
#ifdef PNG_FIXED_POINT_SUPPORTED
   info_ptr->int_gamma = png_gamma;
#endif
   info_ptr->valid |= PNG_INFO_gAMA;
   if (png_gamma == 0)
      png_warning(png_ptr, "Setting gamma=0");
}
#endif

#ifdef PNG_hIST_SUPPORTED
void PNGAPI
png_set_hIST(png_structp png_ptr, png_infop info_ptr, png_uint_16p hist)
{
   int i;

   png_debug1(1, "in %s storage function", "hIST");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   if (info_ptr->num_palette == 0 || info_ptr->num_palette
       > PNG_MAX_PALETTE_LENGTH)
   {
      png_warning(png_ptr,
         "Invalid palette size, hIST allocation skipped.");
      return;
   }

#ifdef PNG_FREE_ME_SUPPORTED
   png_free_data(png_ptr, info_ptr, PNG_FREE_HIST, 0);
#endif
   /* Changed from info->num_palette to PNG_MAX_PALETTE_LENGTH in
    * version 1.2.1
    */
   png_ptr->hist = (png_uint_16p)png_malloc_warn(png_ptr,
      (png_uint_32)(PNG_MAX_PALETTE_LENGTH * png_sizeof(png_uint_16)));
   if (png_ptr->hist == NULL)
   {
      png_warning(png_ptr, "Insufficient memory for hIST chunk data.");
      return;
   }

   for (i = 0; i < info_ptr->num_palette; i++)
      png_ptr->hist[i] = hist[i];
   info_ptr->hist = png_ptr->hist;
   info_ptr->valid |= PNG_INFO_hIST;

#ifdef PNG_FREE_ME_SUPPORTED
   info_ptr->free_me |= PNG_FREE_HIST;
#else
   png_ptr->flags |= PNG_FLAG_FREE_HIST;
#endif
}
#endif

void PNGAPI
png_set_IHDR(png_structp png_ptr, png_infop info_ptr,
   png_uint_32 width, png_uint_32 height, int bit_depth,
   int color_type, int interlace_type, int compression_type,
   int filter_type)
{
   png_debug1(1, "in %s storage function", "IHDR");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   info_ptr->width = width;
   info_ptr->height = height;
   info_ptr->bit_depth = (png_byte)bit_depth;
   info_ptr->color_type = (png_byte)color_type;
   info_ptr->compression_type = (png_byte)compression_type;
   info_ptr->filter_type = (png_byte)filter_type;
   info_ptr->interlace_type = (png_byte)interlace_type;

   png_check_IHDR (png_ptr, info_ptr->width, info_ptr->height,
       info_ptr->bit_depth, info_ptr->color_type, info_ptr->interlace_type,
       info_ptr->compression_type, info_ptr->filter_type);

   if (info_ptr->color_type == PNG_COLOR_TYPE_PALETTE)
      info_ptr->channels = 1;
   else if (info_ptr->color_type & PNG_COLOR_MASK_COLOR)
      info_ptr->channels = 3;
   else
      info_ptr->channels = 1;
   if (info_ptr->color_type & PNG_COLOR_MASK_ALPHA)
      info_ptr->channels++;
   info_ptr->pixel_depth = (png_byte)(info_ptr->channels * info_ptr->bit_depth);

   /* Check for potential overflow */
   if (width > (PNG_UINT_32_MAX
                 >> 3)      /* 8-byte RGBA pixels */
                 - 64       /* bigrowbuf hack */
                 - 1        /* filter byte */
                 - 7*8      /* rounding of width to multiple of 8 pixels */
                 - 8)       /* extra max_pixel_depth pad */
      info_ptr->rowbytes = (png_size_t)0;
   else
      info_ptr->rowbytes = PNG_ROWBYTES(info_ptr->pixel_depth, width);
}

#ifdef PNG_oFFs_SUPPORTED
void PNGAPI
png_set_oFFs(png_structp png_ptr, png_infop info_ptr,
   png_int_32 offset_x, png_int_32 offset_y, int unit_type)
{
   png_debug1(1, "in %s storage function", "oFFs");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   info_ptr->x_offset = offset_x;
   info_ptr->y_offset = offset_y;
   info_ptr->offset_unit_type = (png_byte)unit_type;
   info_ptr->valid |= PNG_INFO_oFFs;
}
#endif

#ifdef PNG_pCAL_SUPPORTED
void PNGAPI
png_set_pCAL(png_structp png_ptr, png_infop info_ptr,
   png_charp purpose, png_int_32 X0, png_int_32 X1, int type, int nparams,
   png_charp units, png_charpp params)
{
   png_uint_32 length;
   int i;

   png_debug1(1, "in %s storage function", "pCAL");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   length = png_strlen(purpose) + 1;
   png_debug1(3, "allocating purpose for info (%lu bytes)",
     (unsigned long)length);
   info_ptr->pcal_purpose = (png_charp)png_malloc_warn(png_ptr, length);
   if (info_ptr->pcal_purpose == NULL)
   {
      png_warning(png_ptr, "Insufficient memory for pCAL purpose.");
      return;
   }
   png_memcpy(info_ptr->pcal_purpose, purpose, (png_size_t)length);

   png_debug(3, "storing X0, X1, type, and nparams in info");
   info_ptr->pcal_X0 = X0;
   info_ptr->pcal_X1 = X1;
   info_ptr->pcal_type = (png_byte)type;
   info_ptr->pcal_nparams = (png_byte)nparams;

   length = png_strlen(units) + 1;
   png_debug1(3, "allocating units for info (%lu bytes)",
     (unsigned long)length);
   info_ptr->pcal_units = (png_charp)png_malloc_warn(png_ptr, length);
   if (info_ptr->pcal_units == NULL)
   {
      png_warning(png_ptr, "Insufficient memory for pCAL units.");
      return;
   }
   png_memcpy(info_ptr->pcal_units, units, (png_size_t)length);

   info_ptr->pcal_params = (png_charpp)png_malloc_warn(png_ptr,
      (png_uint_32)((nparams + 1) * png_sizeof(png_charp)));
   if (info_ptr->pcal_params == NULL)
   {
      png_warning(png_ptr, "Insufficient memory for pCAL params.");
      return;
   }

   png_memset(info_ptr->pcal_params, 0, (nparams + 1) * png_sizeof(png_charp));

   for (i = 0; i < nparams; i++)
   {
      length = png_strlen(params[i]) + 1;
      png_debug2(3, "allocating parameter %d for info (%lu bytes)", i,
        (unsigned long)length);
      info_ptr->pcal_params[i] = (png_charp)png_malloc_warn(png_ptr, length);
      if (info_ptr->pcal_params[i] == NULL)
      {
         png_warning(png_ptr, "Insufficient memory for pCAL parameter.");
         return;
      }
      png_memcpy(info_ptr->pcal_params[i], params[i], (png_size_t)length);
   }

   info_ptr->valid |= PNG_INFO_pCAL;
#ifdef PNG_FREE_ME_SUPPORTED
   info_ptr->free_me |= PNG_FREE_PCAL;
#endif
}
#endif

#if defined(PNG_READ_sCAL_SUPPORTED) || defined(PNG_WRITE_sCAL_SUPPORTED)
#ifdef PNG_FLOATING_POINT_SUPPORTED
void PNGAPI
png_set_sCAL(png_structp png_ptr, png_infop info_ptr,
             int unit, double width, double height)
{
   png_debug1(1, "in %s storage function", "sCAL");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   info_ptr->scal_unit = (png_byte)unit;
   info_ptr->scal_pixel_width = width;
   info_ptr->scal_pixel_height = height;

   info_ptr->valid |= PNG_INFO_sCAL;
}
#else
#ifdef PNG_FIXED_POINT_SUPPORTED
void PNGAPI
png_set_sCAL_s(png_structp png_ptr, png_infop info_ptr,
             int unit, png_charp swidth, png_charp sheight)
{
   png_uint_32 length;

   png_debug1(1, "in %s storage function", "sCAL");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   info_ptr->scal_unit = (png_byte)unit;

   length = png_strlen(swidth) + 1;
   png_debug1(3, "allocating unit for info (%u bytes)",
      (unsigned int)length);
   info_ptr->scal_s_width = (png_charp)png_malloc_warn(png_ptr, length);
   if (info_ptr->scal_s_width == NULL)
   {
      png_warning(png_ptr,
         "Memory allocation failed while processing sCAL.");
      return;
   }
   png_memcpy(info_ptr->scal_s_width, swidth, (png_size_t)length);

   length = png_strlen(sheight) + 1;
   png_debug1(3, "allocating unit for info (%u bytes)",
      (unsigned int)length);
   info_ptr->scal_s_height = (png_charp)png_malloc_warn(png_ptr, length);
   if (info_ptr->scal_s_height == NULL)
   {
      png_free (png_ptr, info_ptr->scal_s_width);
      info_ptr->scal_s_width = NULL;
      png_warning(png_ptr,
         "Memory allocation failed while processing sCAL.");
      return;
   }
   png_memcpy(info_ptr->scal_s_height, sheight, (png_size_t)length);
   info_ptr->valid |= PNG_INFO_sCAL;
#ifdef PNG_FREE_ME_SUPPORTED
   info_ptr->free_me |= PNG_FREE_SCAL;
#endif
}
#endif
#endif
#endif

#ifdef PNG_pHYs_SUPPORTED
void PNGAPI
png_set_pHYs(png_structp png_ptr, png_infop info_ptr,
   png_uint_32 res_x, png_uint_32 res_y, int unit_type)
{
   png_debug1(1, "in %s storage function", "pHYs");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   info_ptr->x_pixels_per_unit = res_x;
   info_ptr->y_pixels_per_unit = res_y;
   info_ptr->phys_unit_type = (png_byte)unit_type;
   info_ptr->valid |= PNG_INFO_pHYs;
}
#endif

void PNGAPI
png_set_PLTE(png_structp png_ptr, png_infop info_ptr,
   png_colorp palette, int num_palette)
{

   png_debug1(1, "in %s storage function", "PLTE");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   if (num_palette < 0 || num_palette > PNG_MAX_PALETTE_LENGTH)
   {
      if (info_ptr->color_type == PNG_COLOR_TYPE_PALETTE)
         png_error(png_ptr, "Invalid palette length");
      else
      {
         png_warning(png_ptr, "Invalid palette length");
         return;
      }
   }

   /* It may not actually be necessary to set png_ptr->palette here;
    * we do it for backward compatibility with the way the png_handle_tRNS
    * function used to do the allocation.
    */
#ifdef PNG_FREE_ME_SUPPORTED
   png_free_data(png_ptr, info_ptr, PNG_FREE_PLTE, 0);
#endif

   /* Changed in libpng-1.2.1 to allocate PNG_MAX_PALETTE_LENGTH instead
    * of num_palette entries, in case of an invalid PNG file that has
    * too-large sample values.
    */
   png_ptr->palette = (png_colorp)png_calloc(png_ptr,
      PNG_MAX_PALETTE_LENGTH * png_sizeof(png_color));
   png_memcpy(png_ptr->palette, palette, num_palette * png_sizeof(png_color));
   info_ptr->palette = png_ptr->palette;
   info_ptr->num_palette = png_ptr->num_palette = (png_uint_16)num_palette;

#ifdef PNG_FREE_ME_SUPPORTED
   info_ptr->free_me |= PNG_FREE_PLTE;
#else
   png_ptr->flags |= PNG_FLAG_FREE_PLTE;
#endif

   info_ptr->valid |= PNG_INFO_PLTE;
}

#ifdef PNG_sBIT_SUPPORTED
void PNGAPI
png_set_sBIT(png_structp png_ptr, png_infop info_ptr,
   png_color_8p sig_bit)
{
   png_debug1(1, "in %s storage function", "sBIT");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   png_memcpy(&(info_ptr->sig_bit), sig_bit, png_sizeof(png_color_8));
   info_ptr->valid |= PNG_INFO_sBIT;
}
#endif

#ifdef PNG_sRGB_SUPPORTED
void PNGAPI
png_set_sRGB(png_structp png_ptr, png_infop info_ptr, int intent)
{
   png_debug1(1, "in %s storage function", "sRGB");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   info_ptr->srgb_intent = (png_byte)intent;
   info_ptr->valid |= PNG_INFO_sRGB;
}

void PNGAPI
png_set_sRGB_gAMA_and_cHRM(png_structp png_ptr, png_infop info_ptr,
   int intent)
{
#ifdef PNG_gAMA_SUPPORTED
#ifdef PNG_FLOATING_POINT_SUPPORTED
   float file_gamma;
#endif
#ifdef PNG_FIXED_POINT_SUPPORTED
   png_fixed_point int_file_gamma;
#endif
#endif
#ifdef PNG_cHRM_SUPPORTED
#ifdef PNG_FLOATING_POINT_SUPPORTED
   float white_x, white_y, red_x, red_y, green_x, green_y, blue_x, blue_y;
#endif
   png_fixed_point int_white_x, int_white_y, int_red_x, int_red_y, int_green_x,
      int_green_y, int_blue_x, int_blue_y;
#endif
   png_debug1(1, "in %s storage function", "sRGB_gAMA_and_cHRM");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   png_set_sRGB(png_ptr, info_ptr, intent);

#ifdef PNG_gAMA_SUPPORTED
#ifdef PNG_FLOATING_POINT_SUPPORTED
   file_gamma = (float).45455;
   png_set_gAMA(png_ptr, info_ptr, file_gamma);
#endif
#ifdef PNG_FIXED_POINT_SUPPORTED
   int_file_gamma = 45455L;
   png_set_gAMA_fixed(png_ptr, info_ptr, int_file_gamma);
#endif
#endif

#ifdef PNG_cHRM_SUPPORTED
   int_white_x = 31270L;
   int_white_y = 32900L;
   int_red_x   = 64000L;
   int_red_y   = 33000L;
   int_green_x = 30000L;
   int_green_y = 60000L;
   int_blue_x  = 15000L;
   int_blue_y  =  6000L;

#ifdef PNG_FLOATING_POINT_SUPPORTED
   white_x = (float).3127;
   white_y = (float).3290;
   red_x   = (float).64;
   red_y   = (float).33;
   green_x = (float).30;
   green_y = (float).60;
   blue_x  = (float).15;
   blue_y  = (float).06;
#endif

#ifdef PNG_FIXED_POINT_SUPPORTED
   png_set_cHRM_fixed(png_ptr, info_ptr,
       int_white_x, int_white_y, int_red_x, int_red_y, int_green_x,
       int_green_y, int_blue_x, int_blue_y);
#endif
#ifdef PNG_FLOATING_POINT_SUPPORTED
   png_set_cHRM(png_ptr, info_ptr,
       white_x, white_y, red_x, red_y, green_x, green_y, blue_x, blue_y);
#endif
#endif /* cHRM */
}
#endif /* sRGB */


#ifdef PNG_iCCP_SUPPORTED
void PNGAPI
png_set_iCCP(png_structp png_ptr, png_infop info_ptr,
             png_charp name, int compression_type,
             png_charp profile, png_uint_32 proflen)
{
   png_charp new_iccp_name;
   png_charp new_iccp_profile;
   png_uint_32 length;

   png_debug1(1, "in %s storage function", "iCCP");

   if (png_ptr == NULL || info_ptr == NULL || name == NULL || profile == NULL)
      return;

   length = png_strlen(name)+1;
   new_iccp_name = (png_charp)png_malloc_warn(png_ptr, length);
   if (new_iccp_name == NULL)
   {
        png_warning(png_ptr, "Insufficient memory to process iCCP chunk.");
      return;
   }
   png_memcpy(new_iccp_name, name, length);
   new_iccp_profile = (png_charp)png_malloc_warn(png_ptr, proflen);
   if (new_iccp_profile == NULL)
   {
      png_free (png_ptr, new_iccp_name);
      png_warning(png_ptr,
          "Insufficient memory to process iCCP profile.");
      return;
   }
   png_memcpy(new_iccp_profile, profile, (png_size_t)proflen);

   png_free_data(png_ptr, info_ptr, PNG_FREE_ICCP, 0);

   info_ptr->iccp_proflen = proflen;
   info_ptr->iccp_name = new_iccp_name;
   info_ptr->iccp_profile = new_iccp_profile;
   /* Compression is always zero but is here so the API and info structure
    * does not have to change if we introduce multiple compression types
    */
   info_ptr->iccp_compression = (png_byte)compression_type;
#ifdef PNG_FREE_ME_SUPPORTED
   info_ptr->free_me |= PNG_FREE_ICCP;
#endif
   info_ptr->valid |= PNG_INFO_iCCP;
}
#endif

#ifdef PNG_TEXT_SUPPORTED
void PNGAPI
png_set_text(png_structp png_ptr, png_infop info_ptr, png_textp text_ptr,
             int num_text)
{
   int ret;
   ret = png_set_text_2(png_ptr, info_ptr, text_ptr, num_text);
   if (ret)
      png_error(png_ptr, "Insufficient memory to store text");
}

int /* PRIVATE */
png_set_text_2(png_structp png_ptr, png_infop info_ptr, png_textp text_ptr,
               int num_text)
{
   int i;

   png_debug1(1, "in %s storage function", ((png_ptr == NULL ||
      png_ptr->chunk_name[0] == '\0') ?
      "text" : (png_const_charp)png_ptr->chunk_name));

   if (png_ptr == NULL || info_ptr == NULL || num_text == 0)
      return(0);

   /* Make sure we have enough space in the "text" array in info_struct
    * to hold all of the incoming text_ptr objects.
    */
   if (info_ptr->num_text + num_text > info_ptr->max_text)
   {
      if (info_ptr->text != NULL)
      {
         png_textp old_text;
         int old_max;

         old_max = info_ptr->max_text;
         info_ptr->max_text = info_ptr->num_text + num_text + 8;
         old_text = info_ptr->text;
         info_ptr->text = (png_textp)png_malloc_warn(png_ptr,
            (png_uint_32)(info_ptr->max_text * png_sizeof(png_text)));
         if (info_ptr->text == NULL)
         {
            png_free(png_ptr, old_text);
            return(1);
         }
         png_memcpy(info_ptr->text, old_text, (png_size_t)(old_max *
            png_sizeof(png_text)));
         png_free(png_ptr, old_text);
      }
      else
      {
         info_ptr->max_text = num_text + 8;
         info_ptr->num_text = 0;
         info_ptr->text = (png_textp)png_malloc_warn(png_ptr,
            (png_uint_32)(info_ptr->max_text * png_sizeof(png_text)));
         if (info_ptr->text == NULL)
            return(1);
#ifdef PNG_FREE_ME_SUPPORTED
         info_ptr->free_me |= PNG_FREE_TEXT;
#endif
      }
      png_debug1(3, "allocated %d entries for info_ptr->text",
         info_ptr->max_text);
   }
   for (i = 0; i < num_text; i++)
   {
      png_size_t text_length, key_len;
      png_size_t lang_len, lang_key_len;
      png_textp textp = &(info_ptr->text[info_ptr->num_text]);

      if (text_ptr[i].key == NULL)
          continue;

      key_len = png_strlen(text_ptr[i].key);

      if (text_ptr[i].compression <= 0)
      {
         lang_len = 0;
         lang_key_len = 0;
      }

      else
#ifdef PNG_iTXt_SUPPORTED
      {
         /* Set iTXt data */

         if (text_ptr[i].lang != NULL)
            lang_len = png_strlen(text_ptr[i].lang);
         else
            lang_len = 0;
         if (text_ptr[i].lang_key != NULL)
            lang_key_len = png_strlen(text_ptr[i].lang_key);
         else
            lang_key_len = 0;
      }
#else /* PNG_iTXt_SUPPORTED */
      {
         png_warning(png_ptr, "iTXt chunk not supported.");
         continue;
      }
#endif

      if (text_ptr[i].text == NULL || text_ptr[i].text[0] == '\0')
      {
         text_length = 0;
#ifdef PNG_iTXt_SUPPORTED
         if (text_ptr[i].compression > 0)
            textp->compression = PNG_ITXT_COMPRESSION_NONE;
         else
#endif
            textp->compression = PNG_TEXT_COMPRESSION_NONE;
      }

      else
      {
         text_length = png_strlen(text_ptr[i].text);
         textp->compression = text_ptr[i].compression;
      }

      textp->key = (png_charp)png_malloc_warn(png_ptr,
         (png_uint_32)
         (key_len + text_length + lang_len + lang_key_len + 4));
      if (textp->key == NULL)
         return(1);
      png_debug2(2, "Allocated %lu bytes at %x in png_set_text",
                 (png_uint_32)
                 (key_len + lang_len + lang_key_len + text_length + 4),
                 (int)textp->key);

      png_memcpy(textp->key, text_ptr[i].key,(png_size_t)(key_len));
      *(textp->key + key_len) = '\0';
#ifdef PNG_iTXt_SUPPORTED
      if (text_ptr[i].compression > 0)
      {
         textp->lang = textp->key + key_len + 1;
         png_memcpy(textp->lang, text_ptr[i].lang, lang_len);
         *(textp->lang + lang_len) = '\0';
         textp->lang_key = textp->lang + lang_len + 1;
         png_memcpy(textp->lang_key, text_ptr[i].lang_key, lang_key_len);
         *(textp->lang_key + lang_key_len) = '\0';
         textp->text = textp->lang_key + lang_key_len + 1;
      }
      else
#endif
      {
#ifdef PNG_iTXt_SUPPORTED
         textp->lang=NULL;
         textp->lang_key=NULL;
#endif
         textp->text = textp->key + key_len + 1;
      }
      if (text_length)
         png_memcpy(textp->text, text_ptr[i].text,
            (png_size_t)(text_length));
      *(textp->text + text_length) = '\0';

#ifdef PNG_iTXt_SUPPORTED
      if (textp->compression > 0)
      {
         textp->text_length = 0;
         textp->itxt_length = text_length;
      }
      else
#endif

      {
         textp->text_length = text_length;
#ifdef PNG_iTXt_SUPPORTED
         textp->itxt_length = 0;
#endif
      }
      info_ptr->num_text++;
      png_debug1(3, "transferred text chunk %d", info_ptr->num_text);
   }
   return(0);
}
#endif

#ifdef PNG_tIME_SUPPORTED
void PNGAPI
png_set_tIME(png_structp png_ptr, png_infop info_ptr, png_timep mod_time)
{
   png_debug1(1, "in %s storage function", "tIME");

   if (png_ptr == NULL || info_ptr == NULL ||
       (png_ptr->mode & PNG_WROTE_tIME))
      return;

   png_memcpy(&(info_ptr->mod_time), mod_time, png_sizeof(png_time));
   info_ptr->valid |= PNG_INFO_tIME;
}
#endif

#ifdef PNG_tRNS_SUPPORTED
void PNGAPI
png_set_tRNS(png_structp png_ptr, png_infop info_ptr,
   png_bytep trans, int num_trans, png_color_16p trans_values)
{
   png_debug1(1, "in %s storage function", "tRNS");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   if (trans != NULL)
   {
       /* It may not actually be necessary to set png_ptr->trans here;
        * we do it for backward compatibility with the way the png_handle_tRNS
        * function used to do the allocation.
        */

#ifdef PNG_FREE_ME_SUPPORTED
       png_free_data(png_ptr, info_ptr, PNG_FREE_TRNS, 0);
#endif

       /* Changed from num_trans to PNG_MAX_PALETTE_LENGTH in version 1.2.1 */
       png_ptr->trans = info_ptr->trans = (png_bytep)png_malloc(png_ptr,
           (png_uint_32)PNG_MAX_PALETTE_LENGTH);
       if (num_trans > 0 && num_trans <= PNG_MAX_PALETTE_LENGTH)
          png_memcpy(info_ptr->trans, trans, (png_size_t)num_trans);
   }

   if (trans_values != NULL)
   {
      int sample_max = (1 << info_ptr->bit_depth);
      if ((info_ptr->color_type == PNG_COLOR_TYPE_GRAY &&
          (int)trans_values->gray > sample_max) ||
          (info_ptr->color_type == PNG_COLOR_TYPE_RGB &&
          ((int)trans_values->red > sample_max ||
          (int)trans_values->green > sample_max ||
          (int)trans_values->blue > sample_max)))
         png_warning(png_ptr,
            "tRNS chunk has out-of-range samples for bit_depth");
      png_memcpy(&(info_ptr->trans_values), trans_values,
         png_sizeof(png_color_16));
      if (num_trans == 0)
         num_trans = 1;
   }

   info_ptr->num_trans = (png_uint_16)num_trans;
   if (num_trans != 0)
   {
      info_ptr->valid |= PNG_INFO_tRNS;
#ifdef PNG_FREE_ME_SUPPORTED
      info_ptr->free_me |= PNG_FREE_TRNS;
#else
      png_ptr->flags |= PNG_FLAG_FREE_TRNS;
#endif
   }
}
#endif

#ifdef PNG_sPLT_SUPPORTED
void PNGAPI
png_set_sPLT(png_structp png_ptr,
             png_infop info_ptr, png_sPLT_tp entries, int nentries)
/*
 *  entries        - array of png_sPLT_t structures
 *                   to be added to the list of palettes
 *                   in the info structure.
 *  nentries       - number of palette structures to be
 *                   added.
 */
{
   png_sPLT_tp np;
   int i;

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   np = (png_sPLT_tp)png_malloc_warn(png_ptr,
       (info_ptr->splt_palettes_num + nentries) *
        (png_uint_32)png_sizeof(png_sPLT_t));
   if (np == NULL)
   {
      png_warning(png_ptr, "No memory for sPLT palettes.");
      return;
   }

   png_memcpy(np, info_ptr->splt_palettes,
       info_ptr->splt_palettes_num * png_sizeof(png_sPLT_t));
   png_free(png_ptr, info_ptr->splt_palettes);
   info_ptr->splt_palettes=NULL;

   for (i = 0; i < nentries; i++)
   {
      png_sPLT_tp to = np + info_ptr->splt_palettes_num + i;
      png_sPLT_tp from = entries + i;
      png_uint_32 length;

      length = png_strlen(from->name) + 1;
      to->name = (png_charp)png_malloc_warn(png_ptr, length);
      if (to->name == NULL)
      {
         png_warning(png_ptr,
           "Out of memory while processing sPLT chunk");
         continue;
      }
      png_memcpy(to->name, from->name, length);
      to->entries = (png_sPLT_entryp)png_malloc_warn(png_ptr,
          (png_uint_32)(from->nentries * png_sizeof(png_sPLT_entry)));
      if (to->entries == NULL)
      {
         png_warning(png_ptr,
           "Out of memory while processing sPLT chunk");
         png_free(png_ptr, to->name);
         to->name = NULL;
         continue;
      }
      png_memcpy(to->entries, from->entries,
          from->nentries * png_sizeof(png_sPLT_entry));
      to->nentries = from->nentries;
      to->depth = from->depth;
   }

   info_ptr->splt_palettes = np;
   info_ptr->splt_palettes_num += nentries;
   info_ptr->valid |= PNG_INFO_sPLT;
#ifdef PNG_FREE_ME_SUPPORTED
   info_ptr->free_me |= PNG_FREE_SPLT;
#endif
}
#endif /* PNG_sPLT_SUPPORTED */

#ifdef PNG_UNKNOWN_CHUNKS_SUPPORTED
void PNGAPI
png_set_unknown_chunks(png_structp png_ptr,
   png_infop info_ptr, png_unknown_chunkp unknowns, int num_unknowns)
{
   png_unknown_chunkp np;
   int i;

   if (png_ptr == NULL || info_ptr == NULL || num_unknowns == 0)
      return;

   np = (png_unknown_chunkp)png_malloc_warn(png_ptr,
       (png_uint_32)((info_ptr->unknown_chunks_num + num_unknowns) *
       png_sizeof(png_unknown_chunk)));
   if (np == NULL)
   {
      png_warning(png_ptr,
          "Out of memory while processing unknown chunk.");
      return;
   }

   png_memcpy(np, info_ptr->unknown_chunks,
       info_ptr->unknown_chunks_num * png_sizeof(png_unknown_chunk));
   png_free(png_ptr, info_ptr->unknown_chunks);
   info_ptr->unknown_chunks = NULL;

   for (i = 0; i < num_unknowns; i++)
   {
      png_unknown_chunkp to = np + info_ptr->unknown_chunks_num + i;
      png_unknown_chunkp from = unknowns + i;

      png_memcpy((png_charp)to->name, (png_charp)from->name,
          png_sizeof(from->name));
      to->name[png_sizeof(to->name)-1] = '\0';
      to->size = from->size;
      /* Note our location in the read or write sequence */
      to->location = (png_byte)(png_ptr->mode & 0xff);

      if (from->size == 0)
         to->data=NULL;
      else
      {
         to->data = (png_bytep)png_malloc_warn(png_ptr,
           (png_uint_32)from->size);
         if (to->data == NULL)
         {
            png_warning(png_ptr,
             "Out of memory while processing unknown chunk.");
            to->size = 0;
         }
         else
            png_memcpy(to->data, from->data, from->size);
      }
   }

   info_ptr->unknown_chunks = np;
   info_ptr->unknown_chunks_num += num_unknowns;
#ifdef PNG_FREE_ME_SUPPORTED
   info_ptr->free_me |= PNG_FREE_UNKN;
#endif
}
void PNGAPI
png_set_unknown_chunk_location(png_structp png_ptr, png_infop info_ptr,
   int chunk, int location)
{
   if (png_ptr != NULL && info_ptr != NULL && chunk >= 0 && chunk <
       (int)info_ptr->unknown_chunks_num)
      info_ptr->unknown_chunks[chunk].location = (png_byte)location;
}
#endif

#if defined(PNG_1_0_X) || defined(PNG_1_2_X)
#if defined(PNG_READ_EMPTY_PLTE_SUPPORTED) || \
    defined(PNG_WRITE_EMPTY_PLTE_SUPPORTED)
void PNGAPI
png_permit_empty_plte (png_structp png_ptr, int empty_plte_permitted)
{
   /* This function is deprecated in favor of png_permit_mng_features()
      and will be removed from libpng-1.3.0 */

   png_debug(1, "in png_permit_empty_plte, DEPRECATED.");

   if (png_ptr == NULL)
      return;
   png_ptr->mng_features_permitted = (png_byte)
     ((png_ptr->mng_features_permitted & (~PNG_FLAG_MNG_EMPTY_PLTE)) |
     ((empty_plte_permitted & PNG_FLAG_MNG_EMPTY_PLTE)));
}
#endif
#endif

#ifdef PNG_MNG_FEATURES_SUPPORTED
png_uint_32 PNGAPI
png_permit_mng_features (png_structp png_ptr, png_uint_32 mng_features)
{
   png_debug(1, "in png_permit_mng_features");

   if (png_ptr == NULL)
      return (png_uint_32)0;
   png_ptr->mng_features_permitted =
     (png_byte)(mng_features & PNG_ALL_MNG_FEATURES);
   return (png_uint_32)png_ptr->mng_features_permitted;
}
#endif

#ifdef PNG_HANDLE_AS_UNKNOWN_SUPPORTED
void PNGAPI
png_set_keep_unknown_chunks(png_structp png_ptr, int keep, png_bytep
   chunk_list, int num_chunks)
{
   png_bytep new_list, p;
   int i, old_num_chunks;
   if (png_ptr == NULL)
      return;
   if (num_chunks == 0)
   {
      if (keep == PNG_HANDLE_CHUNK_ALWAYS || keep == PNG_HANDLE_CHUNK_IF_SAFE)
         png_ptr->flags |= PNG_FLAG_KEEP_UNKNOWN_CHUNKS;
      else
         png_ptr->flags &= ~PNG_FLAG_KEEP_UNKNOWN_CHUNKS;

      if (keep == PNG_HANDLE_CHUNK_ALWAYS)
         png_ptr->flags |= PNG_FLAG_KEEP_UNSAFE_CHUNKS;
      else
         png_ptr->flags &= ~PNG_FLAG_KEEP_UNSAFE_CHUNKS;
      return;
   }
   if (chunk_list == NULL)
      return;
   old_num_chunks = png_ptr->num_chunk_list;
   new_list=(png_bytep)png_malloc(png_ptr,
      (png_uint_32)
       (5*(num_chunks + old_num_chunks)));
   if (png_ptr->chunk_list != NULL)
   {
      png_memcpy(new_list, png_ptr->chunk_list,
          (png_size_t)(5*old_num_chunks));
      png_free(png_ptr, png_ptr->chunk_list);
      png_ptr->chunk_list=NULL;
   }
   png_memcpy(new_list + 5*old_num_chunks, chunk_list,
       (png_size_t)(5*num_chunks));
   for (p = new_list + 5*old_num_chunks + 4, i = 0; i<num_chunks; i++, p += 5)
      *p=(png_byte)keep;
   png_ptr->num_chunk_list = old_num_chunks + num_chunks;
   png_ptr->chunk_list = new_list;
#ifdef PNG_FREE_ME_SUPPORTED
   png_ptr->free_me |= PNG_FREE_LIST;
#endif
}
#endif

#ifdef PNG_READ_USER_CHUNKS_SUPPORTED
void PNGAPI
png_set_read_user_chunk_fn(png_structp png_ptr, png_voidp user_chunk_ptr,
   png_user_chunk_ptr read_user_chunk_fn)
{
   png_debug(1, "in png_set_read_user_chunk_fn");

   if (png_ptr == NULL)
      return;

   png_ptr->read_user_chunk_fn = read_user_chunk_fn;
   png_ptr->user_chunk_ptr = user_chunk_ptr;
}
#endif

#ifdef PNG_INFO_IMAGE_SUPPORTED
void PNGAPI
png_set_rows(png_structp png_ptr, png_infop info_ptr, png_bytepp row_pointers)
{
   png_debug1(1, "in %s storage function", "rows");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   if (info_ptr->row_pointers && (info_ptr->row_pointers != row_pointers))
      png_free_data(png_ptr, info_ptr, PNG_FREE_ROWS, 0);
   info_ptr->row_pointers = row_pointers;
   if (row_pointers)
      info_ptr->valid |= PNG_INFO_IDAT;
}
#endif

void PNGAPI
png_set_compression_buffer_size(png_structp png_ptr,
    png_uint_32 size)
{
    if (png_ptr == NULL)
       return;
    png_free(png_ptr, png_ptr->zbuf);
    png_ptr->zbuf_size = (png_size_t)size;
    png_ptr->zbuf = (png_bytep)png_malloc(png_ptr, size);
    png_ptr->zstream.next_out = png_ptr->zbuf;
    png_ptr->zstream.avail_out = (uInt)png_ptr->zbuf_size;
}

void PNGAPI
png_set_invalid(png_structp png_ptr, png_infop info_ptr, int mask)
{
   if (png_ptr && info_ptr)
      info_ptr->valid &= ~mask;
}


#ifndef PNG_1_0_X
#ifdef PNG_ASSEMBLER_CODE_SUPPORTED
/* Function was added to libpng 1.2.0 and should always exist by default */
void PNGAPI
png_set_asm_flags (png_structp png_ptr, png_uint_32 asm_flags)
{
/* Obsolete as of libpng-1.2.20 and will be removed from libpng-1.4.0 */
    if (png_ptr != NULL)
    png_ptr->asm_flags = 0;
    asm_flags = asm_flags; /* Quiet the compiler */
}

/* This function was added to libpng 1.2.0 */
void PNGAPI
png_set_mmx_thresholds (png_structp png_ptr,
                        png_byte mmx_bitdepth_threshold,
                        png_uint_32 mmx_rowbytes_threshold)
{
/* Obsolete as of libpng-1.2.20 and will be removed from libpng-1.4.0 */
    if (png_ptr == NULL)
       return;
    /* Quiet the compiler */
    mmx_bitdepth_threshold = mmx_bitdepth_threshold;
    mmx_rowbytes_threshold = mmx_rowbytes_threshold;
}
#endif /* ?PNG_ASSEMBLER_CODE_SUPPORTED */

#ifdef PNG_SET_USER_LIMITS_SUPPORTED
/* This function was added to libpng 1.2.6 */
void PNGAPI
png_set_user_limits (png_structp png_ptr, png_uint_32 user_width_max,
    png_uint_32 user_height_max)
{
   /* Images with dimensions larger than these limits will be
    * rejected by png_set_IHDR().  To accept any PNG datastream
    * regardless of dimensions, set both limits to 0x7ffffffL.
    */
   if (png_ptr == NULL)
      return;
   png_ptr->user_width_max = user_width_max;
   png_ptr->user_height_max = user_height_max;
}
#endif /* ?PNG_SET_USER_LIMITS_SUPPORTED */


#ifdef PNG_BENIGN_ERRORS_SUPPORTED
void PNGAPI
png_set_benign_errors(png_structp png_ptr, int allowed)
{
   png_debug(1, "in png_set_benign_errors");

   if (allowed)
      png_ptr->flags |= PNG_FLAG_BENIGN_ERRORS_WARN;
   else
      png_ptr->flags &= ~PNG_FLAG_BENIGN_ERRORS_WARN;
}
#endif /* PNG_BENIGN_ERRORS_SUPPORTED */
#endif /* ?PNG_1_0_X */
#endif /* PNG_READ_SUPPORTED || PNG_WRITE_SUPPORTED */
