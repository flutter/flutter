
/* pngget.c - retrieval of values from info struct
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
 */

#define PNG_INTERNAL
#define PNG_NO_PEDANTIC_WARNINGS
#include "png.h"
#if defined(PNG_READ_SUPPORTED) || defined(PNG_WRITE_SUPPORTED)

png_uint_32 PNGAPI
png_get_valid(png_structp png_ptr, png_infop info_ptr, png_uint_32 flag)
{
   if (png_ptr != NULL && info_ptr != NULL)
      return(info_ptr->valid & flag);

   else
      return(0);
}

png_uint_32 PNGAPI
png_get_rowbytes(png_structp png_ptr, png_infop info_ptr)
{
   if (png_ptr != NULL && info_ptr != NULL)
      return(info_ptr->rowbytes);

   else
      return(0);
}

#ifdef PNG_INFO_IMAGE_SUPPORTED
png_bytepp PNGAPI
png_get_rows(png_structp png_ptr, png_infop info_ptr)
{
   if (png_ptr != NULL && info_ptr != NULL)
      return(info_ptr->row_pointers);

   else
      return(0);
}
#endif

#ifdef PNG_EASY_ACCESS_SUPPORTED
/* Easy access to info, added in libpng-0.99 */
png_uint_32 PNGAPI
png_get_image_width(png_structp png_ptr, png_infop info_ptr)
{
   if (png_ptr != NULL && info_ptr != NULL)
      return info_ptr->width;

   return (0);
}

png_uint_32 PNGAPI
png_get_image_height(png_structp png_ptr, png_infop info_ptr)
{
   if (png_ptr != NULL && info_ptr != NULL)
      return info_ptr->height;

   return (0);
}

png_byte PNGAPI
png_get_bit_depth(png_structp png_ptr, png_infop info_ptr)
{
   if (png_ptr != NULL && info_ptr != NULL)
      return info_ptr->bit_depth;

   return (0);
}

png_byte PNGAPI
png_get_color_type(png_structp png_ptr, png_infop info_ptr)
{
   if (png_ptr != NULL && info_ptr != NULL)
      return info_ptr->color_type;

   return (0);
}

png_byte PNGAPI
png_get_filter_type(png_structp png_ptr, png_infop info_ptr)
{
   if (png_ptr != NULL && info_ptr != NULL)
      return info_ptr->filter_type;

   return (0);
}

png_byte PNGAPI
png_get_interlace_type(png_structp png_ptr, png_infop info_ptr)
{
   if (png_ptr != NULL && info_ptr != NULL)
      return info_ptr->interlace_type;

   return (0);
}

png_byte PNGAPI
png_get_compression_type(png_structp png_ptr, png_infop info_ptr)
{
   if (png_ptr != NULL && info_ptr != NULL)
      return info_ptr->compression_type;

   return (0);
}

png_uint_32 PNGAPI
png_get_x_pixels_per_meter(png_structp png_ptr, png_infop info_ptr)
{
   if (png_ptr != NULL && info_ptr != NULL)
#ifdef PNG_pHYs_SUPPORTED
   if (info_ptr->valid & PNG_INFO_pHYs)
   {
      png_debug1(1, "in %s retrieval function", "png_get_x_pixels_per_meter");

      if (info_ptr->phys_unit_type != PNG_RESOLUTION_METER)
          return (0);

      else
          return (info_ptr->x_pixels_per_unit);
   }
#else
   return (0);
#endif
   return (0);
}

png_uint_32 PNGAPI
png_get_y_pixels_per_meter(png_structp png_ptr, png_infop info_ptr)
{
   if (png_ptr != NULL && info_ptr != NULL)
#ifdef PNG_pHYs_SUPPORTED
   if (info_ptr->valid & PNG_INFO_pHYs)
   {
      png_debug1(1, "in %s retrieval function", "png_get_y_pixels_per_meter");

      if (info_ptr->phys_unit_type != PNG_RESOLUTION_METER)
          return (0);

      else
          return (info_ptr->y_pixels_per_unit);
   }
#else
   return (0);
#endif
   return (0);
}

png_uint_32 PNGAPI
png_get_pixels_per_meter(png_structp png_ptr, png_infop info_ptr)
{
   if (png_ptr != NULL && info_ptr != NULL)
#ifdef PNG_pHYs_SUPPORTED
   if (info_ptr->valid & PNG_INFO_pHYs)
   {
      png_debug1(1, "in %s retrieval function", "png_get_pixels_per_meter");

      if (info_ptr->phys_unit_type != PNG_RESOLUTION_METER ||
         info_ptr->x_pixels_per_unit != info_ptr->y_pixels_per_unit)
          return (0);

      else
          return (info_ptr->x_pixels_per_unit);
   }
#else
   return (0);
#endif
   return (0);
}

#ifdef PNG_FLOATING_POINT_SUPPORTED
float PNGAPI
png_get_pixel_aspect_ratio(png_structp png_ptr, png_infop info_ptr)
   {
   if (png_ptr != NULL && info_ptr != NULL)
#ifdef PNG_pHYs_SUPPORTED

   if (info_ptr->valid & PNG_INFO_pHYs)
   {
      png_debug1(1, "in %s retrieval function", "png_get_aspect_ratio");

      if (info_ptr->x_pixels_per_unit == 0)
         return ((float)0.0);

      else
         return ((float)((float)info_ptr->y_pixels_per_unit
            /(float)info_ptr->x_pixels_per_unit));
   }
#else
      return (0.0);
#endif
   return ((float)0.0);
}
#endif

png_int_32 PNGAPI
png_get_x_offset_microns(png_structp png_ptr, png_infop info_ptr)
{
   if (png_ptr != NULL && info_ptr != NULL)
#ifdef PNG_oFFs_SUPPORTED

   if (info_ptr->valid & PNG_INFO_oFFs)
   {
      png_debug1(1, "in %s retrieval function", "png_get_x_offset_microns");

      if (info_ptr->offset_unit_type != PNG_OFFSET_MICROMETER)
          return (0);

      else
          return (info_ptr->x_offset);
   }
#else
      return (0);
#endif
   return (0);
}

png_int_32 PNGAPI
png_get_y_offset_microns(png_structp png_ptr, png_infop info_ptr)
{
   if (png_ptr != NULL && info_ptr != NULL)

#ifdef PNG_oFFs_SUPPORTED
   if (info_ptr->valid & PNG_INFO_oFFs)
   {
      png_debug1(1, "in %s retrieval function", "png_get_y_offset_microns");

      if (info_ptr->offset_unit_type != PNG_OFFSET_MICROMETER)
          return (0);

      else
          return (info_ptr->y_offset);
   }
#else
   return (0);
#endif
   return (0);
}

png_int_32 PNGAPI
png_get_x_offset_pixels(png_structp png_ptr, png_infop info_ptr)
{
   if (png_ptr != NULL && info_ptr != NULL)

#ifdef PNG_oFFs_SUPPORTED
   if (info_ptr->valid & PNG_INFO_oFFs)
   {
      png_debug1(1, "in %s retrieval function", "png_get_x_offset_microns");

      if (info_ptr->offset_unit_type != PNG_OFFSET_PIXEL)
          return (0);

      else
          return (info_ptr->x_offset);
   }
#else
   return (0);
#endif
   return (0);
}

png_int_32 PNGAPI
png_get_y_offset_pixels(png_structp png_ptr, png_infop info_ptr)
{
   if (png_ptr != NULL && info_ptr != NULL)

#ifdef PNG_oFFs_SUPPORTED
   if (info_ptr->valid & PNG_INFO_oFFs)
   {
      png_debug1(1, "in %s retrieval function", "png_get_y_offset_microns");

      if (info_ptr->offset_unit_type != PNG_OFFSET_PIXEL)
          return (0);

      else
          return (info_ptr->y_offset);
   }
#else
   return (0);
#endif
   return (0);
}

#if defined(PNG_INCH_CONVERSIONS) && defined(PNG_FLOATING_POINT_SUPPORTED)
png_uint_32 PNGAPI
png_get_pixels_per_inch(png_structp png_ptr, png_infop info_ptr)
{
   return ((png_uint_32)((float)png_get_pixels_per_meter(png_ptr, info_ptr)
     *.0254 +.5));
}

png_uint_32 PNGAPI
png_get_x_pixels_per_inch(png_structp png_ptr, png_infop info_ptr)
{
   return ((png_uint_32)((float)png_get_x_pixels_per_meter(png_ptr, info_ptr)
     *.0254 +.5));
}

png_uint_32 PNGAPI
png_get_y_pixels_per_inch(png_structp png_ptr, png_infop info_ptr)
{
   return ((png_uint_32)((float)png_get_y_pixels_per_meter(png_ptr, info_ptr)
     *.0254 +.5));
}

float PNGAPI
png_get_x_offset_inches(png_structp png_ptr, png_infop info_ptr)
{
   return ((float)png_get_x_offset_microns(png_ptr, info_ptr)
     *.00003937);
}

float PNGAPI
png_get_y_offset_inches(png_structp png_ptr, png_infop info_ptr)
{
   return ((float)png_get_y_offset_microns(png_ptr, info_ptr)
     *.00003937);
}

#ifdef PNG_pHYs_SUPPORTED
png_uint_32 PNGAPI
png_get_pHYs_dpi(png_structp png_ptr, png_infop info_ptr,
   png_uint_32 *res_x, png_uint_32 *res_y, int *unit_type)
{
   png_uint_32 retval = 0;

   if (png_ptr != NULL && info_ptr != NULL && (info_ptr->valid & PNG_INFO_pHYs))
   {
      png_debug1(1, "in %s retrieval function", "pHYs");

      if (res_x != NULL)
      {
         *res_x = info_ptr->x_pixels_per_unit;
         retval |= PNG_INFO_pHYs;
      }
      if (res_y != NULL)
      {
         *res_y = info_ptr->y_pixels_per_unit;
         retval |= PNG_INFO_pHYs;
      }
      if (unit_type != NULL)
      {
         *unit_type = (int)info_ptr->phys_unit_type;
         retval |= PNG_INFO_pHYs;
         if (*unit_type == 1)
         {
            if (res_x != NULL) *res_x = (png_uint_32)(*res_x * .0254 + .50);
            if (res_y != NULL) *res_y = (png_uint_32)(*res_y * .0254 + .50);
         }
      }
   }
   return (retval);
}
#endif /* PNG_pHYs_SUPPORTED */
#endif  /* PNG_INCH_CONVERSIONS && PNG_FLOATING_POINT_SUPPORTED */

/* png_get_channels really belongs in here, too, but it's been around longer */

#endif  /* PNG_EASY_ACCESS_SUPPORTED */

png_byte PNGAPI
png_get_channels(png_structp png_ptr, png_infop info_ptr)
{
   if (png_ptr != NULL && info_ptr != NULL)
      return(info_ptr->channels);
   else
      return (0);
}

png_bytep PNGAPI
png_get_signature(png_structp png_ptr, png_infop info_ptr)
{
   if (png_ptr != NULL && info_ptr != NULL)
      return(info_ptr->signature);
   else
      return (NULL);
}

#ifdef PNG_bKGD_SUPPORTED
png_uint_32 PNGAPI
png_get_bKGD(png_structp png_ptr, png_infop info_ptr,
   png_color_16p *background)
{
   if (png_ptr != NULL && info_ptr != NULL && (info_ptr->valid & PNG_INFO_bKGD)
      && background != NULL)
   {
      png_debug1(1, "in %s retrieval function", "bKGD");

      *background = &(info_ptr->background);
      return (PNG_INFO_bKGD);
   }
   return (0);
}
#endif

#ifdef PNG_cHRM_SUPPORTED
#ifdef PNG_FLOATING_POINT_SUPPORTED
png_uint_32 PNGAPI
png_get_cHRM(png_structp png_ptr, png_infop info_ptr,
   double *white_x, double *white_y, double *red_x, double *red_y,
   double *green_x, double *green_y, double *blue_x, double *blue_y)
{
   if (png_ptr != NULL && info_ptr != NULL && (info_ptr->valid & PNG_INFO_cHRM))
   {
      png_debug1(1, "in %s retrieval function", "cHRM");

      if (white_x != NULL)
         *white_x = (double)info_ptr->x_white;
      if (white_y != NULL)
         *white_y = (double)info_ptr->y_white;
      if (red_x != NULL)
         *red_x = (double)info_ptr->x_red;
      if (red_y != NULL)
         *red_y = (double)info_ptr->y_red;
      if (green_x != NULL)
         *green_x = (double)info_ptr->x_green;
      if (green_y != NULL)
         *green_y = (double)info_ptr->y_green;
      if (blue_x != NULL)
         *blue_x = (double)info_ptr->x_blue;
      if (blue_y != NULL)
         *blue_y = (double)info_ptr->y_blue;
      return (PNG_INFO_cHRM);
   }
   return (0);
}
#endif
#ifdef PNG_FIXED_POINT_SUPPORTED
png_uint_32 PNGAPI
png_get_cHRM_fixed(png_structp png_ptr, png_infop info_ptr,
   png_fixed_point *white_x, png_fixed_point *white_y, png_fixed_point *red_x,
   png_fixed_point *red_y, png_fixed_point *green_x, png_fixed_point *green_y,
   png_fixed_point *blue_x, png_fixed_point *blue_y)
{
   png_debug1(1, "in %s retrieval function", "cHRM");

   if (png_ptr != NULL && info_ptr != NULL && (info_ptr->valid & PNG_INFO_cHRM))
   {
      if (white_x != NULL)
         *white_x = info_ptr->int_x_white;
      if (white_y != NULL)
         *white_y = info_ptr->int_y_white;
      if (red_x != NULL)
         *red_x = info_ptr->int_x_red;
      if (red_y != NULL)
         *red_y = info_ptr->int_y_red;
      if (green_x != NULL)
         *green_x = info_ptr->int_x_green;
      if (green_y != NULL)
         *green_y = info_ptr->int_y_green;
      if (blue_x != NULL)
         *blue_x = info_ptr->int_x_blue;
      if (blue_y != NULL)
         *blue_y = info_ptr->int_y_blue;
      return (PNG_INFO_cHRM);
   }
   return (0);
}
#endif
#endif

#ifdef PNG_gAMA_SUPPORTED
#ifdef PNG_FLOATING_POINT_SUPPORTED
png_uint_32 PNGAPI
png_get_gAMA(png_structp png_ptr, png_infop info_ptr, double *file_gamma)
{
   png_debug1(1, "in %s retrieval function", "gAMA");

   if (png_ptr != NULL && info_ptr != NULL && (info_ptr->valid & PNG_INFO_gAMA)
      && file_gamma != NULL)
   {
      *file_gamma = (double)info_ptr->gamma;
      return (PNG_INFO_gAMA);
   }
   return (0);
}
#endif
#ifdef PNG_FIXED_POINT_SUPPORTED
png_uint_32 PNGAPI
png_get_gAMA_fixed(png_structp png_ptr, png_infop info_ptr,
    png_fixed_point *int_file_gamma)
{
   png_debug1(1, "in %s retrieval function", "gAMA");

   if (png_ptr != NULL && info_ptr != NULL && (info_ptr->valid & PNG_INFO_gAMA)
      && int_file_gamma != NULL)
   {
      *int_file_gamma = info_ptr->int_gamma;
      return (PNG_INFO_gAMA);
   }
   return (0);
}
#endif
#endif

#ifdef PNG_sRGB_SUPPORTED
png_uint_32 PNGAPI
png_get_sRGB(png_structp png_ptr, png_infop info_ptr, int *file_srgb_intent)
{
   png_debug1(1, "in %s retrieval function", "sRGB");

   if (png_ptr != NULL && info_ptr != NULL && (info_ptr->valid & PNG_INFO_sRGB)
      && file_srgb_intent != NULL)
   {
      *file_srgb_intent = (int)info_ptr->srgb_intent;
      return (PNG_INFO_sRGB);
   }
   return (0);
}
#endif

#ifdef PNG_iCCP_SUPPORTED
png_uint_32 PNGAPI
png_get_iCCP(png_structp png_ptr, png_infop info_ptr,
             png_charpp name, int *compression_type,
             png_charpp profile, png_uint_32 *proflen)
{
   png_debug1(1, "in %s retrieval function", "iCCP");

   if (png_ptr != NULL && info_ptr != NULL && (info_ptr->valid & PNG_INFO_iCCP)
      && name != NULL && profile != NULL && proflen != NULL)
   {
      *name = info_ptr->iccp_name;
      *profile = info_ptr->iccp_profile;
      /* Compression_type is a dummy so the API won't have to change
       * if we introduce multiple compression types later.
       */
      *proflen = (int)info_ptr->iccp_proflen;
      *compression_type = (int)info_ptr->iccp_compression;
      return (PNG_INFO_iCCP);
   }
   return (0);
}
#endif

#ifdef PNG_sPLT_SUPPORTED
png_uint_32 PNGAPI
png_get_sPLT(png_structp png_ptr, png_infop info_ptr,
             png_sPLT_tpp spalettes)
{
   if (png_ptr != NULL && info_ptr != NULL && spalettes != NULL)
   {
     *spalettes = info_ptr->splt_palettes;
     return ((png_uint_32)info_ptr->splt_palettes_num);
   }
   return (0);
}
#endif

#ifdef PNG_hIST_SUPPORTED
png_uint_32 PNGAPI
png_get_hIST(png_structp png_ptr, png_infop info_ptr, png_uint_16p *hist)
{
   png_debug1(1, "in %s retrieval function", "hIST");

   if (png_ptr != NULL && info_ptr != NULL && (info_ptr->valid & PNG_INFO_hIST)
      && hist != NULL)
   {
      *hist = info_ptr->hist;
      return (PNG_INFO_hIST);
   }
   return (0);
}
#endif

png_uint_32 PNGAPI
png_get_IHDR(png_structp png_ptr, png_infop info_ptr,
   png_uint_32 *width, png_uint_32 *height, int *bit_depth,
   int *color_type, int *interlace_type, int *compression_type,
   int *filter_type)

{
   png_debug1(1, "in %s retrieval function", "IHDR");

   if (png_ptr == NULL || info_ptr == NULL || width == NULL ||
       height == NULL || bit_depth == NULL || color_type == NULL)
      return (0);

   *width = info_ptr->width;
   *height = info_ptr->height;
   *bit_depth = info_ptr->bit_depth;
   *color_type = info_ptr->color_type;

   if (compression_type != NULL)
      *compression_type = info_ptr->compression_type;

   if (filter_type != NULL)
      *filter_type = info_ptr->filter_type;

   if (interlace_type != NULL)
      *interlace_type = info_ptr->interlace_type;

   /* This is redundant if we can be sure that the info_ptr values were all
    * assigned in png_set_IHDR().  We do the check anyhow in case an
    * application has ignored our advice not to mess with the members
    * of info_ptr directly.
    */
   png_check_IHDR (png_ptr, info_ptr->width, info_ptr->height,
       info_ptr->bit_depth, info_ptr->color_type, info_ptr->interlace_type,
       info_ptr->compression_type, info_ptr->filter_type);

   return (1);
}

#ifdef PNG_oFFs_SUPPORTED
png_uint_32 PNGAPI
png_get_oFFs(png_structp png_ptr, png_infop info_ptr,
   png_int_32 *offset_x, png_int_32 *offset_y, int *unit_type)
{
   png_debug1(1, "in %s retrieval function", "oFFs");

   if (png_ptr != NULL && info_ptr != NULL && (info_ptr->valid & PNG_INFO_oFFs)
      && offset_x != NULL && offset_y != NULL && unit_type != NULL)
   {
      *offset_x = info_ptr->x_offset;
      *offset_y = info_ptr->y_offset;
      *unit_type = (int)info_ptr->offset_unit_type;
      return (PNG_INFO_oFFs);
   }
   return (0);
}
#endif

#ifdef PNG_pCAL_SUPPORTED
png_uint_32 PNGAPI
png_get_pCAL(png_structp png_ptr, png_infop info_ptr,
   png_charp *purpose, png_int_32 *X0, png_int_32 *X1, int *type, int *nparams,
   png_charp *units, png_charpp *params)
{
   png_debug1(1, "in %s retrieval function", "pCAL");

   if (png_ptr != NULL && info_ptr != NULL && (info_ptr->valid & PNG_INFO_pCAL)
       && purpose != NULL && X0 != NULL && X1 != NULL && type != NULL &&
       nparams != NULL && units != NULL && params != NULL)
   {
      *purpose = info_ptr->pcal_purpose;
      *X0 = info_ptr->pcal_X0;
      *X1 = info_ptr->pcal_X1;
      *type = (int)info_ptr->pcal_type;
      *nparams = (int)info_ptr->pcal_nparams;
      *units = info_ptr->pcal_units;
      *params = info_ptr->pcal_params;
      return (PNG_INFO_pCAL);
   }
   return (0);
}
#endif

#ifdef PNG_sCAL_SUPPORTED
#ifdef PNG_FLOATING_POINT_SUPPORTED
png_uint_32 PNGAPI
png_get_sCAL(png_structp png_ptr, png_infop info_ptr,
             int *unit, double *width, double *height)
{
    if (png_ptr != NULL && info_ptr != NULL &&
        (info_ptr->valid & PNG_INFO_sCAL))
    {
        *unit = info_ptr->scal_unit;
        *width = info_ptr->scal_pixel_width;
        *height = info_ptr->scal_pixel_height;
        return (PNG_INFO_sCAL);
    }
    return(0);
}
#else
#ifdef PNG_FIXED_POINT_SUPPORTED
png_uint_32 PNGAPI
png_get_sCAL_s(png_structp png_ptr, png_infop info_ptr,
             int *unit, png_charpp width, png_charpp height)
{
    if (png_ptr != NULL && info_ptr != NULL &&
        (info_ptr->valid & PNG_INFO_sCAL))
    {
        *unit = info_ptr->scal_unit;
        *width = info_ptr->scal_s_width;
        *height = info_ptr->scal_s_height;
        return (PNG_INFO_sCAL);
    }
    return(0);
}
#endif
#endif
#endif

#ifdef PNG_pHYs_SUPPORTED
png_uint_32 PNGAPI
png_get_pHYs(png_structp png_ptr, png_infop info_ptr,
   png_uint_32 *res_x, png_uint_32 *res_y, int *unit_type)
{
   png_uint_32 retval = 0;

   png_debug1(1, "in %s retrieval function", "pHYs");

   if (png_ptr != NULL && info_ptr != NULL &&
      (info_ptr->valid & PNG_INFO_pHYs))
   {
      if (res_x != NULL)
      {
         *res_x = info_ptr->x_pixels_per_unit;
         retval |= PNG_INFO_pHYs;
      }

      if (res_y != NULL)
      {
         *res_y = info_ptr->y_pixels_per_unit;
         retval |= PNG_INFO_pHYs;
      }

      if (unit_type != NULL)
      {
         *unit_type = (int)info_ptr->phys_unit_type;
         retval |= PNG_INFO_pHYs;
      }
   }
   return (retval);
}
#endif

png_uint_32 PNGAPI
png_get_PLTE(png_structp png_ptr, png_infop info_ptr, png_colorp *palette,
   int *num_palette)
{
   png_debug1(1, "in %s retrieval function", "PLTE");

   if (png_ptr != NULL && info_ptr != NULL && (info_ptr->valid & PNG_INFO_PLTE)
       && palette != NULL)
   {
      *palette = info_ptr->palette;
      *num_palette = info_ptr->num_palette;
      png_debug1(3, "num_palette = %d", *num_palette);
      return (PNG_INFO_PLTE);
   }
   return (0);
}

#ifdef PNG_sBIT_SUPPORTED
png_uint_32 PNGAPI
png_get_sBIT(png_structp png_ptr, png_infop info_ptr, png_color_8p *sig_bit)
{
   png_debug1(1, "in %s retrieval function", "sBIT");

   if (png_ptr != NULL && info_ptr != NULL && (info_ptr->valid & PNG_INFO_sBIT)
      && sig_bit != NULL)
   {
      *sig_bit = &(info_ptr->sig_bit);
      return (PNG_INFO_sBIT);
   }
   return (0);
}
#endif

#ifdef PNG_TEXT_SUPPORTED
png_uint_32 PNGAPI
png_get_text(png_structp png_ptr, png_infop info_ptr, png_textp *text_ptr,
   int *num_text)
{
   if (png_ptr != NULL && info_ptr != NULL && info_ptr->num_text > 0)
   {
      png_debug1(1, "in %s retrieval function",
         (png_ptr->chunk_name[0] == '\0' ? "text"
             : (png_const_charp)png_ptr->chunk_name));

      if (text_ptr != NULL)
         *text_ptr = info_ptr->text;

      if (num_text != NULL)
         *num_text = info_ptr->num_text;

      return ((png_uint_32)info_ptr->num_text);
   }
   if (num_text != NULL)
     *num_text = 0;
   return(0);
}
#endif

#ifdef PNG_tIME_SUPPORTED
png_uint_32 PNGAPI
png_get_tIME(png_structp png_ptr, png_infop info_ptr, png_timep *mod_time)
{
   png_debug1(1, "in %s retrieval function", "tIME");

   if (png_ptr != NULL && info_ptr != NULL && (info_ptr->valid & PNG_INFO_tIME)
       && mod_time != NULL)
   {
      *mod_time = &(info_ptr->mod_time);
      return (PNG_INFO_tIME);
   }
   return (0);
}
#endif

#ifdef PNG_tRNS_SUPPORTED
png_uint_32 PNGAPI
png_get_tRNS(png_structp png_ptr, png_infop info_ptr,
   png_bytep *trans, int *num_trans, png_color_16p *trans_values)
{
   png_uint_32 retval = 0;
   if (png_ptr != NULL && info_ptr != NULL && (info_ptr->valid & PNG_INFO_tRNS))
   {
      png_debug1(1, "in %s retrieval function", "tRNS");

      if (info_ptr->color_type == PNG_COLOR_TYPE_PALETTE)
      {
          if (trans != NULL)
          {
             *trans = info_ptr->trans;
             retval |= PNG_INFO_tRNS;
          }

          if (trans_values != NULL)
             *trans_values = &(info_ptr->trans_values);
      }
      else /* if (info_ptr->color_type != PNG_COLOR_TYPE_PALETTE) */
      {
          if (trans_values != NULL)
          {
             *trans_values = &(info_ptr->trans_values);
             retval |= PNG_INFO_tRNS;
          }

          if (trans != NULL)
             *trans = NULL;
      }
      if (num_trans != NULL)
      {
         *num_trans = info_ptr->num_trans;
         retval |= PNG_INFO_tRNS;
      }
   }
   return (retval);
}
#endif

#ifdef PNG_UNKNOWN_CHUNKS_SUPPORTED
png_uint_32 PNGAPI
png_get_unknown_chunks(png_structp png_ptr, png_infop info_ptr,
             png_unknown_chunkpp unknowns)
{
   if (png_ptr != NULL && info_ptr != NULL && unknowns != NULL)
   {
     *unknowns = info_ptr->unknown_chunks;
     return ((png_uint_32)info_ptr->unknown_chunks_num);
   }
   return (0);
}
#endif

#ifdef PNG_READ_RGB_TO_GRAY_SUPPORTED
png_byte PNGAPI
png_get_rgb_to_gray_status (png_structp png_ptr)
{
   return (png_byte)(png_ptr? png_ptr->rgb_to_gray_status : 0);
}
#endif

#ifdef PNG_USER_CHUNKS_SUPPORTED
png_voidp PNGAPI
png_get_user_chunk_ptr(png_structp png_ptr)
{
   return (png_ptr? png_ptr->user_chunk_ptr : NULL);
}
#endif

png_uint_32 PNGAPI
png_get_compression_buffer_size(png_structp png_ptr)
{
   return (png_uint_32)(png_ptr? png_ptr->zbuf_size : 0L);
}

#ifdef PNG_ASSEMBLER_CODE_SUPPORTED
#ifndef PNG_1_0_X
/* This function was added to libpng 1.2.0 and should exist by default */
png_uint_32 PNGAPI
png_get_asm_flags (png_structp png_ptr)
{
    /* Obsolete, to be removed from libpng-1.4.0 */
    return (png_ptr? 0L: 0L);
}

/* This function was added to libpng 1.2.0 and should exist by default */
png_uint_32 PNGAPI
png_get_asm_flagmask (int flag_select)
{
    /* Obsolete, to be removed from libpng-1.4.0 */
    flag_select=flag_select;
    return 0L;
}

    /* GRR:  could add this:   && defined(PNG_MMX_CODE_SUPPORTED) */
/* This function was added to libpng 1.2.0 */
png_uint_32 PNGAPI
png_get_mmx_flagmask (int flag_select, int *compilerID)
{
    /* Obsolete, to be removed from libpng-1.4.0 */
    flag_select=flag_select;
    *compilerID = -1;   /* unknown (i.e., no asm/MMX code compiled) */
    return 0L;
}

/* This function was added to libpng 1.2.0 */
png_byte PNGAPI
png_get_mmx_bitdepth_threshold (png_structp png_ptr)
{
    /* Obsolete, to be removed from libpng-1.4.0 */
    return (png_ptr? 0: 0);
}

/* This function was added to libpng 1.2.0 */
png_uint_32 PNGAPI
png_get_mmx_rowbytes_threshold (png_structp png_ptr)
{
    /* Obsolete, to be removed from libpng-1.4.0 */
    return (png_ptr? 0L: 0L);
}
#endif /* ?PNG_1_0_X */
#endif /* ?PNG_ASSEMBLER_CODE_SUPPORTED */

#ifdef PNG_SET_USER_LIMITS_SUPPORTED
/* These functions were added to libpng 1.2.6 but not enabled
* by default. They will be enabled in libpng-1.4.0 */
png_uint_32 PNGAPI
png_get_user_width_max (png_structp png_ptr)
{
    return (png_ptr? png_ptr->user_width_max : 0);
}
png_uint_32 PNGAPI
png_get_user_height_max (png_structp png_ptr)
{
    return (png_ptr? png_ptr->user_height_max : 0);
}
#endif /* ?PNG_SET_USER_LIMITS_SUPPORTED */

#endif /* PNG_READ_SUPPORTED || PNG_WRITE_SUPPORTED */
