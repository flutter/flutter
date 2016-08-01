
/* pngpread.c - read a png file in push mode
 *
 * Last changed in libpng 1.6.18 [July 23, 2015]
 * Copyright (c) 1998-2002,2004,2006-2015 Glenn Randers-Pehrson
 * (Version 0.96 Copyright (c) 1996, 1997 Andreas Dilger)
 * (Version 0.88 Copyright (c) 1995, 1996 Guy Eric Schalnat, Group 42, Inc.)
 *
 * This code is released under the libpng license.
 * For conditions of distribution and use, see the disclaimer
 * and license in png.h
 */

#include "pngpriv.h"

#ifdef PNG_PROGRESSIVE_READ_SUPPORTED

/* Push model modes */
#define PNG_READ_SIG_MODE   0
#define PNG_READ_CHUNK_MODE 1
#define PNG_READ_IDAT_MODE  2
#define PNG_READ_tEXt_MODE  4
#define PNG_READ_zTXt_MODE  5
#define PNG_READ_DONE_MODE  6
#define PNG_READ_iTXt_MODE  7
#define PNG_ERROR_MODE      8

#define PNG_PUSH_SAVE_BUFFER_IF_FULL \
if (png_ptr->push_length + 4 > png_ptr->buffer_size) \
   { png_push_save_buffer(png_ptr); return; }
#define PNG_PUSH_SAVE_BUFFER_IF_LT(N) \
if (png_ptr->buffer_size < N) \
   { png_push_save_buffer(png_ptr); return; }

void PNGAPI
png_process_data(png_structrp png_ptr, png_inforp info_ptr,
    png_bytep buffer, png_size_t buffer_size)
{
   if (png_ptr == NULL || info_ptr == NULL)
      return;

   png_push_restore_buffer(png_ptr, buffer, buffer_size);

   while (png_ptr->buffer_size)
   {
      png_process_some_data(png_ptr, info_ptr);
   }
}

png_size_t PNGAPI
png_process_data_pause(png_structrp png_ptr, int save)
{
   if (png_ptr != NULL)
   {
      /* It's easiest for the caller if we do the save; then the caller doesn't
       * have to supply the same data again:
       */
      if (save != 0)
         png_push_save_buffer(png_ptr);
      else
      {
         /* This includes any pending saved bytes: */
         png_size_t remaining = png_ptr->buffer_size;
         png_ptr->buffer_size = 0;

         /* So subtract the saved buffer size, unless all the data
          * is actually 'saved', in which case we just return 0
          */
         if (png_ptr->save_buffer_size < remaining)
            return remaining - png_ptr->save_buffer_size;
      }
   }

   return 0;
}

png_uint_32 PNGAPI
png_process_data_skip(png_structrp png_ptr)
{
  /* TODO: Deprecate and remove this API.
   * Somewhere the implementation of this seems to have been lost,
   * or abandoned.  It was only to support some internal back-door access
   * to png_struct) in libpng-1.4.x.
   */
   png_app_warning(png_ptr,
"png_process_data_skip is not implemented in any current version of libpng");
   return 0;
}

/* What we do with the incoming data depends on what we were previously
 * doing before we ran out of data...
 */
void /* PRIVATE */
png_process_some_data(png_structrp png_ptr, png_inforp info_ptr)
{
   if (png_ptr == NULL)
      return;

   switch (png_ptr->process_mode)
   {
      case PNG_READ_SIG_MODE:
      {
         png_push_read_sig(png_ptr, info_ptr);
         break;
      }

      case PNG_READ_CHUNK_MODE:
      {
         png_push_read_chunk(png_ptr, info_ptr);
         break;
      }

      case PNG_READ_IDAT_MODE:
      {
         png_push_read_IDAT(png_ptr);
         break;
      }

      default:
      {
         png_ptr->buffer_size = 0;
         break;
      }
   }
}

/* Read any remaining signature bytes from the stream and compare them with
 * the correct PNG signature.  It is possible that this routine is called
 * with bytes already read from the signature, either because they have been
 * checked by the calling application, or because of multiple calls to this
 * routine.
 */
void /* PRIVATE */
png_push_read_sig(png_structrp png_ptr, png_inforp info_ptr)
{
   png_size_t num_checked = png_ptr->sig_bytes, /* SAFE, does not exceed 8 */
       num_to_check = 8 - num_checked;

   if (png_ptr->buffer_size < num_to_check)
   {
      num_to_check = png_ptr->buffer_size;
   }

   png_push_fill_buffer(png_ptr, &(info_ptr->signature[num_checked]),
       num_to_check);
   png_ptr->sig_bytes = (png_byte)(png_ptr->sig_bytes + num_to_check);

   if (png_sig_cmp(info_ptr->signature, num_checked, num_to_check))
   {
      if (num_checked < 4 &&
          png_sig_cmp(info_ptr->signature, num_checked, num_to_check - 4))
         png_error(png_ptr, "Not a PNG file");

      else
         png_error(png_ptr, "PNG file corrupted by ASCII conversion");
   }
   else
   {
      if (png_ptr->sig_bytes >= 8)
      {
         png_ptr->process_mode = PNG_READ_CHUNK_MODE;
      }
   }
}

void /* PRIVATE */
png_push_read_chunk(png_structrp png_ptr, png_inforp info_ptr)
{
   png_uint_32 chunk_name;
#ifdef PNG_HANDLE_AS_UNKNOWN_SUPPORTED
   int keep; /* unknown handling method */
#endif

   /* First we make sure we have enough data for the 4-byte chunk name
    * and the 4-byte chunk length before proceeding with decoding the
    * chunk data.  To fully decode each of these chunks, we also make
    * sure we have enough data in the buffer for the 4-byte CRC at the
    * end of every chunk (except IDAT, which is handled separately).
    */
   if ((png_ptr->mode & PNG_HAVE_CHUNK_HEADER) == 0)
   {
      png_byte chunk_length[4];
      png_byte chunk_tag[4];

      PNG_PUSH_SAVE_BUFFER_IF_LT(8)
      png_push_fill_buffer(png_ptr, chunk_length, 4);
      png_ptr->push_length = png_get_uint_31(png_ptr, chunk_length);
      png_reset_crc(png_ptr);
      png_crc_read(png_ptr, chunk_tag, 4);
      png_ptr->chunk_name = PNG_CHUNK_FROM_STRING(chunk_tag);
      png_check_chunk_name(png_ptr, png_ptr->chunk_name);
      png_ptr->mode |= PNG_HAVE_CHUNK_HEADER;
   }

   chunk_name = png_ptr->chunk_name;

   if (chunk_name == png_IDAT)
   {
      if ((png_ptr->mode & PNG_AFTER_IDAT) != 0)
         png_ptr->mode |= PNG_HAVE_CHUNK_AFTER_IDAT;

      /* If we reach an IDAT chunk, this means we have read all of the
       * header chunks, and we can start reading the image (or if this
       * is called after the image has been read - we have an error).
       */
      if ((png_ptr->mode & PNG_HAVE_IHDR) == 0)
         png_error(png_ptr, "Missing IHDR before IDAT");

      else if (png_ptr->color_type == PNG_COLOR_TYPE_PALETTE &&
          (png_ptr->mode & PNG_HAVE_PLTE) == 0)
         png_error(png_ptr, "Missing PLTE before IDAT");

      png_ptr->mode |= PNG_HAVE_IDAT;
      png_ptr->process_mode = PNG_READ_IDAT_MODE;

      if ((png_ptr->mode & PNG_HAVE_CHUNK_AFTER_IDAT) == 0)
         if (png_ptr->push_length == 0)
            return;

      if ((png_ptr->mode & PNG_AFTER_IDAT) != 0)
         png_benign_error(png_ptr, "Too many IDATs found");
   }

   if (chunk_name == png_IHDR)
   {
      if (png_ptr->push_length != 13)
         png_error(png_ptr, "Invalid IHDR length");

      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_IHDR(png_ptr, info_ptr, png_ptr->push_length);
   }

   else if (chunk_name == png_IEND)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_IEND(png_ptr, info_ptr, png_ptr->push_length);

      png_ptr->process_mode = PNG_READ_DONE_MODE;
      png_push_have_end(png_ptr, info_ptr);
   }

#ifdef PNG_HANDLE_AS_UNKNOWN_SUPPORTED
   else if ((keep = png_chunk_unknown_handling(png_ptr, chunk_name)) != 0)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_unknown(png_ptr, info_ptr, png_ptr->push_length, keep);

      if (chunk_name == png_PLTE)
         png_ptr->mode |= PNG_HAVE_PLTE;
   }
#endif

   else if (chunk_name == png_PLTE)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_PLTE(png_ptr, info_ptr, png_ptr->push_length);
   }

   else if (chunk_name == png_IDAT)
   {
      png_ptr->idat_size = png_ptr->push_length;
      png_ptr->process_mode = PNG_READ_IDAT_MODE;
      png_push_have_info(png_ptr, info_ptr);
      png_ptr->zstream.avail_out =
          (uInt) PNG_ROWBYTES(png_ptr->pixel_depth,
          png_ptr->iwidth) + 1;
      png_ptr->zstream.next_out = png_ptr->row_buf;
      return;
   }

#ifdef PNG_READ_gAMA_SUPPORTED
   else if (png_ptr->chunk_name == png_gAMA)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_gAMA(png_ptr, info_ptr, png_ptr->push_length);
   }

#endif
#ifdef PNG_READ_sBIT_SUPPORTED
   else if (png_ptr->chunk_name == png_sBIT)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_sBIT(png_ptr, info_ptr, png_ptr->push_length);
   }

#endif
#ifdef PNG_READ_cHRM_SUPPORTED
   else if (png_ptr->chunk_name == png_cHRM)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_cHRM(png_ptr, info_ptr, png_ptr->push_length);
   }

#endif
#ifdef PNG_READ_sRGB_SUPPORTED
   else if (chunk_name == png_sRGB)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_sRGB(png_ptr, info_ptr, png_ptr->push_length);
   }

#endif
#ifdef PNG_READ_iCCP_SUPPORTED
   else if (png_ptr->chunk_name == png_iCCP)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_iCCP(png_ptr, info_ptr, png_ptr->push_length);
   }

#endif
#ifdef PNG_READ_sPLT_SUPPORTED
   else if (chunk_name == png_sPLT)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_sPLT(png_ptr, info_ptr, png_ptr->push_length);
   }

#endif
#ifdef PNG_READ_tRNS_SUPPORTED
   else if (chunk_name == png_tRNS)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_tRNS(png_ptr, info_ptr, png_ptr->push_length);
   }

#endif
#ifdef PNG_READ_bKGD_SUPPORTED
   else if (chunk_name == png_bKGD)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_bKGD(png_ptr, info_ptr, png_ptr->push_length);
   }

#endif
#ifdef PNG_READ_hIST_SUPPORTED
   else if (chunk_name == png_hIST)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_hIST(png_ptr, info_ptr, png_ptr->push_length);
   }

#endif
#ifdef PNG_READ_pHYs_SUPPORTED
   else if (chunk_name == png_pHYs)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_pHYs(png_ptr, info_ptr, png_ptr->push_length);
   }

#endif
#ifdef PNG_READ_oFFs_SUPPORTED
   else if (chunk_name == png_oFFs)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_oFFs(png_ptr, info_ptr, png_ptr->push_length);
   }
#endif

#ifdef PNG_READ_pCAL_SUPPORTED
   else if (chunk_name == png_pCAL)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_pCAL(png_ptr, info_ptr, png_ptr->push_length);
   }

#endif
#ifdef PNG_READ_sCAL_SUPPORTED
   else if (chunk_name == png_sCAL)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_sCAL(png_ptr, info_ptr, png_ptr->push_length);
   }

#endif
#ifdef PNG_READ_tIME_SUPPORTED
   else if (chunk_name == png_tIME)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_tIME(png_ptr, info_ptr, png_ptr->push_length);
   }

#endif
#ifdef PNG_READ_tEXt_SUPPORTED
   else if (chunk_name == png_tEXt)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_tEXt(png_ptr, info_ptr, png_ptr->push_length);
   }

#endif
#ifdef PNG_READ_zTXt_SUPPORTED
   else if (chunk_name == png_zTXt)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_zTXt(png_ptr, info_ptr, png_ptr->push_length);
   }

#endif
#ifdef PNG_READ_iTXt_SUPPORTED
   else if (chunk_name == png_iTXt)
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_iTXt(png_ptr, info_ptr, png_ptr->push_length);
   }
#endif

   else
   {
      PNG_PUSH_SAVE_BUFFER_IF_FULL
      png_handle_unknown(png_ptr, info_ptr, png_ptr->push_length,
         PNG_HANDLE_CHUNK_AS_DEFAULT);
   }

   png_ptr->mode &= ~PNG_HAVE_CHUNK_HEADER;
}

void PNGCBAPI
png_push_fill_buffer(png_structp png_ptr, png_bytep buffer, png_size_t length)
{
   png_bytep ptr;

   if (png_ptr == NULL)
      return;

   ptr = buffer;
   if (png_ptr->save_buffer_size != 0)
   {
      png_size_t save_size;

      if (length < png_ptr->save_buffer_size)
         save_size = length;

      else
         save_size = png_ptr->save_buffer_size;

      memcpy(ptr, png_ptr->save_buffer_ptr, save_size);
      length -= save_size;
      ptr += save_size;
      png_ptr->buffer_size -= save_size;
      png_ptr->save_buffer_size -= save_size;
      png_ptr->save_buffer_ptr += save_size;
   }
   if (length != 0 && png_ptr->current_buffer_size != 0)
   {
      png_size_t save_size;

      if (length < png_ptr->current_buffer_size)
         save_size = length;

      else
         save_size = png_ptr->current_buffer_size;

      memcpy(ptr, png_ptr->current_buffer_ptr, save_size);
      png_ptr->buffer_size -= save_size;
      png_ptr->current_buffer_size -= save_size;
      png_ptr->current_buffer_ptr += save_size;
   }
}

void /* PRIVATE */
png_push_save_buffer(png_structrp png_ptr)
{
   if (png_ptr->save_buffer_size != 0)
   {
      if (png_ptr->save_buffer_ptr != png_ptr->save_buffer)
      {
         png_size_t i, istop;
         png_bytep sp;
         png_bytep dp;

         istop = png_ptr->save_buffer_size;
         for (i = 0, sp = png_ptr->save_buffer_ptr, dp = png_ptr->save_buffer;
             i < istop; i++, sp++, dp++)
         {
            *dp = *sp;
         }
      }
   }
   if (png_ptr->save_buffer_size + png_ptr->current_buffer_size >
       png_ptr->save_buffer_max)
   {
      png_size_t new_max;
      png_bytep old_buffer;

      if (png_ptr->save_buffer_size > PNG_SIZE_MAX -
          (png_ptr->current_buffer_size + 256))
      {
         png_error(png_ptr, "Potential overflow of save_buffer");
      }

      new_max = png_ptr->save_buffer_size + png_ptr->current_buffer_size + 256;
      old_buffer = png_ptr->save_buffer;
      png_ptr->save_buffer = (png_bytep)png_malloc_warn(png_ptr,
          (png_size_t)new_max);

      if (png_ptr->save_buffer == NULL)
      {
         png_free(png_ptr, old_buffer);
         png_error(png_ptr, "Insufficient memory for save_buffer");
      }

#if 0
      // This is the code checked into libpng. Calling memcpy with a null
      // source is undefined, even if count is 0, but libpng does not
      // currently check for null or 0. The Skia fix is below.
      // skbug.com/5390
      memcpy(png_ptr->save_buffer, old_buffer, png_ptr->save_buffer_size);
#else
      if (old_buffer)
         memcpy(png_ptr->save_buffer, old_buffer, png_ptr->save_buffer_size);
      else if (png_ptr->save_buffer_size)
         png_error(png_ptr, "save_buffer error");
#endif
      png_free(png_ptr, old_buffer);
      png_ptr->save_buffer_max = new_max;
   }
   if (png_ptr->current_buffer_size)
   {
      memcpy(png_ptr->save_buffer + png_ptr->save_buffer_size,
         png_ptr->current_buffer_ptr, png_ptr->current_buffer_size);
      png_ptr->save_buffer_size += png_ptr->current_buffer_size;
      png_ptr->current_buffer_size = 0;
   }
   png_ptr->save_buffer_ptr = png_ptr->save_buffer;
   png_ptr->buffer_size = 0;
}

void /* PRIVATE */
png_push_restore_buffer(png_structrp png_ptr, png_bytep buffer,
   png_size_t buffer_length)
{
   png_ptr->current_buffer = buffer;
   png_ptr->current_buffer_size = buffer_length;
   png_ptr->buffer_size = buffer_length + png_ptr->save_buffer_size;
   png_ptr->current_buffer_ptr = png_ptr->current_buffer;
}

void /* PRIVATE */
png_push_read_IDAT(png_structrp png_ptr)
{
   if ((png_ptr->mode & PNG_HAVE_CHUNK_HEADER) == 0)
   {
      png_byte chunk_length[4];
      png_byte chunk_tag[4];

      /* TODO: this code can be commoned up with the same code in push_read */
      PNG_PUSH_SAVE_BUFFER_IF_LT(8)
      png_push_fill_buffer(png_ptr, chunk_length, 4);
      png_ptr->push_length = png_get_uint_31(png_ptr, chunk_length);
      png_reset_crc(png_ptr);
      png_crc_read(png_ptr, chunk_tag, 4);
      png_ptr->chunk_name = PNG_CHUNK_FROM_STRING(chunk_tag);
      png_ptr->mode |= PNG_HAVE_CHUNK_HEADER;

      if (png_ptr->chunk_name != png_IDAT)
      {
         png_ptr->process_mode = PNG_READ_CHUNK_MODE;

         if ((png_ptr->flags & PNG_FLAG_ZSTREAM_ENDED) == 0)
            png_error(png_ptr, "Not enough compressed data");

         return;
      }

      png_ptr->idat_size = png_ptr->push_length;
   }

   if (png_ptr->idat_size != 0 && png_ptr->save_buffer_size != 0)
   {
      png_size_t save_size = png_ptr->save_buffer_size;
      png_uint_32 idat_size = png_ptr->idat_size;

      /* We want the smaller of 'idat_size' and 'current_buffer_size', but they
       * are of different types and we don't know which variable has the fewest
       * bits.  Carefully select the smaller and cast it to the type of the
       * larger - this cannot overflow.  Do not cast in the following test - it
       * will break on either 16-bit or 64-bit platforms.
       */
      if (idat_size < save_size)
         save_size = (png_size_t)idat_size;

      else
         idat_size = (png_uint_32)save_size;

      png_calculate_crc(png_ptr, png_ptr->save_buffer_ptr, save_size);

      png_process_IDAT_data(png_ptr, png_ptr->save_buffer_ptr, save_size);

      png_ptr->idat_size -= idat_size;
      png_ptr->buffer_size -= save_size;
      png_ptr->save_buffer_size -= save_size;
      png_ptr->save_buffer_ptr += save_size;
   }

   if (png_ptr->idat_size != 0 && png_ptr->current_buffer_size != 0)
   {
      png_size_t save_size = png_ptr->current_buffer_size;
      png_uint_32 idat_size = png_ptr->idat_size;

      /* We want the smaller of 'idat_size' and 'current_buffer_size', but they
       * are of different types and we don't know which variable has the fewest
       * bits.  Carefully select the smaller and cast it to the type of the
       * larger - this cannot overflow.
       */
      if (idat_size < save_size)
         save_size = (png_size_t)idat_size;

      else
         idat_size = (png_uint_32)save_size;

      png_calculate_crc(png_ptr, png_ptr->current_buffer_ptr, save_size);

      png_process_IDAT_data(png_ptr, png_ptr->current_buffer_ptr, save_size);

      png_ptr->idat_size -= idat_size;
      png_ptr->buffer_size -= save_size;
      png_ptr->current_buffer_size -= save_size;
      png_ptr->current_buffer_ptr += save_size;
   }

   if (png_ptr->idat_size == 0)
   {
      PNG_PUSH_SAVE_BUFFER_IF_LT(4)
      png_crc_finish(png_ptr, 0);
      png_ptr->mode &= ~PNG_HAVE_CHUNK_HEADER;
      png_ptr->mode |= PNG_AFTER_IDAT;
      png_ptr->zowner = 0;
   }
}

void /* PRIVATE */
png_process_IDAT_data(png_structrp png_ptr, png_bytep buffer,
   png_size_t buffer_length)
{
   /* The caller checks for a non-zero buffer length. */
   if (!(buffer_length > 0) || buffer == NULL)
      png_error(png_ptr, "No IDAT data (internal error)");

   /* This routine must process all the data it has been given
    * before returning, calling the row callback as required to
    * handle the uncompressed results.
    */
   png_ptr->zstream.next_in = buffer;
   /* TODO: WARNING: TRUNCATION ERROR: DANGER WILL ROBINSON: */
   png_ptr->zstream.avail_in = (uInt)buffer_length;

   /* Keep going until the decompressed data is all processed
    * or the stream marked as finished.
    */
   while (png_ptr->zstream.avail_in > 0 &&
      (png_ptr->flags & PNG_FLAG_ZSTREAM_ENDED) == 0)
   {
      int ret;

      /* We have data for zlib, but we must check that zlib
       * has someplace to put the results.  It doesn't matter
       * if we don't expect any results -- it may be the input
       * data is just the LZ end code.
       */
      if (!(png_ptr->zstream.avail_out > 0))
      {
         /* TODO: WARNING: TRUNCATION ERROR: DANGER WILL ROBINSON: */
         png_ptr->zstream.avail_out = (uInt)(PNG_ROWBYTES(png_ptr->pixel_depth,
             png_ptr->iwidth) + 1);

         png_ptr->zstream.next_out = png_ptr->row_buf;
      }

      /* Using Z_SYNC_FLUSH here means that an unterminated
       * LZ stream (a stream with a missing end code) can still
       * be handled, otherwise (Z_NO_FLUSH) a future zlib
       * implementation might defer output and therefore
       * change the current behavior (see comments in inflate.c
       * for why this doesn't happen at present with zlib 1.2.5).
       */
      ret = PNG_INFLATE(png_ptr, Z_SYNC_FLUSH);

      /* Check for any failure before proceeding. */
      if (ret != Z_OK && ret != Z_STREAM_END)
      {
         /* Terminate the decompression. */
         png_ptr->flags |= PNG_FLAG_ZSTREAM_ENDED;
         png_ptr->zowner = 0;

         /* This may be a truncated stream (missing or
          * damaged end code).  Treat that as a warning.
          */
         if (png_ptr->row_number >= png_ptr->num_rows ||
             png_ptr->pass > 6)
            png_warning(png_ptr, "Truncated compressed data in IDAT");

         else
            png_error(png_ptr, "Decompression error in IDAT");

         /* Skip the check on unprocessed input */
         return;
      }

      /* Did inflate output any data? */
      if (png_ptr->zstream.next_out != png_ptr->row_buf)
      {
         /* Is this unexpected data after the last row?
          * If it is, artificially terminate the LZ output
          * here.
          */
         if (png_ptr->row_number >= png_ptr->num_rows ||
             png_ptr->pass > 6)
         {
            /* Extra data. */
            png_warning(png_ptr, "Extra compressed data in IDAT");
            png_ptr->flags |= PNG_FLAG_ZSTREAM_ENDED;
            png_ptr->zowner = 0;

            /* Do no more processing; skip the unprocessed
             * input check below.
             */
            return;
         }

         /* Do we have a complete row? */
         if (png_ptr->zstream.avail_out == 0)
            png_push_process_row(png_ptr);
      }

      /* And check for the end of the stream. */
      if (ret == Z_STREAM_END)
         png_ptr->flags |= PNG_FLAG_ZSTREAM_ENDED;
   }

   /* All the data should have been processed, if anything
    * is left at this point we have bytes of IDAT data
    * after the zlib end code.
    */
   if (png_ptr->zstream.avail_in > 0)
      png_warning(png_ptr, "Extra compression data in IDAT");
}

void /* PRIVATE */
png_push_process_row(png_structrp png_ptr)
{
   /* 1.5.6: row_info moved out of png_struct to a local here. */
   png_row_info row_info;

   row_info.width = png_ptr->iwidth; /* NOTE: width of current interlaced row */
   row_info.color_type = png_ptr->color_type;
   row_info.bit_depth = png_ptr->bit_depth;
   row_info.channels = png_ptr->channels;
   row_info.pixel_depth = png_ptr->pixel_depth;
   row_info.rowbytes = PNG_ROWBYTES(row_info.pixel_depth, row_info.width);

   if (png_ptr->row_buf[0] > PNG_FILTER_VALUE_NONE)
   {
      if (png_ptr->row_buf[0] < PNG_FILTER_VALUE_LAST)
         png_read_filter_row(png_ptr, &row_info, png_ptr->row_buf + 1,
            png_ptr->prev_row + 1, png_ptr->row_buf[0]);
      else
         png_error(png_ptr, "bad adaptive filter value");
   }

   /* libpng 1.5.6: the following line was copying png_ptr->rowbytes before
    * 1.5.6, while the buffer really is this big in current versions of libpng
    * it may not be in the future, so this was changed just to copy the
    * interlaced row count:
    */
   memcpy(png_ptr->prev_row, png_ptr->row_buf, row_info.rowbytes + 1);

#ifdef PNG_READ_TRANSFORMS_SUPPORTED
   if (png_ptr->transformations != 0)
      png_do_read_transformations(png_ptr, &row_info);
#endif

   /* The transformed pixel depth should match the depth now in row_info. */
   if (png_ptr->transformed_pixel_depth == 0)
   {
      png_ptr->transformed_pixel_depth = row_info.pixel_depth;
      if (row_info.pixel_depth > png_ptr->maximum_pixel_depth)
         png_error(png_ptr, "progressive row overflow");
   }

   else if (png_ptr->transformed_pixel_depth != row_info.pixel_depth)
      png_error(png_ptr, "internal progressive row size calculation error");


#ifdef PNG_READ_INTERLACING_SUPPORTED
   /* Expand interlaced rows to full size */
   if (png_ptr->interlaced != 0 &&
       (png_ptr->transformations & PNG_INTERLACE) != 0)
   {
      if (png_ptr->pass < 6)
         png_do_read_interlace(&row_info, png_ptr->row_buf + 1, png_ptr->pass,
            png_ptr->transformations);

      switch (png_ptr->pass)
      {
         case 0:
         {
            int i;
            for (i = 0; i < 8 && png_ptr->pass == 0; i++)
            {
               png_push_have_row(png_ptr, png_ptr->row_buf + 1);
               png_read_push_finish_row(png_ptr); /* Updates png_ptr->pass */
            }

            if (png_ptr->pass == 2) /* Pass 1 might be empty */
            {
               for (i = 0; i < 4 && png_ptr->pass == 2; i++)
               {
                  png_push_have_row(png_ptr, NULL);
                  png_read_push_finish_row(png_ptr);
               }
            }

            if (png_ptr->pass == 4 && png_ptr->height <= 4)
            {
               for (i = 0; i < 2 && png_ptr->pass == 4; i++)
               {
                  png_push_have_row(png_ptr, NULL);
                  png_read_push_finish_row(png_ptr);
               }
            }

            if (png_ptr->pass == 6 && png_ptr->height <= 4)
            {
                png_push_have_row(png_ptr, NULL);
                png_read_push_finish_row(png_ptr);
            }

            break;
         }

         case 1:
         {
            int i;
            for (i = 0; i < 8 && png_ptr->pass == 1; i++)
            {
               png_push_have_row(png_ptr, png_ptr->row_buf + 1);
               png_read_push_finish_row(png_ptr);
            }

            if (png_ptr->pass == 2) /* Skip top 4 generated rows */
            {
               for (i = 0; i < 4 && png_ptr->pass == 2; i++)
               {
                  png_push_have_row(png_ptr, NULL);
                  png_read_push_finish_row(png_ptr);
               }
            }

            break;
         }

         case 2:
         {
            int i;

            for (i = 0; i < 4 && png_ptr->pass == 2; i++)
            {
               png_push_have_row(png_ptr, png_ptr->row_buf + 1);
               png_read_push_finish_row(png_ptr);
            }

            for (i = 0; i < 4 && png_ptr->pass == 2; i++)
            {
               png_push_have_row(png_ptr, NULL);
               png_read_push_finish_row(png_ptr);
            }

            if (png_ptr->pass == 4) /* Pass 3 might be empty */
            {
               for (i = 0; i < 2 && png_ptr->pass == 4; i++)
               {
                  png_push_have_row(png_ptr, NULL);
                  png_read_push_finish_row(png_ptr);
               }
            }

            break;
         }

         case 3:
         {
            int i;

            for (i = 0; i < 4 && png_ptr->pass == 3; i++)
            {
               png_push_have_row(png_ptr, png_ptr->row_buf + 1);
               png_read_push_finish_row(png_ptr);
            }

            if (png_ptr->pass == 4) /* Skip top two generated rows */
            {
               for (i = 0; i < 2 && png_ptr->pass == 4; i++)
               {
                  png_push_have_row(png_ptr, NULL);
                  png_read_push_finish_row(png_ptr);
               }
            }

            break;
         }

         case 4:
         {
            int i;

            for (i = 0; i < 2 && png_ptr->pass == 4; i++)
            {
               png_push_have_row(png_ptr, png_ptr->row_buf + 1);
               png_read_push_finish_row(png_ptr);
            }

            for (i = 0; i < 2 && png_ptr->pass == 4; i++)
            {
               png_push_have_row(png_ptr, NULL);
               png_read_push_finish_row(png_ptr);
            }

            if (png_ptr->pass == 6) /* Pass 5 might be empty */
            {
               png_push_have_row(png_ptr, NULL);
               png_read_push_finish_row(png_ptr);
            }

            break;
         }

         case 5:
         {
            int i;

            for (i = 0; i < 2 && png_ptr->pass == 5; i++)
            {
               png_push_have_row(png_ptr, png_ptr->row_buf + 1);
               png_read_push_finish_row(png_ptr);
            }

            if (png_ptr->pass == 6) /* Skip top generated row */
            {
               png_push_have_row(png_ptr, NULL);
               png_read_push_finish_row(png_ptr);
            }

            break;
         }

         default:
         case 6:
         {
            png_push_have_row(png_ptr, png_ptr->row_buf + 1);
            png_read_push_finish_row(png_ptr);

            if (png_ptr->pass != 6)
               break;

            png_push_have_row(png_ptr, NULL);
            png_read_push_finish_row(png_ptr);
         }
      }
   }
   else
#endif
   {
      png_push_have_row(png_ptr, png_ptr->row_buf + 1);
      png_read_push_finish_row(png_ptr);
   }
}

void /* PRIVATE */
png_read_push_finish_row(png_structrp png_ptr)
{
#ifdef PNG_READ_INTERLACING_SUPPORTED
   /* Arrays to facilitate easy interlacing - use pass (0 - 6) as index */

   /* Start of interlace block */
   static PNG_CONST png_byte png_pass_start[] = {0, 4, 0, 2, 0, 1, 0};

   /* Offset to next interlace block */
   static PNG_CONST png_byte png_pass_inc[] = {8, 8, 4, 4, 2, 2, 1};

   /* Start of interlace block in the y direction */
   static PNG_CONST png_byte png_pass_ystart[] = {0, 0, 4, 0, 2, 0, 1};

   /* Offset to next interlace block in the y direction */
   static PNG_CONST png_byte png_pass_yinc[] = {8, 8, 8, 4, 4, 2, 2};

   /* Height of interlace block.  This is not currently used - if you need
    * it, uncomment it here and in png.h
   static PNG_CONST png_byte png_pass_height[] = {8, 8, 4, 4, 2, 2, 1};
   */
#endif

   png_ptr->row_number++;
   if (png_ptr->row_number < png_ptr->num_rows)
      return;

#ifdef PNG_READ_INTERLACING_SUPPORTED
   if (png_ptr->interlaced != 0)
   {
      png_ptr->row_number = 0;
      memset(png_ptr->prev_row, 0, png_ptr->rowbytes + 1);

      do
      {
         png_ptr->pass++;
         if ((png_ptr->pass == 1 && png_ptr->width < 5) ||
             (png_ptr->pass == 3 && png_ptr->width < 3) ||
             (png_ptr->pass == 5 && png_ptr->width < 2))
            png_ptr->pass++;

         if (png_ptr->pass > 7)
            png_ptr->pass--;

         if (png_ptr->pass >= 7)
            break;

         png_ptr->iwidth = (png_ptr->width +
             png_pass_inc[png_ptr->pass] - 1 -
             png_pass_start[png_ptr->pass]) /
             png_pass_inc[png_ptr->pass];

         if ((png_ptr->transformations & PNG_INTERLACE) != 0)
            break;

         png_ptr->num_rows = (png_ptr->height +
             png_pass_yinc[png_ptr->pass] - 1 -
             png_pass_ystart[png_ptr->pass]) /
             png_pass_yinc[png_ptr->pass];

      } while (png_ptr->iwidth == 0 || png_ptr->num_rows == 0);
   }
#endif /* READ_INTERLACING */
}

void /* PRIVATE */
png_push_have_info(png_structrp png_ptr, png_inforp info_ptr)
{
   if (png_ptr->info_fn != NULL)
      (*(png_ptr->info_fn))(png_ptr, info_ptr);
}

void /* PRIVATE */
png_push_have_end(png_structrp png_ptr, png_inforp info_ptr)
{
   if (png_ptr->end_fn != NULL)
      (*(png_ptr->end_fn))(png_ptr, info_ptr);
}

void /* PRIVATE */
png_push_have_row(png_structrp png_ptr, png_bytep row)
{
   if (png_ptr->row_fn != NULL)
      (*(png_ptr->row_fn))(png_ptr, row, png_ptr->row_number,
         (int)png_ptr->pass);
}

#ifdef PNG_READ_INTERLACING_SUPPORTED
void PNGAPI
png_progressive_combine_row(png_const_structrp png_ptr, png_bytep old_row,
    png_const_bytep new_row)
{
   if (png_ptr == NULL)
      return;

   /* new_row is a flag here - if it is NULL then the app callback was called
    * from an empty row (see the calls to png_struct::row_fn below), otherwise
    * it must be png_ptr->row_buf+1
    */
   if (new_row != NULL)
      png_combine_row(png_ptr, old_row, 1/*blocky display*/);
}
#endif /* READ_INTERLACING */

void PNGAPI
png_set_progressive_read_fn(png_structrp png_ptr, png_voidp progressive_ptr,
    png_progressive_info_ptr info_fn, png_progressive_row_ptr row_fn,
    png_progressive_end_ptr end_fn)
{
   if (png_ptr == NULL)
      return;

   png_ptr->info_fn = info_fn;
   png_ptr->row_fn = row_fn;
   png_ptr->end_fn = end_fn;

   png_set_read_fn(png_ptr, progressive_ptr, png_push_fill_buffer);
}

png_voidp PNGAPI
png_get_progressive_ptr(png_const_structrp png_ptr)
{
   if (png_ptr == NULL)
      return (NULL);

   return png_ptr->io_ptr;
}
#endif /* PROGRESSIVE_READ */
