
/* pngwutil.c - utilities to write a PNG file
 *
 * Last changed in libpng 1.6.22 [(PENDING RELEASE)]
 * Copyright (c) 1998-2002,2004,2006-2015 Glenn Randers-Pehrson
 * (Version 0.96 Copyright (c) 1996, 1997 Andreas Dilger)
 * (Version 0.88 Copyright (c) 1995, 1996 Guy Eric Schalnat, Group 42, Inc.)
 *
 * This code is released under the libpng license.
 * For conditions of distribution and use, see the disclaimer
 * and license in png.h
 */

#include "pngpriv.h"

#ifdef PNG_WRITE_SUPPORTED

#ifdef PNG_WRITE_INT_FUNCTIONS_SUPPORTED
/* Place a 32-bit number into a buffer in PNG byte order.  We work
 * with unsigned numbers for convenience, although one supported
 * ancillary chunk uses signed (two's complement) numbers.
 */
void PNGAPI
png_save_uint_32(png_bytep buf, png_uint_32 i)
{
   buf[0] = (png_byte)((i >> 24) & 0xffU);
   buf[1] = (png_byte)((i >> 16) & 0xffU);
   buf[2] = (png_byte)((i >>  8) & 0xffU);
   buf[3] = (png_byte)( i        & 0xffU);
}

/* Place a 16-bit number into a buffer in PNG byte order.
 * The parameter is declared unsigned int, not png_uint_16,
 * just to avoid potential problems on pre-ANSI C compilers.
 */
void PNGAPI
png_save_uint_16(png_bytep buf, unsigned int i)
{
   buf[0] = (png_byte)((i >> 8) & 0xffU);
   buf[1] = (png_byte)( i       & 0xffU);
}
#endif

/* Simple function to write the signature.  If we have already written
 * the magic bytes of the signature, or more likely, the PNG stream is
 * being embedded into another stream and doesn't need its own signature,
 * we should call png_set_sig_bytes() to tell libpng how many of the
 * bytes have already been written.
 */
void PNGAPI
png_write_sig(png_structrp png_ptr)
{
   png_byte png_signature[8] = {137, 80, 78, 71, 13, 10, 26, 10};

#ifdef PNG_IO_STATE_SUPPORTED
   /* Inform the I/O callback that the signature is being written */
   png_ptr->io_state = PNG_IO_WRITING | PNG_IO_SIGNATURE;
#endif

   /* Write the rest of the 8 byte signature */
   png_write_data(png_ptr, &png_signature[png_ptr->sig_bytes],
      (png_size_t)(8 - png_ptr->sig_bytes));

   if (png_ptr->sig_bytes < 3)
      png_ptr->mode |= PNG_HAVE_PNG_SIGNATURE;
}

/* Write the start of a PNG chunk.  The type is the chunk type.
 * The total_length is the sum of the lengths of all the data you will be
 * passing in png_write_chunk_data().
 */
static void
png_write_chunk_header(png_structrp png_ptr, png_uint_32 chunk_name,
    png_uint_32 length)
{
   png_byte buf[8];

#if defined(PNG_DEBUG) && (PNG_DEBUG > 0)
   PNG_CSTRING_FROM_CHUNK(buf, chunk_name);
   png_debug2(0, "Writing %s chunk, length = %lu", buf, (unsigned long)length);
#endif

   if (png_ptr == NULL)
      return;

#ifdef PNG_IO_STATE_SUPPORTED
   /* Inform the I/O callback that the chunk header is being written.
    * PNG_IO_CHUNK_HDR requires a single I/O call.
    */
   png_ptr->io_state = PNG_IO_WRITING | PNG_IO_CHUNK_HDR;
#endif

   /* Write the length and the chunk name */
   png_save_uint_32(buf, length);
   png_save_uint_32(buf + 4, chunk_name);
   png_write_data(png_ptr, buf, 8);

   /* Put the chunk name into png_ptr->chunk_name */
   png_ptr->chunk_name = chunk_name;

   /* Reset the crc and run it over the chunk name */
   png_reset_crc(png_ptr);

   png_calculate_crc(png_ptr, buf + 4, 4);

#ifdef PNG_IO_STATE_SUPPORTED
   /* Inform the I/O callback that chunk data will (possibly) be written.
    * PNG_IO_CHUNK_DATA does NOT require a specific number of I/O calls.
    */
   png_ptr->io_state = PNG_IO_WRITING | PNG_IO_CHUNK_DATA;
#endif
}

void PNGAPI
png_write_chunk_start(png_structrp png_ptr, png_const_bytep chunk_string,
    png_uint_32 length)
{
   png_write_chunk_header(png_ptr, PNG_CHUNK_FROM_STRING(chunk_string), length);
}

/* Write the data of a PNG chunk started with png_write_chunk_header().
 * Note that multiple calls to this function are allowed, and that the
 * sum of the lengths from these calls *must* add up to the total_length
 * given to png_write_chunk_header().
 */
void PNGAPI
png_write_chunk_data(png_structrp png_ptr, png_const_bytep data,
    png_size_t length)
{
   /* Write the data, and run the CRC over it */
   if (png_ptr == NULL)
      return;

   if (data != NULL && length > 0)
   {
      png_write_data(png_ptr, data, length);

      /* Update the CRC after writing the data,
       * in case the user I/O routine alters it.
       */
      png_calculate_crc(png_ptr, data, length);
   }
}

/* Finish a chunk started with png_write_chunk_header(). */
void PNGAPI
png_write_chunk_end(png_structrp png_ptr)
{
   png_byte buf[4];

   if (png_ptr == NULL) return;

#ifdef PNG_IO_STATE_SUPPORTED
   /* Inform the I/O callback that the chunk CRC is being written.
    * PNG_IO_CHUNK_CRC requires a single I/O function call.
    */
   png_ptr->io_state = PNG_IO_WRITING | PNG_IO_CHUNK_CRC;
#endif

   /* Write the crc in a single operation */
   png_save_uint_32(buf, png_ptr->crc);

   png_write_data(png_ptr, buf, (png_size_t)4);
}

/* Write a PNG chunk all at once.  The type is an array of ASCII characters
 * representing the chunk name.  The array must be at least 4 bytes in
 * length, and does not need to be null terminated.  To be safe, pass the
 * pre-defined chunk names here, and if you need a new one, define it
 * where the others are defined.  The length is the length of the data.
 * All the data must be present.  If that is not possible, use the
 * png_write_chunk_start(), png_write_chunk_data(), and png_write_chunk_end()
 * functions instead.
 */
static void
png_write_complete_chunk(png_structrp png_ptr, png_uint_32 chunk_name,
   png_const_bytep data, png_size_t length)
{
   if (png_ptr == NULL)
      return;

   /* On 64-bit architectures 'length' may not fit in a png_uint_32. */
   if (length > PNG_UINT_31_MAX)
      png_error(png_ptr, "length exceeds PNG maximum");

   png_write_chunk_header(png_ptr, chunk_name, (png_uint_32)length);
   png_write_chunk_data(png_ptr, data, length);
   png_write_chunk_end(png_ptr);
}

/* This is the API that calls the internal function above. */
void PNGAPI
png_write_chunk(png_structrp png_ptr, png_const_bytep chunk_string,
   png_const_bytep data, png_size_t length)
{
   png_write_complete_chunk(png_ptr, PNG_CHUNK_FROM_STRING(chunk_string), data,
      length);
}

/* This is used below to find the size of an image to pass to png_deflate_claim,
 * so it only needs to be accurate if the size is less than 16384 bytes (the
 * point at which a lower LZ window size can be used.)
 */
static png_alloc_size_t
png_image_size(png_structrp png_ptr)
{
   /* Only return sizes up to the maximum of a png_uint_32; do this by limiting
    * the width and height used to 15 bits.
    */
   png_uint_32 h = png_ptr->height;

   if (png_ptr->rowbytes < 32768 && h < 32768)
   {
      if (png_ptr->interlaced != 0)
      {
         /* Interlacing makes the image larger because of the replication of
          * both the filter byte and the padding to a byte boundary.
          */
         png_uint_32 w = png_ptr->width;
         unsigned int pd = png_ptr->pixel_depth;
         png_alloc_size_t cb_base;
         int pass;

         for (cb_base=0, pass=0; pass<=6; ++pass)
         {
            png_uint_32 pw = PNG_PASS_COLS(w, pass);

            if (pw > 0)
               cb_base += (PNG_ROWBYTES(pd, pw)+1) * PNG_PASS_ROWS(h, pass);
         }

         return cb_base;
      }

      else
         return (png_ptr->rowbytes+1) * h;
   }

   else
      return 0xffffffffU;
}

#ifdef PNG_WRITE_OPTIMIZE_CMF_SUPPORTED
   /* This is the code to hack the first two bytes of the deflate stream (the
    * deflate header) to correct the windowBits value to match the actual data
    * size.  Note that the second argument is the *uncompressed* size but the
    * first argument is the *compressed* data (and it must be deflate
    * compressed.)
    */
static void
optimize_cmf(png_bytep data, png_alloc_size_t data_size)
{
   /* Optimize the CMF field in the zlib stream.  The resultant zlib stream is
    * still compliant to the stream specification.
    */
   if (data_size <= 16384) /* else windowBits must be 15 */
   {
      unsigned int z_cmf = data[0];  /* zlib compression method and flags */

      if ((z_cmf & 0x0f) == 8 && (z_cmf & 0xf0) <= 0x70)
      {
         unsigned int z_cinfo;
         unsigned int half_z_window_size;

         z_cinfo = z_cmf >> 4;
         half_z_window_size = 1U << (z_cinfo + 7);

         if (data_size <= half_z_window_size) /* else no change */
         {
            unsigned int tmp;

            do
            {
               half_z_window_size >>= 1;
               --z_cinfo;
            }
            while (z_cinfo > 0 && data_size <= half_z_window_size);

            z_cmf = (z_cmf & 0x0f) | (z_cinfo << 4);

            data[0] = (png_byte)z_cmf;
            tmp = data[1] & 0xe0;
            tmp += 0x1f - ((z_cmf << 8) + tmp) % 0x1f;
            data[1] = (png_byte)tmp;
         }
      }
   }
}
#endif /* WRITE_OPTIMIZE_CMF */

/* Initialize the compressor for the appropriate type of compression. */
static int
png_deflate_claim(png_structrp png_ptr, png_uint_32 owner,
   png_alloc_size_t data_size)
{
   if (png_ptr->zowner != 0)
   {
#if defined(PNG_WARNINGS_SUPPORTED) || defined(PNG_ERROR_TEXT_SUPPORTED)
      char msg[64];

      PNG_STRING_FROM_CHUNK(msg, owner);
      msg[4] = ':';
      msg[5] = ' ';
      PNG_STRING_FROM_CHUNK(msg+6, png_ptr->zowner);
      /* So the message that results is "<chunk> using zstream"; this is an
       * internal error, but is very useful for debugging.  i18n requirements
       * are minimal.
       */
      (void)png_safecat(msg, (sizeof msg), 10, " using zstream");
#endif
#if PNG_RELEASE_BUILD
         png_warning(png_ptr, msg);

         /* Attempt sane error recovery */
         if (png_ptr->zowner == png_IDAT) /* don't steal from IDAT */
         {
            png_ptr->zstream.msg = PNGZ_MSG_CAST("in use by IDAT");
            return Z_STREAM_ERROR;
         }

         png_ptr->zowner = 0;
#else
         png_error(png_ptr, msg);
#endif
   }

   {
      int level = png_ptr->zlib_level;
      int method = png_ptr->zlib_method;
      int windowBits = png_ptr->zlib_window_bits;
      int memLevel = png_ptr->zlib_mem_level;
      int strategy; /* set below */
      int ret; /* zlib return code */

      if (owner == png_IDAT)
      {
         if ((png_ptr->flags & PNG_FLAG_ZLIB_CUSTOM_STRATEGY) != 0)
            strategy = png_ptr->zlib_strategy;

         else if (png_ptr->do_filter != PNG_FILTER_NONE)
            strategy = PNG_Z_DEFAULT_STRATEGY;

         else
            strategy = PNG_Z_DEFAULT_NOFILTER_STRATEGY;
      }

      else
      {
#ifdef PNG_WRITE_CUSTOMIZE_ZTXT_COMPRESSION_SUPPORTED
            level = png_ptr->zlib_text_level;
            method = png_ptr->zlib_text_method;
            windowBits = png_ptr->zlib_text_window_bits;
            memLevel = png_ptr->zlib_text_mem_level;
            strategy = png_ptr->zlib_text_strategy;
#else
            /* If customization is not supported the values all come from the
             * IDAT values except for the strategy, which is fixed to the
             * default.  (This is the pre-1.6.0 behavior too, although it was
             * implemented in a very different way.)
             */
            strategy = Z_DEFAULT_STRATEGY;
#endif
      }

      /* Adjust 'windowBits' down if larger than 'data_size'; to stop this
       * happening just pass 32768 as the data_size parameter.  Notice that zlib
       * requires an extra 262 bytes in the window in addition to the data to be
       * able to see the whole of the data, so if data_size+262 takes us to the
       * next windowBits size we need to fix up the value later.  (Because even
       * though deflate needs the extra window, inflate does not!)
       */
      if (data_size <= 16384)
      {
         /* IMPLEMENTATION NOTE: this 'half_window_size' stuff is only here to
          * work round a Microsoft Visual C misbehavior which, contrary to C-90,
          * widens the result of the following shift to 64-bits if (and,
          * apparently, only if) it is used in a test.
          */
         unsigned int half_window_size = 1U << (windowBits-1);

         while (data_size + 262 <= half_window_size)
         {
            half_window_size >>= 1;
            --windowBits;
         }
      }

      /* Check against the previous initialized values, if any. */
      if ((png_ptr->flags & PNG_FLAG_ZSTREAM_INITIALIZED) != 0 &&
         (png_ptr->zlib_set_level != level ||
         png_ptr->zlib_set_method != method ||
         png_ptr->zlib_set_window_bits != windowBits ||
         png_ptr->zlib_set_mem_level != memLevel ||
         png_ptr->zlib_set_strategy != strategy))
      {
         if (deflateEnd(&png_ptr->zstream) != Z_OK)
            png_warning(png_ptr, "deflateEnd failed (ignored)");

         png_ptr->flags &= ~PNG_FLAG_ZSTREAM_INITIALIZED;
      }

      /* For safety clear out the input and output pointers (currently zlib
       * doesn't use them on Init, but it might in the future).
       */
      png_ptr->zstream.next_in = NULL;
      png_ptr->zstream.avail_in = 0;
      png_ptr->zstream.next_out = NULL;
      png_ptr->zstream.avail_out = 0;

      /* Now initialize if required, setting the new parameters, otherwise just
       * to a simple reset to the previous parameters.
       */
      if ((png_ptr->flags & PNG_FLAG_ZSTREAM_INITIALIZED) != 0)
         ret = deflateReset(&png_ptr->zstream);

      else
      {
         ret = deflateInit2(&png_ptr->zstream, level, method, windowBits,
            memLevel, strategy);

         if (ret == Z_OK)
            png_ptr->flags |= PNG_FLAG_ZSTREAM_INITIALIZED;
      }

      /* The return code is from either deflateReset or deflateInit2; they have
       * pretty much the same set of error codes.
       */
      if (ret == Z_OK)
         png_ptr->zowner = owner;

      else
         png_zstream_error(png_ptr, ret);

      return ret;
   }
}

/* Clean up (or trim) a linked list of compression buffers. */
void /* PRIVATE */
png_free_buffer_list(png_structrp png_ptr, png_compression_bufferp *listp)
{
   png_compression_bufferp list = *listp;

   if (list != NULL)
   {
      *listp = NULL;

      do
      {
         png_compression_bufferp next = list->next;

         png_free(png_ptr, list);
         list = next;
      }
      while (list != NULL);
   }
}

#ifdef PNG_WRITE_COMPRESSED_TEXT_SUPPORTED
/* This pair of functions encapsulates the operation of (a) compressing a
 * text string, and (b) issuing it later as a series of chunk data writes.
 * The compression_state structure is shared context for these functions
 * set up by the caller to allow access to the relevant local variables.
 *
 * compression_buffer (new in 1.6.0) is just a linked list of zbuffer_size
 * temporary buffers.  From 1.6.0 it is retained in png_struct so that it will
 * be correctly freed in the event of a write error (previous implementations
 * just leaked memory.)
 */
typedef struct
{
   png_const_bytep      input;        /* The uncompressed input data */
   png_alloc_size_t     input_len;    /* Its length */
   png_uint_32          output_len;   /* Final compressed length */
   png_byte             output[1024]; /* First block of output */
} compression_state;

static void
png_text_compress_init(compression_state *comp, png_const_bytep input,
   png_alloc_size_t input_len)
{
   comp->input = input;
   comp->input_len = input_len;
   comp->output_len = 0;
}

/* Compress the data in the compression state input */
static int
png_text_compress(png_structrp png_ptr, png_uint_32 chunk_name,
   compression_state *comp, png_uint_32 prefix_len)
{
   int ret;

   /* To find the length of the output it is necessary to first compress the
    * input. The result is buffered rather than using the two-pass algorithm
    * that is used on the inflate side; deflate is assumed to be slower and a
    * PNG writer is assumed to have more memory available than a PNG reader.
    *
    * IMPLEMENTATION NOTE: the zlib API deflateBound() can be used to find an
    * upper limit on the output size, but it is always bigger than the input
    * size so it is likely to be more efficient to use this linked-list
    * approach.
    */
   ret = png_deflate_claim(png_ptr, chunk_name, comp->input_len);

   if (ret != Z_OK)
      return ret;

   /* Set up the compression buffers, we need a loop here to avoid overflowing a
    * uInt.  Use ZLIB_IO_MAX to limit the input.  The output is always limited
    * by the output buffer size, so there is no need to check that.  Since this
    * is ANSI-C we know that an 'int', hence a uInt, is always at least 16 bits
    * in size.
    */
   {
      png_compression_bufferp *end = &png_ptr->zbuffer_list;
      png_alloc_size_t input_len = comp->input_len; /* may be zero! */
      png_uint_32 output_len;

      /* zlib updates these for us: */
      png_ptr->zstream.next_in = PNGZ_INPUT_CAST(comp->input);
      png_ptr->zstream.avail_in = 0; /* Set below */
      png_ptr->zstream.next_out = comp->output;
      png_ptr->zstream.avail_out = (sizeof comp->output);

      output_len = png_ptr->zstream.avail_out;

      do
      {
         uInt avail_in = ZLIB_IO_MAX;

         if (avail_in > input_len)
            avail_in = (uInt)input_len;

         input_len -= avail_in;

         png_ptr->zstream.avail_in = avail_in;

         if (png_ptr->zstream.avail_out == 0)
         {
            png_compression_buffer *next;

            /* Chunk data is limited to 2^31 bytes in length, so the prefix
             * length must be counted here.
             */
            if (output_len + prefix_len > PNG_UINT_31_MAX)
            {
               ret = Z_MEM_ERROR;
               break;
            }

            /* Need a new (malloc'ed) buffer, but there may be one present
             * already.
             */
            next = *end;
            if (next == NULL)
            {
               next = png_voidcast(png_compression_bufferp, png_malloc_base
                  (png_ptr, PNG_COMPRESSION_BUFFER_SIZE(png_ptr)));

               if (next == NULL)
               {
                  ret = Z_MEM_ERROR;
                  break;
               }

               /* Link in this buffer (so that it will be freed later) */
               next->next = NULL;
               *end = next;
            }

            png_ptr->zstream.next_out = next->output;
            png_ptr->zstream.avail_out = png_ptr->zbuffer_size;
            output_len += png_ptr->zstream.avail_out;

            /* Move 'end' to the next buffer pointer. */
            end = &next->next;
         }

         /* Compress the data */
         ret = deflate(&png_ptr->zstream,
            input_len > 0 ? Z_NO_FLUSH : Z_FINISH);

         /* Claw back input data that was not consumed (because avail_in is
          * reset above every time round the loop).
          */
         input_len += png_ptr->zstream.avail_in;
         png_ptr->zstream.avail_in = 0; /* safety */
      }
      while (ret == Z_OK);

      /* There may be some space left in the last output buffer. This needs to
       * be subtracted from output_len.
       */
      output_len -= png_ptr->zstream.avail_out;
      png_ptr->zstream.avail_out = 0; /* safety */
      comp->output_len = output_len;

      /* Now double check the output length, put in a custom message if it is
       * too long.  Otherwise ensure the z_stream::msg pointer is set to
       * something.
       */
      if (output_len + prefix_len >= PNG_UINT_31_MAX)
      {
         png_ptr->zstream.msg = PNGZ_MSG_CAST("compressed data too long");
         ret = Z_MEM_ERROR;
      }

      else
         png_zstream_error(png_ptr, ret);

      /* Reset zlib for another zTXt/iTXt or image data */
      png_ptr->zowner = 0;

      /* The only success case is Z_STREAM_END, input_len must be 0; if not this
       * is an internal error.
       */
      if (ret == Z_STREAM_END && input_len == 0)
      {
#ifdef PNG_WRITE_OPTIMIZE_CMF_SUPPORTED
         /* Fix up the deflate header, if required */
         optimize_cmf(comp->output, comp->input_len);
#endif
         /* But Z_OK is returned, not Z_STREAM_END; this allows the claim
          * function above to return Z_STREAM_END on an error (though it never
          * does in the current versions of zlib.)
          */
         return Z_OK;
      }

      else
         return ret;
   }
}

/* Ship the compressed text out via chunk writes */
static void
png_write_compressed_data_out(png_structrp png_ptr, compression_state *comp)
{
   png_uint_32 output_len = comp->output_len;
   png_const_bytep output = comp->output;
   png_uint_32 avail = (sizeof comp->output);
   png_compression_buffer *next = png_ptr->zbuffer_list;

   for (;;)
   {
      if (avail > output_len)
         avail = output_len;

      png_write_chunk_data(png_ptr, output, avail);

      output_len -= avail;

      if (output_len == 0 || next == NULL)
         break;

      avail = png_ptr->zbuffer_size;
      output = next->output;
      next = next->next;
   }

   /* This is an internal error; 'next' must have been NULL! */
   if (output_len > 0)
      png_error(png_ptr, "error writing ancillary chunked compressed data");
}
#endif /* WRITE_COMPRESSED_TEXT */

/* Write the IHDR chunk, and update the png_struct with the necessary
 * information.  Note that the rest of this code depends upon this
 * information being correct.
 */
void /* PRIVATE */
png_write_IHDR(png_structrp png_ptr, png_uint_32 width, png_uint_32 height,
    int bit_depth, int color_type, int compression_type, int filter_type,
    int interlace_type)
{
   png_byte buf[13]; /* Buffer to store the IHDR info */

   png_debug(1, "in png_write_IHDR");

   /* Check that we have valid input data from the application info */
   switch (color_type)
   {
      case PNG_COLOR_TYPE_GRAY:
         switch (bit_depth)
         {
            case 1:
            case 2:
            case 4:
            case 8:
#ifdef PNG_WRITE_16BIT_SUPPORTED
            case 16:
#endif
               png_ptr->channels = 1; break;

            default:
               png_error(png_ptr,
                   "Invalid bit depth for grayscale image");
         }
         break;

      case PNG_COLOR_TYPE_RGB:
#ifdef PNG_WRITE_16BIT_SUPPORTED
         if (bit_depth != 8 && bit_depth != 16)
#else
         if (bit_depth != 8)
#endif
            png_error(png_ptr, "Invalid bit depth for RGB image");

         png_ptr->channels = 3;
         break;

      case PNG_COLOR_TYPE_PALETTE:
         switch (bit_depth)
         {
            case 1:
            case 2:
            case 4:
            case 8:
               png_ptr->channels = 1;
               break;

            default:
               png_error(png_ptr, "Invalid bit depth for paletted image");
         }
         break;

      case PNG_COLOR_TYPE_GRAY_ALPHA:
         if (bit_depth != 8 && bit_depth != 16)
            png_error(png_ptr, "Invalid bit depth for grayscale+alpha image");

         png_ptr->channels = 2;
         break;

      case PNG_COLOR_TYPE_RGB_ALPHA:
#ifdef PNG_WRITE_16BIT_SUPPORTED
         if (bit_depth != 8 && bit_depth != 16)
#else
         if (bit_depth != 8)
#endif
            png_error(png_ptr, "Invalid bit depth for RGBA image");

         png_ptr->channels = 4;
         break;

      default:
         png_error(png_ptr, "Invalid image color type specified");
   }

   if (compression_type != PNG_COMPRESSION_TYPE_BASE)
   {
      png_warning(png_ptr, "Invalid compression type specified");
      compression_type = PNG_COMPRESSION_TYPE_BASE;
   }

   /* Write filter_method 64 (intrapixel differencing) only if
    * 1. Libpng was compiled with PNG_MNG_FEATURES_SUPPORTED and
    * 2. Libpng did not write a PNG signature (this filter_method is only
    *    used in PNG datastreams that are embedded in MNG datastreams) and
    * 3. The application called png_permit_mng_features with a mask that
    *    included PNG_FLAG_MNG_FILTER_64 and
    * 4. The filter_method is 64 and
    * 5. The color_type is RGB or RGBA
    */
   if (
#ifdef PNG_MNG_FEATURES_SUPPORTED
       !((png_ptr->mng_features_permitted & PNG_FLAG_MNG_FILTER_64) != 0 &&
       ((png_ptr->mode & PNG_HAVE_PNG_SIGNATURE) == 0) &&
       (color_type == PNG_COLOR_TYPE_RGB ||
        color_type == PNG_COLOR_TYPE_RGB_ALPHA) &&
       (filter_type == PNG_INTRAPIXEL_DIFFERENCING)) &&
#endif
       filter_type != PNG_FILTER_TYPE_BASE)
   {
      png_warning(png_ptr, "Invalid filter type specified");
      filter_type = PNG_FILTER_TYPE_BASE;
   }

#ifdef PNG_WRITE_INTERLACING_SUPPORTED
   if (interlace_type != PNG_INTERLACE_NONE &&
       interlace_type != PNG_INTERLACE_ADAM7)
   {
      png_warning(png_ptr, "Invalid interlace type specified");
      interlace_type = PNG_INTERLACE_ADAM7;
   }
#else
   interlace_type=PNG_INTERLACE_NONE;
#endif

   /* Save the relevant information */
   png_ptr->bit_depth = (png_byte)bit_depth;
   png_ptr->color_type = (png_byte)color_type;
   png_ptr->interlaced = (png_byte)interlace_type;
#ifdef PNG_MNG_FEATURES_SUPPORTED
   png_ptr->filter_type = (png_byte)filter_type;
#endif
   png_ptr->compression_type = (png_byte)compression_type;
   png_ptr->width = width;
   png_ptr->height = height;

   png_ptr->pixel_depth = (png_byte)(bit_depth * png_ptr->channels);
   png_ptr->rowbytes = PNG_ROWBYTES(png_ptr->pixel_depth, width);
   /* Set the usr info, so any transformations can modify it */
   png_ptr->usr_width = png_ptr->width;
   png_ptr->usr_bit_depth = png_ptr->bit_depth;
   png_ptr->usr_channels = png_ptr->channels;

   /* Pack the header information into the buffer */
   png_save_uint_32(buf, width);
   png_save_uint_32(buf + 4, height);
   buf[8] = (png_byte)bit_depth;
   buf[9] = (png_byte)color_type;
   buf[10] = (png_byte)compression_type;
   buf[11] = (png_byte)filter_type;
   buf[12] = (png_byte)interlace_type;

   /* Write the chunk */
   png_write_complete_chunk(png_ptr, png_IHDR, buf, (png_size_t)13);

   if ((png_ptr->do_filter) == PNG_NO_FILTERS)
   {
      if (png_ptr->color_type == PNG_COLOR_TYPE_PALETTE ||
          png_ptr->bit_depth < 8)
         png_ptr->do_filter = PNG_FILTER_NONE;

      else
         png_ptr->do_filter = PNG_ALL_FILTERS;
   }

   png_ptr->mode = PNG_HAVE_IHDR; /* not READY_FOR_ZTXT */
}

/* Write the palette.  We are careful not to trust png_color to be in the
 * correct order for PNG, so people can redefine it to any convenient
 * structure.
 */
void /* PRIVATE */
png_write_PLTE(png_structrp png_ptr, png_const_colorp palette,
    png_uint_32 num_pal)
{
   png_uint_32 max_palette_length, i;
   png_const_colorp pal_ptr;
   png_byte buf[3];

   png_debug(1, "in png_write_PLTE");

   max_palette_length = (png_ptr->color_type == PNG_COLOR_TYPE_PALETTE) ?
      (1 << png_ptr->bit_depth) : PNG_MAX_PALETTE_LENGTH;

   if ((
#ifdef PNG_MNG_FEATURES_SUPPORTED
       (png_ptr->mng_features_permitted & PNG_FLAG_MNG_EMPTY_PLTE) == 0 &&
#endif
       num_pal == 0) || num_pal > max_palette_length)
   {
      if (png_ptr->color_type == PNG_COLOR_TYPE_PALETTE)
      {
         png_error(png_ptr, "Invalid number of colors in palette");
      }

      else
      {
         png_warning(png_ptr, "Invalid number of colors in palette");
         return;
      }
   }

   if ((png_ptr->color_type & PNG_COLOR_MASK_COLOR) == 0)
   {
      png_warning(png_ptr,
          "Ignoring request to write a PLTE chunk in grayscale PNG");

      return;
   }

   png_ptr->num_palette = (png_uint_16)num_pal;
   png_debug1(3, "num_palette = %d", png_ptr->num_palette);

   png_write_chunk_header(png_ptr, png_PLTE, (png_uint_32)(num_pal * 3));
#ifdef PNG_POINTER_INDEXING_SUPPORTED

   for (i = 0, pal_ptr = palette; i < num_pal; i++, pal_ptr++)
   {
      buf[0] = pal_ptr->red;
      buf[1] = pal_ptr->green;
      buf[2] = pal_ptr->blue;
      png_write_chunk_data(png_ptr, buf, (png_size_t)3);
   }

#else
   /* This is a little slower but some buggy compilers need to do this
    * instead
    */
   pal_ptr=palette;

   for (i = 0; i < num_pal; i++)
   {
      buf[0] = pal_ptr[i].red;
      buf[1] = pal_ptr[i].green;
      buf[2] = pal_ptr[i].blue;
      png_write_chunk_data(png_ptr, buf, (png_size_t)3);
   }

#endif
   png_write_chunk_end(png_ptr);
   png_ptr->mode |= PNG_HAVE_PLTE;
}

/* This is similar to png_text_compress, above, except that it does not require
 * all of the data at once and, instead of buffering the compressed result,
 * writes it as IDAT chunks.  Unlike png_text_compress it *can* png_error out
 * because it calls the write interface.  As a result it does its own error
 * reporting and does not return an error code.  In the event of error it will
 * just call png_error.  The input data length may exceed 32-bits.  The 'flush'
 * parameter is exactly the same as that to deflate, with the following
 * meanings:
 *
 * Z_NO_FLUSH: normal incremental output of compressed data
 * Z_SYNC_FLUSH: do a SYNC_FLUSH, used by png_write_flush
 * Z_FINISH: this is the end of the input, do a Z_FINISH and clean up
 *
 * The routine manages the acquire and release of the png_ptr->zstream by
 * checking and (at the end) clearing png_ptr->zowner; it does some sanity
 * checks on the 'mode' flags while doing this.
 */
void /* PRIVATE */
png_compress_IDAT(png_structrp png_ptr, png_const_bytep input,
   png_alloc_size_t input_len, int flush)
{
   if (png_ptr->zowner != png_IDAT)
   {
      /* First time.   Ensure we have a temporary buffer for compression and
       * trim the buffer list if it has more than one entry to free memory.
       * If 'WRITE_COMPRESSED_TEXT' is not set the list will never have been
       * created at this point, but the check here is quick and safe.
       */
      if (png_ptr->zbuffer_list == NULL)
      {
         png_ptr->zbuffer_list = png_voidcast(png_compression_bufferp,
            png_malloc(png_ptr, PNG_COMPRESSION_BUFFER_SIZE(png_ptr)));
         png_ptr->zbuffer_list->next = NULL;
      }

      else
         png_free_buffer_list(png_ptr, &png_ptr->zbuffer_list->next);

      /* It is a terminal error if we can't claim the zstream. */
      if (png_deflate_claim(png_ptr, png_IDAT, png_image_size(png_ptr)) != Z_OK)
         png_error(png_ptr, png_ptr->zstream.msg);

      /* The output state is maintained in png_ptr->zstream, so it must be
       * initialized here after the claim.
       */
      png_ptr->zstream.next_out = png_ptr->zbuffer_list->output;
      png_ptr->zstream.avail_out = png_ptr->zbuffer_size;
   }

   /* Now loop reading and writing until all the input is consumed or an error
    * terminates the operation.  The _out values are maintained across calls to
    * this function, but the input must be reset each time.
    */
   png_ptr->zstream.next_in = PNGZ_INPUT_CAST(input);
   png_ptr->zstream.avail_in = 0; /* set below */
   for (;;)
   {
      int ret;

      /* INPUT: from the row data */
      uInt avail = ZLIB_IO_MAX;

      if (avail > input_len)
         avail = (uInt)input_len; /* safe because of the check */

      png_ptr->zstream.avail_in = avail;
      input_len -= avail;

      ret = deflate(&png_ptr->zstream, input_len > 0 ? Z_NO_FLUSH : flush);

      /* Include as-yet unconsumed input */
      input_len += png_ptr->zstream.avail_in;
      png_ptr->zstream.avail_in = 0;

      /* OUTPUT: write complete IDAT chunks when avail_out drops to zero. Note
       * that these two zstream fields are preserved across the calls, therefore
       * there is no need to set these up on entry to the loop.
       */
      if (png_ptr->zstream.avail_out == 0)
      {
         png_bytep data = png_ptr->zbuffer_list->output;
         uInt size = png_ptr->zbuffer_size;

         /* Write an IDAT containing the data then reset the buffer.  The
          * first IDAT may need deflate header optimization.
          */
#ifdef PNG_WRITE_OPTIMIZE_CMF_SUPPORTED
            if ((png_ptr->mode & PNG_HAVE_IDAT) == 0 &&
                png_ptr->compression_type == PNG_COMPRESSION_TYPE_BASE)
               optimize_cmf(data, png_image_size(png_ptr));
#endif

         png_write_complete_chunk(png_ptr, png_IDAT, data, size);
         png_ptr->mode |= PNG_HAVE_IDAT;

         png_ptr->zstream.next_out = data;
         png_ptr->zstream.avail_out = size;

         /* For SYNC_FLUSH or FINISH it is essential to keep calling zlib with
          * the same flush parameter until it has finished output, for NO_FLUSH
          * it doesn't matter.
          */
         if (ret == Z_OK && flush != Z_NO_FLUSH)
            continue;
      }

      /* The order of these checks doesn't matter much; it just affects which
       * possible error might be detected if multiple things go wrong at once.
       */
      if (ret == Z_OK) /* most likely return code! */
      {
         /* If all the input has been consumed then just return.  If Z_FINISH
          * was used as the flush parameter something has gone wrong if we get
          * here.
          */
         if (input_len == 0)
         {
            if (flush == Z_FINISH)
               png_error(png_ptr, "Z_OK on Z_FINISH with output space");

            return;
         }
      }

      else if (ret == Z_STREAM_END && flush == Z_FINISH)
      {
         /* This is the end of the IDAT data; any pending output must be
          * flushed.  For small PNG files we may still be at the beginning.
          */
         png_bytep data = png_ptr->zbuffer_list->output;
         uInt size = png_ptr->zbuffer_size - png_ptr->zstream.avail_out;

#ifdef PNG_WRITE_OPTIMIZE_CMF_SUPPORTED
         if ((png_ptr->mode & PNG_HAVE_IDAT) == 0 &&
             png_ptr->compression_type == PNG_COMPRESSION_TYPE_BASE)
            optimize_cmf(data, png_image_size(png_ptr));
#endif

         png_write_complete_chunk(png_ptr, png_IDAT, data, size);
         png_ptr->zstream.avail_out = 0;
         png_ptr->zstream.next_out = NULL;
         png_ptr->mode |= PNG_HAVE_IDAT | PNG_AFTER_IDAT;

         png_ptr->zowner = 0; /* Release the stream */
         return;
      }

      else
      {
         /* This is an error condition. */
         png_zstream_error(png_ptr, ret);
         png_error(png_ptr, png_ptr->zstream.msg);
      }
   }
}

/* Write an IEND chunk */
void /* PRIVATE */
png_write_IEND(png_structrp png_ptr)
{
   png_debug(1, "in png_write_IEND");

   png_write_complete_chunk(png_ptr, png_IEND, NULL, (png_size_t)0);
   png_ptr->mode |= PNG_HAVE_IEND;
}

#ifdef PNG_WRITE_gAMA_SUPPORTED
/* Write a gAMA chunk */
void /* PRIVATE */
png_write_gAMA_fixed(png_structrp png_ptr, png_fixed_point file_gamma)
{
   png_byte buf[4];

   png_debug(1, "in png_write_gAMA");

   /* file_gamma is saved in 1/100,000ths */
   png_save_uint_32(buf, (png_uint_32)file_gamma);
   png_write_complete_chunk(png_ptr, png_gAMA, buf, (png_size_t)4);
}
#endif

#ifdef PNG_WRITE_sRGB_SUPPORTED
/* Write a sRGB chunk */
void /* PRIVATE */
png_write_sRGB(png_structrp png_ptr, int srgb_intent)
{
   png_byte buf[1];

   png_debug(1, "in png_write_sRGB");

   if (srgb_intent >= PNG_sRGB_INTENT_LAST)
      png_warning(png_ptr,
          "Invalid sRGB rendering intent specified");

   buf[0]=(png_byte)srgb_intent;
   png_write_complete_chunk(png_ptr, png_sRGB, buf, (png_size_t)1);
}
#endif

#ifdef PNG_WRITE_iCCP_SUPPORTED
/* Write an iCCP chunk */
void /* PRIVATE */
png_write_iCCP(png_structrp png_ptr, png_const_charp name,
    png_const_bytep profile)
{
   png_uint_32 name_len;
   png_uint_32 profile_len;
   png_byte new_name[81]; /* 1 byte for the compression byte */
   compression_state comp;
   png_uint_32 temp;

   png_debug(1, "in png_write_iCCP");

   /* These are all internal problems: the profile should have been checked
    * before when it was stored.
    */
   if (profile == NULL)
      png_error(png_ptr, "No profile for iCCP chunk"); /* internal error */

   profile_len = png_get_uint_32(profile);

   if (profile_len < 132)
      png_error(png_ptr, "ICC profile too short");

   temp = (png_uint_32) (*(profile+8));
   if (temp > 3 && (profile_len & 0x03))
      png_error(png_ptr, "ICC profile length invalid (not a multiple of 4)");

   {
      png_uint_32 embedded_profile_len = png_get_uint_32(profile);

      if (profile_len != embedded_profile_len)
         png_error(png_ptr, "Profile length does not match profile");
   }

   name_len = png_check_keyword(png_ptr, name, new_name);

   if (name_len == 0)
      png_error(png_ptr, "iCCP: invalid keyword");

   new_name[++name_len] = PNG_COMPRESSION_TYPE_BASE;

   /* Make sure we include the NULL after the name and the compression type */
   ++name_len;

   png_text_compress_init(&comp, profile, profile_len);

   /* Allow for keyword terminator and compression byte */
   if (png_text_compress(png_ptr, png_iCCP, &comp, name_len) != Z_OK)
      png_error(png_ptr, png_ptr->zstream.msg);

   png_write_chunk_header(png_ptr, png_iCCP, name_len + comp.output_len);

   png_write_chunk_data(png_ptr, new_name, name_len);

   png_write_compressed_data_out(png_ptr, &comp);

   png_write_chunk_end(png_ptr);
}
#endif

#ifdef PNG_WRITE_sPLT_SUPPORTED
/* Write a sPLT chunk */
void /* PRIVATE */
png_write_sPLT(png_structrp png_ptr, png_const_sPLT_tp spalette)
{
   png_uint_32 name_len;
   png_byte new_name[80];
   png_byte entrybuf[10];
   png_size_t entry_size = (spalette->depth == 8 ? 6 : 10);
   png_size_t palette_size = entry_size * spalette->nentries;
   png_sPLT_entryp ep;
#ifndef PNG_POINTER_INDEXING_SUPPORTED
   int i;
#endif

   png_debug(1, "in png_write_sPLT");

   name_len = png_check_keyword(png_ptr, spalette->name, new_name);

   if (name_len == 0)
      png_error(png_ptr, "sPLT: invalid keyword");

   /* Make sure we include the NULL after the name */
   png_write_chunk_header(png_ptr, png_sPLT,
       (png_uint_32)(name_len + 2 + palette_size));

   png_write_chunk_data(png_ptr, (png_bytep)new_name,
       (png_size_t)(name_len + 1));

   png_write_chunk_data(png_ptr, &spalette->depth, (png_size_t)1);

   /* Loop through each palette entry, writing appropriately */
#ifdef PNG_POINTER_INDEXING_SUPPORTED
   for (ep = spalette->entries; ep<spalette->entries + spalette->nentries; ep++)
   {
      if (spalette->depth == 8)
      {
         entrybuf[0] = (png_byte)ep->red;
         entrybuf[1] = (png_byte)ep->green;
         entrybuf[2] = (png_byte)ep->blue;
         entrybuf[3] = (png_byte)ep->alpha;
         png_save_uint_16(entrybuf + 4, ep->frequency);
      }

      else
      {
         png_save_uint_16(entrybuf + 0, ep->red);
         png_save_uint_16(entrybuf + 2, ep->green);
         png_save_uint_16(entrybuf + 4, ep->blue);
         png_save_uint_16(entrybuf + 6, ep->alpha);
         png_save_uint_16(entrybuf + 8, ep->frequency);
      }

      png_write_chunk_data(png_ptr, entrybuf, entry_size);
   }
#else
   ep=spalette->entries;
   for (i = 0; i>spalette->nentries; i++)
   {
      if (spalette->depth == 8)
      {
         entrybuf[0] = (png_byte)ep[i].red;
         entrybuf[1] = (png_byte)ep[i].green;
         entrybuf[2] = (png_byte)ep[i].blue;
         entrybuf[3] = (png_byte)ep[i].alpha;
         png_save_uint_16(entrybuf + 4, ep[i].frequency);
      }

      else
      {
         png_save_uint_16(entrybuf + 0, ep[i].red);
         png_save_uint_16(entrybuf + 2, ep[i].green);
         png_save_uint_16(entrybuf + 4, ep[i].blue);
         png_save_uint_16(entrybuf + 6, ep[i].alpha);
         png_save_uint_16(entrybuf + 8, ep[i].frequency);
      }

      png_write_chunk_data(png_ptr, entrybuf, entry_size);
   }
#endif

   png_write_chunk_end(png_ptr);
}
#endif

#ifdef PNG_WRITE_sBIT_SUPPORTED
/* Write the sBIT chunk */
void /* PRIVATE */
png_write_sBIT(png_structrp png_ptr, png_const_color_8p sbit, int color_type)
{
   png_byte buf[4];
   png_size_t size;

   png_debug(1, "in png_write_sBIT");

   /* Make sure we don't depend upon the order of PNG_COLOR_8 */
   if ((color_type & PNG_COLOR_MASK_COLOR) != 0)
   {
      png_byte maxbits;

      maxbits = (png_byte)(color_type==PNG_COLOR_TYPE_PALETTE ? 8 :
          png_ptr->usr_bit_depth);

      if (sbit->red == 0 || sbit->red > maxbits ||
          sbit->green == 0 || sbit->green > maxbits ||
          sbit->blue == 0 || sbit->blue > maxbits)
      {
         png_warning(png_ptr, "Invalid sBIT depth specified");
         return;
      }

      buf[0] = sbit->red;
      buf[1] = sbit->green;
      buf[2] = sbit->blue;
      size = 3;
   }

   else
   {
      if (sbit->gray == 0 || sbit->gray > png_ptr->usr_bit_depth)
      {
         png_warning(png_ptr, "Invalid sBIT depth specified");
         return;
      }

      buf[0] = sbit->gray;
      size = 1;
   }

   if ((color_type & PNG_COLOR_MASK_ALPHA) != 0)
   {
      if (sbit->alpha == 0 || sbit->alpha > png_ptr->usr_bit_depth)
      {
         png_warning(png_ptr, "Invalid sBIT depth specified");
         return;
      }

      buf[size++] = sbit->alpha;
   }

   png_write_complete_chunk(png_ptr, png_sBIT, buf, size);
}
#endif

#ifdef PNG_WRITE_cHRM_SUPPORTED
/* Write the cHRM chunk */
void /* PRIVATE */
png_write_cHRM_fixed(png_structrp png_ptr, const png_xy *xy)
{
   png_byte buf[32];

   png_debug(1, "in png_write_cHRM");

   /* Each value is saved in 1/100,000ths */
   png_save_int_32(buf,      xy->whitex);
   png_save_int_32(buf +  4, xy->whitey);

   png_save_int_32(buf +  8, xy->redx);
   png_save_int_32(buf + 12, xy->redy);

   png_save_int_32(buf + 16, xy->greenx);
   png_save_int_32(buf + 20, xy->greeny);

   png_save_int_32(buf + 24, xy->bluex);
   png_save_int_32(buf + 28, xy->bluey);

   png_write_complete_chunk(png_ptr, png_cHRM, buf, 32);
}
#endif

#ifdef PNG_WRITE_tRNS_SUPPORTED
/* Write the tRNS chunk */
void /* PRIVATE */
png_write_tRNS(png_structrp png_ptr, png_const_bytep trans_alpha,
    png_const_color_16p tran, int num_trans, int color_type)
{
   png_byte buf[6];

   png_debug(1, "in png_write_tRNS");

   if (color_type == PNG_COLOR_TYPE_PALETTE)
   {
      if (num_trans <= 0 || num_trans > (int)png_ptr->num_palette)
      {
         png_app_warning(png_ptr,
             "Invalid number of transparent colors specified");
         return;
      }

      /* Write the chunk out as it is */
      png_write_complete_chunk(png_ptr, png_tRNS, trans_alpha,
         (png_size_t)num_trans);
   }

   else if (color_type == PNG_COLOR_TYPE_GRAY)
   {
      /* One 16-bit value */
      if (tran->gray >= (1 << png_ptr->bit_depth))
      {
         png_app_warning(png_ptr,
             "Ignoring attempt to write tRNS chunk out-of-range for bit_depth");

         return;
      }

      png_save_uint_16(buf, tran->gray);
      png_write_complete_chunk(png_ptr, png_tRNS, buf, (png_size_t)2);
   }

   else if (color_type == PNG_COLOR_TYPE_RGB)
   {
      /* Three 16-bit values */
      png_save_uint_16(buf, tran->red);
      png_save_uint_16(buf + 2, tran->green);
      png_save_uint_16(buf + 4, tran->blue);
#ifdef PNG_WRITE_16BIT_SUPPORTED
      if (png_ptr->bit_depth == 8 && (buf[0] | buf[2] | buf[4]) != 0)
#else
      if ((buf[0] | buf[2] | buf[4]) != 0)
#endif
      {
         png_app_warning(png_ptr,
           "Ignoring attempt to write 16-bit tRNS chunk when bit_depth is 8");
         return;
      }

      png_write_complete_chunk(png_ptr, png_tRNS, buf, (png_size_t)6);
   }

   else
   {
      png_app_warning(png_ptr, "Can't write tRNS with an alpha channel");
   }
}
#endif

#ifdef PNG_WRITE_bKGD_SUPPORTED
/* Write the background chunk */
void /* PRIVATE */
png_write_bKGD(png_structrp png_ptr, png_const_color_16p back, int color_type)
{
   png_byte buf[6];

   png_debug(1, "in png_write_bKGD");

   if (color_type == PNG_COLOR_TYPE_PALETTE)
   {
      if (
#ifdef PNG_MNG_FEATURES_SUPPORTED
          (png_ptr->num_palette != 0 ||
          (png_ptr->mng_features_permitted & PNG_FLAG_MNG_EMPTY_PLTE) == 0) &&
#endif
         back->index >= png_ptr->num_palette)
      {
         png_warning(png_ptr, "Invalid background palette index");
         return;
      }

      buf[0] = back->index;
      png_write_complete_chunk(png_ptr, png_bKGD, buf, (png_size_t)1);
   }

   else if ((color_type & PNG_COLOR_MASK_COLOR) != 0)
   {
      png_save_uint_16(buf, back->red);
      png_save_uint_16(buf + 2, back->green);
      png_save_uint_16(buf + 4, back->blue);
#ifdef PNG_WRITE_16BIT_SUPPORTED
      if (png_ptr->bit_depth == 8 && (buf[0] | buf[2] | buf[4]) != 0)
#else
      if ((buf[0] | buf[2] | buf[4]) != 0)
#endif
      {
         png_warning(png_ptr,
             "Ignoring attempt to write 16-bit bKGD chunk when bit_depth is 8");

         return;
      }

      png_write_complete_chunk(png_ptr, png_bKGD, buf, (png_size_t)6);
   }

   else
   {
      if (back->gray >= (1 << png_ptr->bit_depth))
      {
         png_warning(png_ptr,
             "Ignoring attempt to write bKGD chunk out-of-range for bit_depth");

         return;
      }

      png_save_uint_16(buf, back->gray);
      png_write_complete_chunk(png_ptr, png_bKGD, buf, (png_size_t)2);
   }
}
#endif

#ifdef PNG_WRITE_hIST_SUPPORTED
/* Write the histogram */
void /* PRIVATE */
png_write_hIST(png_structrp png_ptr, png_const_uint_16p hist, int num_hist)
{
   int i;
   png_byte buf[3];

   png_debug(1, "in png_write_hIST");

   if (num_hist > (int)png_ptr->num_palette)
   {
      png_debug2(3, "num_hist = %d, num_palette = %d", num_hist,
          png_ptr->num_palette);

      png_warning(png_ptr, "Invalid number of histogram entries specified");
      return;
   }

   png_write_chunk_header(png_ptr, png_hIST, (png_uint_32)(num_hist * 2));

   for (i = 0; i < num_hist; i++)
   {
      png_save_uint_16(buf, hist[i]);
      png_write_chunk_data(png_ptr, buf, (png_size_t)2);
   }

   png_write_chunk_end(png_ptr);
}
#endif

#ifdef PNG_WRITE_tEXt_SUPPORTED
/* Write a tEXt chunk */
void /* PRIVATE */
png_write_tEXt(png_structrp png_ptr, png_const_charp key, png_const_charp text,
    png_size_t text_len)
{
   png_uint_32 key_len;
   png_byte new_key[80];

   png_debug(1, "in png_write_tEXt");

   key_len = png_check_keyword(png_ptr, key, new_key);

   if (key_len == 0)
      png_error(png_ptr, "tEXt: invalid keyword");

   if (text == NULL || *text == '\0')
      text_len = 0;

   else
      text_len = strlen(text);

   if (text_len > PNG_UINT_31_MAX - (key_len+1))
      png_error(png_ptr, "tEXt: text too long");

   /* Make sure we include the 0 after the key */
   png_write_chunk_header(png_ptr, png_tEXt,
       (png_uint_32)/*checked above*/(key_len + text_len + 1));
   /*
    * We leave it to the application to meet PNG-1.0 requirements on the
    * contents of the text.  PNG-1.0 through PNG-1.2 discourage the use of
    * any non-Latin-1 characters except for NEWLINE.  ISO PNG will forbid them.
    * The NUL character is forbidden by PNG-1.0 through PNG-1.2 and ISO PNG.
    */
   png_write_chunk_data(png_ptr, new_key, key_len + 1);

   if (text_len != 0)
      png_write_chunk_data(png_ptr, (png_const_bytep)text, text_len);

   png_write_chunk_end(png_ptr);
}
#endif

#ifdef PNG_WRITE_zTXt_SUPPORTED
/* Write a compressed text chunk */
void /* PRIVATE */
png_write_zTXt(png_structrp png_ptr, png_const_charp key, png_const_charp text,
    int compression)
{
   png_uint_32 key_len;
   png_byte new_key[81];
   compression_state comp;

   png_debug(1, "in png_write_zTXt");

   if (compression == PNG_TEXT_COMPRESSION_NONE)
   {
      png_write_tEXt(png_ptr, key, text, 0);
      return;
   }

   if (compression != PNG_TEXT_COMPRESSION_zTXt)
      png_error(png_ptr, "zTXt: invalid compression type");

   key_len = png_check_keyword(png_ptr, key, new_key);

   if (key_len == 0)
      png_error(png_ptr, "zTXt: invalid keyword");

   /* Add the compression method and 1 for the keyword separator. */
   new_key[++key_len] = PNG_COMPRESSION_TYPE_BASE;
   ++key_len;

   /* Compute the compressed data; do it now for the length */
   png_text_compress_init(&comp, (png_const_bytep)text,
      text == NULL ? 0 : strlen(text));

   if (png_text_compress(png_ptr, png_zTXt, &comp, key_len) != Z_OK)
      png_error(png_ptr, png_ptr->zstream.msg);

   /* Write start of chunk */
   png_write_chunk_header(png_ptr, png_zTXt, key_len + comp.output_len);

   /* Write key */
   png_write_chunk_data(png_ptr, new_key, key_len);

   /* Write the compressed data */
   png_write_compressed_data_out(png_ptr, &comp);

   /* Close the chunk */
   png_write_chunk_end(png_ptr);
}
#endif

#ifdef PNG_WRITE_iTXt_SUPPORTED
/* Write an iTXt chunk */
void /* PRIVATE */
png_write_iTXt(png_structrp png_ptr, int compression, png_const_charp key,
    png_const_charp lang, png_const_charp lang_key, png_const_charp text)
{
   png_uint_32 key_len, prefix_len;
   png_size_t lang_len, lang_key_len;
   png_byte new_key[82];
   compression_state comp;

   png_debug(1, "in png_write_iTXt");

   key_len = png_check_keyword(png_ptr, key, new_key);

   if (key_len == 0)
      png_error(png_ptr, "iTXt: invalid keyword");

   /* Set the compression flag */
   switch (compression)
   {
      case PNG_ITXT_COMPRESSION_NONE:
      case PNG_TEXT_COMPRESSION_NONE:
         compression = new_key[++key_len] = 0; /* no compression */
         break;

      case PNG_TEXT_COMPRESSION_zTXt:
      case PNG_ITXT_COMPRESSION_zTXt:
         compression = new_key[++key_len] = 1; /* compressed */
         break;

      default:
         png_error(png_ptr, "iTXt: invalid compression");
   }

   new_key[++key_len] = PNG_COMPRESSION_TYPE_BASE;
   ++key_len; /* for the keywod separator */

   /* We leave it to the application to meet PNG-1.0 requirements on the
    * contents of the text.  PNG-1.0 through PNG-1.2 discourage the use of
    * any non-Latin-1 characters except for NEWLINE.  ISO PNG, however,
    * specifies that the text is UTF-8 and this really doesn't require any
    * checking.
    *
    * The NUL character is forbidden by PNG-1.0 through PNG-1.2 and ISO PNG.
    *
    * TODO: validate the language tag correctly (see the spec.)
    */
   if (lang == NULL) lang = ""; /* empty language is valid */
   lang_len = strlen(lang)+1;
   if (lang_key == NULL) lang_key = ""; /* may be empty */
   lang_key_len = strlen(lang_key)+1;
   if (text == NULL) text = ""; /* may be empty */

   prefix_len = key_len;
   if (lang_len > PNG_UINT_31_MAX-prefix_len)
      prefix_len = PNG_UINT_31_MAX;
   else
      prefix_len = (png_uint_32)(prefix_len + lang_len);

   if (lang_key_len > PNG_UINT_31_MAX-prefix_len)
      prefix_len = PNG_UINT_31_MAX;
   else
      prefix_len = (png_uint_32)(prefix_len + lang_key_len);

   png_text_compress_init(&comp, (png_const_bytep)text, strlen(text));

   if (compression != 0)
   {
      if (png_text_compress(png_ptr, png_iTXt, &comp, prefix_len) != Z_OK)
         png_error(png_ptr, png_ptr->zstream.msg);
   }

   else
   {
      if (comp.input_len > PNG_UINT_31_MAX-prefix_len)
         png_error(png_ptr, "iTXt: uncompressed text too long");

      /* So the string will fit in a chunk: */
      comp.output_len = (png_uint_32)/*SAFE*/comp.input_len;
   }

   png_write_chunk_header(png_ptr, png_iTXt, comp.output_len + prefix_len);

   png_write_chunk_data(png_ptr, new_key, key_len);

   png_write_chunk_data(png_ptr, (png_const_bytep)lang, lang_len);

   png_write_chunk_data(png_ptr, (png_const_bytep)lang_key, lang_key_len);

   if (compression != 0)
      png_write_compressed_data_out(png_ptr, &comp);

   else
      png_write_chunk_data(png_ptr, (png_const_bytep)text, comp.output_len);

   png_write_chunk_end(png_ptr);
}
#endif

#ifdef PNG_WRITE_oFFs_SUPPORTED
/* Write the oFFs chunk */
void /* PRIVATE */
png_write_oFFs(png_structrp png_ptr, png_int_32 x_offset, png_int_32 y_offset,
    int unit_type)
{
   png_byte buf[9];

   png_debug(1, "in png_write_oFFs");

   if (unit_type >= PNG_OFFSET_LAST)
      png_warning(png_ptr, "Unrecognized unit type for oFFs chunk");

   png_save_int_32(buf, x_offset);
   png_save_int_32(buf + 4, y_offset);
   buf[8] = (png_byte)unit_type;

   png_write_complete_chunk(png_ptr, png_oFFs, buf, (png_size_t)9);
}
#endif
#ifdef PNG_WRITE_pCAL_SUPPORTED
/* Write the pCAL chunk (described in the PNG extensions document) */
void /* PRIVATE */
png_write_pCAL(png_structrp png_ptr, png_charp purpose, png_int_32 X0,
    png_int_32 X1, int type, int nparams, png_const_charp units,
    png_charpp params)
{
   png_uint_32 purpose_len;
   png_size_t units_len, total_len;
   png_size_tp params_len;
   png_byte buf[10];
   png_byte new_purpose[80];
   int i;

   png_debug1(1, "in png_write_pCAL (%d parameters)", nparams);

   if (type >= PNG_EQUATION_LAST)
      png_error(png_ptr, "Unrecognized equation type for pCAL chunk");

   purpose_len = png_check_keyword(png_ptr, purpose, new_purpose);

   if (purpose_len == 0)
      png_error(png_ptr, "pCAL: invalid keyword");

   ++purpose_len; /* terminator */

   png_debug1(3, "pCAL purpose length = %d", (int)purpose_len);
   units_len = strlen(units) + (nparams == 0 ? 0 : 1);
   png_debug1(3, "pCAL units length = %d", (int)units_len);
   total_len = purpose_len + units_len + 10;

   params_len = (png_size_tp)png_malloc(png_ptr,
       (png_alloc_size_t)(nparams * (sizeof (png_size_t))));

   /* Find the length of each parameter, making sure we don't count the
    * null terminator for the last parameter.
    */
   for (i = 0; i < nparams; i++)
   {
      params_len[i] = strlen(params[i]) + (i == nparams - 1 ? 0 : 1);
      png_debug2(3, "pCAL parameter %d length = %lu", i,
          (unsigned long)params_len[i]);
      total_len += params_len[i];
   }

   png_debug1(3, "pCAL total length = %d", (int)total_len);
   png_write_chunk_header(png_ptr, png_pCAL, (png_uint_32)total_len);
   png_write_chunk_data(png_ptr, new_purpose, purpose_len);
   png_save_int_32(buf, X0);
   png_save_int_32(buf + 4, X1);
   buf[8] = (png_byte)type;
   buf[9] = (png_byte)nparams;
   png_write_chunk_data(png_ptr, buf, (png_size_t)10);
   png_write_chunk_data(png_ptr, (png_const_bytep)units, (png_size_t)units_len);

   for (i = 0; i < nparams; i++)
   {
      png_write_chunk_data(png_ptr, (png_const_bytep)params[i], params_len[i]);
   }

   png_free(png_ptr, params_len);
   png_write_chunk_end(png_ptr);
}
#endif

#ifdef PNG_WRITE_sCAL_SUPPORTED
/* Write the sCAL chunk */
void /* PRIVATE */
png_write_sCAL_s(png_structrp png_ptr, int unit, png_const_charp width,
    png_const_charp height)
{
   png_byte buf[64];
   png_size_t wlen, hlen, total_len;

   png_debug(1, "in png_write_sCAL_s");

   wlen = strlen(width);
   hlen = strlen(height);
   total_len = wlen + hlen + 2;

   if (total_len > 64)
   {
      png_warning(png_ptr, "Can't write sCAL (buffer too small)");
      return;
   }

   buf[0] = (png_byte)unit;
   memcpy(buf + 1, width, wlen + 1);      /* Append the '\0' here */
   memcpy(buf + wlen + 2, height, hlen);  /* Do NOT append the '\0' here */

   png_debug1(3, "sCAL total length = %u", (unsigned int)total_len);
   png_write_complete_chunk(png_ptr, png_sCAL, buf, total_len);
}
#endif

#ifdef PNG_WRITE_pHYs_SUPPORTED
/* Write the pHYs chunk */
void /* PRIVATE */
png_write_pHYs(png_structrp png_ptr, png_uint_32 x_pixels_per_unit,
    png_uint_32 y_pixels_per_unit,
    int unit_type)
{
   png_byte buf[9];

   png_debug(1, "in png_write_pHYs");

   if (unit_type >= PNG_RESOLUTION_LAST)
      png_warning(png_ptr, "Unrecognized unit type for pHYs chunk");

   png_save_uint_32(buf, x_pixels_per_unit);
   png_save_uint_32(buf + 4, y_pixels_per_unit);
   buf[8] = (png_byte)unit_type;

   png_write_complete_chunk(png_ptr, png_pHYs, buf, (png_size_t)9);
}
#endif

#ifdef PNG_WRITE_tIME_SUPPORTED
/* Write the tIME chunk.  Use either png_convert_from_struct_tm()
 * or png_convert_from_time_t(), or fill in the structure yourself.
 */
void /* PRIVATE */
png_write_tIME(png_structrp png_ptr, png_const_timep mod_time)
{
   png_byte buf[7];

   png_debug(1, "in png_write_tIME");

   if (mod_time->month  > 12 || mod_time->month  < 1 ||
       mod_time->day    > 31 || mod_time->day    < 1 ||
       mod_time->hour   > 23 || mod_time->second > 60)
   {
      png_warning(png_ptr, "Invalid time specified for tIME chunk");
      return;
   }

   png_save_uint_16(buf, mod_time->year);
   buf[2] = mod_time->month;
   buf[3] = mod_time->day;
   buf[4] = mod_time->hour;
   buf[5] = mod_time->minute;
   buf[6] = mod_time->second;

   png_write_complete_chunk(png_ptr, png_tIME, buf, (png_size_t)7);
}
#endif

/* Initializes the row writing capability of libpng */
void /* PRIVATE */
png_write_start_row(png_structrp png_ptr)
{
#ifdef PNG_WRITE_INTERLACING_SUPPORTED
   /* Arrays to facilitate easy interlacing - use pass (0 - 6) as index */

   /* Start of interlace block */
   static PNG_CONST png_byte png_pass_start[7] = {0, 4, 0, 2, 0, 1, 0};

   /* Offset to next interlace block */
   static PNG_CONST png_byte png_pass_inc[7] = {8, 8, 4, 4, 2, 2, 1};

   /* Start of interlace block in the y direction */
   static PNG_CONST png_byte png_pass_ystart[7] = {0, 0, 4, 0, 2, 0, 1};

   /* Offset to next interlace block in the y direction */
   static PNG_CONST png_byte png_pass_yinc[7] = {8, 8, 8, 4, 4, 2, 2};
#endif

   png_alloc_size_t buf_size;
   int usr_pixel_depth;

#ifdef PNG_WRITE_FILTER_SUPPORTED
   png_byte filters;
#endif

   png_debug(1, "in png_write_start_row");

   usr_pixel_depth = png_ptr->usr_channels * png_ptr->usr_bit_depth;
   buf_size = PNG_ROWBYTES(usr_pixel_depth, png_ptr->width) + 1;

   /* 1.5.6: added to allow checking in the row write code. */
   png_ptr->transformed_pixel_depth = png_ptr->pixel_depth;
   png_ptr->maximum_pixel_depth = (png_byte)usr_pixel_depth;

   /* Set up row buffer */
   png_ptr->row_buf = png_voidcast(png_bytep, png_malloc(png_ptr, buf_size));

   png_ptr->row_buf[0] = PNG_FILTER_VALUE_NONE;

#ifdef PNG_WRITE_FILTER_SUPPORTED
   filters = png_ptr->do_filter;

   if (png_ptr->height == 1)
      filters &= 0xff & ~(PNG_FILTER_UP|PNG_FILTER_AVG|PNG_FILTER_PAETH);

   if (png_ptr->width == 1)
      filters &= 0xff & ~(PNG_FILTER_SUB|PNG_FILTER_AVG|PNG_FILTER_PAETH);

   if (filters == 0)
      filters = PNG_FILTER_NONE;

   png_ptr->do_filter = filters;

   if (((filters & (PNG_FILTER_SUB | PNG_FILTER_UP | PNG_FILTER_AVG |
       PNG_FILTER_PAETH)) != 0) && png_ptr->try_row == NULL)
   {
      int num_filters = 0;

      png_ptr->try_row = png_voidcast(png_bytep, png_malloc(png_ptr, buf_size));

      if (filters & PNG_FILTER_SUB)
         num_filters++;

      if (filters & PNG_FILTER_UP)
         num_filters++;

      if (filters & PNG_FILTER_AVG)
         num_filters++;

      if (filters & PNG_FILTER_PAETH)
         num_filters++;

      if (num_filters > 1)
         png_ptr->tst_row = png_voidcast(png_bytep, png_malloc(png_ptr,
             buf_size));
   }

   /* We only need to keep the previous row if we are using one of the following
    * filters.
    */
   if ((filters & (PNG_FILTER_AVG | PNG_FILTER_UP | PNG_FILTER_PAETH)) != 0)
      png_ptr->prev_row = png_voidcast(png_bytep,
         png_calloc(png_ptr, buf_size));
#endif /* WRITE_FILTER */

#ifdef PNG_WRITE_INTERLACING_SUPPORTED
   /* If interlaced, we need to set up width and height of pass */
   if (png_ptr->interlaced != 0)
   {
      if ((png_ptr->transformations & PNG_INTERLACE) == 0)
      {
         png_ptr->num_rows = (png_ptr->height + png_pass_yinc[0] - 1 -
             png_pass_ystart[0]) / png_pass_yinc[0];

         png_ptr->usr_width = (png_ptr->width + png_pass_inc[0] - 1 -
             png_pass_start[0]) / png_pass_inc[0];
      }

      else
      {
         png_ptr->num_rows = png_ptr->height;
         png_ptr->usr_width = png_ptr->width;
      }
   }

   else
#endif
   {
      png_ptr->num_rows = png_ptr->height;
      png_ptr->usr_width = png_ptr->width;
   }
}

/* Internal use only.  Called when finished processing a row of data. */
void /* PRIVATE */
png_write_finish_row(png_structrp png_ptr)
{
#ifdef PNG_WRITE_INTERLACING_SUPPORTED
   /* Arrays to facilitate easy interlacing - use pass (0 - 6) as index */

   /* Start of interlace block */
   static PNG_CONST png_byte png_pass_start[7] = {0, 4, 0, 2, 0, 1, 0};

   /* Offset to next interlace block */
   static PNG_CONST png_byte png_pass_inc[7] = {8, 8, 4, 4, 2, 2, 1};

   /* Start of interlace block in the y direction */
   static PNG_CONST png_byte png_pass_ystart[7] = {0, 0, 4, 0, 2, 0, 1};

   /* Offset to next interlace block in the y direction */
   static PNG_CONST png_byte png_pass_yinc[7] = {8, 8, 8, 4, 4, 2, 2};
#endif

   png_debug(1, "in png_write_finish_row");

   /* Next row */
   png_ptr->row_number++;

   /* See if we are done */
   if (png_ptr->row_number < png_ptr->num_rows)
      return;

#ifdef PNG_WRITE_INTERLACING_SUPPORTED
   /* If interlaced, go to next pass */
   if (png_ptr->interlaced != 0)
   {
      png_ptr->row_number = 0;
      if ((png_ptr->transformations & PNG_INTERLACE) != 0)
      {
         png_ptr->pass++;
      }

      else
      {
         /* Loop until we find a non-zero width or height pass */
         do
         {
            png_ptr->pass++;

            if (png_ptr->pass >= 7)
               break;

            png_ptr->usr_width = (png_ptr->width +
                png_pass_inc[png_ptr->pass] - 1 -
                png_pass_start[png_ptr->pass]) /
                png_pass_inc[png_ptr->pass];

            png_ptr->num_rows = (png_ptr->height +
                png_pass_yinc[png_ptr->pass] - 1 -
                png_pass_ystart[png_ptr->pass]) /
                png_pass_yinc[png_ptr->pass];

            if ((png_ptr->transformations & PNG_INTERLACE) != 0)
               break;

         } while (png_ptr->usr_width == 0 || png_ptr->num_rows == 0);

      }

      /* Reset the row above the image for the next pass */
      if (png_ptr->pass < 7)
      {
         if (png_ptr->prev_row != NULL)
            memset(png_ptr->prev_row, 0,
                (png_size_t)(PNG_ROWBYTES(png_ptr->usr_channels*
                png_ptr->usr_bit_depth, png_ptr->width)) + 1);

         return;
      }
   }
#endif

   /* If we get here, we've just written the last row, so we need
      to flush the compressor */
   png_compress_IDAT(png_ptr, NULL, 0, Z_FINISH);
}

#ifdef PNG_WRITE_INTERLACING_SUPPORTED
/* Pick out the correct pixels for the interlace pass.
 * The basic idea here is to go through the row with a source
 * pointer and a destination pointer (sp and dp), and copy the
 * correct pixels for the pass.  As the row gets compacted,
 * sp will always be >= dp, so we should never overwrite anything.
 * See the default: case for the easiest code to understand.
 */
void /* PRIVATE */
png_do_write_interlace(png_row_infop row_info, png_bytep row, int pass)
{
   /* Arrays to facilitate easy interlacing - use pass (0 - 6) as index */

   /* Start of interlace block */
   static PNG_CONST png_byte png_pass_start[7] = {0, 4, 0, 2, 0, 1, 0};

   /* Offset to next interlace block */
   static PNG_CONST png_byte  png_pass_inc[7] = {8, 8, 4, 4, 2, 2, 1};

   png_debug(1, "in png_do_write_interlace");

   /* We don't have to do anything on the last pass (6) */
   if (pass < 6)
   {
      /* Each pixel depth is handled separately */
      switch (row_info->pixel_depth)
      {
         case 1:
         {
            png_bytep sp;
            png_bytep dp;
            unsigned int shift;
            int d;
            int value;
            png_uint_32 i;
            png_uint_32 row_width = row_info->width;

            dp = row;
            d = 0;
            shift = 7;

            for (i = png_pass_start[pass]; i < row_width;
               i += png_pass_inc[pass])
            {
               sp = row + (png_size_t)(i >> 3);
               value = (int)(*sp >> (7 - (int)(i & 0x07))) & 0x01;
               d |= (value << shift);

               if (shift == 0)
               {
                  shift = 7;
                  *dp++ = (png_byte)d;
                  d = 0;
               }

               else
                  shift--;

            }
            if (shift != 7)
               *dp = (png_byte)d;

            break;
         }

         case 2:
         {
            png_bytep sp;
            png_bytep dp;
            unsigned int shift;
            int d;
            int value;
            png_uint_32 i;
            png_uint_32 row_width = row_info->width;

            dp = row;
            shift = 6;
            d = 0;

            for (i = png_pass_start[pass]; i < row_width;
               i += png_pass_inc[pass])
            {
               sp = row + (png_size_t)(i >> 2);
               value = (*sp >> ((3 - (int)(i & 0x03)) << 1)) & 0x03;
               d |= (value << shift);

               if (shift == 0)
               {
                  shift = 6;
                  *dp++ = (png_byte)d;
                  d = 0;
               }

               else
                  shift -= 2;
            }
            if (shift != 6)
               *dp = (png_byte)d;

            break;
         }

         case 4:
         {
            png_bytep sp;
            png_bytep dp;
            unsigned int shift;
            int d;
            int value;
            png_uint_32 i;
            png_uint_32 row_width = row_info->width;

            dp = row;
            shift = 4;
            d = 0;
            for (i = png_pass_start[pass]; i < row_width;
                i += png_pass_inc[pass])
            {
               sp = row + (png_size_t)(i >> 1);
               value = (*sp >> ((1 - (int)(i & 0x01)) << 2)) & 0x0f;
               d |= (value << shift);

               if (shift == 0)
               {
                  shift = 4;
                  *dp++ = (png_byte)d;
                  d = 0;
               }

               else
                  shift -= 4;
            }
            if (shift != 4)
               *dp = (png_byte)d;

            break;
         }

         default:
         {
            png_bytep sp;
            png_bytep dp;
            png_uint_32 i;
            png_uint_32 row_width = row_info->width;
            png_size_t pixel_bytes;

            /* Start at the beginning */
            dp = row;

            /* Find out how many bytes each pixel takes up */
            pixel_bytes = (row_info->pixel_depth >> 3);

            /* Loop through the row, only looking at the pixels that matter */
            for (i = png_pass_start[pass]; i < row_width;
               i += png_pass_inc[pass])
            {
               /* Find out where the original pixel is */
               sp = row + (png_size_t)i * pixel_bytes;

               /* Move the pixel */
               if (dp != sp)
                  memcpy(dp, sp, pixel_bytes);

               /* Next pixel */
               dp += pixel_bytes;
            }
            break;
         }
      }
      /* Set new row width */
      row_info->width = (row_info->width +
          png_pass_inc[pass] - 1 -
          png_pass_start[pass]) /
          png_pass_inc[pass];

      row_info->rowbytes = PNG_ROWBYTES(row_info->pixel_depth,
          row_info->width);
   }
}
#endif


/* This filters the row, chooses which filter to use, if it has not already
 * been specified by the application, and then writes the row out with the
 * chosen filter.
 */
static void /* PRIVATE */
png_write_filtered_row(png_structrp png_ptr, png_bytep filtered_row,
   png_size_t row_bytes);

#ifdef PNG_WRITE_FILTER_SUPPORTED
static png_size_t /* PRIVATE */
png_setup_sub_row(png_structrp png_ptr, const png_uint_32 bpp,
    const png_size_t row_bytes, const png_size_t lmins)
{
   png_bytep rp, dp, lp;
   png_size_t i;
   png_size_t sum = 0;
   int v;

   png_ptr->try_row[0] = PNG_FILTER_VALUE_SUB;

   for (i = 0, rp = png_ptr->row_buf + 1, dp = png_ptr->try_row + 1; i < bpp;
        i++, rp++, dp++)
   {
      v = *dp = *rp;
      sum += (v < 128) ? v : 256 - v;
   }

   for (lp = png_ptr->row_buf + 1; i < row_bytes;
      i++, rp++, lp++, dp++)
   {
      v = *dp = (png_byte)(((int)*rp - (int)*lp) & 0xff);
      sum += (v < 128) ? v : 256 - v;

      if (sum > lmins)  /* We are already worse, don't continue. */
        break;
   }

   return (sum);
}

static png_size_t /* PRIVATE */
png_setup_up_row(png_structrp png_ptr, const png_size_t row_bytes,
    const png_size_t lmins)
{
   png_bytep rp, dp, pp;
   png_size_t i;
   png_size_t sum = 0;
   int v;

   png_ptr->try_row[0] = PNG_FILTER_VALUE_UP;

   for (i = 0, rp = png_ptr->row_buf + 1, dp = png_ptr->try_row + 1,
       pp = png_ptr->prev_row + 1; i < row_bytes;
       i++, rp++, pp++, dp++)
   {
      v = *dp = (png_byte)(((int)*rp - (int)*pp) & 0xff);
      sum += (v < 128) ? v : 256 - v;

      if (sum > lmins)  /* We are already worse, don't continue. */
        break;
   }

   return (sum);
}

static png_size_t /* PRIVATE */
png_setup_avg_row(png_structrp png_ptr, const png_uint_32 bpp,
      const png_size_t row_bytes, const png_size_t lmins)
{
   png_bytep rp, dp, pp, lp;
   png_uint_32 i;
   png_size_t sum = 0;
   int v;

   png_ptr->try_row[0] = PNG_FILTER_VALUE_AVG;

   for (i = 0, rp = png_ptr->row_buf + 1, dp = png_ptr->try_row + 1,
        pp = png_ptr->prev_row + 1; i < bpp; i++)
   {
      v = *dp++ = (png_byte)(((int)*rp++ - ((int)*pp++ / 2)) & 0xff);

      sum += (v < 128) ? v : 256 - v;
   }

   for (lp = png_ptr->row_buf + 1; i < row_bytes; i++)
   {
      v = *dp++ = (png_byte)(((int)*rp++ - (((int)*pp++ + (int)*lp++) / 2))
          & 0xff);

      sum += (v < 128) ? v : 256 - v;

      if (sum > lmins)  /* We are already worse, don't continue. */
        break;
   }

   return (sum);
}

static png_size_t /* PRIVATE */
png_setup_paeth_row(png_structrp png_ptr, const png_uint_32 bpp,
    const png_size_t row_bytes, const png_size_t lmins)
{
   png_bytep rp, dp, pp, cp, lp;
   png_size_t i;
   png_size_t sum = 0;
   int v;

   png_ptr->try_row[0] = PNG_FILTER_VALUE_PAETH;

   for (i = 0, rp = png_ptr->row_buf + 1, dp = png_ptr->try_row + 1,
       pp = png_ptr->prev_row + 1; i < bpp; i++)
   {
      v = *dp++ = (png_byte)(((int)*rp++ - (int)*pp++) & 0xff);

      sum += (v < 128) ? v : 256 - v;
   }

   for (lp = png_ptr->row_buf + 1, cp = png_ptr->prev_row + 1; i < row_bytes;
        i++)
   {
      int a, b, c, pa, pb, pc, p;

      b = *pp++;
      c = *cp++;
      a = *lp++;

      p = b - c;
      pc = a - c;

#ifdef PNG_USE_ABS
      pa = abs(p);
      pb = abs(pc);
      pc = abs(p + pc);
#else
      pa = p < 0 ? -p : p;
      pb = pc < 0 ? -pc : pc;
      pc = (p + pc) < 0 ? -(p + pc) : p + pc;
#endif

      p = (pa <= pb && pa <=pc) ? a : (pb <= pc) ? b : c;

      v = *dp++ = (png_byte)(((int)*rp++ - p) & 0xff);

      sum += (v < 128) ? v : 256 - v;

      if (sum > lmins)  /* We are already worse, don't continue. */
        break;
   }

   return (sum);
}
#endif /* WRITE_FILTER */

void /* PRIVATE */
png_write_find_filter(png_structrp png_ptr, png_row_infop row_info)
{
#ifndef PNG_WRITE_FILTER_SUPPORTED
   png_write_filtered_row(png_ptr, png_ptr->row_buf, row_info->rowbytes+1);
#else
   png_byte filter_to_do = png_ptr->do_filter;
   png_bytep row_buf;
   png_bytep best_row;
   png_uint_32 bpp;
   png_size_t mins;
   png_size_t row_bytes = row_info->rowbytes;

   png_debug(1, "in png_write_find_filter");

   /* Find out how many bytes offset each pixel is */
   bpp = (row_info->pixel_depth + 7) >> 3;

   row_buf = png_ptr->row_buf;
   mins = PNG_SIZE_MAX - 256/* so we can detect potential overflow of the
                               running sum */;

   /* The prediction method we use is to find which method provides the
    * smallest value when summing the absolute values of the distances
    * from zero, using anything >= 128 as negative numbers.  This is known
    * as the "minimum sum of absolute differences" heuristic.  Other
    * heuristics are the "weighted minimum sum of absolute differences"
    * (experimental and can in theory improve compression), and the "zlib
    * predictive" method (not implemented yet), which does test compressions
    * of lines using different filter methods, and then chooses the
    * (series of) filter(s) that give minimum compressed data size (VERY
    * computationally expensive).
    *
    * GRR 980525:  consider also
    *
    *   (1) minimum sum of absolute differences from running average (i.e.,
    *       keep running sum of non-absolute differences & count of bytes)
    *       [track dispersion, too?  restart average if dispersion too large?]
    *
    *  (1b) minimum sum of absolute differences from sliding average, probably
    *       with window size <= deflate window (usually 32K)
    *
    *   (2) minimum sum of squared differences from zero or running average
    *       (i.e., ~ root-mean-square approach)
    */


   /* We don't need to test the 'no filter' case if this is the only filter
    * that has been chosen, as it doesn't actually do anything to the data.
    */
   best_row = png_ptr->row_buf;


   if ((filter_to_do & PNG_FILTER_NONE) != 0 && filter_to_do != PNG_FILTER_NONE)
   {
      png_bytep rp;
      png_size_t sum = 0;
      png_size_t i;
      int v;

      if (PNG_SIZE_MAX/128 <= row_bytes)
      {
         for (i = 0, rp = row_buf + 1; i < row_bytes; i++, rp++)
         {
            /* Check for overflow */
            if (sum > PNG_SIZE_MAX/128 - 256)
               break;

            v = *rp;
            sum += (v < 128) ? v : 256 - v;
         }
      }
      else /* Overflow is not possible */
      {
         for (i = 0, rp = row_buf + 1; i < row_bytes; i++, rp++)
         {
            v = *rp;
            sum += (v < 128) ? v : 256 - v;
         }
      }

      mins = sum;
   }

   /* Sub filter */
   if (filter_to_do == PNG_FILTER_SUB)
   /* It's the only filter so no testing is needed */
   {
      (void) png_setup_sub_row(png_ptr, bpp, row_bytes, mins);
      best_row = png_ptr->try_row;
   }

   else if ((filter_to_do & PNG_FILTER_SUB) != 0)
   {
      png_size_t sum;
      png_size_t lmins = mins;

      sum = png_setup_sub_row(png_ptr, bpp, row_bytes, lmins);

      if (sum < mins)
      {
         mins = sum;
         best_row = png_ptr->try_row;
         if (png_ptr->tst_row != NULL)
         {
            png_ptr->try_row = png_ptr->tst_row;
            png_ptr->tst_row = best_row;
         }
      }
   }

   /* Up filter */
   if (filter_to_do == PNG_FILTER_UP)
   {
      (void) png_setup_up_row(png_ptr, row_bytes, mins);
      best_row = png_ptr->try_row;
   }

   else if ((filter_to_do & PNG_FILTER_UP) != 0)
   {
      png_size_t sum;
      png_size_t lmins = mins;

      sum = png_setup_up_row(png_ptr, row_bytes, lmins);

      if (sum < mins)
      {
         mins = sum;
         best_row = png_ptr->try_row;
         if (png_ptr->tst_row != NULL)
         {
            png_ptr->try_row = png_ptr->tst_row;
            png_ptr->tst_row = best_row;
         }
      }
   }

   /* Avg filter */
   if (filter_to_do == PNG_FILTER_AVG)
   {
      (void) png_setup_avg_row(png_ptr, bpp, row_bytes, mins);
      best_row = png_ptr->try_row;
   }

   else if ((filter_to_do & PNG_FILTER_AVG) != 0)
   {
      png_size_t sum;
      png_size_t lmins = mins;

      sum= png_setup_avg_row(png_ptr, bpp, row_bytes, lmins);

      if (sum < mins)
      {
         mins = sum;
         best_row = png_ptr->try_row;
         if (png_ptr->tst_row != NULL)
         {
            png_ptr->try_row = png_ptr->tst_row;
            png_ptr->tst_row = best_row;
         }
      }
   }

   /* Paeth filter */
   if ((filter_to_do == PNG_FILTER_PAETH) != 0)
   {
      (void) png_setup_paeth_row(png_ptr, bpp, row_bytes, mins);
      best_row = png_ptr->try_row;
   }

   else if ((filter_to_do & PNG_FILTER_PAETH) != 0)
   {
      png_size_t sum;
      png_size_t lmins = mins;

      sum = png_setup_paeth_row(png_ptr, bpp, row_bytes, lmins);

      if (sum < mins)
      {
         best_row = png_ptr->try_row;
         if (png_ptr->tst_row != NULL)
         {
            png_ptr->try_row = png_ptr->tst_row;
            png_ptr->tst_row = best_row;
         }
      }
   }

   /* Do the actual writing of the filtered row data from the chosen filter. */
   png_write_filtered_row(png_ptr, best_row, row_info->rowbytes+1);

#endif /* WRITE_FILTER */
}


/* Do the actual writing of a previously filtered row. */
static void
png_write_filtered_row(png_structrp png_ptr, png_bytep filtered_row,
   png_size_t full_row_length/*includes filter byte*/)
{
   png_debug(1, "in png_write_filtered_row");

   png_debug1(2, "filter = %d", filtered_row[0]);

   png_compress_IDAT(png_ptr, filtered_row, full_row_length, Z_NO_FLUSH);

#ifdef PNG_WRITE_FILTER_SUPPORTED
   /* Swap the current and previous rows */
   if (png_ptr->prev_row != NULL)
   {
      png_bytep tptr;

      tptr = png_ptr->prev_row;
      png_ptr->prev_row = png_ptr->row_buf;
      png_ptr->row_buf = tptr;
   }
#endif /* WRITE_FILTER */

   /* Finish row - updates counters and flushes zlib if last row */
   png_write_finish_row(png_ptr);

#ifdef PNG_WRITE_FLUSH_SUPPORTED
   png_ptr->flush_rows++;

   if (png_ptr->flush_dist > 0 &&
       png_ptr->flush_rows >= png_ptr->flush_dist)
   {
      png_write_flush(png_ptr);
   }
#endif /* WRITE_FLUSH */
}
#endif /* WRITE */
