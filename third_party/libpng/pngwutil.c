
/* pngwutil.c - utilities to write a PNG file
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
#define PNG_NO_PEDANTIC_WARNINGS
#include "png.h"
#ifdef PNG_WRITE_SUPPORTED

/* Place a 32-bit number into a buffer in PNG byte order.  We work
 * with unsigned numbers for convenience, although one supported
 * ancillary chunk uses signed (two's complement) numbers.
 */
void PNGAPI
png_save_uint_32(png_bytep buf, png_uint_32 i)
{
   buf[0] = (png_byte)((i >> 24) & 0xff);
   buf[1] = (png_byte)((i >> 16) & 0xff);
   buf[2] = (png_byte)((i >> 8) & 0xff);
   buf[3] = (png_byte)(i & 0xff);
}

/* The png_save_int_32 function assumes integers are stored in two's
 * complement format.  If this isn't the case, then this routine needs to
 * be modified to write data in two's complement format.
 */
void PNGAPI
png_save_int_32(png_bytep buf, png_int_32 i)
{
   buf[0] = (png_byte)((i >> 24) & 0xff);
   buf[1] = (png_byte)((i >> 16) & 0xff);
   buf[2] = (png_byte)((i >> 8) & 0xff);
   buf[3] = (png_byte)(i & 0xff);
}

/* Place a 16-bit number into a buffer in PNG byte order.
 * The parameter is declared unsigned int, not png_uint_16,
 * just to avoid potential problems on pre-ANSI C compilers.
 */
void PNGAPI
png_save_uint_16(png_bytep buf, unsigned int i)
{
   buf[0] = (png_byte)((i >> 8) & 0xff);
   buf[1] = (png_byte)(i & 0xff);
}

/* Simple function to write the signature.  If we have already written
 * the magic bytes of the signature, or more likely, the PNG stream is
 * being embedded into another stream and doesn't need its own signature,
 * we should call png_set_sig_bytes() to tell libpng how many of the
 * bytes have already been written.
 */
void /* PRIVATE */
png_write_sig(png_structp png_ptr)
{
   png_byte png_signature[8] = {137, 80, 78, 71, 13, 10, 26, 10};

   /* Write the rest of the 8 byte signature */
   png_write_data(png_ptr, &png_signature[png_ptr->sig_bytes],
      (png_size_t)(8 - png_ptr->sig_bytes));
   if (png_ptr->sig_bytes < 3)
      png_ptr->mode |= PNG_HAVE_PNG_SIGNATURE;
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
void PNGAPI
png_write_chunk(png_structp png_ptr, png_bytep chunk_name,
   png_bytep data, png_size_t length)
{
   if (png_ptr == NULL)
      return;
   png_write_chunk_start(png_ptr, chunk_name, (png_uint_32)length);
   png_write_chunk_data(png_ptr, data, (png_size_t)length);
   png_write_chunk_end(png_ptr);
}

/* Write the start of a PNG chunk.  The type is the chunk type.
 * The total_length is the sum of the lengths of all the data you will be
 * passing in png_write_chunk_data().
 */
void PNGAPI
png_write_chunk_start(png_structp png_ptr, png_bytep chunk_name,
   png_uint_32 length)
{
   png_byte buf[8];

   png_debug2(0, "Writing %s chunk, length = %lu", chunk_name,
      (unsigned long)length);

   if (png_ptr == NULL)
      return;


   /* Write the length and the chunk name */
   png_save_uint_32(buf, length);
   png_memcpy(buf + 4, chunk_name, 4);
   png_write_data(png_ptr, buf, (png_size_t)8);
   /* Put the chunk name into png_ptr->chunk_name */
   png_memcpy(png_ptr->chunk_name, chunk_name, 4);
   /* Reset the crc and run it over the chunk name */
   png_reset_crc(png_ptr);
   png_calculate_crc(png_ptr, chunk_name, (png_size_t)4);
}

/* Write the data of a PNG chunk started with png_write_chunk_start().
 * Note that multiple calls to this function are allowed, and that the
 * sum of the lengths from these calls *must* add up to the total_length
 * given to png_write_chunk_start().
 */
void PNGAPI
png_write_chunk_data(png_structp png_ptr, png_bytep data, png_size_t length)
{
   /* Write the data, and run the CRC over it */
   if (png_ptr == NULL)
      return;
   if (data != NULL && length > 0)
   {
      png_write_data(png_ptr, data, length);
      /* Update the CRC after writing the data,
       * in case that the user I/O routine alters it.
       */
      png_calculate_crc(png_ptr, data, length);
   }
}

/* Finish a chunk started with png_write_chunk_start(). */
void PNGAPI
png_write_chunk_end(png_structp png_ptr)
{
   png_byte buf[4];

   if (png_ptr == NULL) return;

   /* Write the crc in a single operation */
   png_save_uint_32(buf, png_ptr->crc);

   png_write_data(png_ptr, buf, (png_size_t)4);
}

#if defined(PNG_WRITE_TEXT_SUPPORTED) || defined(PNG_WRITE_iCCP_SUPPORTED)
/* This pair of functions encapsulates the operation of (a) compressing a
 * text string, and (b) issuing it later as a series of chunk data writes.
 * The compression_state structure is shared context for these functions
 * set up by the caller in order to make the whole mess thread-safe.
 */

typedef struct
{
   char *input;   /* The uncompressed input data */
   int input_len;   /* Its length */
   int num_output_ptr; /* Number of output pointers used */
   int max_output_ptr; /* Size of output_ptr */
   png_charpp output_ptr; /* Array of pointers to output */
} compression_state;

/* Compress given text into storage in the png_ptr structure */
static int /* PRIVATE */
png_text_compress(png_structp png_ptr,
        png_charp text, png_size_t text_len, int compression,
        compression_state *comp)
{
   int ret;

   comp->num_output_ptr = 0;
   comp->max_output_ptr = 0;
   comp->output_ptr = NULL;
   comp->input = NULL;
   comp->input_len = 0;

   /* We may just want to pass the text right through */
   if (compression == PNG_TEXT_COMPRESSION_NONE)
   {
       comp->input = text;
       comp->input_len = text_len;
       return((int)text_len);
   }

   if (compression >= PNG_TEXT_COMPRESSION_LAST)
   {
#if defined(PNG_STDIO_SUPPORTED) && !defined(_WIN32_WCE)
      char msg[50];
      png_snprintf(msg, 50, "Unknown compression type %d", compression);
      png_warning(png_ptr, msg);
#else
      png_warning(png_ptr, "Unknown compression type");
#endif
   }

   /* We can't write the chunk until we find out how much data we have,
    * which means we need to run the compressor first and save the
    * output.  This shouldn't be a problem, as the vast majority of
    * comments should be reasonable, but we will set up an array of
    * malloc'd pointers to be sure.
    *
    * If we knew the application was well behaved, we could simplify this
    * greatly by assuming we can always malloc an output buffer large
    * enough to hold the compressed text ((1001 * text_len / 1000) + 12)
    * and malloc this directly.  The only time this would be a bad idea is
    * if we can't malloc more than 64K and we have 64K of random input
    * data, or if the input string is incredibly large (although this
    * wouldn't cause a failure, just a slowdown due to swapping).
    */

   /* Set up the compression buffers */
   png_ptr->zstream.avail_in = (uInt)text_len;
   png_ptr->zstream.next_in = (Bytef *)text;
   png_ptr->zstream.avail_out = (uInt)png_ptr->zbuf_size;
   png_ptr->zstream.next_out = (Bytef *)png_ptr->zbuf;

   /* This is the same compression loop as in png_write_row() */
   do
   {
      /* Compress the data */
      ret = deflate(&png_ptr->zstream, Z_NO_FLUSH);
      if (ret != Z_OK)
      {
         /* Error */
         if (png_ptr->zstream.msg != NULL)
            png_error(png_ptr, png_ptr->zstream.msg);
         else
            png_error(png_ptr, "zlib error");
      }
      /* Check to see if we need more room */
      if (!(png_ptr->zstream.avail_out))
      {
         /* Make sure the output array has room */
         if (comp->num_output_ptr >= comp->max_output_ptr)
         {
            int old_max;

            old_max = comp->max_output_ptr;
            comp->max_output_ptr = comp->num_output_ptr + 4;
            if (comp->output_ptr != NULL)
            {
               png_charpp old_ptr;

               old_ptr = comp->output_ptr;
               comp->output_ptr = (png_charpp)png_malloc(png_ptr,
                  (png_uint_32)
                  (comp->max_output_ptr * png_sizeof(png_charpp)));
               png_memcpy(comp->output_ptr, old_ptr, old_max
                  * png_sizeof(png_charp));
               png_free(png_ptr, old_ptr);
            }
            else
               comp->output_ptr = (png_charpp)png_malloc(png_ptr,
                  (png_uint_32)
                  (comp->max_output_ptr * png_sizeof(png_charp)));
         }

         /* Save the data */
         comp->output_ptr[comp->num_output_ptr] =
            (png_charp)png_malloc(png_ptr,
            (png_uint_32)png_ptr->zbuf_size);
         png_memcpy(comp->output_ptr[comp->num_output_ptr], png_ptr->zbuf,
            png_ptr->zbuf_size);
         comp->num_output_ptr++;

         /* and reset the buffer */
         png_ptr->zstream.avail_out = (uInt)png_ptr->zbuf_size;
         png_ptr->zstream.next_out = png_ptr->zbuf;
      }
   /* Continue until we don't have any more to compress */
   } while (png_ptr->zstream.avail_in);

   /* Finish the compression */
   do
   {
      /* Tell zlib we are finished */
      ret = deflate(&png_ptr->zstream, Z_FINISH);

      if (ret == Z_OK)
      {
         /* Check to see if we need more room */
         if (!(png_ptr->zstream.avail_out))
         {
            /* Check to make sure our output array has room */
            if (comp->num_output_ptr >= comp->max_output_ptr)
            {
               int old_max;

               old_max = comp->max_output_ptr;
               comp->max_output_ptr = comp->num_output_ptr + 4;
               if (comp->output_ptr != NULL)
               {
                  png_charpp old_ptr;

                  old_ptr = comp->output_ptr;
                  /* This could be optimized to realloc() */
                  comp->output_ptr = (png_charpp)png_malloc(png_ptr,
                     (png_uint_32)(comp->max_output_ptr *
                     png_sizeof(png_charp)));
                  png_memcpy(comp->output_ptr, old_ptr,
                     old_max * png_sizeof(png_charp));
                  png_free(png_ptr, old_ptr);
               }
               else
                  comp->output_ptr = (png_charpp)png_malloc(png_ptr,
                     (png_uint_32)(comp->max_output_ptr *
                     png_sizeof(png_charp)));
            }

            /* Save the data */
            comp->output_ptr[comp->num_output_ptr] =
               (png_charp)png_malloc(png_ptr,
               (png_uint_32)png_ptr->zbuf_size);
            png_memcpy(comp->output_ptr[comp->num_output_ptr], png_ptr->zbuf,
               png_ptr->zbuf_size);
            comp->num_output_ptr++;

            /* and reset the buffer pointers */
            png_ptr->zstream.avail_out = (uInt)png_ptr->zbuf_size;
            png_ptr->zstream.next_out = png_ptr->zbuf;
         }
      }
      else if (ret != Z_STREAM_END)
      {
         /* We got an error */
         if (png_ptr->zstream.msg != NULL)
            png_error(png_ptr, png_ptr->zstream.msg);
         else
            png_error(png_ptr, "zlib error");
      }
   } while (ret != Z_STREAM_END);

   /* Text length is number of buffers plus last buffer */
   text_len = png_ptr->zbuf_size * comp->num_output_ptr;
   if (png_ptr->zstream.avail_out < png_ptr->zbuf_size)
      text_len += png_ptr->zbuf_size - (png_size_t)png_ptr->zstream.avail_out;

   return((int)text_len);
}

/* Ship the compressed text out via chunk writes */
static void /* PRIVATE */
png_write_compressed_data_out(png_structp png_ptr, compression_state *comp)
{
   int i;

   /* Handle the no-compression case */
   if (comp->input)
   {
      png_write_chunk_data(png_ptr, (png_bytep)comp->input,
                            (png_size_t)comp->input_len);
      return;
   }

   /* Write saved output buffers, if any */
   for (i = 0; i < comp->num_output_ptr; i++)
   {
      png_write_chunk_data(png_ptr, (png_bytep)comp->output_ptr[i],
         (png_size_t)png_ptr->zbuf_size);
      png_free(png_ptr, comp->output_ptr[i]);
       comp->output_ptr[i]=NULL;
   }
   if (comp->max_output_ptr != 0)
      png_free(png_ptr, comp->output_ptr);
       comp->output_ptr=NULL;
   /* Write anything left in zbuf */
   if (png_ptr->zstream.avail_out < (png_uint_32)png_ptr->zbuf_size)
      png_write_chunk_data(png_ptr, png_ptr->zbuf,
         (png_size_t)(png_ptr->zbuf_size - png_ptr->zstream.avail_out));

   /* Reset zlib for another zTXt/iTXt or image data */
   deflateReset(&png_ptr->zstream);
   png_ptr->zstream.data_type = Z_BINARY;
}
#endif

/* Write the IHDR chunk, and update the png_struct with the necessary
 * information.  Note that the rest of this code depends upon this
 * information being correct.
 */
void /* PRIVATE */
png_write_IHDR(png_structp png_ptr, png_uint_32 width, png_uint_32 height,
   int bit_depth, int color_type, int compression_type, int filter_type,
   int interlace_type)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_IHDR;
#endif
   int ret;

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
            case 16: png_ptr->channels = 1; break;
            default: png_error(png_ptr,
                         "Invalid bit depth for grayscale image");
         }
         break;
      case PNG_COLOR_TYPE_RGB:
         if (bit_depth != 8 && bit_depth != 16)
            png_error(png_ptr, "Invalid bit depth for RGB image");
         png_ptr->channels = 3;
         break;
      case PNG_COLOR_TYPE_PALETTE:
         switch (bit_depth)
         {
            case 1:
            case 2:
            case 4:
            case 8: png_ptr->channels = 1; break;
            default: png_error(png_ptr, "Invalid bit depth for paletted image");
         }
         break;
      case PNG_COLOR_TYPE_GRAY_ALPHA:
         if (bit_depth != 8 && bit_depth != 16)
            png_error(png_ptr, "Invalid bit depth for grayscale+alpha image");
         png_ptr->channels = 2;
         break;
      case PNG_COLOR_TYPE_RGB_ALPHA:
         if (bit_depth != 8 && bit_depth != 16)
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
      !((png_ptr->mng_features_permitted & PNG_FLAG_MNG_FILTER_64) &&
      ((png_ptr->mode&PNG_HAVE_PNG_SIGNATURE) == 0) &&
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

   /* Save the relevent information */
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
   png_write_chunk(png_ptr, (png_bytep)png_IHDR, buf, (png_size_t)13);

   /* Initialize zlib with PNG info */
   png_ptr->zstream.zalloc = png_zalloc;
   png_ptr->zstream.zfree = png_zfree;
   png_ptr->zstream.opaque = (voidpf)png_ptr;
   if (!(png_ptr->do_filter))
   {
      if (png_ptr->color_type == PNG_COLOR_TYPE_PALETTE ||
         png_ptr->bit_depth < 8)
         png_ptr->do_filter = PNG_FILTER_NONE;
      else
         png_ptr->do_filter = PNG_ALL_FILTERS;
   }
   if (!(png_ptr->flags & PNG_FLAG_ZLIB_CUSTOM_STRATEGY))
   {
      if (png_ptr->do_filter != PNG_FILTER_NONE)
         png_ptr->zlib_strategy = Z_FILTERED;
      else
         png_ptr->zlib_strategy = Z_DEFAULT_STRATEGY;
   }
   if (!(png_ptr->flags & PNG_FLAG_ZLIB_CUSTOM_LEVEL))
      png_ptr->zlib_level = Z_DEFAULT_COMPRESSION;
   if (!(png_ptr->flags & PNG_FLAG_ZLIB_CUSTOM_MEM_LEVEL))
      png_ptr->zlib_mem_level = 8;
   if (!(png_ptr->flags & PNG_FLAG_ZLIB_CUSTOM_WINDOW_BITS))
      png_ptr->zlib_window_bits = 15;
   if (!(png_ptr->flags & PNG_FLAG_ZLIB_CUSTOM_METHOD))
      png_ptr->zlib_method = 8;
   ret = deflateInit2(&png_ptr->zstream, png_ptr->zlib_level,
         png_ptr->zlib_method, png_ptr->zlib_window_bits,
         png_ptr->zlib_mem_level, png_ptr->zlib_strategy);
   if (ret != Z_OK)
   {
      if (ret == Z_VERSION_ERROR) png_error(png_ptr,
          "zlib failed to initialize compressor -- version error");
      if (ret == Z_STREAM_ERROR) png_error(png_ptr,
           "zlib failed to initialize compressor -- stream error");
      if (ret == Z_MEM_ERROR) png_error(png_ptr,
           "zlib failed to initialize compressor -- mem error");
      png_error(png_ptr, "zlib failed to initialize compressor");
   }
   png_ptr->zstream.next_out = png_ptr->zbuf;
   png_ptr->zstream.avail_out = (uInt)png_ptr->zbuf_size;
   /* libpng is not interested in zstream.data_type */
   /* Set it to a predefined value, to avoid its evaluation inside zlib */
   png_ptr->zstream.data_type = Z_BINARY;

   png_ptr->mode = PNG_HAVE_IHDR;
}

/* Write the palette.  We are careful not to trust png_color to be in the
 * correct order for PNG, so people can redefine it to any convenient
 * structure.
 */
void /* PRIVATE */
png_write_PLTE(png_structp png_ptr, png_colorp palette, png_uint_32 num_pal)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_PLTE;
#endif
   png_uint_32 i;
   png_colorp pal_ptr;
   png_byte buf[3];

   png_debug(1, "in png_write_PLTE");

   if ((
#ifdef PNG_MNG_FEATURES_SUPPORTED
        !(png_ptr->mng_features_permitted & PNG_FLAG_MNG_EMPTY_PLTE) &&
#endif
        num_pal == 0) || num_pal > 256)
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

   if (!(png_ptr->color_type&PNG_COLOR_MASK_COLOR))
   {
      png_warning(png_ptr,
        "Ignoring request to write a PLTE chunk in grayscale PNG");
      return;
   }

   png_ptr->num_palette = (png_uint_16)num_pal;
   png_debug1(3, "num_palette = %d", png_ptr->num_palette);

   png_write_chunk_start(png_ptr, (png_bytep)png_PLTE,
     (png_uint_32)(num_pal * 3));
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

/* Write an IDAT chunk */
void /* PRIVATE */
png_write_IDAT(png_structp png_ptr, png_bytep data, png_size_t length)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_IDAT;
#endif

   png_debug(1, "in png_write_IDAT");

   /* Optimize the CMF field in the zlib stream. */
   /* This hack of the zlib stream is compliant to the stream specification. */
   if (!(png_ptr->mode & PNG_HAVE_IDAT) &&
       png_ptr->compression_type == PNG_COMPRESSION_TYPE_BASE)
   {
      unsigned int z_cmf = data[0];  /* zlib compression method and flags */
      if ((z_cmf & 0x0f) == 8 && (z_cmf & 0xf0) <= 0x70)
      {
         /* Avoid memory underflows and multiplication overflows.
          *
          * The conditions below are practically always satisfied;
          * however, they still must be checked.
          */
         if (length >= 2 &&
             png_ptr->height < 16384 && png_ptr->width < 16384)
         {
            png_uint_32 uncompressed_idat_size = png_ptr->height *
               ((png_ptr->width *
               png_ptr->channels * png_ptr->bit_depth + 15) >> 3);
            unsigned int z_cinfo = z_cmf >> 4;
            unsigned int half_z_window_size = 1 << (z_cinfo + 7);
            while (uncompressed_idat_size <= half_z_window_size &&
                   half_z_window_size >= 256)
            {
               z_cinfo--;
               half_z_window_size >>= 1;
            }
            z_cmf = (z_cmf & 0x0f) | (z_cinfo << 4);
            if (data[0] != (png_byte)z_cmf)
            {
               data[0] = (png_byte)z_cmf;
               data[1] &= 0xe0;
               data[1] += (png_byte)(0x1f - ((z_cmf << 8) + data[1]) % 0x1f);
            }
         }
      }
      else
         png_error(png_ptr,
            "Invalid zlib compression method or flags in IDAT");
   }

   png_write_chunk(png_ptr, (png_bytep)png_IDAT, data, length);
   png_ptr->mode |= PNG_HAVE_IDAT;
}

/* Write an IEND chunk */
void /* PRIVATE */
png_write_IEND(png_structp png_ptr)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_IEND;
#endif

   png_debug(1, "in png_write_IEND");

   png_write_chunk(png_ptr, (png_bytep)png_IEND, png_bytep_NULL,
     (png_size_t)0);
   png_ptr->mode |= PNG_HAVE_IEND;
}

#ifdef PNG_WRITE_gAMA_SUPPORTED
/* Write a gAMA chunk */
#ifdef PNG_FLOATING_POINT_SUPPORTED
void /* PRIVATE */
png_write_gAMA(png_structp png_ptr, double file_gamma)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_gAMA;
#endif
   png_uint_32 igamma;
   png_byte buf[4];

   png_debug(1, "in png_write_gAMA");

   /* file_gamma is saved in 1/100,000ths */
   igamma = (png_uint_32)(file_gamma * 100000.0 + 0.5);
   png_save_uint_32(buf, igamma);
   png_write_chunk(png_ptr, (png_bytep)png_gAMA, buf, (png_size_t)4);
}
#endif
#ifdef PNG_FIXED_POINT_SUPPORTED
void /* PRIVATE */
png_write_gAMA_fixed(png_structp png_ptr, png_fixed_point file_gamma)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_gAMA;
#endif
   png_byte buf[4];

   png_debug(1, "in png_write_gAMA");

   /* file_gamma is saved in 1/100,000ths */
   png_save_uint_32(buf, (png_uint_32)file_gamma);
   png_write_chunk(png_ptr, (png_bytep)png_gAMA, buf, (png_size_t)4);
}
#endif
#endif

#ifdef PNG_WRITE_sRGB_SUPPORTED
/* Write a sRGB chunk */
void /* PRIVATE */
png_write_sRGB(png_structp png_ptr, int srgb_intent)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_sRGB;
#endif
   png_byte buf[1];

   png_debug(1, "in png_write_sRGB");

   if (srgb_intent >= PNG_sRGB_INTENT_LAST)
         png_warning(png_ptr,
            "Invalid sRGB rendering intent specified");
   buf[0]=(png_byte)srgb_intent;
   png_write_chunk(png_ptr, (png_bytep)png_sRGB, buf, (png_size_t)1);
}
#endif

#ifdef PNG_WRITE_iCCP_SUPPORTED
/* Write an iCCP chunk */
void /* PRIVATE */
png_write_iCCP(png_structp png_ptr, png_charp name, int compression_type,
   png_charp profile, int profile_len)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_iCCP;
#endif
   png_size_t name_len;
   png_charp new_name;
   compression_state comp;
   int embedded_profile_len = 0;

   png_debug(1, "in png_write_iCCP");

   comp.num_output_ptr = 0;
   comp.max_output_ptr = 0;
   comp.output_ptr = NULL;
   comp.input = NULL;
   comp.input_len = 0;

   if ((name_len = png_check_keyword(png_ptr, name,
      &new_name)) == 0)
      return;

   if (compression_type != PNG_COMPRESSION_TYPE_BASE)
      png_warning(png_ptr, "Unknown compression type in iCCP chunk");

   if (profile == NULL)
      profile_len = 0;

   if (profile_len > 3)
      embedded_profile_len =
          ((*( (png_bytep)profile    ))<<24) |
          ((*( (png_bytep)profile + 1))<<16) |
          ((*( (png_bytep)profile + 2))<< 8) |
          ((*( (png_bytep)profile + 3))    );

   if (embedded_profile_len < 0)
   {
      png_warning(png_ptr,
        "Embedded profile length in iCCP chunk is negative");
      png_free(png_ptr, new_name);
      return;
   }

   if (profile_len < embedded_profile_len)
   {
      png_warning(png_ptr,
        "Embedded profile length too large in iCCP chunk");
      png_free(png_ptr, new_name);
      return;
   }

   if (profile_len > embedded_profile_len)
   {
      png_warning(png_ptr,
        "Truncating profile to actual length in iCCP chunk");
      profile_len = embedded_profile_len;
   }

   if (profile_len)
      profile_len = png_text_compress(png_ptr, profile,
        (png_size_t)profile_len, PNG_COMPRESSION_TYPE_BASE, &comp);

   /* Make sure we include the NULL after the name and the compression type */
   png_write_chunk_start(png_ptr, (png_bytep)png_iCCP,
          (png_uint_32)(name_len + profile_len + 2));
   new_name[name_len + 1] = 0x00;
   png_write_chunk_data(png_ptr, (png_bytep)new_name,
     (png_size_t)(name_len + 2));

   if (profile_len)
      png_write_compressed_data_out(png_ptr, &comp);

   png_write_chunk_end(png_ptr);
   png_free(png_ptr, new_name);
}
#endif

#ifdef PNG_WRITE_sPLT_SUPPORTED
/* Write a sPLT chunk */
void /* PRIVATE */
png_write_sPLT(png_structp png_ptr, png_sPLT_tp spalette)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_sPLT;
#endif
   png_size_t name_len;
   png_charp new_name;
   png_byte entrybuf[10];
   int entry_size = (spalette->depth == 8 ? 6 : 10);
   int palette_size = entry_size * spalette->nentries;
   png_sPLT_entryp ep;
#ifndef PNG_POINTER_INDEXING_SUPPORTED
   int i;
#endif

   png_debug(1, "in png_write_sPLT");

   if ((name_len = png_check_keyword(png_ptr,spalette->name, &new_name))==0)
      return;

   /* Make sure we include the NULL after the name */
   png_write_chunk_start(png_ptr, (png_bytep)png_sPLT,
     (png_uint_32)(name_len + 2 + palette_size));
   png_write_chunk_data(png_ptr, (png_bytep)new_name,
     (png_size_t)(name_len + 1));
   png_write_chunk_data(png_ptr, (png_bytep)&spalette->depth, (png_size_t)1);

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
      png_write_chunk_data(png_ptr, entrybuf, (png_size_t)entry_size);
   }
#else
   ep=spalette->entries;
   for (i=0; i>spalette->nentries; i++)
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
      png_write_chunk_data(png_ptr, entrybuf, (png_size_t)entry_size);
   }
#endif

   png_write_chunk_end(png_ptr);
   png_free(png_ptr, new_name);
}
#endif

#ifdef PNG_WRITE_sBIT_SUPPORTED
/* Write the sBIT chunk */
void /* PRIVATE */
png_write_sBIT(png_structp png_ptr, png_color_8p sbit, int color_type)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_sBIT;
#endif
   png_byte buf[4];
   png_size_t size;

   png_debug(1, "in png_write_sBIT");

   /* Make sure we don't depend upon the order of PNG_COLOR_8 */
   if (color_type & PNG_COLOR_MASK_COLOR)
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

   if (color_type & PNG_COLOR_MASK_ALPHA)
   {
      if (sbit->alpha == 0 || sbit->alpha > png_ptr->usr_bit_depth)
      {
         png_warning(png_ptr, "Invalid sBIT depth specified");
         return;
      }
      buf[size++] = sbit->alpha;
   }

   png_write_chunk(png_ptr, (png_bytep)png_sBIT, buf, size);
}
#endif

#ifdef PNG_WRITE_cHRM_SUPPORTED
/* Write the cHRM chunk */
#ifdef PNG_FLOATING_POINT_SUPPORTED
void /* PRIVATE */
png_write_cHRM(png_structp png_ptr, double white_x, double white_y,
   double red_x, double red_y, double green_x, double green_y,
   double blue_x, double blue_y)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_cHRM;
#endif
   png_byte buf[32];

   png_fixed_point int_white_x, int_white_y, int_red_x, int_red_y,
      int_green_x, int_green_y, int_blue_x, int_blue_y;

   png_debug(1, "in png_write_cHRM");

   int_white_x = (png_uint_32)(white_x * 100000.0 + 0.5);
   int_white_y = (png_uint_32)(white_y * 100000.0 + 0.5);
   int_red_x   = (png_uint_32)(red_x   * 100000.0 + 0.5);
   int_red_y   = (png_uint_32)(red_y   * 100000.0 + 0.5);
   int_green_x = (png_uint_32)(green_x * 100000.0 + 0.5);
   int_green_y = (png_uint_32)(green_y * 100000.0 + 0.5);
   int_blue_x  = (png_uint_32)(blue_x  * 100000.0 + 0.5);
   int_blue_y  = (png_uint_32)(blue_y  * 100000.0 + 0.5);

#ifdef PNG_CHECK_cHRM_SUPPORTED
   if (png_check_cHRM_fixed(png_ptr, int_white_x, int_white_y,
      int_red_x, int_red_y, int_green_x, int_green_y, int_blue_x, int_blue_y))
#endif
   {
      /* Each value is saved in 1/100,000ths */

      png_save_uint_32(buf, int_white_x);
      png_save_uint_32(buf + 4, int_white_y);

      png_save_uint_32(buf + 8, int_red_x);
      png_save_uint_32(buf + 12, int_red_y);

      png_save_uint_32(buf + 16, int_green_x);
      png_save_uint_32(buf + 20, int_green_y);

      png_save_uint_32(buf + 24, int_blue_x);
      png_save_uint_32(buf + 28, int_blue_y);

      png_write_chunk(png_ptr, (png_bytep)png_cHRM, buf, (png_size_t)32);
   }
}
#endif
#ifdef PNG_FIXED_POINT_SUPPORTED
void /* PRIVATE */
png_write_cHRM_fixed(png_structp png_ptr, png_fixed_point white_x,
   png_fixed_point white_y, png_fixed_point red_x, png_fixed_point red_y,
   png_fixed_point green_x, png_fixed_point green_y, png_fixed_point blue_x,
   png_fixed_point blue_y)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_cHRM;
#endif
   png_byte buf[32];

   png_debug(1, "in png_write_cHRM");

   /* Each value is saved in 1/100,000ths */
#ifdef PNG_CHECK_cHRM_SUPPORTED
   if (png_check_cHRM_fixed(png_ptr, white_x, white_y, red_x, red_y,
      green_x, green_y, blue_x, blue_y))
#endif
   {
      png_save_uint_32(buf, (png_uint_32)white_x);
      png_save_uint_32(buf + 4, (png_uint_32)white_y);

      png_save_uint_32(buf + 8, (png_uint_32)red_x);
      png_save_uint_32(buf + 12, (png_uint_32)red_y);

      png_save_uint_32(buf + 16, (png_uint_32)green_x);
      png_save_uint_32(buf + 20, (png_uint_32)green_y);

      png_save_uint_32(buf + 24, (png_uint_32)blue_x);
      png_save_uint_32(buf + 28, (png_uint_32)blue_y);

      png_write_chunk(png_ptr, (png_bytep)png_cHRM, buf, (png_size_t)32);
   }
}
#endif
#endif

#ifdef PNG_WRITE_tRNS_SUPPORTED
/* Write the tRNS chunk */
void /* PRIVATE */
png_write_tRNS(png_structp png_ptr, png_bytep trans, png_color_16p tran,
   int num_trans, int color_type)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_tRNS;
#endif
   png_byte buf[6];

   png_debug(1, "in png_write_tRNS");

   if (color_type == PNG_COLOR_TYPE_PALETTE)
   {
      if (num_trans <= 0 || num_trans > (int)png_ptr->num_palette)
      {
         png_warning(png_ptr, "Invalid number of transparent colors specified");
         return;
      }
      /* Write the chunk out as it is */
      png_write_chunk(png_ptr, (png_bytep)png_tRNS, trans,
        (png_size_t)num_trans);
   }
   else if (color_type == PNG_COLOR_TYPE_GRAY)
   {
      /* One 16 bit value */
      if (tran->gray >= (1 << png_ptr->bit_depth))
      {
         png_warning(png_ptr,
           "Ignoring attempt to write tRNS chunk out-of-range for bit_depth");
         return;
      }
      png_save_uint_16(buf, tran->gray);
      png_write_chunk(png_ptr, (png_bytep)png_tRNS, buf, (png_size_t)2);
   }
   else if (color_type == PNG_COLOR_TYPE_RGB)
   {
      /* Three 16 bit values */
      png_save_uint_16(buf, tran->red);
      png_save_uint_16(buf + 2, tran->green);
      png_save_uint_16(buf + 4, tran->blue);
      if (png_ptr->bit_depth == 8 && (buf[0] | buf[2] | buf[4]))
      {
         png_warning(png_ptr,
           "Ignoring attempt to write 16-bit tRNS chunk when bit_depth is 8");
         return;
      }
      png_write_chunk(png_ptr, (png_bytep)png_tRNS, buf, (png_size_t)6);
   }
   else
   {
      png_warning(png_ptr, "Can't write tRNS with an alpha channel");
   }
}
#endif

#ifdef PNG_WRITE_bKGD_SUPPORTED
/* Write the background chunk */
void /* PRIVATE */
png_write_bKGD(png_structp png_ptr, png_color_16p back, int color_type)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_bKGD;
#endif
   png_byte buf[6];

   png_debug(1, "in png_write_bKGD");

   if (color_type == PNG_COLOR_TYPE_PALETTE)
   {
      if (
#ifdef PNG_MNG_FEATURES_SUPPORTED
          (png_ptr->num_palette ||
          (!(png_ptr->mng_features_permitted & PNG_FLAG_MNG_EMPTY_PLTE))) &&
#endif
         back->index >= png_ptr->num_palette)
      {
         png_warning(png_ptr, "Invalid background palette index");
         return;
      }
      buf[0] = back->index;
      png_write_chunk(png_ptr, (png_bytep)png_bKGD, buf, (png_size_t)1);
   }
   else if (color_type & PNG_COLOR_MASK_COLOR)
   {
      png_save_uint_16(buf, back->red);
      png_save_uint_16(buf + 2, back->green);
      png_save_uint_16(buf + 4, back->blue);
      if (png_ptr->bit_depth == 8 && (buf[0] | buf[2] | buf[4]))
      {
         png_warning(png_ptr,
           "Ignoring attempt to write 16-bit bKGD chunk when bit_depth is 8");
         return;
      }
      png_write_chunk(png_ptr, (png_bytep)png_bKGD, buf, (png_size_t)6);
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
      png_write_chunk(png_ptr, (png_bytep)png_bKGD, buf, (png_size_t)2);
   }
}
#endif

#ifdef PNG_WRITE_hIST_SUPPORTED
/* Write the histogram */
void /* PRIVATE */
png_write_hIST(png_structp png_ptr, png_uint_16p hist, int num_hist)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_hIST;
#endif
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

   png_write_chunk_start(png_ptr, (png_bytep)png_hIST,
     (png_uint_32)(num_hist * 2));
   for (i = 0; i < num_hist; i++)
   {
      png_save_uint_16(buf, hist[i]);
      png_write_chunk_data(png_ptr, buf, (png_size_t)2);
   }
   png_write_chunk_end(png_ptr);
}
#endif

#if defined(PNG_WRITE_TEXT_SUPPORTED) || defined(PNG_WRITE_pCAL_SUPPORTED) || \
    defined(PNG_WRITE_iCCP_SUPPORTED) || defined(PNG_WRITE_sPLT_SUPPORTED)
/* Check that the tEXt or zTXt keyword is valid per PNG 1.0 specification,
 * and if invalid, correct the keyword rather than discarding the entire
 * chunk.  The PNG 1.0 specification requires keywords 1-79 characters in
 * length, forbids leading or trailing whitespace, multiple internal spaces,
 * and the non-break space (0x80) from ISO 8859-1.  Returns keyword length.
 *
 * The new_key is allocated to hold the corrected keyword and must be freed
 * by the calling routine.  This avoids problems with trying to write to
 * static keywords without having to have duplicate copies of the strings.
 */
png_size_t /* PRIVATE */
png_check_keyword(png_structp png_ptr, png_charp key, png_charpp new_key)
{
   png_size_t key_len;
   png_charp kp, dp;
   int kflag;
   int kwarn=0;

   png_debug(1, "in png_check_keyword");

   *new_key = NULL;

   if (key == NULL || (key_len = png_strlen(key)) == 0)
   {
      png_warning(png_ptr, "zero length keyword");
      return ((png_size_t)0);
   }

   png_debug1(2, "Keyword to be checked is '%s'", key);

   *new_key = (png_charp)png_malloc_warn(png_ptr, (png_uint_32)(key_len + 2));
   if (*new_key == NULL)
   {
      png_warning(png_ptr, "Out of memory while procesing keyword");
      return ((png_size_t)0);
   }

   /* Replace non-printing characters with a blank and print a warning */
   for (kp = key, dp = *new_key; *kp != '\0'; kp++, dp++)
   {
      if ((png_byte)*kp < 0x20 ||
         ((png_byte)*kp > 0x7E && (png_byte)*kp < 0xA1))
      {
#if defined(PNG_STDIO_SUPPORTED) && !defined(_WIN32_WCE)
         char msg[40];

         png_snprintf(msg, 40,
           "invalid keyword character 0x%02X", (png_byte)*kp);
         png_warning(png_ptr, msg);
#else
         png_warning(png_ptr, "invalid character in keyword");
#endif
         *dp = ' ';
      }
      else
      {
         *dp = *kp;
      }
   }
   *dp = '\0';

   /* Remove any trailing white space. */
   kp = *new_key + key_len - 1;
   if (*kp == ' ')
   {
      png_warning(png_ptr, "trailing spaces removed from keyword");

      while (*kp == ' ')
      {
         *(kp--) = '\0';
         key_len--;
      }
   }

   /* Remove any leading white space. */
   kp = *new_key;
   if (*kp == ' ')
   {
      png_warning(png_ptr, "leading spaces removed from keyword");

      while (*kp == ' ')
      {
         kp++;
         key_len--;
      }
   }

   png_debug1(2, "Checking for multiple internal spaces in '%s'", kp);

   /* Remove multiple internal spaces. */
   for (kflag = 0, dp = *new_key; *kp != '\0'; kp++)
   {
      if (*kp == ' ' && kflag == 0)
      {
         *(dp++) = *kp;
         kflag = 1;
      }
      else if (*kp == ' ')
      {
         key_len--;
         kwarn=1;
      }
      else
      {
         *(dp++) = *kp;
         kflag = 0;
      }
   }
   *dp = '\0';
   if (kwarn)
      png_warning(png_ptr, "extra interior spaces removed from keyword");

   if (key_len == 0)
   {
      png_free(png_ptr, *new_key);
       *new_key=NULL;
      png_warning(png_ptr, "Zero length keyword");
   }

   if (key_len > 79)
   {
      png_warning(png_ptr, "keyword length must be 1 - 79 characters");
      (*new_key)[79] = '\0';
      key_len = 79;
   }

   return (key_len);
}
#endif

#ifdef PNG_WRITE_tEXt_SUPPORTED
/* Write a tEXt chunk */
void /* PRIVATE */
png_write_tEXt(png_structp png_ptr, png_charp key, png_charp text,
   png_size_t text_len)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_tEXt;
#endif
   png_size_t key_len;
   png_charp new_key;

   png_debug(1, "in png_write_tEXt");

   if ((key_len = png_check_keyword(png_ptr, key, &new_key))==0)
      return;

   if (text == NULL || *text == '\0')
      text_len = 0;
   else
      text_len = png_strlen(text);

   /* Make sure we include the 0 after the key */
   png_write_chunk_start(png_ptr, (png_bytep)png_tEXt,
      (png_uint_32)(key_len + text_len + 1));
   /*
    * We leave it to the application to meet PNG-1.0 requirements on the
    * contents of the text.  PNG-1.0 through PNG-1.2 discourage the use of
    * any non-Latin-1 characters except for NEWLINE.  ISO PNG will forbid them.
    * The NUL character is forbidden by PNG-1.0 through PNG-1.2 and ISO PNG.
    */
   png_write_chunk_data(png_ptr, (png_bytep)new_key,
     (png_size_t)(key_len + 1));
   if (text_len)
      png_write_chunk_data(png_ptr, (png_bytep)text, (png_size_t)text_len);

   png_write_chunk_end(png_ptr);
   png_free(png_ptr, new_key);
}
#endif

#ifdef PNG_WRITE_zTXt_SUPPORTED
/* Write a compressed text chunk */
void /* PRIVATE */
png_write_zTXt(png_structp png_ptr, png_charp key, png_charp text,
   png_size_t text_len, int compression)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_zTXt;
#endif
   png_size_t key_len;
   char buf[1];
   png_charp new_key;
   compression_state comp;

   png_debug(1, "in png_write_zTXt");

   comp.num_output_ptr = 0;
   comp.max_output_ptr = 0;
   comp.output_ptr = NULL;
   comp.input = NULL;
   comp.input_len = 0;

   if ((key_len = png_check_keyword(png_ptr, key, &new_key))==0)
   {
      png_free(png_ptr, new_key);
      return;
   }

   if (text == NULL || *text == '\0' || compression==PNG_TEXT_COMPRESSION_NONE)
   {
      png_write_tEXt(png_ptr, new_key, text, (png_size_t)0);
      png_free(png_ptr, new_key);
      return;
   }

   text_len = png_strlen(text);

   /* Compute the compressed data; do it now for the length */
   text_len = png_text_compress(png_ptr, text, text_len, compression,
       &comp);

   /* Write start of chunk */
   png_write_chunk_start(png_ptr, (png_bytep)png_zTXt,
     (png_uint_32)(key_len+text_len + 2));
   /* Write key */
   png_write_chunk_data(png_ptr, (png_bytep)new_key,
     (png_size_t)(key_len + 1));
   png_free(png_ptr, new_key);

   buf[0] = (png_byte)compression;
   /* Write compression */
   png_write_chunk_data(png_ptr, (png_bytep)buf, (png_size_t)1);
   /* Write the compressed data */
   png_write_compressed_data_out(png_ptr, &comp);

   /* Close the chunk */
   png_write_chunk_end(png_ptr);
}
#endif

#ifdef PNG_WRITE_iTXt_SUPPORTED
/* Write an iTXt chunk */
void /* PRIVATE */
png_write_iTXt(png_structp png_ptr, int compression, png_charp key,
    png_charp lang, png_charp lang_key, png_charp text)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_iTXt;
#endif
   png_size_t lang_len, key_len, lang_key_len, text_len;
   png_charp new_lang;
   png_charp new_key = NULL;
   png_byte cbuf[2];
   compression_state comp;

   png_debug(1, "in png_write_iTXt");

   comp.num_output_ptr = 0;
   comp.max_output_ptr = 0;
   comp.output_ptr = NULL;
   comp.input = NULL;

   if ((key_len = png_check_keyword(png_ptr, key, &new_key))==0)
      return;

   if ((lang_len = png_check_keyword(png_ptr, lang, &new_lang))==0)
   {
      png_warning(png_ptr, "Empty language field in iTXt chunk");
      new_lang = NULL;
      lang_len = 0;
   }

   if (lang_key == NULL)
      lang_key_len = 0;
   else
      lang_key_len = png_strlen(lang_key);

   if (text == NULL)
      text_len = 0;
   else
      text_len = png_strlen(text);

   /* Compute the compressed data; do it now for the length */
   text_len = png_text_compress(png_ptr, text, text_len, compression-2,
      &comp);


   /* Make sure we include the compression flag, the compression byte,
    * and the NULs after the key, lang, and lang_key parts */

   png_write_chunk_start(png_ptr, (png_bytep)png_iTXt,
          (png_uint_32)(
        5 /* comp byte, comp flag, terminators for key, lang and lang_key */
        + key_len
        + lang_len
        + lang_key_len
        + text_len));

   /* We leave it to the application to meet PNG-1.0 requirements on the
    * contents of the text.  PNG-1.0 through PNG-1.2 discourage the use of
    * any non-Latin-1 characters except for NEWLINE.  ISO PNG will forbid them.
    * The NUL character is forbidden by PNG-1.0 through PNG-1.2 and ISO PNG.
    */
   png_write_chunk_data(png_ptr, (png_bytep)new_key,
     (png_size_t)(key_len + 1));

   /* Set the compression flag */
   if (compression == PNG_ITXT_COMPRESSION_NONE || \
       compression == PNG_TEXT_COMPRESSION_NONE)
       cbuf[0] = 0;
   else /* compression == PNG_ITXT_COMPRESSION_zTXt */
       cbuf[0] = 1;
   /* Set the compression method */
   cbuf[1] = 0;
   png_write_chunk_data(png_ptr, cbuf, (png_size_t)2);

   cbuf[0] = 0;
   png_write_chunk_data(png_ptr, (new_lang ? (png_bytep)new_lang : cbuf),
     (png_size_t)(lang_len + 1));
   png_write_chunk_data(png_ptr, (lang_key ? (png_bytep)lang_key : cbuf),
     (png_size_t)(lang_key_len + 1));
   png_write_compressed_data_out(png_ptr, &comp);

   png_write_chunk_end(png_ptr);
   png_free(png_ptr, new_key);
   png_free(png_ptr, new_lang);
}
#endif

#ifdef PNG_WRITE_oFFs_SUPPORTED
/* Write the oFFs chunk */
void /* PRIVATE */
png_write_oFFs(png_structp png_ptr, png_int_32 x_offset, png_int_32 y_offset,
   int unit_type)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_oFFs;
#endif
   png_byte buf[9];

   png_debug(1, "in png_write_oFFs");

   if (unit_type >= PNG_OFFSET_LAST)
      png_warning(png_ptr, "Unrecognized unit type for oFFs chunk");

   png_save_int_32(buf, x_offset);
   png_save_int_32(buf + 4, y_offset);
   buf[8] = (png_byte)unit_type;

   png_write_chunk(png_ptr, (png_bytep)png_oFFs, buf, (png_size_t)9);
}
#endif
#ifdef PNG_WRITE_pCAL_SUPPORTED
/* Write the pCAL chunk (described in the PNG extensions document) */
void /* PRIVATE */
png_write_pCAL(png_structp png_ptr, png_charp purpose, png_int_32 X0,
   png_int_32 X1, int type, int nparams, png_charp units, png_charpp params)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_pCAL;
#endif
   png_size_t purpose_len, units_len, total_len;
   png_uint_32p params_len;
   png_byte buf[10];
   png_charp new_purpose;
   int i;

   png_debug1(1, "in png_write_pCAL (%d parameters)", nparams);

   if (type >= PNG_EQUATION_LAST)
      png_warning(png_ptr, "Unrecognized equation type for pCAL chunk");

   purpose_len = png_check_keyword(png_ptr, purpose, &new_purpose) + 1;
   png_debug1(3, "pCAL purpose length = %d", (int)purpose_len);
   units_len = png_strlen(units) + (nparams == 0 ? 0 : 1);
   png_debug1(3, "pCAL units length = %d", (int)units_len);
   total_len = purpose_len + units_len + 10;

   params_len = (png_uint_32p)png_malloc(png_ptr,
      (png_uint_32)(nparams * png_sizeof(png_uint_32)));

   /* Find the length of each parameter, making sure we don't count the
      null terminator for the last parameter. */
   for (i = 0; i < nparams; i++)
   {
      params_len[i] = png_strlen(params[i]) + (i == nparams - 1 ? 0 : 1);
      png_debug2(3, "pCAL parameter %d length = %lu", i,
        (unsigned long) params_len[i]);
      total_len += (png_size_t)params_len[i];
   }

   png_debug1(3, "pCAL total length = %d", (int)total_len);
   png_write_chunk_start(png_ptr, (png_bytep)png_pCAL, (png_uint_32)total_len);
   png_write_chunk_data(png_ptr, (png_bytep)new_purpose,
     (png_size_t)purpose_len);
   png_save_int_32(buf, X0);
   png_save_int_32(buf + 4, X1);
   buf[8] = (png_byte)type;
   buf[9] = (png_byte)nparams;
   png_write_chunk_data(png_ptr, buf, (png_size_t)10);
   png_write_chunk_data(png_ptr, (png_bytep)units, (png_size_t)units_len);

   png_free(png_ptr, new_purpose);

   for (i = 0; i < nparams; i++)
   {
      png_write_chunk_data(png_ptr, (png_bytep)params[i],
         (png_size_t)params_len[i]);
   }

   png_free(png_ptr, params_len);
   png_write_chunk_end(png_ptr);
}
#endif

#ifdef PNG_WRITE_sCAL_SUPPORTED
/* Write the sCAL chunk */
#if defined(PNG_FLOATING_POINT_SUPPORTED) && defined(PNG_STDIO_SUPPORTED)
void /* PRIVATE */
png_write_sCAL(png_structp png_ptr, int unit, double width, double height)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_sCAL;
#endif
   char buf[64];
   png_size_t total_len;

   png_debug(1, "in png_write_sCAL");

   buf[0] = (char)unit;
#ifdef _WIN32_WCE
/* sprintf() function is not supported on WindowsCE */
   {
      wchar_t wc_buf[32];
      size_t wc_len;
      swprintf(wc_buf, TEXT("%12.12e"), width);
      wc_len = wcslen(wc_buf);
      WideCharToMultiByte(CP_ACP, 0, wc_buf, -1, buf + 1, wc_len, NULL,
          NULL);
      total_len = wc_len + 2;
      swprintf(wc_buf, TEXT("%12.12e"), height);
      wc_len = wcslen(wc_buf);
      WideCharToMultiByte(CP_ACP, 0, wc_buf, -1, buf + total_len, wc_len,
         NULL, NULL);
      total_len += wc_len;
   }
#else
   png_snprintf(buf + 1, 63, "%12.12e", width);
   total_len = 1 + png_strlen(buf + 1) + 1;
   png_snprintf(buf + total_len, 64-total_len, "%12.12e", height);
   total_len += png_strlen(buf + total_len);
#endif

   png_debug1(3, "sCAL total length = %u", (unsigned int)total_len);
   png_write_chunk(png_ptr, (png_bytep)png_sCAL, (png_bytep)buf, total_len);
}
#else
#ifdef PNG_FIXED_POINT_SUPPORTED
void /* PRIVATE */
png_write_sCAL_s(png_structp png_ptr, int unit, png_charp width,
   png_charp height)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_sCAL;
#endif
   png_byte buf[64];
   png_size_t wlen, hlen, total_len;

   png_debug(1, "in png_write_sCAL_s");

   wlen = png_strlen(width);
   hlen = png_strlen(height);
   total_len = wlen + hlen + 2;
   if (total_len > 64)
   {
      png_warning(png_ptr, "Can't write sCAL (buffer too small)");
      return;
   }

   buf[0] = (png_byte)unit;
   png_memcpy(buf + 1, width, wlen + 1);      /* Append the '\0' here */
   png_memcpy(buf + wlen + 2, height, hlen);  /* Do NOT append the '\0' here */

   png_debug1(3, "sCAL total length = %u", (unsigned int)total_len);
   png_write_chunk(png_ptr, (png_bytep)png_sCAL, buf, total_len);
}
#endif
#endif
#endif

#ifdef PNG_WRITE_pHYs_SUPPORTED
/* Write the pHYs chunk */
void /* PRIVATE */
png_write_pHYs(png_structp png_ptr, png_uint_32 x_pixels_per_unit,
   png_uint_32 y_pixels_per_unit,
   int unit_type)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_pHYs;
#endif
   png_byte buf[9];

   png_debug(1, "in png_write_pHYs");

   if (unit_type >= PNG_RESOLUTION_LAST)
      png_warning(png_ptr, "Unrecognized unit type for pHYs chunk");

   png_save_uint_32(buf, x_pixels_per_unit);
   png_save_uint_32(buf + 4, y_pixels_per_unit);
   buf[8] = (png_byte)unit_type;

   png_write_chunk(png_ptr, (png_bytep)png_pHYs, buf, (png_size_t)9);
}
#endif

#ifdef PNG_WRITE_tIME_SUPPORTED
/* Write the tIME chunk.  Use either png_convert_from_struct_tm()
 * or png_convert_from_time_t(), or fill in the structure yourself.
 */
void /* PRIVATE */
png_write_tIME(png_structp png_ptr, png_timep mod_time)
{
#ifdef PNG_USE_LOCAL_ARRAYS
   PNG_tIME;
#endif
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

   png_write_chunk(png_ptr, (png_bytep)png_tIME, buf, (png_size_t)7);
}
#endif

/* Initializes the row writing capability of libpng */
void /* PRIVATE */
png_write_start_row(png_structp png_ptr)
{
#ifdef PNG_WRITE_INTERLACING_SUPPORTED
   /* Arrays to facilitate easy interlacing - use pass (0 - 6) as index */

   /* Start of interlace block */
   int png_pass_start[7] = {0, 4, 0, 2, 0, 1, 0};

   /* Offset to next interlace block */
   int png_pass_inc[7] = {8, 8, 4, 4, 2, 2, 1};

   /* Start of interlace block in the y direction */
   int png_pass_ystart[7] = {0, 0, 4, 0, 2, 0, 1};

   /* Offset to next interlace block in the y direction */
   int png_pass_yinc[7] = {8, 8, 8, 4, 4, 2, 2};
#endif

   png_size_t buf_size;

   png_debug(1, "in png_write_start_row");

   buf_size = (png_size_t)(PNG_ROWBYTES(
      png_ptr->usr_channels*png_ptr->usr_bit_depth, png_ptr->width) + 1);

   /* Set up row buffer */
   png_ptr->row_buf = (png_bytep)png_malloc(png_ptr,
     (png_uint_32)buf_size);
   png_ptr->row_buf[0] = PNG_FILTER_VALUE_NONE;

#ifdef PNG_WRITE_FILTER_SUPPORTED
   /* Set up filtering buffer, if using this filter */
   if (png_ptr->do_filter & PNG_FILTER_SUB)
   {
      png_ptr->sub_row = (png_bytep)png_malloc(png_ptr,
         (png_uint_32)(png_ptr->rowbytes + 1));
      png_ptr->sub_row[0] = PNG_FILTER_VALUE_SUB;
   }

   /* We only need to keep the previous row if we are using one of these. */
   if (png_ptr->do_filter & (PNG_FILTER_AVG | PNG_FILTER_UP | PNG_FILTER_PAETH))
   {
      /* Set up previous row buffer */
      png_ptr->prev_row = (png_bytep)png_calloc(png_ptr,
         (png_uint_32)buf_size);

      if (png_ptr->do_filter & PNG_FILTER_UP)
      {
         png_ptr->up_row = (png_bytep)png_malloc(png_ptr,
            (png_uint_32)(png_ptr->rowbytes + 1));
         png_ptr->up_row[0] = PNG_FILTER_VALUE_UP;
      }

      if (png_ptr->do_filter & PNG_FILTER_AVG)
      {
         png_ptr->avg_row = (png_bytep)png_malloc(png_ptr,
            (png_uint_32)(png_ptr->rowbytes + 1));
         png_ptr->avg_row[0] = PNG_FILTER_VALUE_AVG;
      }

      if (png_ptr->do_filter & PNG_FILTER_PAETH)
      {
         png_ptr->paeth_row = (png_bytep)png_malloc(png_ptr,
            (png_uint_32)(png_ptr->rowbytes + 1));
         png_ptr->paeth_row[0] = PNG_FILTER_VALUE_PAETH;
      }
   }
#endif /* PNG_WRITE_FILTER_SUPPORTED */

#ifdef PNG_WRITE_INTERLACING_SUPPORTED
   /* If interlaced, we need to set up width and height of pass */
   if (png_ptr->interlaced)
   {
      if (!(png_ptr->transformations & PNG_INTERLACE))
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
   png_ptr->zstream.avail_out = (uInt)png_ptr->zbuf_size;
   png_ptr->zstream.next_out = png_ptr->zbuf;
}

/* Internal use only.  Called when finished processing a row of data. */
void /* PRIVATE */
png_write_finish_row(png_structp png_ptr)
{
#ifdef PNG_WRITE_INTERLACING_SUPPORTED
   /* Arrays to facilitate easy interlacing - use pass (0 - 6) as index */

   /* Start of interlace block */
   int png_pass_start[7] = {0, 4, 0, 2, 0, 1, 0};

   /* Offset to next interlace block */
   int png_pass_inc[7] = {8, 8, 4, 4, 2, 2, 1};

   /* Start of interlace block in the y direction */
   int png_pass_ystart[7] = {0, 0, 4, 0, 2, 0, 1};

   /* Offset to next interlace block in the y direction */
   int png_pass_yinc[7] = {8, 8, 8, 4, 4, 2, 2};
#endif

   int ret;

   png_debug(1, "in png_write_finish_row");

   /* Next row */
   png_ptr->row_number++;

   /* See if we are done */
   if (png_ptr->row_number < png_ptr->num_rows)
      return;

#ifdef PNG_WRITE_INTERLACING_SUPPORTED
   /* If interlaced, go to next pass */
   if (png_ptr->interlaced)
   {
      png_ptr->row_number = 0;
      if (png_ptr->transformations & PNG_INTERLACE)
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
            if (png_ptr->transformations & PNG_INTERLACE)
               break;
         } while (png_ptr->usr_width == 0 || png_ptr->num_rows == 0);

      }

      /* Reset the row above the image for the next pass */
      if (png_ptr->pass < 7)
      {
         if (png_ptr->prev_row != NULL)
            png_memset(png_ptr->prev_row, 0,
               (png_size_t)(PNG_ROWBYTES(png_ptr->usr_channels*
               png_ptr->usr_bit_depth, png_ptr->width)) + 1);
         return;
      }
   }
#endif

   /* If we get here, we've just written the last row, so we need
      to flush the compressor */
   do
   {
      /* Tell the compressor we are done */
      ret = deflate(&png_ptr->zstream, Z_FINISH);
      /* Check for an error */
      if (ret == Z_OK)
      {
         /* Check to see if we need more room */
         if (!(png_ptr->zstream.avail_out))
         {
            png_write_IDAT(png_ptr, png_ptr->zbuf, png_ptr->zbuf_size);
            png_ptr->zstream.next_out = png_ptr->zbuf;
            png_ptr->zstream.avail_out = (uInt)png_ptr->zbuf_size;
         }
      }
      else if (ret != Z_STREAM_END)
      {
         if (png_ptr->zstream.msg != NULL)
            png_error(png_ptr, png_ptr->zstream.msg);
         else
            png_error(png_ptr, "zlib error");
      }
   } while (ret != Z_STREAM_END);

   /* Write any extra space */
   if (png_ptr->zstream.avail_out < png_ptr->zbuf_size)
   {
      png_write_IDAT(png_ptr, png_ptr->zbuf, png_ptr->zbuf_size -
         png_ptr->zstream.avail_out);
   }

   deflateReset(&png_ptr->zstream);
   png_ptr->zstream.data_type = Z_BINARY;
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
   int png_pass_start[7] = {0, 4, 0, 2, 0, 1, 0};

   /* Offset to next interlace block */
   int png_pass_inc[7] = {8, 8, 4, 4, 2, 2, 1};

   png_debug(1, "in png_do_write_interlace");

   /* We don't have to do anything on the last pass (6) */
#ifdef PNG_USELESS_TESTS_SUPPORTED
   if (row != NULL && row_info != NULL && pass < 6)
#else
   if (pass < 6)
#endif
   {
      /* Each pixel depth is handled separately */
      switch (row_info->pixel_depth)
      {
         case 1:
         {
            png_bytep sp;
            png_bytep dp;
            int shift;
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
            int shift;
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
            int shift;
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
            /* Loop through the row, only looking at the pixels that
               matter */
            for (i = png_pass_start[pass]; i < row_width;
               i += png_pass_inc[pass])
            {
               /* Find out where the original pixel is */
               sp = row + (png_size_t)i * pixel_bytes;
               /* Move the pixel */
               if (dp != sp)
                  png_memcpy(dp, sp, pixel_bytes);
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
#define PNG_MAXSUM (((png_uint_32)(-1)) >> 1)
#define PNG_HISHIFT 10
#define PNG_LOMASK ((png_uint_32)0xffffL)
#define PNG_HIMASK ((png_uint_32)(~PNG_LOMASK >> PNG_HISHIFT))
void /* PRIVATE */
png_write_find_filter(png_structp png_ptr, png_row_infop row_info)
{
   png_bytep best_row;
#ifdef PNG_WRITE_FILTER_SUPPORTED
   png_bytep prev_row, row_buf;
   png_uint_32 mins, bpp;
   png_byte filter_to_do = png_ptr->do_filter;
   png_uint_32 row_bytes = row_info->rowbytes;
#ifdef PNG_WRITE_WEIGHTED_FILTER_SUPPORTED
   int num_p_filters = (int)png_ptr->num_prev_filters;
#endif 

   png_debug(1, "in png_write_find_filter");

#ifndef PNG_WRITE_WEIGHTED_FILTER_SUPPORTED
  if (png_ptr->row_number == 0 && filter_to_do == PNG_ALL_FILTERS)
  {
      /* These will never be selected so we need not test them. */
      filter_to_do &= ~(PNG_FILTER_UP | PNG_FILTER_PAETH);
  }
#endif 

   /* Find out how many bytes offset each pixel is */
   bpp = (row_info->pixel_depth + 7) >> 3;

   prev_row = png_ptr->prev_row;
#endif
   best_row = png_ptr->row_buf;
#ifdef PNG_WRITE_FILTER_SUPPORTED
   row_buf = best_row;
   mins = PNG_MAXSUM;

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
    *   (1) minimum sum of absolute differences from running average (i.e.,
    *       keep running sum of non-absolute differences & count of bytes)
    *       [track dispersion, too?  restart average if dispersion too large?]
    *  (1b) minimum sum of absolute differences from sliding average, probably
    *       with window size <= deflate window (usually 32K)
    *   (2) minimum sum of squared differences from zero or running average
    *       (i.e., ~ root-mean-square approach)
    */


   /* We don't need to test the 'no filter' case if this is the only filter
    * that has been chosen, as it doesn't actually do anything to the data.
    */
   if ((filter_to_do & PNG_FILTER_NONE) &&
       filter_to_do != PNG_FILTER_NONE)
   {
      png_bytep rp;
      png_uint_32 sum = 0;
      png_uint_32 i;
      int v;

      for (i = 0, rp = row_buf + 1; i < row_bytes; i++, rp++)
      {
         v = *rp;
         sum += (v < 128) ? v : 256 - v;
      }

#ifdef PNG_WRITE_WEIGHTED_FILTER_SUPPORTED
      if (png_ptr->heuristic_method == PNG_FILTER_HEURISTIC_WEIGHTED)
      {
         png_uint_32 sumhi, sumlo;
         int j;
         sumlo = sum & PNG_LOMASK;
         sumhi = (sum >> PNG_HISHIFT) & PNG_HIMASK; /* Gives us some footroom */

         /* Reduce the sum if we match any of the previous rows */
         for (j = 0; j < num_p_filters; j++)
         {
            if (png_ptr->prev_filters[j] == PNG_FILTER_VALUE_NONE)
            {
               sumlo = (sumlo * png_ptr->filter_weights[j]) >>
                  PNG_WEIGHT_SHIFT;
               sumhi = (sumhi * png_ptr->filter_weights[j]) >>
                  PNG_WEIGHT_SHIFT;
            }
         }

         /* Factor in the cost of this filter (this is here for completeness,
          * but it makes no sense to have a "cost" for the NONE filter, as
          * it has the minimum possible computational cost - none).
          */
         sumlo = (sumlo * png_ptr->filter_costs[PNG_FILTER_VALUE_NONE]) >>
            PNG_COST_SHIFT;
         sumhi = (sumhi * png_ptr->filter_costs[PNG_FILTER_VALUE_NONE]) >>
            PNG_COST_SHIFT;

         if (sumhi > PNG_HIMASK)
            sum = PNG_MAXSUM;
         else
            sum = (sumhi << PNG_HISHIFT) + sumlo;
      }
#endif
      mins = sum;
   }

   /* Sub filter */
   if (filter_to_do == PNG_FILTER_SUB)
   /* It's the only filter so no testing is needed */
   {
      png_bytep rp, lp, dp;
      png_uint_32 i;
      for (i = 0, rp = row_buf + 1, dp = png_ptr->sub_row + 1; i < bpp;
           i++, rp++, dp++)
      {
         *dp = *rp;
      }
      for (lp = row_buf + 1; i < row_bytes;
         i++, rp++, lp++, dp++)
      {
         *dp = (png_byte)(((int)*rp - (int)*lp) & 0xff);
      }
      best_row = png_ptr->sub_row;
   }

   else if (filter_to_do & PNG_FILTER_SUB)
   {
      png_bytep rp, dp, lp;
      png_uint_32 sum = 0, lmins = mins;
      png_uint_32 i;
      int v;

#ifdef PNG_WRITE_WEIGHTED_FILTER_SUPPORTED
      /* We temporarily increase the "minimum sum" by the factor we
       * would reduce the sum of this filter, so that we can do the
       * early exit comparison without scaling the sum each time.
       */
      if (png_ptr->heuristic_method == PNG_FILTER_HEURISTIC_WEIGHTED)
      {
         int j;
         png_uint_32 lmhi, lmlo;
         lmlo = lmins & PNG_LOMASK;
         lmhi = (lmins >> PNG_HISHIFT) & PNG_HIMASK;

         for (j = 0; j < num_p_filters; j++)
         {
            if (png_ptr->prev_filters[j] == PNG_FILTER_VALUE_SUB)
            {
               lmlo = (lmlo * png_ptr->inv_filter_weights[j]) >>
                  PNG_WEIGHT_SHIFT;
               lmhi = (lmhi * png_ptr->inv_filter_weights[j]) >>
                  PNG_WEIGHT_SHIFT;
            }
         }

         lmlo = (lmlo * png_ptr->inv_filter_costs[PNG_FILTER_VALUE_SUB]) >>
            PNG_COST_SHIFT;
         lmhi = (lmhi * png_ptr->inv_filter_costs[PNG_FILTER_VALUE_SUB]) >>
            PNG_COST_SHIFT;

         if (lmhi > PNG_HIMASK)
            lmins = PNG_MAXSUM;
         else
            lmins = (lmhi << PNG_HISHIFT) + lmlo;
      }
#endif

      for (i = 0, rp = row_buf + 1, dp = png_ptr->sub_row + 1; i < bpp;
           i++, rp++, dp++)
      {
         v = *dp = *rp;

         sum += (v < 128) ? v : 256 - v;
      }
      for (lp = row_buf + 1; i < row_bytes;
         i++, rp++, lp++, dp++)
      {
         v = *dp = (png_byte)(((int)*rp - (int)*lp) & 0xff);

         sum += (v < 128) ? v : 256 - v;

         if (sum > lmins)  /* We are already worse, don't continue. */
            break;
      }

#ifdef PNG_WRITE_WEIGHTED_FILTER_SUPPORTED
      if (png_ptr->heuristic_method == PNG_FILTER_HEURISTIC_WEIGHTED)
      {
         int j;
         png_uint_32 sumhi, sumlo;
         sumlo = sum & PNG_LOMASK;
         sumhi = (sum >> PNG_HISHIFT) & PNG_HIMASK;

         for (j = 0; j < num_p_filters; j++)
         {
            if (png_ptr->prev_filters[j] == PNG_FILTER_VALUE_SUB)
            {
               sumlo = (sumlo * png_ptr->inv_filter_weights[j]) >>
                  PNG_WEIGHT_SHIFT;
               sumhi = (sumhi * png_ptr->inv_filter_weights[j]) >>
                  PNG_WEIGHT_SHIFT;
            }
         }

         sumlo = (sumlo * png_ptr->inv_filter_costs[PNG_FILTER_VALUE_SUB]) >>
            PNG_COST_SHIFT;
         sumhi = (sumhi * png_ptr->inv_filter_costs[PNG_FILTER_VALUE_SUB]) >>
            PNG_COST_SHIFT;

         if (sumhi > PNG_HIMASK)
            sum = PNG_MAXSUM;
         else
            sum = (sumhi << PNG_HISHIFT) + sumlo;
      }
#endif

      if (sum < mins)
      {
         mins = sum;
         best_row = png_ptr->sub_row;
      }
   }

   /* Up filter */
   if (filter_to_do == PNG_FILTER_UP)
   {
      png_bytep rp, dp, pp;
      png_uint_32 i;

      for (i = 0, rp = row_buf + 1, dp = png_ptr->up_row + 1,
           pp = prev_row + 1; i < row_bytes;
           i++, rp++, pp++, dp++)
      {
         *dp = (png_byte)(((int)*rp - (int)*pp) & 0xff);
      }
      best_row = png_ptr->up_row;
   }

   else if (filter_to_do & PNG_FILTER_UP)
   {
      png_bytep rp, dp, pp;
      png_uint_32 sum = 0, lmins = mins;
      png_uint_32 i;
      int v;


#ifdef PNG_WRITE_WEIGHTED_FILTER_SUPPORTED
      if (png_ptr->heuristic_method == PNG_FILTER_HEURISTIC_WEIGHTED)
      {
         int j;
         png_uint_32 lmhi, lmlo;
         lmlo = lmins & PNG_LOMASK;
         lmhi = (lmins >> PNG_HISHIFT) & PNG_HIMASK;

         for (j = 0; j < num_p_filters; j++)
         {
            if (png_ptr->prev_filters[j] == PNG_FILTER_VALUE_UP)
            {
               lmlo = (lmlo * png_ptr->inv_filter_weights[j]) >>
                  PNG_WEIGHT_SHIFT;
               lmhi = (lmhi * png_ptr->inv_filter_weights[j]) >>
                  PNG_WEIGHT_SHIFT;
            }
         }

         lmlo = (lmlo * png_ptr->inv_filter_costs[PNG_FILTER_VALUE_UP]) >>
            PNG_COST_SHIFT;
         lmhi = (lmhi * png_ptr->inv_filter_costs[PNG_FILTER_VALUE_UP]) >>
            PNG_COST_SHIFT;

         if (lmhi > PNG_HIMASK)
            lmins = PNG_MAXSUM;
         else
            lmins = (lmhi << PNG_HISHIFT) + lmlo;
      }
#endif

      for (i = 0, rp = row_buf + 1, dp = png_ptr->up_row + 1,
           pp = prev_row + 1; i < row_bytes; i++)
      {
         v = *dp++ = (png_byte)(((int)*rp++ - (int)*pp++) & 0xff);

         sum += (v < 128) ? v : 256 - v;

         if (sum > lmins)  /* We are already worse, don't continue. */
            break;
      }

#ifdef PNG_WRITE_WEIGHTED_FILTER_SUPPORTED
      if (png_ptr->heuristic_method == PNG_FILTER_HEURISTIC_WEIGHTED)
      {
         int j;
         png_uint_32 sumhi, sumlo;
         sumlo = sum & PNG_LOMASK;
         sumhi = (sum >> PNG_HISHIFT) & PNG_HIMASK;

         for (j = 0; j < num_p_filters; j++)
         {
            if (png_ptr->prev_filters[j] == PNG_FILTER_VALUE_UP)
            {
               sumlo = (sumlo * png_ptr->filter_weights[j]) >>
                  PNG_WEIGHT_SHIFT;
               sumhi = (sumhi * png_ptr->filter_weights[j]) >>
                  PNG_WEIGHT_SHIFT;
            }
         }

         sumlo = (sumlo * png_ptr->filter_costs[PNG_FILTER_VALUE_UP]) >>
            PNG_COST_SHIFT;
         sumhi = (sumhi * png_ptr->filter_costs[PNG_FILTER_VALUE_UP]) >>
            PNG_COST_SHIFT;

         if (sumhi > PNG_HIMASK)
            sum = PNG_MAXSUM;
         else
            sum = (sumhi << PNG_HISHIFT) + sumlo;
      }
#endif

      if (sum < mins)
      {
         mins = sum;
         best_row = png_ptr->up_row;
      }
   }

   /* Avg filter */
   if (filter_to_do == PNG_FILTER_AVG)
   {
      png_bytep rp, dp, pp, lp;
      png_uint_32 i;
      for (i = 0, rp = row_buf + 1, dp = png_ptr->avg_row + 1,
           pp = prev_row + 1; i < bpp; i++)
      {
         *dp++ = (png_byte)(((int)*rp++ - ((int)*pp++ / 2)) & 0xff);
      }
      for (lp = row_buf + 1; i < row_bytes; i++)
      {
         *dp++ = (png_byte)(((int)*rp++ - (((int)*pp++ + (int)*lp++) / 2))
                 & 0xff);
      }
      best_row = png_ptr->avg_row;
   }

   else if (filter_to_do & PNG_FILTER_AVG)
   {
      png_bytep rp, dp, pp, lp;
      png_uint_32 sum = 0, lmins = mins;
      png_uint_32 i;
      int v;

#ifdef PNG_WRITE_WEIGHTED_FILTER_SUPPORTED
      if (png_ptr->heuristic_method == PNG_FILTER_HEURISTIC_WEIGHTED)
      {
         int j;
         png_uint_32 lmhi, lmlo;
         lmlo = lmins & PNG_LOMASK;
         lmhi = (lmins >> PNG_HISHIFT) & PNG_HIMASK;

         for (j = 0; j < num_p_filters; j++)
         {
            if (png_ptr->prev_filters[j] == PNG_FILTER_VALUE_AVG)
            {
               lmlo = (lmlo * png_ptr->inv_filter_weights[j]) >>
                  PNG_WEIGHT_SHIFT;
               lmhi = (lmhi * png_ptr->inv_filter_weights[j]) >>
                  PNG_WEIGHT_SHIFT;
            }
         }

         lmlo = (lmlo * png_ptr->inv_filter_costs[PNG_FILTER_VALUE_AVG]) >>
            PNG_COST_SHIFT;
         lmhi = (lmhi * png_ptr->inv_filter_costs[PNG_FILTER_VALUE_AVG]) >>
            PNG_COST_SHIFT;

         if (lmhi > PNG_HIMASK)
            lmins = PNG_MAXSUM;
         else
            lmins = (lmhi << PNG_HISHIFT) + lmlo;
      }
#endif

      for (i = 0, rp = row_buf + 1, dp = png_ptr->avg_row + 1,
           pp = prev_row + 1; i < bpp; i++)
      {
         v = *dp++ = (png_byte)(((int)*rp++ - ((int)*pp++ / 2)) & 0xff);

         sum += (v < 128) ? v : 256 - v;
      }
      for (lp = row_buf + 1; i < row_bytes; i++)
      {
         v = *dp++ =
          (png_byte)(((int)*rp++ - (((int)*pp++ + (int)*lp++) / 2)) & 0xff);

         sum += (v < 128) ? v : 256 - v;

         if (sum > lmins)  /* We are already worse, don't continue. */
            break;
      }

#ifdef PNG_WRITE_WEIGHTED_FILTER_SUPPORTED
      if (png_ptr->heuristic_method == PNG_FILTER_HEURISTIC_WEIGHTED)
      {
         int j;
         png_uint_32 sumhi, sumlo;
         sumlo = sum & PNG_LOMASK;
         sumhi = (sum >> PNG_HISHIFT) & PNG_HIMASK;

         for (j = 0; j < num_p_filters; j++)
         {
            if (png_ptr->prev_filters[j] == PNG_FILTER_VALUE_NONE)
            {
               sumlo = (sumlo * png_ptr->filter_weights[j]) >>
                  PNG_WEIGHT_SHIFT;
               sumhi = (sumhi * png_ptr->filter_weights[j]) >>
                  PNG_WEIGHT_SHIFT;
            }
         }

         sumlo = (sumlo * png_ptr->filter_costs[PNG_FILTER_VALUE_AVG]) >>
            PNG_COST_SHIFT;
         sumhi = (sumhi * png_ptr->filter_costs[PNG_FILTER_VALUE_AVG]) >>
            PNG_COST_SHIFT;

         if (sumhi > PNG_HIMASK)
            sum = PNG_MAXSUM;
         else
            sum = (sumhi << PNG_HISHIFT) + sumlo;
      }
#endif

      if (sum < mins)
      {
         mins = sum;
         best_row = png_ptr->avg_row;
      }
   }

   /* Paeth filter */
   if (filter_to_do == PNG_FILTER_PAETH)
   {
      png_bytep rp, dp, pp, cp, lp;
      png_uint_32 i;
      for (i = 0, rp = row_buf + 1, dp = png_ptr->paeth_row + 1,
           pp = prev_row + 1; i < bpp; i++)
      {
         *dp++ = (png_byte)(((int)*rp++ - (int)*pp++) & 0xff);
      }

      for (lp = row_buf + 1, cp = prev_row + 1; i < row_bytes; i++)
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

         *dp++ = (png_byte)(((int)*rp++ - p) & 0xff);
      }
      best_row = png_ptr->paeth_row;
   }

   else if (filter_to_do & PNG_FILTER_PAETH)
   {
      png_bytep rp, dp, pp, cp, lp;
      png_uint_32 sum = 0, lmins = mins;
      png_uint_32 i;
      int v;

#ifdef PNG_WRITE_WEIGHTED_FILTER_SUPPORTED
      if (png_ptr->heuristic_method == PNG_FILTER_HEURISTIC_WEIGHTED)
      {
         int j;
         png_uint_32 lmhi, lmlo;
         lmlo = lmins & PNG_LOMASK;
         lmhi = (lmins >> PNG_HISHIFT) & PNG_HIMASK;

         for (j = 0; j < num_p_filters; j++)
         {
            if (png_ptr->prev_filters[j] == PNG_FILTER_VALUE_PAETH)
            {
               lmlo = (lmlo * png_ptr->inv_filter_weights[j]) >>
                  PNG_WEIGHT_SHIFT;
               lmhi = (lmhi * png_ptr->inv_filter_weights[j]) >>
                  PNG_WEIGHT_SHIFT;
            }
         }

         lmlo = (lmlo * png_ptr->inv_filter_costs[PNG_FILTER_VALUE_PAETH]) >>
            PNG_COST_SHIFT;
         lmhi = (lmhi * png_ptr->inv_filter_costs[PNG_FILTER_VALUE_PAETH]) >>
            PNG_COST_SHIFT;

         if (lmhi > PNG_HIMASK)
            lmins = PNG_MAXSUM;
         else
            lmins = (lmhi << PNG_HISHIFT) + lmlo;
      }
#endif

      for (i = 0, rp = row_buf + 1, dp = png_ptr->paeth_row + 1,
           pp = prev_row + 1; i < bpp; i++)
      {
         v = *dp++ = (png_byte)(((int)*rp++ - (int)*pp++) & 0xff);

         sum += (v < 128) ? v : 256 - v;
      }

      for (lp = row_buf + 1, cp = prev_row + 1; i < row_bytes; i++)
      {
         int a, b, c, pa, pb, pc, p;

         b = *pp++;
         c = *cp++;
         a = *lp++;

#ifndef PNG_SLOW_PAETH
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
#else /* PNG_SLOW_PAETH */
         p = a + b - c;
         pa = abs(p - a);
         pb = abs(p - b);
         pc = abs(p - c);
         if (pa <= pb && pa <= pc)
            p = a;
         else if (pb <= pc)
            p = b;
         else
            p = c;
#endif /* PNG_SLOW_PAETH */

         v = *dp++ = (png_byte)(((int)*rp++ - p) & 0xff);

         sum += (v < 128) ? v : 256 - v;

         if (sum > lmins)  /* We are already worse, don't continue. */
            break;
      }

#ifdef PNG_WRITE_WEIGHTED_FILTER_SUPPORTED
      if (png_ptr->heuristic_method == PNG_FILTER_HEURISTIC_WEIGHTED)
      {
         int j;
         png_uint_32 sumhi, sumlo;
         sumlo = sum & PNG_LOMASK;
         sumhi = (sum >> PNG_HISHIFT) & PNG_HIMASK;

         for (j = 0; j < num_p_filters; j++)
         {
            if (png_ptr->prev_filters[j] == PNG_FILTER_VALUE_PAETH)
            {
               sumlo = (sumlo * png_ptr->filter_weights[j]) >>
                  PNG_WEIGHT_SHIFT;
               sumhi = (sumhi * png_ptr->filter_weights[j]) >>
                  PNG_WEIGHT_SHIFT;
            }
         }

         sumlo = (sumlo * png_ptr->filter_costs[PNG_FILTER_VALUE_PAETH]) >>
            PNG_COST_SHIFT;
         sumhi = (sumhi * png_ptr->filter_costs[PNG_FILTER_VALUE_PAETH]) >>
            PNG_COST_SHIFT;

         if (sumhi > PNG_HIMASK)
            sum = PNG_MAXSUM;
         else
            sum = (sumhi << PNG_HISHIFT) + sumlo;
      }
#endif

      if (sum < mins)
      {
         best_row = png_ptr->paeth_row;
      }
   }
#endif /* PNG_WRITE_FILTER_SUPPORTED */
   /* Do the actual writing of the filtered row data from the chosen filter. */

   png_write_filtered_row(png_ptr, best_row);

#ifdef PNG_WRITE_FILTER_SUPPORTED
#ifdef PNG_WRITE_WEIGHTED_FILTER_SUPPORTED
   /* Save the type of filter we picked this time for future calculations */
   if (png_ptr->num_prev_filters > 0)
   {
      int j;
      for (j = 1; j < num_p_filters; j++)
      {
         png_ptr->prev_filters[j] = png_ptr->prev_filters[j - 1];
      }
      png_ptr->prev_filters[j] = best_row[0];
   }
#endif
#endif /* PNG_WRITE_FILTER_SUPPORTED */
}


/* Do the actual writing of a previously filtered row. */
void /* PRIVATE */
png_write_filtered_row(png_structp png_ptr, png_bytep filtered_row)
{
   png_debug(1, "in png_write_filtered_row");

   png_debug1(2, "filter = %d", filtered_row[0]);
   /* Set up the zlib input buffer */

   png_ptr->zstream.next_in = filtered_row;
   png_ptr->zstream.avail_in = (uInt)png_ptr->row_info.rowbytes + 1;
   /* Repeat until we have compressed all the data */
   do
   {
      int ret; /* Return of zlib */

      /* Compress the data */
      ret = deflate(&png_ptr->zstream, Z_NO_FLUSH);
      /* Check for compression errors */
      if (ret != Z_OK)
      {
         if (png_ptr->zstream.msg != NULL)
            png_error(png_ptr, png_ptr->zstream.msg);
         else
            png_error(png_ptr, "zlib error");
      }

      /* See if it is time to write another IDAT */
      if (!(png_ptr->zstream.avail_out))
      {
         /* Write the IDAT and reset the zlib output buffer */
         png_write_IDAT(png_ptr, png_ptr->zbuf, png_ptr->zbuf_size);
         png_ptr->zstream.next_out = png_ptr->zbuf;
         png_ptr->zstream.avail_out = (uInt)png_ptr->zbuf_size;
      }
   /* Repeat until all data has been compressed */
   } while (png_ptr->zstream.avail_in);

   /* Swap the current and previous rows */
   if (png_ptr->prev_row != NULL)
   {
      png_bytep tptr;

      tptr = png_ptr->prev_row;
      png_ptr->prev_row = png_ptr->row_buf;
      png_ptr->row_buf = tptr;
   }

   /* Finish row - updates counters and flushes zlib if last row */
   png_write_finish_row(png_ptr);

#ifdef PNG_WRITE_FLUSH_SUPPORTED
   png_ptr->flush_rows++;

   if (png_ptr->flush_dist > 0 &&
       png_ptr->flush_rows >= png_ptr->flush_dist)
   {
      png_write_flush(png_ptr);
   }
#endif
}
#endif /* PNG_WRITE_SUPPORTED */
