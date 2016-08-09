
/* pngwrite.c - general routines to write a PNG file
 *
 * Last changed in libpng 1.6.19 [November 12, 2015]
 * Copyright (c) 1998-2002,2004,2006-2015 Glenn Randers-Pehrson
 * (Version 0.96 Copyright (c) 1996, 1997 Andreas Dilger)
 * (Version 0.88 Copyright (c) 1995, 1996 Guy Eric Schalnat, Group 42, Inc.)
 *
 * This code is released under the libpng license.
 * For conditions of distribution and use, see the disclaimer
 * and license in png.h
 */

#include "pngpriv.h"
#ifdef PNG_SIMPLIFIED_WRITE_STDIO_SUPPORTED
#  include <errno.h>
#endif /* SIMPLIFIED_WRITE_STDIO */

#ifdef PNG_WRITE_SUPPORTED

#ifdef PNG_WRITE_UNKNOWN_CHUNKS_SUPPORTED
/* Write out all the unknown chunks for the current given location */
static void
write_unknown_chunks(png_structrp png_ptr, png_const_inforp info_ptr,
   unsigned int where)
{
   if (info_ptr->unknown_chunks_num != 0)
   {
      png_const_unknown_chunkp up;

      png_debug(5, "writing extra chunks");

      for (up = info_ptr->unknown_chunks;
           up < info_ptr->unknown_chunks + info_ptr->unknown_chunks_num;
           ++up)
         if ((up->location & where) != 0)
      {
         /* If per-chunk unknown chunk handling is enabled use it, otherwise
          * just write the chunks the application has set.
          */
#ifdef PNG_SET_UNKNOWN_CHUNKS_SUPPORTED
         int keep = png_handle_as_unknown(png_ptr, up->name);

         /* NOTE: this code is radically different from the read side in the
          * matter of handling an ancillary unknown chunk.  In the read side
          * the default behavior is to discard it, in the code below the default
          * behavior is to write it.  Critical chunks are, however, only
          * written if explicitly listed or if the default is set to write all
          * unknown chunks.
          *
          * The default handling is also slightly weird - it is not possible to
          * stop the writing of all unsafe-to-copy chunks!
          *
          * TODO: REVIEW: this would seem to be a bug.
          */
         if (keep != PNG_HANDLE_CHUNK_NEVER &&
             ((up->name[3] & 0x20) /* safe-to-copy overrides everything */ ||
              keep == PNG_HANDLE_CHUNK_ALWAYS ||
              (keep == PNG_HANDLE_CHUNK_AS_DEFAULT &&
               png_ptr->unknown_default == PNG_HANDLE_CHUNK_ALWAYS)))
#endif
         {
            /* TODO: review, what is wrong with a zero length unknown chunk? */
            if (up->size == 0)
               png_warning(png_ptr, "Writing zero-length unknown chunk");

            png_write_chunk(png_ptr, up->name, up->data, up->size);
         }
      }
   }
}
#endif /* WRITE_UNKNOWN_CHUNKS */

/* Writes all the PNG information.  This is the suggested way to use the
 * library.  If you have a new chunk to add, make a function to write it,
 * and put it in the correct location here.  If you want the chunk written
 * after the image data, put it in png_write_end().  I strongly encourage
 * you to supply a PNG_INFO_ flag, and check info_ptr->valid before writing
 * the chunk, as that will keep the code from breaking if you want to just
 * write a plain PNG file.  If you have long comments, I suggest writing
 * them in png_write_end(), and compressing them.
 */
void PNGAPI
png_write_info_before_PLTE(png_structrp png_ptr, png_const_inforp info_ptr)
{
   png_debug(1, "in png_write_info_before_PLTE");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   if ((png_ptr->mode & PNG_WROTE_INFO_BEFORE_PLTE) == 0)
   {
      /* Write PNG signature */
      png_write_sig(png_ptr);

#ifdef PNG_MNG_FEATURES_SUPPORTED
      if ((png_ptr->mode & PNG_HAVE_PNG_SIGNATURE) != 0 && \
          png_ptr->mng_features_permitted != 0)
      {
         png_warning(png_ptr,
             "MNG features are not allowed in a PNG datastream");
         png_ptr->mng_features_permitted = 0;
      }
#endif

      /* Write IHDR information. */
      png_write_IHDR(png_ptr, info_ptr->width, info_ptr->height,
          info_ptr->bit_depth, info_ptr->color_type, info_ptr->compression_type,
          info_ptr->filter_type,
#ifdef PNG_WRITE_INTERLACING_SUPPORTED
          info_ptr->interlace_type
#else
          0
#endif
         );

      /* The rest of these check to see if the valid field has the appropriate
       * flag set, and if it does, writes the chunk.
       *
       * 1.6.0: COLORSPACE support controls the writing of these chunks too, and
       * the chunks will be written if the WRITE routine is there and
       * information * is available in the COLORSPACE. (See
       * png_colorspace_sync_info in png.c for where the valid flags get set.)
       *
       * Under certain circumstances the colorspace can be invalidated without
       * syncing the info_struct 'valid' flags; this happens if libpng detects
       * an error and calls png_error while the color space is being set, yet
       * the application continues writing the PNG.  So check the 'invalid'
       * flag here too.
       */
#ifdef PNG_GAMMA_SUPPORTED
#  ifdef PNG_WRITE_gAMA_SUPPORTED
      if ((info_ptr->colorspace.flags & PNG_COLORSPACE_INVALID) == 0 &&
          (info_ptr->colorspace.flags & PNG_COLORSPACE_FROM_gAMA) != 0 &&
          (info_ptr->valid & PNG_INFO_gAMA) != 0)
         png_write_gAMA_fixed(png_ptr, info_ptr->colorspace.gamma);
#  endif
#endif

#ifdef PNG_COLORSPACE_SUPPORTED
      /* Write only one of sRGB or an ICC profile.  If a profile was supplied
       * and it matches one of the known sRGB ones issue a warning.
       */
#  ifdef PNG_WRITE_iCCP_SUPPORTED
         if ((info_ptr->colorspace.flags & PNG_COLORSPACE_INVALID) == 0 &&
             (info_ptr->valid & PNG_INFO_iCCP) != 0)
         {
#    ifdef PNG_WRITE_sRGB_SUPPORTED
               if ((info_ptr->valid & PNG_INFO_sRGB) != 0)
                  png_app_warning(png_ptr,
                     "profile matches sRGB but writing iCCP instead");
#     endif

            png_write_iCCP(png_ptr, info_ptr->iccp_name,
               info_ptr->iccp_profile);
         }
#     ifdef PNG_WRITE_sRGB_SUPPORTED
         else
#     endif
#  endif

#  ifdef PNG_WRITE_sRGB_SUPPORTED
         if ((info_ptr->colorspace.flags & PNG_COLORSPACE_INVALID) == 0 &&
             (info_ptr->valid & PNG_INFO_sRGB) != 0)
            png_write_sRGB(png_ptr, info_ptr->colorspace.rendering_intent);
#  endif /* WRITE_sRGB */
#endif /* COLORSPACE */

#ifdef PNG_WRITE_sBIT_SUPPORTED
         if ((info_ptr->valid & PNG_INFO_sBIT) != 0)
            png_write_sBIT(png_ptr, &(info_ptr->sig_bit), info_ptr->color_type);
#endif

#ifdef PNG_COLORSPACE_SUPPORTED
#  ifdef PNG_WRITE_cHRM_SUPPORTED
         if ((info_ptr->colorspace.flags & PNG_COLORSPACE_INVALID) == 0 &&
             (info_ptr->colorspace.flags & PNG_COLORSPACE_FROM_cHRM) != 0 &&
             (info_ptr->valid & PNG_INFO_cHRM) != 0)
            png_write_cHRM_fixed(png_ptr, &info_ptr->colorspace.end_points_xy);
#  endif
#endif

#ifdef PNG_WRITE_UNKNOWN_CHUNKS_SUPPORTED
         write_unknown_chunks(png_ptr, info_ptr, PNG_HAVE_IHDR);
#endif

      png_ptr->mode |= PNG_WROTE_INFO_BEFORE_PLTE;
   }
}

void PNGAPI
png_write_info(png_structrp png_ptr, png_const_inforp info_ptr)
{
#if defined(PNG_WRITE_TEXT_SUPPORTED) || defined(PNG_WRITE_sPLT_SUPPORTED)
   int i;
#endif

   png_debug(1, "in png_write_info");

   if (png_ptr == NULL || info_ptr == NULL)
      return;

   png_write_info_before_PLTE(png_ptr, info_ptr);

   if ((info_ptr->valid & PNG_INFO_PLTE) != 0)
      png_write_PLTE(png_ptr, info_ptr->palette,
          (png_uint_32)info_ptr->num_palette);

   else if (info_ptr->color_type == PNG_COLOR_TYPE_PALETTE)
      png_error(png_ptr, "Valid palette required for paletted images");

#ifdef PNG_WRITE_tRNS_SUPPORTED
   if ((info_ptr->valid & PNG_INFO_tRNS) !=0)
   {
#ifdef PNG_WRITE_INVERT_ALPHA_SUPPORTED
      /* Invert the alpha channel (in tRNS) */
      if ((png_ptr->transformations & PNG_INVERT_ALPHA) != 0 &&
          info_ptr->color_type == PNG_COLOR_TYPE_PALETTE)
      {
         int j, jend;

         jend = info_ptr->num_trans;
         if (jend > PNG_MAX_PALETTE_LENGTH)
            jend = PNG_MAX_PALETTE_LENGTH;

         for (j = 0; j<jend; ++j)
            info_ptr->trans_alpha[j] =
               (png_byte)(255 - info_ptr->trans_alpha[j]);
      }
#endif
      png_write_tRNS(png_ptr, info_ptr->trans_alpha, &(info_ptr->trans_color),
          info_ptr->num_trans, info_ptr->color_type);
   }
#endif
#ifdef PNG_WRITE_bKGD_SUPPORTED
   if ((info_ptr->valid & PNG_INFO_bKGD) != 0)
      png_write_bKGD(png_ptr, &(info_ptr->background), info_ptr->color_type);
#endif

#ifdef PNG_WRITE_hIST_SUPPORTED
   if ((info_ptr->valid & PNG_INFO_hIST) != 0)
      png_write_hIST(png_ptr, info_ptr->hist, info_ptr->num_palette);
#endif

#ifdef PNG_WRITE_oFFs_SUPPORTED
   if ((info_ptr->valid & PNG_INFO_oFFs) != 0)
      png_write_oFFs(png_ptr, info_ptr->x_offset, info_ptr->y_offset,
          info_ptr->offset_unit_type);
#endif

#ifdef PNG_WRITE_pCAL_SUPPORTED
   if ((info_ptr->valid & PNG_INFO_pCAL) != 0)
      png_write_pCAL(png_ptr, info_ptr->pcal_purpose, info_ptr->pcal_X0,
          info_ptr->pcal_X1, info_ptr->pcal_type, info_ptr->pcal_nparams,
          info_ptr->pcal_units, info_ptr->pcal_params);
#endif

#ifdef PNG_WRITE_sCAL_SUPPORTED
   if ((info_ptr->valid & PNG_INFO_sCAL) != 0)
      png_write_sCAL_s(png_ptr, (int)info_ptr->scal_unit,
          info_ptr->scal_s_width, info_ptr->scal_s_height);
#endif /* sCAL */

#ifdef PNG_WRITE_pHYs_SUPPORTED
   if ((info_ptr->valid & PNG_INFO_pHYs) != 0)
      png_write_pHYs(png_ptr, info_ptr->x_pixels_per_unit,
          info_ptr->y_pixels_per_unit, info_ptr->phys_unit_type);
#endif /* pHYs */

#ifdef PNG_WRITE_tIME_SUPPORTED
   if ((info_ptr->valid & PNG_INFO_tIME) != 0)
   {
      png_write_tIME(png_ptr, &(info_ptr->mod_time));
      png_ptr->mode |= PNG_WROTE_tIME;
   }
#endif /* tIME */

#ifdef PNG_WRITE_sPLT_SUPPORTED
   if ((info_ptr->valid & PNG_INFO_sPLT) != 0)
      for (i = 0; i < (int)info_ptr->splt_palettes_num; i++)
         png_write_sPLT(png_ptr, info_ptr->splt_palettes + i);
#endif /* sPLT */

#ifdef PNG_WRITE_TEXT_SUPPORTED
   /* Check to see if we need to write text chunks */
   for (i = 0; i < info_ptr->num_text; i++)
   {
      png_debug2(2, "Writing header text chunk %d, type %d", i,
          info_ptr->text[i].compression);
      /* An internationalized chunk? */
      if (info_ptr->text[i].compression > 0)
      {
#ifdef PNG_WRITE_iTXt_SUPPORTED
         /* Write international chunk */
         png_write_iTXt(png_ptr,
             info_ptr->text[i].compression,
             info_ptr->text[i].key,
             info_ptr->text[i].lang,
             info_ptr->text[i].lang_key,
             info_ptr->text[i].text);
         /* Mark this chunk as written */
         if (info_ptr->text[i].compression == PNG_TEXT_COMPRESSION_NONE)
            info_ptr->text[i].compression = PNG_TEXT_COMPRESSION_NONE_WR;
         else
            info_ptr->text[i].compression = PNG_TEXT_COMPRESSION_zTXt_WR;
#else
         png_warning(png_ptr, "Unable to write international text");
#endif
      }

      /* If we want a compressed text chunk */
      else if (info_ptr->text[i].compression == PNG_TEXT_COMPRESSION_zTXt)
      {
#ifdef PNG_WRITE_zTXt_SUPPORTED
         /* Write compressed chunk */
         png_write_zTXt(png_ptr, info_ptr->text[i].key,
             info_ptr->text[i].text, info_ptr->text[i].compression);
         /* Mark this chunk as written */
         info_ptr->text[i].compression = PNG_TEXT_COMPRESSION_zTXt_WR;
#else
         png_warning(png_ptr, "Unable to write compressed text");
#endif
      }

      else if (info_ptr->text[i].compression == PNG_TEXT_COMPRESSION_NONE)
      {
#ifdef PNG_WRITE_tEXt_SUPPORTED
         /* Write uncompressed chunk */
         png_write_tEXt(png_ptr, info_ptr->text[i].key,
             info_ptr->text[i].text,
             0);
         /* Mark this chunk as written */
         info_ptr->text[i].compression = PNG_TEXT_COMPRESSION_NONE_WR;
#else
         /* Can't get here */
         png_warning(png_ptr, "Unable to write uncompressed text");
#endif
      }
   }
#endif /* tEXt */

#ifdef PNG_WRITE_UNKNOWN_CHUNKS_SUPPORTED
   write_unknown_chunks(png_ptr, info_ptr, PNG_HAVE_PLTE);
#endif
}

/* Writes the end of the PNG file.  If you don't want to write comments or
 * time information, you can pass NULL for info.  If you already wrote these
 * in png_write_info(), do not write them again here.  If you have long
 * comments, I suggest writing them here, and compressing them.
 */
void PNGAPI
png_write_end(png_structrp png_ptr, png_inforp info_ptr)
{
   png_debug(1, "in png_write_end");

   if (png_ptr == NULL)
      return;

   if ((png_ptr->mode & PNG_HAVE_IDAT) == 0)
      png_error(png_ptr, "No IDATs written into file");

#ifdef PNG_WRITE_CHECK_FOR_INVALID_INDEX_SUPPORTED
   if (png_ptr->num_palette_max > png_ptr->num_palette)
      png_benign_error(png_ptr, "Wrote palette index exceeding num_palette");
#endif

   /* See if user wants us to write information chunks */
   if (info_ptr != NULL)
   {
#ifdef PNG_WRITE_TEXT_SUPPORTED
      int i; /* local index variable */
#endif
#ifdef PNG_WRITE_tIME_SUPPORTED
      /* Check to see if user has supplied a time chunk */
      if ((info_ptr->valid & PNG_INFO_tIME) != 0 &&
          (png_ptr->mode & PNG_WROTE_tIME) == 0)
         png_write_tIME(png_ptr, &(info_ptr->mod_time));

#endif
#ifdef PNG_WRITE_TEXT_SUPPORTED
      /* Loop through comment chunks */
      for (i = 0; i < info_ptr->num_text; i++)
      {
         png_debug2(2, "Writing trailer text chunk %d, type %d", i,
            info_ptr->text[i].compression);
         /* An internationalized chunk? */
         if (info_ptr->text[i].compression > 0)
         {
#ifdef PNG_WRITE_iTXt_SUPPORTED
            /* Write international chunk */
            png_write_iTXt(png_ptr,
                info_ptr->text[i].compression,
                info_ptr->text[i].key,
                info_ptr->text[i].lang,
                info_ptr->text[i].lang_key,
                info_ptr->text[i].text);
            /* Mark this chunk as written */
            if (info_ptr->text[i].compression == PNG_TEXT_COMPRESSION_NONE)
               info_ptr->text[i].compression = PNG_TEXT_COMPRESSION_NONE_WR;
            else
               info_ptr->text[i].compression = PNG_TEXT_COMPRESSION_zTXt_WR;
#else
            png_warning(png_ptr, "Unable to write international text");
#endif
         }

         else if (info_ptr->text[i].compression >= PNG_TEXT_COMPRESSION_zTXt)
         {
#ifdef PNG_WRITE_zTXt_SUPPORTED
            /* Write compressed chunk */
            png_write_zTXt(png_ptr, info_ptr->text[i].key,
                info_ptr->text[i].text, info_ptr->text[i].compression);
            /* Mark this chunk as written */
            info_ptr->text[i].compression = PNG_TEXT_COMPRESSION_zTXt_WR;
#else
            png_warning(png_ptr, "Unable to write compressed text");
#endif
         }

         else if (info_ptr->text[i].compression == PNG_TEXT_COMPRESSION_NONE)
         {
#ifdef PNG_WRITE_tEXt_SUPPORTED
            /* Write uncompressed chunk */
            png_write_tEXt(png_ptr, info_ptr->text[i].key,
                info_ptr->text[i].text, 0);
            /* Mark this chunk as written */
            info_ptr->text[i].compression = PNG_TEXT_COMPRESSION_NONE_WR;
#else
            png_warning(png_ptr, "Unable to write uncompressed text");
#endif
         }
      }
#endif
#ifdef PNG_WRITE_UNKNOWN_CHUNKS_SUPPORTED
      write_unknown_chunks(png_ptr, info_ptr, PNG_AFTER_IDAT);
#endif
   }

   png_ptr->mode |= PNG_AFTER_IDAT;

   /* Write end of PNG file */
   png_write_IEND(png_ptr);

   /* This flush, added in libpng-1.0.8, removed from libpng-1.0.9beta03,
    * and restored again in libpng-1.2.30, may cause some applications that
    * do not set png_ptr->output_flush_fn to crash.  If your application
    * experiences a problem, please try building libpng with
    * PNG_WRITE_FLUSH_AFTER_IEND_SUPPORTED defined, and report the event to
    * png-mng-implement at lists.sf.net .
    */
#ifdef PNG_WRITE_FLUSH_SUPPORTED
#  ifdef PNG_WRITE_FLUSH_AFTER_IEND_SUPPORTED
   png_flush(png_ptr);
#  endif
#endif
}

#ifdef PNG_CONVERT_tIME_SUPPORTED
void PNGAPI
png_convert_from_struct_tm(png_timep ptime, PNG_CONST struct tm * ttime)
{
   png_debug(1, "in png_convert_from_struct_tm");

   ptime->year = (png_uint_16)(1900 + ttime->tm_year);
   ptime->month = (png_byte)(ttime->tm_mon + 1);
   ptime->day = (png_byte)ttime->tm_mday;
   ptime->hour = (png_byte)ttime->tm_hour;
   ptime->minute = (png_byte)ttime->tm_min;
   ptime->second = (png_byte)ttime->tm_sec;
}

void PNGAPI
png_convert_from_time_t(png_timep ptime, time_t ttime)
{
   struct tm *tbuf;

   png_debug(1, "in png_convert_from_time_t");

   tbuf = gmtime(&ttime);
   png_convert_from_struct_tm(ptime, tbuf);
}
#endif

/* Initialize png_ptr structure, and allocate any memory needed */
PNG_FUNCTION(png_structp,PNGAPI
png_create_write_struct,(png_const_charp user_png_ver, png_voidp error_ptr,
    png_error_ptr error_fn, png_error_ptr warn_fn),PNG_ALLOCATED)
{
#ifndef PNG_USER_MEM_SUPPORTED
   png_structrp png_ptr = png_create_png_struct(user_png_ver, error_ptr,
       error_fn, warn_fn, NULL, NULL, NULL);
#else
   return png_create_write_struct_2(user_png_ver, error_ptr, error_fn,
       warn_fn, NULL, NULL, NULL);
}

/* Alternate initialize png_ptr structure, and allocate any memory needed */
PNG_FUNCTION(png_structp,PNGAPI
png_create_write_struct_2,(png_const_charp user_png_ver, png_voidp error_ptr,
    png_error_ptr error_fn, png_error_ptr warn_fn, png_voidp mem_ptr,
    png_malloc_ptr malloc_fn, png_free_ptr free_fn),PNG_ALLOCATED)
{
   png_structrp png_ptr = png_create_png_struct(user_png_ver, error_ptr,
       error_fn, warn_fn, mem_ptr, malloc_fn, free_fn);
#endif /* USER_MEM */
   if (png_ptr != NULL)
   {
      /* Set the zlib control values to defaults; they can be overridden by the
       * application after the struct has been created.
       */
      png_ptr->zbuffer_size = PNG_ZBUF_SIZE;

      /* The 'zlib_strategy' setting is irrelevant because png_default_claim in
       * pngwutil.c defaults it according to whether or not filters will be
       * used, and ignores this setting.
       */
      png_ptr->zlib_strategy = PNG_Z_DEFAULT_STRATEGY;
      png_ptr->zlib_level = PNG_Z_DEFAULT_COMPRESSION;
      png_ptr->zlib_mem_level = 8;
      png_ptr->zlib_window_bits = 15;
      png_ptr->zlib_method = 8;

#ifdef PNG_WRITE_COMPRESSED_TEXT_SUPPORTED
      png_ptr->zlib_text_strategy = PNG_TEXT_Z_DEFAULT_STRATEGY;
      png_ptr->zlib_text_level = PNG_TEXT_Z_DEFAULT_COMPRESSION;
      png_ptr->zlib_text_mem_level = 8;
      png_ptr->zlib_text_window_bits = 15;
      png_ptr->zlib_text_method = 8;
#endif /* WRITE_COMPRESSED_TEXT */

      /* This is a highly dubious configuration option; by default it is off,
       * but it may be appropriate for private builds that are testing
       * extensions not conformant to the current specification, or of
       * applications that must not fail to write at all costs!
       */
#ifdef PNG_BENIGN_WRITE_ERRORS_SUPPORTED
      /* In stable builds only warn if an application error can be completely
       * handled.
       */
      png_ptr->flags |= PNG_FLAG_BENIGN_ERRORS_WARN;
#endif

      /* App warnings are warnings in release (or release candidate) builds but
       * are errors during development.
       */
#if PNG_RELEASE_BUILD
      png_ptr->flags |= PNG_FLAG_APP_WARNINGS_WARN;
#endif

      /* TODO: delay this, it can be done in png_init_io() (if the app doesn't
       * do it itself) avoiding setting the default function if it is not
       * required.
       */
      png_set_write_fn(png_ptr, NULL, NULL, NULL);
   }

   return png_ptr;
}


/* Write a few rows of image data.  If the image is interlaced,
 * either you will have to write the 7 sub images, or, if you
 * have called png_set_interlace_handling(), you will have to
 * "write" the image seven times.
 */
void PNGAPI
png_write_rows(png_structrp png_ptr, png_bytepp row,
    png_uint_32 num_rows)
{
   png_uint_32 i; /* row counter */
   png_bytepp rp; /* row pointer */

   png_debug(1, "in png_write_rows");

   if (png_ptr == NULL)
      return;

   /* Loop through the rows */
   for (i = 0, rp = row; i < num_rows; i++, rp++)
   {
      png_write_row(png_ptr, *rp);
   }
}

/* Write the image.  You only need to call this function once, even
 * if you are writing an interlaced image.
 */
void PNGAPI
png_write_image(png_structrp png_ptr, png_bytepp image)
{
   png_uint_32 i; /* row index */
   int pass, num_pass; /* pass variables */
   png_bytepp rp; /* points to current row */

   if (png_ptr == NULL)
      return;

   png_debug(1, "in png_write_image");

#ifdef PNG_WRITE_INTERLACING_SUPPORTED
   /* Initialize interlace handling.  If image is not interlaced,
    * this will set pass to 1
    */
   num_pass = png_set_interlace_handling(png_ptr);
#else
   num_pass = 1;
#endif
   /* Loop through passes */
   for (pass = 0; pass < num_pass; pass++)
   {
      /* Loop through image */
      for (i = 0, rp = image; i < png_ptr->height; i++, rp++)
      {
         png_write_row(png_ptr, *rp);
      }
   }
}

#ifdef PNG_MNG_FEATURES_SUPPORTED
/* Performs intrapixel differencing  */
static void
png_do_write_intrapixel(png_row_infop row_info, png_bytep row)
{
   png_debug(1, "in png_do_write_intrapixel");

   if ((row_info->color_type & PNG_COLOR_MASK_COLOR) != 0)
   {
      int bytes_per_pixel;
      png_uint_32 row_width = row_info->width;
      if (row_info->bit_depth == 8)
      {
         png_bytep rp;
         png_uint_32 i;

         if (row_info->color_type == PNG_COLOR_TYPE_RGB)
            bytes_per_pixel = 3;

         else if (row_info->color_type == PNG_COLOR_TYPE_RGB_ALPHA)
            bytes_per_pixel = 4;

         else
            return;

         for (i = 0, rp = row; i < row_width; i++, rp += bytes_per_pixel)
         {
            *(rp)     = (png_byte)(*rp       - *(rp + 1));
            *(rp + 2) = (png_byte)(*(rp + 2) - *(rp + 1));
         }
      }

#ifdef PNG_WRITE_16BIT_SUPPORTED
      else if (row_info->bit_depth == 16)
      {
         png_bytep rp;
         png_uint_32 i;

         if (row_info->color_type == PNG_COLOR_TYPE_RGB)
            bytes_per_pixel = 6;

         else if (row_info->color_type == PNG_COLOR_TYPE_RGB_ALPHA)
            bytes_per_pixel = 8;

         else
            return;

         for (i = 0, rp = row; i < row_width; i++, rp += bytes_per_pixel)
         {
            png_uint_32 s0   = (*(rp    ) << 8) | *(rp + 1);
            png_uint_32 s1   = (*(rp + 2) << 8) | *(rp + 3);
            png_uint_32 s2   = (*(rp + 4) << 8) | *(rp + 5);
            png_uint_32 red  = (png_uint_32)((s0 - s1) & 0xffffL);
            png_uint_32 blue = (png_uint_32)((s2 - s1) & 0xffffL);
            *(rp    ) = (png_byte)(red >> 8);
            *(rp + 1) = (png_byte)red;
            *(rp + 4) = (png_byte)(blue >> 8);
            *(rp + 5) = (png_byte)blue;
         }
      }
#endif /* WRITE_16BIT */
   }
}
#endif /* MNG_FEATURES */

/* Called by user to write a row of image data */
void PNGAPI
png_write_row(png_structrp png_ptr, png_const_bytep row)
{
   /* 1.5.6: moved from png_struct to be a local structure: */
   png_row_info row_info;

   if (png_ptr == NULL)
      return;

   png_debug2(1, "in png_write_row (row %u, pass %d)",
      png_ptr->row_number, png_ptr->pass);

   /* Initialize transformations and other stuff if first time */
   if (png_ptr->row_number == 0 && png_ptr->pass == 0)
   {
      /* Make sure we wrote the header info */
      if ((png_ptr->mode & PNG_WROTE_INFO_BEFORE_PLTE) == 0)
         png_error(png_ptr,
             "png_write_info was never called before png_write_row");

      /* Check for transforms that have been set but were defined out */
#if !defined(PNG_WRITE_INVERT_SUPPORTED) && defined(PNG_READ_INVERT_SUPPORTED)
      if ((png_ptr->transformations & PNG_INVERT_MONO) != 0)
         png_warning(png_ptr, "PNG_WRITE_INVERT_SUPPORTED is not defined");
#endif

#if !defined(PNG_WRITE_FILLER_SUPPORTED) && defined(PNG_READ_FILLER_SUPPORTED)
      if ((png_ptr->transformations & PNG_FILLER) != 0)
         png_warning(png_ptr, "PNG_WRITE_FILLER_SUPPORTED is not defined");
#endif
#if !defined(PNG_WRITE_PACKSWAP_SUPPORTED) && \
    defined(PNG_READ_PACKSWAP_SUPPORTED)
      if ((png_ptr->transformations & PNG_PACKSWAP) != 0)
         png_warning(png_ptr,
             "PNG_WRITE_PACKSWAP_SUPPORTED is not defined");
#endif

#if !defined(PNG_WRITE_PACK_SUPPORTED) && defined(PNG_READ_PACK_SUPPORTED)
      if ((png_ptr->transformations & PNG_PACK) != 0)
         png_warning(png_ptr, "PNG_WRITE_PACK_SUPPORTED is not defined");
#endif

#if !defined(PNG_WRITE_SHIFT_SUPPORTED) && defined(PNG_READ_SHIFT_SUPPORTED)
      if ((png_ptr->transformations & PNG_SHIFT) != 0)
         png_warning(png_ptr, "PNG_WRITE_SHIFT_SUPPORTED is not defined");
#endif

#if !defined(PNG_WRITE_BGR_SUPPORTED) && defined(PNG_READ_BGR_SUPPORTED)
      if ((png_ptr->transformations & PNG_BGR) != 0)
         png_warning(png_ptr, "PNG_WRITE_BGR_SUPPORTED is not defined");
#endif

#if !defined(PNG_WRITE_SWAP_SUPPORTED) && defined(PNG_READ_SWAP_SUPPORTED)
      if ((png_ptr->transformations & PNG_SWAP_BYTES) != 0)
         png_warning(png_ptr, "PNG_WRITE_SWAP_SUPPORTED is not defined");
#endif

      png_write_start_row(png_ptr);
   }

#ifdef PNG_WRITE_INTERLACING_SUPPORTED
   /* If interlaced and not interested in row, return */
   if (png_ptr->interlaced != 0 &&
       (png_ptr->transformations & PNG_INTERLACE) != 0)
   {
      switch (png_ptr->pass)
      {
         case 0:
            if ((png_ptr->row_number & 0x07) != 0)
            {
               png_write_finish_row(png_ptr);
               return;
            }
            break;

         case 1:
            if ((png_ptr->row_number & 0x07) != 0 || png_ptr->width < 5)
            {
               png_write_finish_row(png_ptr);
               return;
            }
            break;

         case 2:
            if ((png_ptr->row_number & 0x07) != 4)
            {
               png_write_finish_row(png_ptr);
               return;
            }
            break;

         case 3:
            if ((png_ptr->row_number & 0x03) != 0 || png_ptr->width < 3)
            {
               png_write_finish_row(png_ptr);
               return;
            }
            break;

         case 4:
            if ((png_ptr->row_number & 0x03) != 2)
            {
               png_write_finish_row(png_ptr);
               return;
            }
            break;

         case 5:
            if ((png_ptr->row_number & 0x01) != 0 || png_ptr->width < 2)
            {
               png_write_finish_row(png_ptr);
               return;
            }
            break;

         case 6:
            if ((png_ptr->row_number & 0x01) == 0)
            {
               png_write_finish_row(png_ptr);
               return;
            }
            break;

         default: /* error: ignore it */
            break;
      }
   }
#endif

   /* Set up row info for transformations */
   row_info.color_type = png_ptr->color_type;
   row_info.width = png_ptr->usr_width;
   row_info.channels = png_ptr->usr_channels;
   row_info.bit_depth = png_ptr->usr_bit_depth;
   row_info.pixel_depth = (png_byte)(row_info.bit_depth * row_info.channels);
   row_info.rowbytes = PNG_ROWBYTES(row_info.pixel_depth, row_info.width);

   png_debug1(3, "row_info->color_type = %d", row_info.color_type);
   png_debug1(3, "row_info->width = %u", row_info.width);
   png_debug1(3, "row_info->channels = %d", row_info.channels);
   png_debug1(3, "row_info->bit_depth = %d", row_info.bit_depth);
   png_debug1(3, "row_info->pixel_depth = %d", row_info.pixel_depth);
   png_debug1(3, "row_info->rowbytes = %lu", (unsigned long)row_info.rowbytes);

   /* Copy user's row into buffer, leaving room for filter byte. */
   memcpy(png_ptr->row_buf + 1, row, row_info.rowbytes);

#ifdef PNG_WRITE_INTERLACING_SUPPORTED
   /* Handle interlacing */
   if (png_ptr->interlaced && png_ptr->pass < 6 &&
       (png_ptr->transformations & PNG_INTERLACE) != 0)
   {
      png_do_write_interlace(&row_info, png_ptr->row_buf + 1, png_ptr->pass);
      /* This should always get caught above, but still ... */
      if (row_info.width == 0)
      {
         png_write_finish_row(png_ptr);
         return;
      }
   }
#endif

#ifdef PNG_WRITE_TRANSFORMS_SUPPORTED
   /* Handle other transformations */
   if (png_ptr->transformations != 0)
      png_do_write_transformations(png_ptr, &row_info);
#endif

   /* At this point the row_info pixel depth must match the 'transformed' depth,
    * which is also the output depth.
    */
   if (row_info.pixel_depth != png_ptr->pixel_depth ||
       row_info.pixel_depth != png_ptr->transformed_pixel_depth)
      png_error(png_ptr, "internal write transform logic error");

#ifdef PNG_MNG_FEATURES_SUPPORTED
   /* Write filter_method 64 (intrapixel differencing) only if
    * 1. Libpng was compiled with PNG_MNG_FEATURES_SUPPORTED and
    * 2. Libpng did not write a PNG signature (this filter_method is only
    *    used in PNG datastreams that are embedded in MNG datastreams) and
    * 3. The application called png_permit_mng_features with a mask that
    *    included PNG_FLAG_MNG_FILTER_64 and
    * 4. The filter_method is 64 and
    * 5. The color_type is RGB or RGBA
    */
   if ((png_ptr->mng_features_permitted & PNG_FLAG_MNG_FILTER_64) != 0 &&
       (png_ptr->filter_type == PNG_INTRAPIXEL_DIFFERENCING))
   {
      /* Intrapixel differencing */
      png_do_write_intrapixel(&row_info, png_ptr->row_buf + 1);
   }
#endif

/* Added at libpng-1.5.10 */
#ifdef PNG_WRITE_CHECK_FOR_INVALID_INDEX_SUPPORTED
   /* Check for out-of-range palette index */
   if (row_info.color_type == PNG_COLOR_TYPE_PALETTE &&
       png_ptr->num_palette_max >= 0)
      png_do_check_palette_indexes(png_ptr, &row_info);
#endif

   /* Find a filter if necessary, filter the row and write it out. */
   png_write_find_filter(png_ptr, &row_info);

   if (png_ptr->write_row_fn != NULL)
      (*(png_ptr->write_row_fn))(png_ptr, png_ptr->row_number, png_ptr->pass);
}

#ifdef PNG_WRITE_FLUSH_SUPPORTED
/* Set the automatic flush interval or 0 to turn flushing off */
void PNGAPI
png_set_flush(png_structrp png_ptr, int nrows)
{
   png_debug(1, "in png_set_flush");

   if (png_ptr == NULL)
      return;

   png_ptr->flush_dist = (nrows < 0 ? 0 : nrows);
}

/* Flush the current output buffers now */
void PNGAPI
png_write_flush(png_structrp png_ptr)
{
   png_debug(1, "in png_write_flush");

   if (png_ptr == NULL)
      return;

   /* We have already written out all of the data */
   if (png_ptr->row_number >= png_ptr->num_rows)
      return;

   png_compress_IDAT(png_ptr, NULL, 0, Z_SYNC_FLUSH);
   png_ptr->flush_rows = 0;
   png_flush(png_ptr);
}
#endif /* WRITE_FLUSH */

/* Free any memory used in png_ptr struct without freeing the struct itself. */
static void
png_write_destroy(png_structrp png_ptr)
{
   png_debug(1, "in png_write_destroy");

   /* Free any memory zlib uses */
   if ((png_ptr->flags & PNG_FLAG_ZSTREAM_INITIALIZED) != 0)
      deflateEnd(&png_ptr->zstream);

   /* Free our memory.  png_free checks NULL for us. */
   png_free_buffer_list(png_ptr, &png_ptr->zbuffer_list);
   png_free(png_ptr, png_ptr->row_buf);
   png_ptr->row_buf = NULL;
#ifdef PNG_WRITE_FILTER_SUPPORTED
   png_free(png_ptr, png_ptr->prev_row);
   png_free(png_ptr, png_ptr->try_row);
   png_free(png_ptr, png_ptr->tst_row);
   png_ptr->prev_row = NULL;
   png_ptr->try_row = NULL;
   png_ptr->tst_row = NULL;
#endif

#ifdef PNG_SET_UNKNOWN_CHUNKS_SUPPORTED
   png_free(png_ptr, png_ptr->chunk_list);
   png_ptr->chunk_list = NULL;
#endif

   /* The error handling and memory handling information is left intact at this
    * point: the jmp_buf may still have to be freed.  See png_destroy_png_struct
    * for how this happens.
    */
}

/* Free all memory used by the write.
 * In libpng 1.6.0 this API changed quietly to no longer accept a NULL value for
 * *png_ptr_ptr.  Prior to 1.6.0 it would accept such a value and it would free
 * the passed in info_structs but it would quietly fail to free any of the data
 * inside them.  In 1.6.0 it quietly does nothing (it has to be quiet because it
 * has no png_ptr.)
 */
void PNGAPI
png_destroy_write_struct(png_structpp png_ptr_ptr, png_infopp info_ptr_ptr)
{
   png_debug(1, "in png_destroy_write_struct");

   if (png_ptr_ptr != NULL)
   {
      png_structrp png_ptr = *png_ptr_ptr;

      if (png_ptr != NULL) /* added in libpng 1.6.0 */
      {
         png_destroy_info_struct(png_ptr, info_ptr_ptr);

         *png_ptr_ptr = NULL;
         png_write_destroy(png_ptr);
         png_destroy_png_struct(png_ptr);
      }
   }
}

/* Allow the application to select one or more row filters to use. */
void PNGAPI
png_set_filter(png_structrp png_ptr, int method, int filters)
{
   png_debug(1, "in png_set_filter");

   if (png_ptr == NULL)
      return;

#ifdef PNG_MNG_FEATURES_SUPPORTED
   if ((png_ptr->mng_features_permitted & PNG_FLAG_MNG_FILTER_64) != 0 &&
       (method == PNG_INTRAPIXEL_DIFFERENCING))
      method = PNG_FILTER_TYPE_BASE;

#endif
   if (method == PNG_FILTER_TYPE_BASE)
   {
      switch (filters & (PNG_ALL_FILTERS | 0x07))
      {
#ifdef PNG_WRITE_FILTER_SUPPORTED
         case 5:
         case 6:
         case 7: png_app_error(png_ptr, "Unknown row filter for method 0");
            /* FALL THROUGH */
#endif /* WRITE_FILTER */
         case PNG_FILTER_VALUE_NONE:
            png_ptr->do_filter = PNG_FILTER_NONE; break;

#ifdef PNG_WRITE_FILTER_SUPPORTED
         case PNG_FILTER_VALUE_SUB:
            png_ptr->do_filter = PNG_FILTER_SUB; break;

         case PNG_FILTER_VALUE_UP:
            png_ptr->do_filter = PNG_FILTER_UP; break;

         case PNG_FILTER_VALUE_AVG:
            png_ptr->do_filter = PNG_FILTER_AVG; break;

         case PNG_FILTER_VALUE_PAETH:
            png_ptr->do_filter = PNG_FILTER_PAETH; break;

         default:
            png_ptr->do_filter = (png_byte)filters; break;
#else
         default:
            png_app_error(png_ptr, "Unknown row filter for method 0");
#endif /* WRITE_FILTER */
      }

#ifdef PNG_WRITE_FILTER_SUPPORTED
      /* If we have allocated the row_buf, this means we have already started
       * with the image and we should have allocated all of the filter buffers
       * that have been selected.  If prev_row isn't already allocated, then
       * it is too late to start using the filters that need it, since we
       * will be missing the data in the previous row.  If an application
       * wants to start and stop using particular filters during compression,
       * it should start out with all of the filters, and then remove them
       * or add them back after the start of compression.
       *
       * NOTE: this is a nasty constraint on the code, because it means that the
       * prev_row buffer must be maintained even if there are currently no
       * 'prev_row' requiring filters active.
       */
      if (png_ptr->row_buf != NULL)
      {
         int num_filters;
         png_alloc_size_t buf_size;

         /* Repeat the checks in png_write_start_row; 1 pixel high or wide
          * images cannot benefit from certain filters.  If this isn't done here
          * the check below will fire on 1 pixel high images.
          */
         if (png_ptr->height == 1)
            filters &= ~(PNG_FILTER_UP|PNG_FILTER_AVG|PNG_FILTER_PAETH);

         if (png_ptr->width == 1)
            filters &= ~(PNG_FILTER_SUB|PNG_FILTER_AVG|PNG_FILTER_PAETH);

         if ((filters & (PNG_FILTER_UP|PNG_FILTER_AVG|PNG_FILTER_PAETH)) != 0
            && png_ptr->prev_row == NULL)
         {
            /* This is the error case, however it is benign - the previous row
             * is not available so the filter can't be used.  Just warn here.
             */
            png_app_warning(png_ptr,
               "png_set_filter: UP/AVG/PAETH cannot be added after start");
            filters &= ~(PNG_FILTER_UP|PNG_FILTER_AVG|PNG_FILTER_PAETH);
         }

         num_filters = 0;

         if (filters & PNG_FILTER_SUB)
            num_filters++;

         if (filters & PNG_FILTER_UP)
            num_filters++;

         if (filters & PNG_FILTER_AVG)
            num_filters++;

         if (filters & PNG_FILTER_PAETH)
            num_filters++;

         /* Allocate needed row buffers if they have not already been
          * allocated.
          */
         buf_size = PNG_ROWBYTES(png_ptr->usr_channels * png_ptr->usr_bit_depth,
             png_ptr->width) + 1;

         if (png_ptr->try_row == NULL)
            png_ptr->try_row = png_voidcast(png_bytep,
               png_malloc(png_ptr, buf_size));

         if (num_filters > 1)
         {
            if (png_ptr->tst_row == NULL)
               png_ptr->tst_row = png_voidcast(png_bytep,
                  png_malloc(png_ptr, buf_size));
         }
      }
      png_ptr->do_filter = (png_byte)filters;
#endif
   }
   else
      png_error(png_ptr, "Unknown custom filter method");
}

#ifdef PNG_WRITE_WEIGHTED_FILTER_SUPPORTED /* DEPRECATED */
/* Provide floating and fixed point APIs */
#ifdef PNG_FLOATING_POINT_SUPPORTED
void PNGAPI
png_set_filter_heuristics(png_structrp png_ptr, int heuristic_method,
    int num_weights, png_const_doublep filter_weights,
    png_const_doublep filter_costs)
{
   PNG_UNUSED(png_ptr)
   PNG_UNUSED(heuristic_method)
   PNG_UNUSED(num_weights)
   PNG_UNUSED(filter_weights)
   PNG_UNUSED(filter_costs)
}
#endif /* FLOATING_POINT */

#ifdef PNG_FIXED_POINT_SUPPORTED
void PNGAPI
png_set_filter_heuristics_fixed(png_structrp png_ptr, int heuristic_method,
    int num_weights, png_const_fixed_point_p filter_weights,
    png_const_fixed_point_p filter_costs)
{
   PNG_UNUSED(png_ptr)
   PNG_UNUSED(heuristic_method)
   PNG_UNUSED(num_weights)
   PNG_UNUSED(filter_weights)
   PNG_UNUSED(filter_costs)
}
#endif /* FIXED_POINT */
#endif /* WRITE_WEIGHTED_FILTER */

#ifdef PNG_WRITE_CUSTOMIZE_COMPRESSION_SUPPORTED
void PNGAPI
png_set_compression_level(png_structrp png_ptr, int level)
{
   png_debug(1, "in png_set_compression_level");

   if (png_ptr == NULL)
      return;

   png_ptr->zlib_level = level;
}

void PNGAPI
png_set_compression_mem_level(png_structrp png_ptr, int mem_level)
{
   png_debug(1, "in png_set_compression_mem_level");

   if (png_ptr == NULL)
      return;

   png_ptr->zlib_mem_level = mem_level;
}

void PNGAPI
png_set_compression_strategy(png_structrp png_ptr, int strategy)
{
   png_debug(1, "in png_set_compression_strategy");

   if (png_ptr == NULL)
      return;

   /* The flag setting here prevents the libpng dynamic selection of strategy.
    */
   png_ptr->flags |= PNG_FLAG_ZLIB_CUSTOM_STRATEGY;
   png_ptr->zlib_strategy = strategy;
}

/* If PNG_WRITE_OPTIMIZE_CMF_SUPPORTED is defined, libpng will use a
 * smaller value of window_bits if it can do so safely.
 */
void PNGAPI
png_set_compression_window_bits(png_structrp png_ptr, int window_bits)
{
   if (png_ptr == NULL)
      return;

   /* Prior to 1.6.0 this would warn but then set the window_bits value. This
    * meant that negative window bits values could be selected that would cause
    * libpng to write a non-standard PNG file with raw deflate or gzip
    * compressed IDAT or ancillary chunks.  Such files can be read and there is
    * no warning on read, so this seems like a very bad idea.
    */
   if (window_bits > 15)
   {
      png_warning(png_ptr, "Only compression windows <= 32k supported by PNG");
      window_bits = 15;
   }

   else if (window_bits < 8)
   {
      png_warning(png_ptr, "Only compression windows >= 256 supported by PNG");
      window_bits = 8;
   }

   png_ptr->zlib_window_bits = window_bits;
}

void PNGAPI
png_set_compression_method(png_structrp png_ptr, int method)
{
   png_debug(1, "in png_set_compression_method");

   if (png_ptr == NULL)
      return;

   /* This would produce an invalid PNG file if it worked, but it doesn't and
    * deflate will fault it, so it is harmless to just warn here.
    */
   if (method != 8)
      png_warning(png_ptr, "Only compression method 8 is supported by PNG");

   png_ptr->zlib_method = method;
}
#endif /* WRITE_CUSTOMIZE_COMPRESSION */

/* The following were added to libpng-1.5.4 */
#ifdef PNG_WRITE_CUSTOMIZE_ZTXT_COMPRESSION_SUPPORTED
void PNGAPI
png_set_text_compression_level(png_structrp png_ptr, int level)
{
   png_debug(1, "in png_set_text_compression_level");

   if (png_ptr == NULL)
      return;

   png_ptr->zlib_text_level = level;
}

void PNGAPI
png_set_text_compression_mem_level(png_structrp png_ptr, int mem_level)
{
   png_debug(1, "in png_set_text_compression_mem_level");

   if (png_ptr == NULL)
      return;

   png_ptr->zlib_text_mem_level = mem_level;
}

void PNGAPI
png_set_text_compression_strategy(png_structrp png_ptr, int strategy)
{
   png_debug(1, "in png_set_text_compression_strategy");

   if (png_ptr == NULL)
      return;

   png_ptr->zlib_text_strategy = strategy;
}

/* If PNG_WRITE_OPTIMIZE_CMF_SUPPORTED is defined, libpng will use a
 * smaller value of window_bits if it can do so safely.
 */
void PNGAPI
png_set_text_compression_window_bits(png_structrp png_ptr, int window_bits)
{
   if (png_ptr == NULL)
      return;

   if (window_bits > 15)
   {
      png_warning(png_ptr, "Only compression windows <= 32k supported by PNG");
      window_bits = 15;
   }

   else if (window_bits < 8)
   {
      png_warning(png_ptr, "Only compression windows >= 256 supported by PNG");
      window_bits = 8;
   }

   png_ptr->zlib_text_window_bits = window_bits;
}

void PNGAPI
png_set_text_compression_method(png_structrp png_ptr, int method)
{
   png_debug(1, "in png_set_text_compression_method");

   if (png_ptr == NULL)
      return;

   if (method != 8)
      png_warning(png_ptr, "Only compression method 8 is supported by PNG");

   png_ptr->zlib_text_method = method;
}
#endif /* WRITE_CUSTOMIZE_ZTXT_COMPRESSION */
/* end of API added to libpng-1.5.4 */

void PNGAPI
png_set_write_status_fn(png_structrp png_ptr, png_write_status_ptr write_row_fn)
{
   if (png_ptr == NULL)
      return;

   png_ptr->write_row_fn = write_row_fn;
}

#ifdef PNG_WRITE_USER_TRANSFORM_SUPPORTED
void PNGAPI
png_set_write_user_transform_fn(png_structrp png_ptr, png_user_transform_ptr
    write_user_transform_fn)
{
   png_debug(1, "in png_set_write_user_transform_fn");

   if (png_ptr == NULL)
      return;

   png_ptr->transformations |= PNG_USER_TRANSFORM;
   png_ptr->write_user_transform_fn = write_user_transform_fn;
}
#endif


#ifdef PNG_INFO_IMAGE_SUPPORTED
void PNGAPI
png_write_png(png_structrp png_ptr, png_inforp info_ptr,
    int transforms, voidp params)
{
   if (png_ptr == NULL || info_ptr == NULL)
      return;

   if ((info_ptr->valid & PNG_INFO_IDAT) == 0)
   {
      png_app_error(png_ptr, "no rows for png_write_image to write");
      return;
   }

   /* Write the file header information. */
   png_write_info(png_ptr, info_ptr);

   /* ------ these transformations don't touch the info structure ------- */

   /* Invert monochrome pixels */
   if ((transforms & PNG_TRANSFORM_INVERT_MONO) != 0)
#ifdef PNG_WRITE_INVERT_SUPPORTED
      png_set_invert_mono(png_ptr);
#else
      png_app_error(png_ptr, "PNG_TRANSFORM_INVERT_MONO not supported");
#endif

   /* Shift the pixels up to a legal bit depth and fill in
    * as appropriate to correctly scale the image.
    */
   if ((transforms & PNG_TRANSFORM_SHIFT) != 0)
#ifdef PNG_WRITE_SHIFT_SUPPORTED
      if ((info_ptr->valid & PNG_INFO_sBIT) != 0)
         png_set_shift(png_ptr, &info_ptr->sig_bit);
#else
      png_app_error(png_ptr, "PNG_TRANSFORM_SHIFT not supported");
#endif

   /* Pack pixels into bytes */
   if ((transforms & PNG_TRANSFORM_PACKING) != 0)
#ifdef PNG_WRITE_PACK_SUPPORTED
      png_set_packing(png_ptr);
#else
      png_app_error(png_ptr, "PNG_TRANSFORM_PACKING not supported");
#endif

   /* Swap location of alpha bytes from ARGB to RGBA */
   if ((transforms & PNG_TRANSFORM_SWAP_ALPHA) != 0)
#ifdef PNG_WRITE_SWAP_ALPHA_SUPPORTED
      png_set_swap_alpha(png_ptr);
#else
      png_app_error(png_ptr, "PNG_TRANSFORM_SWAP_ALPHA not supported");
#endif

   /* Remove a filler (X) from XRGB/RGBX/AG/GA into to convert it into
    * RGB, note that the code expects the input color type to be G or RGB; no
    * alpha channel.
    */
   if ((transforms & (PNG_TRANSFORM_STRIP_FILLER_AFTER|
       PNG_TRANSFORM_STRIP_FILLER_BEFORE)) != 0)
   {
#ifdef PNG_WRITE_FILLER_SUPPORTED
      if ((transforms & PNG_TRANSFORM_STRIP_FILLER_AFTER) != 0)
      {
         if ((transforms & PNG_TRANSFORM_STRIP_FILLER_BEFORE) != 0)
            png_app_error(png_ptr,
                "PNG_TRANSFORM_STRIP_FILLER: BEFORE+AFTER not supported");

         /* Continue if ignored - this is the pre-1.6.10 behavior */
         png_set_filler(png_ptr, 0, PNG_FILLER_AFTER);
      }

      else if ((transforms & PNG_TRANSFORM_STRIP_FILLER_BEFORE) != 0)
         png_set_filler(png_ptr, 0, PNG_FILLER_BEFORE);
#else
      png_app_error(png_ptr, "PNG_TRANSFORM_STRIP_FILLER not supported");
#endif
   }

   /* Flip BGR pixels to RGB */
   if ((transforms & PNG_TRANSFORM_BGR) != 0)
#ifdef PNG_WRITE_BGR_SUPPORTED
      png_set_bgr(png_ptr);
#else
      png_app_error(png_ptr, "PNG_TRANSFORM_BGR not supported");
#endif

   /* Swap bytes of 16-bit files to most significant byte first */
   if ((transforms & PNG_TRANSFORM_SWAP_ENDIAN) != 0)
#ifdef PNG_WRITE_SWAP_SUPPORTED
      png_set_swap(png_ptr);
#else
      png_app_error(png_ptr, "PNG_TRANSFORM_SWAP_ENDIAN not supported");
#endif

   /* Swap bits of 1-bit, 2-bit, 4-bit packed pixel formats */
   if ((transforms & PNG_TRANSFORM_PACKSWAP) != 0)
#ifdef PNG_WRITE_PACKSWAP_SUPPORTED
      png_set_packswap(png_ptr);
#else
      png_app_error(png_ptr, "PNG_TRANSFORM_PACKSWAP not supported");
#endif

   /* Invert the alpha channel from opacity to transparency */
   if ((transforms & PNG_TRANSFORM_INVERT_ALPHA) != 0)
#ifdef PNG_WRITE_INVERT_ALPHA_SUPPORTED
      png_set_invert_alpha(png_ptr);
#else
      png_app_error(png_ptr, "PNG_TRANSFORM_INVERT_ALPHA not supported");
#endif

   /* ----------------------- end of transformations ------------------- */

   /* Write the bits */
   png_write_image(png_ptr, info_ptr->row_pointers);

   /* It is REQUIRED to call this to finish writing the rest of the file */
   png_write_end(png_ptr, info_ptr);

   PNG_UNUSED(params)
}
#endif


#ifdef PNG_SIMPLIFIED_WRITE_SUPPORTED
/* Initialize the write structure - general purpose utility. */
static int
png_image_write_init(png_imagep image)
{
   png_structp png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, image,
       png_safe_error, png_safe_warning);

   if (png_ptr != NULL)
   {
      png_infop info_ptr = png_create_info_struct(png_ptr);

      if (info_ptr != NULL)
      {
         png_controlp control = png_voidcast(png_controlp,
             png_malloc_warn(png_ptr, (sizeof *control)));

         if (control != NULL)
         {
            memset(control, 0, (sizeof *control));

            control->png_ptr = png_ptr;
            control->info_ptr = info_ptr;
            control->for_write = 1;

            image->opaque = control;
            return 1;
         }

         /* Error clean up */
         png_destroy_info_struct(png_ptr, &info_ptr);
      }

      png_destroy_write_struct(&png_ptr, NULL);
   }

   return png_image_error(image, "png_image_write_: out of memory");
}

/* Arguments to png_image_write_main: */
typedef struct
{
   /* Arguments: */
   png_imagep      image;
   png_const_voidp buffer;
   png_int_32      row_stride;
   png_const_voidp colormap;
   int             convert_to_8bit;
   /* Local variables: */
   png_const_voidp first_row;
   ptrdiff_t       row_bytes;
   png_voidp       local_row;
   /* Byte count for memory writing */
   png_bytep        memory;
   png_alloc_size_t memory_bytes; /* not used for STDIO */
   png_alloc_size_t output_bytes; /* running total */
} png_image_write_control;

/* Write png_uint_16 input to a 16-bit PNG; the png_ptr has already been set to
 * do any necessary byte swapping.  The component order is defined by the
 * png_image format value.
 */
static int
png_write_image_16bit(png_voidp argument)
{
   png_image_write_control *display = png_voidcast(png_image_write_control*,
       argument);
   png_imagep image = display->image;
   png_structrp png_ptr = image->opaque->png_ptr;

   png_const_uint_16p input_row = png_voidcast(png_const_uint_16p,
       display->first_row);
   png_uint_16p output_row = png_voidcast(png_uint_16p, display->local_row);
   png_uint_16p row_end;
   const int channels = (image->format & PNG_FORMAT_FLAG_COLOR) != 0 ? 3 : 1;
   int aindex = 0;
   png_uint_32 y = image->height;

   if ((image->format & PNG_FORMAT_FLAG_ALPHA) != 0)
   {
#   ifdef PNG_SIMPLIFIED_WRITE_AFIRST_SUPPORTED
      if ((image->format & PNG_FORMAT_FLAG_AFIRST) != 0)
      {
         aindex = -1;
         ++input_row; /* To point to the first component */
         ++output_row;
      }
         else
            aindex = channels;
#     else
         aindex = channels;
#     endif
   }

   else
      png_error(png_ptr, "png_write_image: internal call error");

   /* Work out the output row end and count over this, note that the increment
    * above to 'row' means that row_end can actually be beyond the end of the
    * row; this is correct.
    */
   row_end = output_row + image->width * (channels+1);

   while (y-- > 0)
   {
      png_const_uint_16p in_ptr = input_row;
      png_uint_16p out_ptr = output_row;

      while (out_ptr < row_end)
      {
         const png_uint_16 alpha = in_ptr[aindex];
         png_uint_32 reciprocal = 0;
         int c;

         out_ptr[aindex] = alpha;

         /* Calculate a reciprocal.  The correct calculation is simply
          * component/alpha*65535 << 15. (I.e. 15 bits of precision); this
          * allows correct rounding by adding .5 before the shift.  'reciprocal'
          * is only initialized when required.
          */
         if (alpha > 0 && alpha < 65535)
            reciprocal = ((0xffff<<15)+(alpha>>1))/alpha;

         c = channels;
         do /* always at least one channel */
         {
            png_uint_16 component = *in_ptr++;

            /* The following gives 65535 for an alpha of 0, which is fine,
             * otherwise if 0/0 is represented as some other value there is more
             * likely to be a discontinuity which will probably damage
             * compression when moving from a fully transparent area to a
             * nearly transparent one.  (The assumption here is that opaque
             * areas tend not to be 0 intensity.)
             */
            if (component >= alpha)
               component = 65535;

            /* component<alpha, so component/alpha is less than one and
             * component*reciprocal is less than 2^31.
             */
            else if (component > 0 && alpha < 65535)
            {
               png_uint_32 calc = component * reciprocal;
               calc += 16384; /* round to nearest */
               component = (png_uint_16)(calc >> 15);
            }

            *out_ptr++ = component;
         }
         while (--c > 0);

         /* Skip to next component (skip the intervening alpha channel) */
         ++in_ptr;
         ++out_ptr;
      }

      png_write_row(png_ptr, png_voidcast(png_const_bytep, display->local_row));
      input_row += display->row_bytes/(sizeof (png_uint_16));
   }

   return 1;
}

/* Given 16-bit input (1 to 4 channels) write 8-bit output.  If an alpha channel
 * is present it must be removed from the components, the components are then
 * written in sRGB encoding.  No components are added or removed.
 *
 * Calculate an alpha reciprocal to reverse pre-multiplication.  As above the
 * calculation can be done to 15 bits of accuracy; however, the output needs to
 * be scaled in the range 0..255*65535, so include that scaling here.
 */
#   define UNP_RECIPROCAL(alpha) ((((0xffff*0xff)<<7)+(alpha>>1))/alpha)

static png_byte
png_unpremultiply(png_uint_32 component, png_uint_32 alpha,
   png_uint_32 reciprocal/*from the above macro*/)
{
   /* The following gives 1.0 for an alpha of 0, which is fine, otherwise if 0/0
    * is represented as some other value there is more likely to be a
    * discontinuity which will probably damage compression when moving from a
    * fully transparent area to a nearly transparent one.  (The assumption here
    * is that opaque areas tend not to be 0 intensity.)
    *
    * There is a rounding problem here; if alpha is less than 128 it will end up
    * as 0 when scaled to 8 bits.  To avoid introducing spurious colors into the
    * output change for this too.
    */
   if (component >= alpha || alpha < 128)
      return 255;

   /* component<alpha, so component/alpha is less than one and
    * component*reciprocal is less than 2^31.
    */
   else if (component > 0)
   {
      /* The test is that alpha/257 (rounded) is less than 255, the first value
       * that becomes 255 is 65407.
       * NOTE: this must agree with the PNG_DIV257 macro (which must, therefore,
       * be exact!)  [Could also test reciprocal != 0]
       */
      if (alpha < 65407)
      {
         component *= reciprocal;
         component += 64; /* round to nearest */
         component >>= 7;
      }

      else
         component *= 255;

      /* Convert the component to sRGB. */
      return (png_byte)PNG_sRGB_FROM_LINEAR(component);
   }

   else
      return 0;
}

static int
png_write_image_8bit(png_voidp argument)
{
   png_image_write_control *display = png_voidcast(png_image_write_control*,
       argument);
   png_imagep image = display->image;
   png_structrp png_ptr = image->opaque->png_ptr;

   png_const_uint_16p input_row = png_voidcast(png_const_uint_16p,
       display->first_row);
   png_bytep output_row = png_voidcast(png_bytep, display->local_row);
   png_uint_32 y = image->height;
   const int channels = (image->format & PNG_FORMAT_FLAG_COLOR) != 0 ? 3 : 1;

   if ((image->format & PNG_FORMAT_FLAG_ALPHA) != 0)
   {
      png_bytep row_end;
      int aindex;

#   ifdef PNG_SIMPLIFIED_WRITE_AFIRST_SUPPORTED
      if ((image->format & PNG_FORMAT_FLAG_AFIRST) != 0)
      {
         aindex = -1;
         ++input_row; /* To point to the first component */
         ++output_row;
      }

      else
#   endif
      aindex = channels;

      /* Use row_end in place of a loop counter: */
      row_end = output_row + image->width * (channels+1);

      while (y-- > 0)
      {
         png_const_uint_16p in_ptr = input_row;
         png_bytep out_ptr = output_row;

         while (out_ptr < row_end)
         {
            png_uint_16 alpha = in_ptr[aindex];
            png_byte alphabyte = (png_byte)PNG_DIV257(alpha);
            png_uint_32 reciprocal = 0;
            int c;

            /* Scale and write the alpha channel. */
            out_ptr[aindex] = alphabyte;

            if (alphabyte > 0 && alphabyte < 255)
               reciprocal = UNP_RECIPROCAL(alpha);

            c = channels;
            do /* always at least one channel */
               *out_ptr++ = png_unpremultiply(*in_ptr++, alpha, reciprocal);
            while (--c > 0);

            /* Skip to next component (skip the intervening alpha channel) */
            ++in_ptr;
            ++out_ptr;
         } /* while out_ptr < row_end */

         png_write_row(png_ptr, png_voidcast(png_const_bytep,
             display->local_row));
         input_row += display->row_bytes/(sizeof (png_uint_16));
      } /* while y */
   }

   else
   {
      /* No alpha channel, so the row_end really is the end of the row and it
       * is sufficient to loop over the components one by one.
       */
      png_bytep row_end = output_row + image->width * channels;

      while (y-- > 0)
      {
         png_const_uint_16p in_ptr = input_row;
         png_bytep out_ptr = output_row;

         while (out_ptr < row_end)
         {
            png_uint_32 component = *in_ptr++;

            component *= 255;
            *out_ptr++ = (png_byte)PNG_sRGB_FROM_LINEAR(component);
         }

         png_write_row(png_ptr, output_row);
         input_row += display->row_bytes/(sizeof (png_uint_16));
      }
   }

   return 1;
}

static void
png_image_set_PLTE(png_image_write_control *display)
{
   const png_imagep image = display->image;
   const void *cmap = display->colormap;
   const int entries = image->colormap_entries > 256 ? 256 :
       (int)image->colormap_entries;

   /* NOTE: the caller must check for cmap != NULL and entries != 0 */
   const png_uint_32 format = image->format;
   const int channels = PNG_IMAGE_SAMPLE_CHANNELS(format);

#   if defined(PNG_FORMAT_BGR_SUPPORTED) &&\
      defined(PNG_SIMPLIFIED_WRITE_AFIRST_SUPPORTED)
      const int afirst = (format & PNG_FORMAT_FLAG_AFIRST) != 0 &&
          (format & PNG_FORMAT_FLAG_ALPHA) != 0;
#   else
#     define afirst 0
#   endif

#   ifdef PNG_FORMAT_BGR_SUPPORTED
      const int bgr = (format & PNG_FORMAT_FLAG_BGR) != 0 ? 2 : 0;
#   else
#     define bgr 0
#   endif

   int i, num_trans;
   png_color palette[256];
   png_byte tRNS[256];

   memset(tRNS, 255, (sizeof tRNS));
   memset(palette, 0, (sizeof palette));

   for (i=num_trans=0; i<entries; ++i)
   {
      /* This gets automatically converted to sRGB with reversal of the
       * pre-multiplication if the color-map has an alpha channel.
       */
      if ((format & PNG_FORMAT_FLAG_LINEAR) != 0)
      {
         png_const_uint_16p entry = png_voidcast(png_const_uint_16p, cmap);

         entry += i * channels;

         if ((channels & 1) != 0) /* no alpha */
         {
            if (channels >= 3) /* RGB */
            {
               palette[i].blue = (png_byte)PNG_sRGB_FROM_LINEAR(255 *
                   entry[(2 ^ bgr)]);
               palette[i].green = (png_byte)PNG_sRGB_FROM_LINEAR(255 *
                   entry[1]);
               palette[i].red = (png_byte)PNG_sRGB_FROM_LINEAR(255 *
                   entry[bgr]);
            }

            else /* Gray */
               palette[i].blue = palette[i].red = palette[i].green =
                  (png_byte)PNG_sRGB_FROM_LINEAR(255 * *entry);
         }

         else /* alpha */
         {
            png_uint_16 alpha = entry[afirst ? 0 : channels-1];
            png_byte alphabyte = (png_byte)PNG_DIV257(alpha);
            png_uint_32 reciprocal = 0;

            /* Calculate a reciprocal, as in the png_write_image_8bit code above
             * this is designed to produce a value scaled to 255*65535 when
             * divided by 128 (i.e. asr 7).
             */
            if (alphabyte > 0 && alphabyte < 255)
               reciprocal = (((0xffff*0xff)<<7)+(alpha>>1))/alpha;

            tRNS[i] = alphabyte;
            if (alphabyte < 255)
               num_trans = i+1;

            if (channels >= 3) /* RGB */
            {
               palette[i].blue = png_unpremultiply(entry[afirst + (2 ^ bgr)],
                  alpha, reciprocal);
               palette[i].green = png_unpremultiply(entry[afirst + 1], alpha,
                  reciprocal);
               palette[i].red = png_unpremultiply(entry[afirst + bgr], alpha,
                  reciprocal);
            }

            else /* gray */
               palette[i].blue = palette[i].red = palette[i].green =
                  png_unpremultiply(entry[afirst], alpha, reciprocal);
         }
      }

      else /* Color-map has sRGB values */
      {
         png_const_bytep entry = png_voidcast(png_const_bytep, cmap);

         entry += i * channels;

         switch (channels)
         {
            case 4:
               tRNS[i] = entry[afirst ? 0 : 3];
               if (tRNS[i] < 255)
                  num_trans = i+1;
               /* FALL THROUGH */
            case 3:
               palette[i].blue = entry[afirst + (2 ^ bgr)];
               palette[i].green = entry[afirst + 1];
               palette[i].red = entry[afirst + bgr];
               break;

            case 2:
               tRNS[i] = entry[1 ^ afirst];
               if (tRNS[i] < 255)
                  num_trans = i+1;
               /* FALL THROUGH */
            case 1:
               palette[i].blue = palette[i].red = palette[i].green =
                  entry[afirst];
               break;

            default:
               break;
         }
      }
   }

#   ifdef afirst
#     undef afirst
#   endif
#   ifdef bgr
#     undef bgr
#   endif

   png_set_PLTE(image->opaque->png_ptr, image->opaque->info_ptr, palette,
      entries);

   if (num_trans > 0)
      png_set_tRNS(image->opaque->png_ptr, image->opaque->info_ptr, tRNS,
         num_trans, NULL);

   image->colormap_entries = entries;
}

static int
png_image_write_main(png_voidp argument)
{
   png_image_write_control *display = png_voidcast(png_image_write_control*,
      argument);
   png_imagep image = display->image;
   png_structrp png_ptr = image->opaque->png_ptr;
   png_inforp info_ptr = image->opaque->info_ptr;
   png_uint_32 format = image->format;

   /* The following four ints are actually booleans */
   int colormap = (format & PNG_FORMAT_FLAG_COLORMAP);
   int linear = !colormap && (format & PNG_FORMAT_FLAG_LINEAR); /* input */
   int alpha = !colormap && (format & PNG_FORMAT_FLAG_ALPHA);
   int write_16bit = linear && !colormap && (display->convert_to_8bit == 0);

#   ifdef PNG_BENIGN_ERRORS_SUPPORTED
      /* Make sure we error out on any bad situation */
      png_set_benign_errors(png_ptr, 0/*error*/);
#   endif

   /* Default the 'row_stride' parameter if required, also check the row stride
    * and total image size to ensure that they are within the system limits.
    */
   {
      const unsigned int channels = PNG_IMAGE_PIXEL_CHANNELS(image->format);

      if (image->width <= 0x7FFFFFFFU/channels) /* no overflow */
      {
         png_uint_32 check;
         const png_uint_32 png_row_stride = image->width * channels;

         if (display->row_stride == 0)
            display->row_stride = (png_int_32)/*SAFE*/png_row_stride;

         if (display->row_stride < 0)
            check = -display->row_stride;

         else
            check = display->row_stride;

         if (check >= png_row_stride)
         {
            /* Now check for overflow of the image buffer calculation; this
             * limits the whole image size to 32 bits for API compatibility with
             * the current, 32-bit, PNG_IMAGE_BUFFER_SIZE macro.
             */
            if (image->height > 0xFFFFFFFF/png_row_stride)
               png_error(image->opaque->png_ptr, "memory image too large");
         }

         else
            png_error(image->opaque->png_ptr, "supplied row stride too small");
      }

      else
         png_error(image->opaque->png_ptr, "image row stride too large");
   }

   /* Set the required transforms then write the rows in the correct order. */
   if ((format & PNG_FORMAT_FLAG_COLORMAP) != 0)
   {
      if (display->colormap != NULL && image->colormap_entries > 0)
      {
         png_uint_32 entries = image->colormap_entries;

         png_set_IHDR(png_ptr, info_ptr, image->width, image->height,
            entries > 16 ? 8 : (entries > 4 ? 4 : (entries > 2 ? 2 : 1)),
            PNG_COLOR_TYPE_PALETTE, PNG_INTERLACE_NONE,
            PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);

         png_image_set_PLTE(display);
      }

      else
         png_error(image->opaque->png_ptr,
            "no color-map for color-mapped image");
   }

   else
      png_set_IHDR(png_ptr, info_ptr, image->width, image->height,
         write_16bit ? 16 : 8,
         ((format & PNG_FORMAT_FLAG_COLOR) ? PNG_COLOR_MASK_COLOR : 0) +
         ((format & PNG_FORMAT_FLAG_ALPHA) ? PNG_COLOR_MASK_ALPHA : 0),
         PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);

   /* Counter-intuitively the data transformations must be called *after*
    * png_write_info, not before as in the read code, but the 'set' functions
    * must still be called before.  Just set the color space information, never
    * write an interlaced image.
    */

   if (write_16bit != 0)
   {
      /* The gamma here is 1.0 (linear) and the cHRM chunk matches sRGB. */
      png_set_gAMA_fixed(png_ptr, info_ptr, PNG_GAMMA_LINEAR);

      if ((image->flags & PNG_IMAGE_FLAG_COLORSPACE_NOT_sRGB) == 0)
         png_set_cHRM_fixed(png_ptr, info_ptr,
            /* color      x       y */
            /* white */ 31270, 32900,
            /* red   */ 64000, 33000,
            /* green */ 30000, 60000,
            /* blue  */ 15000,  6000
         );
   }

   else if ((image->flags & PNG_IMAGE_FLAG_COLORSPACE_NOT_sRGB) == 0)
      png_set_sRGB(png_ptr, info_ptr, PNG_sRGB_INTENT_PERCEPTUAL);

   /* Else writing an 8-bit file and the *colors* aren't sRGB, but the 8-bit
    * space must still be gamma encoded.
    */
   else
      png_set_gAMA_fixed(png_ptr, info_ptr, PNG_GAMMA_sRGB_INVERSE);

   /* Write the file header. */
   png_write_info(png_ptr, info_ptr);

   /* Now set up the data transformations (*after* the header is written),
    * remove the handled transformations from the 'format' flags for checking.
    *
    * First check for a little endian system if writing 16-bit files.
    */
   if (write_16bit != 0)
   {
      PNG_CONST png_uint_16 le = 0x0001;

      if ((*(png_const_bytep) & le) != 0)
         png_set_swap(png_ptr);
   }

#   ifdef PNG_SIMPLIFIED_WRITE_BGR_SUPPORTED
      if ((format & PNG_FORMAT_FLAG_BGR) != 0)
      {
         if (colormap == 0 && (format & PNG_FORMAT_FLAG_COLOR) != 0)
            png_set_bgr(png_ptr);
         format &= ~PNG_FORMAT_FLAG_BGR;
      }
#   endif

#   ifdef PNG_SIMPLIFIED_WRITE_AFIRST_SUPPORTED
      if ((format & PNG_FORMAT_FLAG_AFIRST) != 0)
      {
         if (colormap == 0 && (format & PNG_FORMAT_FLAG_ALPHA) != 0)
            png_set_swap_alpha(png_ptr);
         format &= ~PNG_FORMAT_FLAG_AFIRST;
      }
#   endif

   /* If there are 16 or fewer color-map entries we wrote a lower bit depth
    * above, but the application data is still byte packed.
    */
   if (colormap != 0 && image->colormap_entries <= 16)
      png_set_packing(png_ptr);

   /* That should have handled all (both) the transforms. */
   if ((format & ~(png_uint_32)(PNG_FORMAT_FLAG_COLOR | PNG_FORMAT_FLAG_LINEAR |
         PNG_FORMAT_FLAG_ALPHA | PNG_FORMAT_FLAG_COLORMAP)) != 0)
      png_error(png_ptr, "png_write_image: unsupported transformation");

   {
      png_const_bytep row = png_voidcast(png_const_bytep, display->buffer);
      ptrdiff_t row_bytes = display->row_stride;

      if (linear != 0)
         row_bytes *= (sizeof (png_uint_16));

      if (row_bytes < 0)
         row += (image->height-1) * (-row_bytes);

      display->first_row = row;
      display->row_bytes = row_bytes;
   }

   /* Apply 'fast' options if the flag is set. */
   if ((image->flags & PNG_IMAGE_FLAG_FAST) != 0)
   {
      png_set_filter(png_ptr, PNG_FILTER_TYPE_BASE, PNG_NO_FILTERS);
      /* NOTE: determined by experiment using pngstest, this reflects some
       * balance between the time to write the image once and the time to read
       * it about 50 times.  The speed-up in pngstest was about 10-20% of the
       * total (user) time on a heavily loaded system.
       */
#   ifdef PNG_WRITE_CUSTOMIZE_COMPRESSION_SUPPORTED
      png_set_compression_level(png_ptr, 3);
#   endif
   }

   /* Check for the cases that currently require a pre-transform on the row
    * before it is written.  This only applies when the input is 16-bit and
    * either there is an alpha channel or it is converted to 8-bit.
    */
   if ((linear != 0 && alpha != 0 ) ||
       (colormap == 0 && display->convert_to_8bit != 0))
   {
      png_bytep row = png_voidcast(png_bytep, png_malloc(png_ptr,
         png_get_rowbytes(png_ptr, info_ptr)));
      int result;

      display->local_row = row;
      if (write_16bit != 0)
         result = png_safe_execute(image, png_write_image_16bit, display);
      else
         result = png_safe_execute(image, png_write_image_8bit, display);
      display->local_row = NULL;

      png_free(png_ptr, row);

      /* Skip the 'write_end' on error: */
      if (result == 0)
         return 0;
   }

   /* Otherwise this is the case where the input is in a format currently
    * supported by the rest of the libpng write code; call it directly.
    */
   else
   {
      png_const_bytep row = png_voidcast(png_const_bytep, display->first_row);
      ptrdiff_t row_bytes = display->row_bytes;
      png_uint_32 y = image->height;

      while (y-- > 0)
      {
         png_write_row(png_ptr, row);
         row += row_bytes;
      }
   }

   png_write_end(png_ptr, info_ptr);
   return 1;
}


static void (PNGCBAPI
image_memory_write)(png_structp png_ptr, png_bytep/*const*/ data,
   png_size_t size)
{
   png_image_write_control *display = png_voidcast(png_image_write_control*,
      png_ptr->io_ptr/*backdoor: png_get_io_ptr(png_ptr)*/);
   const png_alloc_size_t ob = display->output_bytes;

   /* Check for overflow; this should never happen: */
   if (size <= ((png_alloc_size_t)-1) - ob)
   {
      /* I don't think libpng ever does this, but just in case: */
      if (size > 0)
      {
         if (display->memory_bytes >= ob+size) /* writing */
            memcpy(display->memory+ob, data, size);

         /* Always update the size: */
         display->output_bytes = ob+size;
      }
   }

   else
      png_error(png_ptr, "png_image_write_to_memory: PNG too big");
}

static void (PNGCBAPI
image_memory_flush)(png_structp png_ptr)
{
   PNG_UNUSED(png_ptr)
}

static int
png_image_write_memory(png_voidp argument)
{
   png_image_write_control *display = png_voidcast(png_image_write_control*,
      argument);

   /* The rest of the memory-specific init and write_main in an error protected
    * environment.  This case needs to use callbacks for the write operations
    * since libpng has no built in support for writing to memory.
    */
   png_set_write_fn(display->image->opaque->png_ptr, display/*io_ptr*/,
         image_memory_write, image_memory_flush);

   return png_image_write_main(display);
}

int PNGAPI
png_image_write_to_memory(png_imagep image, void *memory,
   png_alloc_size_t * PNG_RESTRICT memory_bytes, int convert_to_8bit,
   const void *buffer, png_int_32 row_stride, const void *colormap)
{
   /* Write the image to the given buffer, or count the bytes if it is NULL */
   if (image != NULL && image->version == PNG_IMAGE_VERSION)
   {
      if (memory_bytes != NULL && buffer != NULL)
      {
         /* This is to give the caller an easier error detection in the NULL
          * case and guard against uninitialized variable problems:
          */
         if (memory == NULL)
            *memory_bytes = 0;

         if (png_image_write_init(image) != 0)
         {
            png_image_write_control display;
            int result;

            memset(&display, 0, (sizeof display));
            display.image = image;
            display.buffer = buffer;
            display.row_stride = row_stride;
            display.colormap = colormap;
            display.convert_to_8bit = convert_to_8bit;
            display.memory = png_voidcast(png_bytep, memory);
            display.memory_bytes = *memory_bytes;
            display.output_bytes = 0;

            result = png_safe_execute(image, png_image_write_memory, &display);
            png_image_free(image);

            /* write_memory returns true even if we ran out of buffer. */
            if (result)
            {
               /* On out-of-buffer this function returns '0' but still updates
                * memory_bytes:
                */
               if (memory != NULL && display.output_bytes > *memory_bytes)
                  result = 0;

               *memory_bytes = display.output_bytes;
            }

            return result;
         }

         else
            return 0;
      }

      else
         return png_image_error(image,
            "png_image_write_to_memory: invalid argument");
   }

   else if (image != NULL)
      return png_image_error(image,
         "png_image_write_to_memory: incorrect PNG_IMAGE_VERSION");

   else
      return 0;
}

#ifdef PNG_SIMPLIFIED_WRITE_STDIO_SUPPORTED
int PNGAPI
png_image_write_to_stdio(png_imagep image, FILE *file, int convert_to_8bit,
   const void *buffer, png_int_32 row_stride, const void *colormap)
{
   /* Write the image to the given (FILE*). */
   if (image != NULL && image->version == PNG_IMAGE_VERSION)
   {
      if (file != NULL && buffer != NULL)
      {
         if (png_image_write_init(image) != 0)
         {
            png_image_write_control display;
            int result;

            /* This is slightly evil, but png_init_io doesn't do anything other
             * than this and we haven't changed the standard IO functions so
             * this saves a 'safe' function.
             */
            image->opaque->png_ptr->io_ptr = file;

            memset(&display, 0, (sizeof display));
            display.image = image;
            display.buffer = buffer;
            display.row_stride = row_stride;
            display.colormap = colormap;
            display.convert_to_8bit = convert_to_8bit;

            result = png_safe_execute(image, png_image_write_main, &display);
            png_image_free(image);
            return result;
         }

         else
            return 0;
      }

      else
         return png_image_error(image,
            "png_image_write_to_stdio: invalid argument");
   }

   else if (image != NULL)
      return png_image_error(image,
         "png_image_write_to_stdio: incorrect PNG_IMAGE_VERSION");

   else
      return 0;
}

int PNGAPI
png_image_write_to_file(png_imagep image, const char *file_name,
   int convert_to_8bit, const void *buffer, png_int_32 row_stride,
   const void *colormap)
{
   /* Write the image to the named file. */
   if (image != NULL && image->version == PNG_IMAGE_VERSION)
   {
      if (file_name != NULL && buffer != NULL)
      {
         FILE *fp = fopen(file_name, "wb");

         if (fp != NULL)
         {
            if (png_image_write_to_stdio(image, fp, convert_to_8bit, buffer,
               row_stride, colormap) != 0)
            {
               int error; /* from fflush/fclose */

               /* Make sure the file is flushed correctly. */
               if (fflush(fp) == 0 && ferror(fp) == 0)
               {
                  if (fclose(fp) == 0)
                     return 1;

                  error = errno; /* from fclose */
               }

               else
               {
                  error = errno; /* from fflush or ferror */
                  (void)fclose(fp);
               }

               (void)remove(file_name);
               /* The image has already been cleaned up; this is just used to
                * set the error (because the original write succeeded).
                */
               return png_image_error(image, strerror(error));
            }

            else
            {
               /* Clean up: just the opened file. */
               (void)fclose(fp);
               (void)remove(file_name);
               return 0;
            }
         }

         else
            return png_image_error(image, strerror(errno));
      }

      else
         return png_image_error(image,
            "png_image_write_to_file: invalid argument");
   }

   else if (image != NULL)
      return png_image_error(image,
         "png_image_write_to_file: incorrect PNG_IMAGE_VERSION");

   else
      return 0;
}
#endif /* SIMPLIFIED_WRITE_STDIO */
#endif /* SIMPLIFIED_WRITE */
#endif /* WRITE */
