
#if 0 /* in case someone actually tries to compile this */

/* example.c - an example of using libpng
 * Last changed in libpng 1.6.15 [November 20, 2014]
 * Maintained 1998-2014 Glenn Randers-Pehrson
 * Maintained 1996, 1997 Andreas Dilger)
 * Written 1995, 1996 Guy Eric Schalnat, Group 42, Inc.)
 * To the extent possible under law, the authors have waived
 * all copyright and related or neighboring rights to this file.
 * This work is published from: United States.
 */

/* This is an example of how to use libpng to read and write PNG files.
 * The file libpng-manual.txt is much more verbose then this.  If you have not
 * read it, do so first.  This was designed to be a starting point of an
 * implementation.  This is not officially part of libpng, is hereby placed
 * in the public domain, and therefore does not require a copyright notice.
 *
 * This file does not currently compile, because it is missing certain
 * parts, like allocating memory to hold an image.  You will have to
 * supply these parts to get it to compile.  For an example of a minimal
 * working PNG reader/writer, see pngtest.c, included in this distribution;
 * see also the programs in the contrib directory.
 */

/* The simple, but restricted, approach to reading a PNG file or data stream
 * just requires two function calls, as in the following complete program.
 * Writing a file just needs one function call, so long as the data has an
 * appropriate layout.
 *
 * The following code reads PNG image data from a file and writes it, in a
 * potentially new format, to a new file.  While this code will compile there is
 * minimal (insufficient) error checking; for a more realistic version look at
 * contrib/examples/pngtopng.c
 */
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <png.h>
#include <zlib.h>

int main(int argc, const char **argv)
{
   if (argc == 3)
   {
      png_image image; /* The control structure used by libpng */

      /* Initialize the 'png_image' structure. */
      memset(&image, 0, (sizeof image));
      image.version = PNG_IMAGE_VERSION;

      /* The first argument is the file to read: */
      if (png_image_begin_read_from_file(&image, argv[1]) != 0)
      {
         png_bytep buffer;

         /* Set the format in which to read the PNG file; this code chooses a
          * simple sRGB format with a non-associated alpha channel, adequate to
          * store most images.
          */
         image.format = PNG_FORMAT_RGBA;

         /* Now allocate enough memory to hold the image in this format; the
          * PNG_IMAGE_SIZE macro uses the information about the image (width,
          * height and format) stored in 'image'.
          */
         buffer = malloc(PNG_IMAGE_SIZE(image));

         /* If enough memory was available read the image in the desired format
          * then write the result out to the new file.  'background' is not
          * necessary when reading the image because the alpha channel is
          * preserved; if it were to be removed, for example if we requested
          * PNG_FORMAT_RGB, then either a solid background color would have to
          * be supplied or the output buffer would have to be initialized to the
          * actual background of the image.
          *
          * The fourth argument to png_image_finish_read is the 'row_stride' -
          * this is the number of components allocated for the image in each
          * row.  It has to be at least as big as the value returned by
          * PNG_IMAGE_ROW_STRIDE, but if you just allocate space for the
          * default, minimum, size using PNG_IMAGE_SIZE as above you can pass
          * zero.
          *
          * The final argument is a pointer to a buffer for the colormap;
          * colormaps have exactly the same format as a row of image pixels (so
          * you choose what format to make the colormap by setting
          * image.format).  A colormap is only returned if
          * PNG_FORMAT_FLAG_COLORMAP is also set in image.format, so in this
          * case NULL is passed as the final argument.  If you do want to force
          * all images into an index/color-mapped format then you can use:
          *
          *    PNG_IMAGE_COLORMAP_SIZE(image)
          *
          * to find the maximum size of the colormap in bytes.
          */
         if (buffer != NULL &&
            png_image_finish_read(&image, NULL/*background*/, buffer,
               0/*row_stride*/, NULL/*colormap*/) != 0)
         {
            /* Now write the image out to the second argument.  In the write
             * call 'convert_to_8bit' allows 16-bit data to be squashed down to
             * 8 bits; this isn't necessary here because the original read was
             * to the 8-bit format.
             */
            if (png_image_write_to_file(&image, argv[2], 0/*convert_to_8bit*/,
               buffer, 0/*row_stride*/, NULL/*colormap*/) != 0)
            {
               /* The image has been written successfully. */
               exit(0);
            }
         }

         else
         {
            /* Calling png_free_image is optional unless the simplified API was
             * not run to completion.  In this case if there wasn't enough
             * memory for 'buffer' we didn't complete the read, so we must free
             * the image:
             */
            if (buffer == NULL)
               png_free_image(&image);

            else
               free(buffer);
      }

      /* Something went wrong reading or writing the image.  libpng stores a
       * textual message in the 'png_image' structure:
       */
      fprintf(stderr, "pngtopng: error: %s\n", image.message);
      exit (1);
   }

   fprintf(stderr, "pngtopng: usage: pngtopng input-file output-file\n");
   exit(1);
}

/* That's it ;-)  Of course you probably want to do more with PNG files than
 * just converting them all to 32-bit RGBA PNG files; you can do that between
 * the call to png_image_finish_read and png_image_write_to_file.  You can also
 * ask for the image data to be presented in a number of different formats.  You
 * do this by simply changing the 'format' parameter set before allocating the
 * buffer.
 *
 * The format parameter consists of five flags that define various aspects of
 * the image, you can simply add these together to get the format or you can use
 * one of the predefined macros from png.h (as above):
 *
 * PNG_FORMAT_FLAG_COLOR: if set the image will have three color components per
 *    pixel (red, green and blue), if not set the image will just have one
 *    luminance (grayscale) component.
 *
 * PNG_FORMAT_FLAG_ALPHA: if set each pixel in the image will have an additional
 *    alpha value; a linear value that describes the degree the image pixel
 *    covers (overwrites) the contents of the existing pixel on the display.
 *
 * PNG_FORMAT_FLAG_LINEAR: if set the components of each pixel will be returned
 *    as a series of 16-bit linear values, if not set the components will be
 *    returned as a series of 8-bit values encoded according to the 'sRGB'
 *    standard.  The 8-bit format is the normal format for images intended for
 *    direct display, because almost all display devices do the inverse of the
 *    sRGB transformation to the data they receive.  The 16-bit format is more
 *    common for scientific data and image data that must be further processed;
 *    because it is linear simple math can be done on the component values.
 *    Regardless of the setting of this flag the alpha channel is always linear,
 *    although it will be 8 bits or 16 bits wide as specified by the flag.
 *
 * PNG_FORMAT_FLAG_BGR: if set the components of a color pixel will be returned
 *    in the order blue, then green, then red.  If not set the pixel components
 *    are in the order red, then green, then blue.
 *
 * PNG_FORMAT_FLAG_AFIRST: if set the alpha channel (if present) precedes the
 *    color or grayscale components.  If not set the alpha channel follows the
 *    components.
 *
 * You do not have to read directly from a file.  You can read from memory or,
 * on systems that support it, from a <stdio.h> FILE*.  This is controlled by
 * the particular png_image_read_from_ function you call at the start.  Likewise
 * on write you can write to a FILE* if your system supports it.  Check the
 * macro PNG_STDIO_SUPPORTED to see if stdio support has been included in your
 * libpng build.
 *
 * If you read 16-bit (PNG_FORMAT_FLAG_LINEAR) data you may need to write it in
 * the 8-bit format for display.  You do this by setting the convert_to_8bit
 * flag to 'true'.
 *
 * Don't repeatedly convert between the 8-bit and 16-bit forms.  There is
 * significant data loss when 16-bit data is converted to the 8-bit encoding and
 * the current libpng implementation of conversion to 16-bit is also
 * significantly lossy.  The latter will be fixed in the future, but the former
 * is unavoidable - the 8-bit format just doesn't have enough resolution.
 */

/* If your program needs more information from the PNG data it reads, or if you
 * need to do more complex transformations, or minimize transformations, on the
 * data you read, then you must use one of the several lower level libpng
 * interfaces.
 *
 * All these interfaces require that you do your own error handling - your
 * program must be able to arrange for control to return to your own code any
 * time libpng encounters a problem.  There are several ways to do this, but the
 * standard way is to use the ANSI-C (C90) <setjmp.h> interface to establish a
 * return point within your own code.  You must do this if you do not use the
 * simplified interface (above).
 *
 * The first step is to include the header files you need, including the libpng
 * header file.  Include any standard headers and feature test macros your
 * program requires before including png.h:
 */
#include <png.h>

 /* The png_jmpbuf() macro, used in error handling, became available in
  * libpng version 1.0.6.  If you want to be able to run your code with older
  * versions of libpng, you must define the macro yourself (but only if it
  * is not already defined by libpng!).
  */

#ifndef png_jmpbuf
#  define png_jmpbuf(png_ptr) ((png_ptr)->png_jmpbuf)
#endif

/* Check to see if a file is a PNG file using png_sig_cmp().  png_sig_cmp()
 * returns zero if the image is a PNG and nonzero if it isn't a PNG.
 *
 * The function check_if_png() shown here, but not used, returns nonzero (true)
 * if the file can be opened and is a PNG, 0 (false) otherwise.
 *
 * If this call is successful, and you are going to keep the file open,
 * you should call png_set_sig_bytes(png_ptr, PNG_BYTES_TO_CHECK); once
 * you have created the png_ptr, so that libpng knows your application
 * has read that many bytes from the start of the file.  Make sure you
 * don't call png_set_sig_bytes() with more than 8 bytes read or give it
 * an incorrect number of bytes read, or you will either have read too
 * many bytes (your fault), or you are telling libpng to read the wrong
 * number of magic bytes (also your fault).
 *
 * Many applications already read the first 2 or 4 bytes from the start
 * of the image to determine the file type, so it would be easiest just
 * to pass the bytes to png_sig_cmp() or even skip that if you know
 * you have a PNG file, and call png_set_sig_bytes().
 */
#define PNG_BYTES_TO_CHECK 4
int check_if_png(char *file_name, FILE **fp)
{
   char buf[PNG_BYTES_TO_CHECK];

   /* Open the prospective PNG file. */
   if ((*fp = fopen(file_name, "rb")) == NULL)
      return 0;

   /* Read in some of the signature bytes */
   if (fread(buf, 1, PNG_BYTES_TO_CHECK, *fp) != PNG_BYTES_TO_CHECK)
      return 0;

   /* Compare the first PNG_BYTES_TO_CHECK bytes of the signature.
      Return nonzero (true) if they match */

   return(!png_sig_cmp(buf, (png_size_t)0, PNG_BYTES_TO_CHECK));
}

/* Read a PNG file.  You may want to return an error code if the read
 * fails (depending upon the failure).  There are two "prototypes" given
 * here - one where we are given the filename, and we need to open the
 * file, and the other where we are given an open file (possibly with
 * some or all of the magic bytes read - see comments above).
 */
#ifdef open_file /* prototype 1 */
void read_png(char *file_name)  /* We need to open the file */
{
   png_structp png_ptr;
   png_infop info_ptr;
   int sig_read = 0;
   png_uint_32 width, height;
   int bit_depth, color_type, interlace_type;
   FILE *fp;

   if ((fp = fopen(file_name, "rb")) == NULL)
      return (ERROR);

#else no_open_file /* prototype 2 */
void read_png(FILE *fp, int sig_read)  /* File is already open */
{
   png_structp png_ptr;
   png_infop info_ptr;
   png_uint_32 width, height;
   int bit_depth, color_type, interlace_type;
#endif no_open_file /* Only use one prototype! */

   /* Create and initialize the png_struct with the desired error handler
    * functions.  If you want to use the default stderr and longjump method,
    * you can supply NULL for the last three parameters.  We also supply the
    * the compiler header file version, so that we know if the application
    * was compiled with a compatible version of the library.  REQUIRED
    */
   png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING,
      png_voidp user_error_ptr, user_error_fn, user_warning_fn);

   if (png_ptr == NULL)
   {
      fclose(fp);
      return (ERROR);
   }

   /* Allocate/initialize the memory for image information.  REQUIRED. */
   info_ptr = png_create_info_struct(png_ptr);
   if (info_ptr == NULL)
   {
      fclose(fp);
      png_destroy_read_struct(&png_ptr, NULL, NULL);
      return (ERROR);
   }

   /* Set error handling if you are using the setjmp/longjmp method (this is
    * the normal method of doing things with libpng).  REQUIRED unless you
    * set up your own error handlers in the png_create_read_struct() earlier.
    */

   if (setjmp(png_jmpbuf(png_ptr)))
   {
      /* Free all of the memory associated with the png_ptr and info_ptr */
      png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
      fclose(fp);
      /* If we get here, we had a problem reading the file */
      return (ERROR);
   }

   /* One of the following I/O initialization methods is REQUIRED */
#ifdef streams /* PNG file I/O method 1 */
   /* Set up the input control if you are using standard C streams */
   png_init_io(png_ptr, fp);

#else no_streams /* PNG file I/O method 2 */
   /* If you are using replacement read functions, instead of calling
    * png_init_io() here you would call:
    */
   png_set_read_fn(png_ptr, (void *)user_io_ptr, user_read_fn);
   /* where user_io_ptr is a structure you want available to the callbacks */
#endif no_streams /* Use only one I/O method! */

   /* If we have already read some of the signature */
   png_set_sig_bytes(png_ptr, sig_read);

#ifdef hilevel
   /*
    * If you have enough memory to read in the entire image at once,
    * and you need to specify only transforms that can be controlled
    * with one of the PNG_TRANSFORM_* bits (this presently excludes
    * quantizing, filling, setting background, and doing gamma
    * adjustment), then you can read the entire image (including
    * pixels) into the info structure with this call:
    */
   png_read_png(png_ptr, info_ptr, png_transforms, NULL);

#else
   /* OK, you're doing it the hard way, with the lower-level functions */

   /* The call to png_read_info() gives us all of the information from the
    * PNG file before the first IDAT (image data chunk).  REQUIRED
    */
   png_read_info(png_ptr, info_ptr);

   png_get_IHDR(png_ptr, info_ptr, &width, &height, &bit_depth, &color_type,
       &interlace_type, NULL, NULL);

   /* Set up the data transformations you want.  Note that these are all
    * optional.  Only call them if you want/need them.  Many of the
    * transformations only work on specific types of images, and many
    * are mutually exclusive.
    */

   /* Tell libpng to strip 16 bits/color files down to 8 bits/color.
    * Use accurate scaling if it's available, otherwise just chop off the
    * low byte.
    */
#ifdef PNG_READ_SCALE_16_TO_8_SUPPORTED
    png_set_scale_16(png_ptr);
#else
   png_set_strip_16(png_ptr);
#endif

   /* Strip alpha bytes from the input data without combining with the
    * background (not recommended).
    */
   png_set_strip_alpha(png_ptr);

   /* Extract multiple pixels with bit depths of 1, 2, and 4 from a single
    * byte into separate bytes (useful for paletted and grayscale images).
    */
   png_set_packing(png_ptr);

   /* Change the order of packed pixels to least significant bit first
    * (not useful if you are using png_set_packing). */
   png_set_packswap(png_ptr);

   /* Expand paletted colors into true RGB triplets */
   if (color_type == PNG_COLOR_TYPE_PALETTE)
      png_set_palette_to_rgb(png_ptr);

   /* Expand grayscale images to the full 8 bits from 1, 2, or 4 bits/pixel */
   if (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8)
      png_set_expand_gray_1_2_4_to_8(png_ptr);

   /* Expand paletted or RGB images with transparency to full alpha channels
    * so the data will be available as RGBA quartets.
    */
   if (png_get_valid(png_ptr, info_ptr, PNG_INFO_tRNS) != 0)
      png_set_tRNS_to_alpha(png_ptr);

   /* Set the background color to draw transparent and alpha images over.
    * It is possible to set the red, green, and blue components directly
    * for paletted images instead of supplying a palette index.  Note that
    * even if the PNG file supplies a background, you are not required to
    * use it - you should use the (solid) application background if it has one.
    */

   png_color_16 my_background, *image_background;

   if (png_get_bKGD(png_ptr, info_ptr, &image_background) != 0)
      png_set_background(png_ptr, image_background,
                         PNG_BACKGROUND_GAMMA_FILE, 1, 1.0);
   else
      png_set_background(png_ptr, &my_background,
                         PNG_BACKGROUND_GAMMA_SCREEN, 0, 1.0);

   /* Some suggestions as to how to get a screen gamma value
    *
    * Note that screen gamma is the display_exponent, which includes
    * the CRT_exponent and any correction for viewing conditions
    */
   if (/* We have a user-defined screen gamma value */)
   {
      screen_gamma = user-defined screen_gamma;
   }
   /* This is one way that applications share the same screen gamma value */
   else if ((gamma_str = getenv("SCREEN_GAMMA")) != NULL)
   {
      screen_gamma = atof(gamma_str);
   }
   /* If we don't have another value */
   else
   {
      screen_gamma = PNG_DEFAULT_sRGB;  /* A good guess for a PC monitor
                                           in a dimly lit room */
      screen_gamma = PNG_GAMMA_MAC_18 or 1.0; /* Good guesses for Mac systems */
   }

   /* Tell libpng to handle the gamma conversion for you.  The final call
    * is a good guess for PC generated images, but it should be configurable
    * by the user at run time by the user.  It is strongly suggested that
    * your application support gamma correction.
    */

   int intent;

   if (png_get_sRGB(png_ptr, info_ptr, &intent) != 0)
      png_set_gamma(png_ptr, screen_gamma, PNG_DEFAULT_sRGB);
   else
   {
      double image_gamma;
      if (png_get_gAMA(png_ptr, info_ptr, &image_gamma) != 0)
         png_set_gamma(png_ptr, screen_gamma, image_gamma);
      else
         png_set_gamma(png_ptr, screen_gamma, 0.45455);
   }

#ifdef PNG_READ_QUANTIZE_SUPPORTED
   /* Quantize RGB files down to 8-bit palette or reduce palettes
    * to the number of colors available on your screen.
    */
   if ((color_type & PNG_COLOR_MASK_COLOR) != 0)
   {
      int num_palette;
      png_colorp palette;

      /* This reduces the image to the application supplied palette */
      if (/* We have our own palette */)
      {
         /* An array of colors to which the image should be quantized */
         png_color std_color_cube[MAX_SCREEN_COLORS];

         png_set_quantize(png_ptr, std_color_cube, MAX_SCREEN_COLORS,
            MAX_SCREEN_COLORS, NULL, 0);
      }
      /* This reduces the image to the palette supplied in the file */
      else if (png_get_PLTE(png_ptr, info_ptr, &palette, &num_palette) != 0)
      {
         png_uint_16p histogram = NULL;

         png_get_hIST(png_ptr, info_ptr, &histogram);

         png_set_quantize(png_ptr, palette, num_palette,
                        max_screen_colors, histogram, 0);
      }
   }
#endif /* READ_QUANTIZE */

   /* Invert monochrome files to have 0 as white and 1 as black */
   png_set_invert_mono(png_ptr);

   /* If you want to shift the pixel values from the range [0,255] or
    * [0,65535] to the original [0,7] or [0,31], or whatever range the
    * colors were originally in:
    */
   if (png_get_valid(png_ptr, info_ptr, PNG_INFO_sBIT) != 0)
   {
      png_color_8p sig_bit_p;

      png_get_sBIT(png_ptr, info_ptr, &sig_bit_p);
      png_set_shift(png_ptr, sig_bit_p);
   }

   /* Flip the RGB pixels to BGR (or RGBA to BGRA) */
   if ((color_type & PNG_COLOR_MASK_COLOR) != 0)
      png_set_bgr(png_ptr);

   /* Swap the RGBA or GA data to ARGB or AG (or BGRA to ABGR) */
   png_set_swap_alpha(png_ptr);

   /* Swap bytes of 16-bit files to least significant byte first */
   png_set_swap(png_ptr);

   /* Add filler (or alpha) byte (before/after each RGB triplet) */
   png_set_filler(png_ptr, 0xffff, PNG_FILLER_AFTER);

#ifdef PNG_READ_INTERLACING_SUPPORTED
   /* Turn on interlace handling.  REQUIRED if you are not using
    * png_read_image().  To see how to handle interlacing passes,
    * see the png_read_row() method below:
    */
   number_passes = png_set_interlace_handling(png_ptr);
#else
   number_passes = 1;
#endif /* READ_INTERLACING */


   /* Optional call to gamma correct and add the background to the palette
    * and update info structure.  REQUIRED if you are expecting libpng to
    * update the palette for you (ie you selected such a transform above).
    */
   png_read_update_info(png_ptr, info_ptr);

   /* Allocate the memory to hold the image using the fields of info_ptr. */

   /* The easiest way to read the image: */
   png_bytep row_pointers[height];

   /* Clear the pointer array */
   for (row = 0; row < height; row++)
      row_pointers[row] = NULL;

   for (row = 0; row < height; row++)
      row_pointers[row] = png_malloc(png_ptr, png_get_rowbytes(png_ptr,
         info_ptr));

   /* Now it's time to read the image.  One of these methods is REQUIRED */
#ifdef entire /* Read the entire image in one go */
   png_read_image(png_ptr, row_pointers);

#else no_entire /* Read the image one or more scanlines at a time */
   /* The other way to read images - deal with interlacing: */

   for (pass = 0; pass < number_passes; pass++)
   {
#ifdef single /* Read the image a single row at a time */
      for (y = 0; y < height; y++)
      {
         png_read_rows(png_ptr, &row_pointers[y], NULL, 1);
      }

#else no_single /* Read the image several rows at a time */
      for (y = 0; y < height; y += number_of_rows)
      {
#ifdef sparkle /* Read the image using the "sparkle" effect. */
         png_read_rows(png_ptr, &row_pointers[y], NULL,
            number_of_rows);
#else no_sparkle /* Read the image using the "rectangle" effect */
         png_read_rows(png_ptr, NULL, &row_pointers[y],
            number_of_rows);
#endif no_sparkle /* Use only one of these two methods */
      }

      /* If you want to display the image after every pass, do so here */
#endif no_single /* Use only one of these two methods */
   }
#endif no_entire /* Use only one of these two methods */

   /* Read rest of file, and get additional chunks in info_ptr - REQUIRED */
   png_read_end(png_ptr, info_ptr);
#endif hilevel

   /* At this point you have read the entire image */

   /* Clean up after the read, and free any memory allocated - REQUIRED */
   png_destroy_read_struct(&png_ptr, &info_ptr, NULL);

   /* Close the file */
   fclose(fp);

   /* That's it */
   return (OK);
}

/* Progressively read a file */

int
initialize_png_reader(png_structp *png_ptr, png_infop *info_ptr)
{
   /* Create and initialize the png_struct with the desired error handler
    * functions.  If you want to use the default stderr and longjump method,
    * you can supply NULL for the last three parameters.  We also check that
    * the library version is compatible in case we are using dynamically
    * linked libraries.
    */
   *png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING,
       png_voidp user_error_ptr, user_error_fn, user_warning_fn);

   if (*png_ptr == NULL)
   {
      *info_ptr = NULL;
      return (ERROR);
   }

   *info_ptr = png_create_info_struct(png_ptr);

   if (*info_ptr == NULL)
   {
      png_destroy_read_struct(png_ptr, info_ptr, NULL);
      return (ERROR);
   }

   if (setjmp(png_jmpbuf((*png_ptr))))
   {
      png_destroy_read_struct(png_ptr, info_ptr, NULL);
      return (ERROR);
   }

   /* This one's new.  You will need to provide all three
    * function callbacks, even if you aren't using them all.
    * If you aren't using all functions, you can specify NULL
    * parameters.  Even when all three functions are NULL,
    * you need to call png_set_progressive_read_fn().
    * These functions shouldn't be dependent on global or
    * static variables if you are decoding several images
    * simultaneously.  You should store stream specific data
    * in a separate struct, given as the second parameter,
    * and retrieve the pointer from inside the callbacks using
    * the function png_get_progressive_ptr(png_ptr).
    */
   png_set_progressive_read_fn(*png_ptr, (void *)stream_data,
      info_callback, row_callback, end_callback);

   return (OK);
}

int
process_data(png_structp *png_ptr, png_infop *info_ptr,
   png_bytep buffer, png_uint_32 length)
{
   if (setjmp(png_jmpbuf((*png_ptr))))
   {
      /* Free the png_ptr and info_ptr memory on error */
      png_destroy_read_struct(png_ptr, info_ptr, NULL);
      return (ERROR);
   }

   /* This one's new also.  Simply give it chunks of data as
    * they arrive from the data stream (in order, of course).
    * On segmented machines, don't give it any more than 64K.
    * The library seems to run fine with sizes of 4K, although
    * you can give it much less if necessary (I assume you can
    * give it chunks of 1 byte, but I haven't tried with less
    * than 256 bytes yet).  When this function returns, you may
    * want to display any rows that were generated in the row
    * callback, if you aren't already displaying them there.
    */
   png_process_data(*png_ptr, *info_ptr, buffer, length);
   return (OK);
}

info_callback(png_structp png_ptr, png_infop info)
{
   /* Do any setup here, including setting any of the transformations
    * mentioned in the Reading PNG files section.  For now, you _must_
    * call either png_start_read_image() or png_read_update_info()
    * after all the transformations are set (even if you don't set
    * any).  You may start getting rows before png_process_data()
    * returns, so this is your last chance to prepare for that.
    */
}

row_callback(png_structp png_ptr, png_bytep new_row,
   png_uint_32 row_num, int pass)
{
   /*
    * This function is called for every row in the image.  If the
    * image is interlaced, and you turned on the interlace handler,
    * this function will be called for every row in every pass.
    *
    * In this function you will receive a pointer to new row data from
    * libpng called new_row that is to replace a corresponding row (of
    * the same data format) in a buffer allocated by your application.
    *
    * The new row data pointer "new_row" may be NULL, indicating there is
    * no new data to be replaced (in cases of interlace loading).
    *
    * If new_row is not NULL then you need to call
    * png_progressive_combine_row() to replace the corresponding row as
    * shown below:
    */

   /* Get pointer to corresponding row in our
    * PNG read buffer.
    */
   png_bytep old_row = ((png_bytep *)our_data)[row_num];

#ifdef PNG_READ_INTERLACING_SUPPORTED
   /* If both rows are allocated then copy the new row
    * data to the corresponding row data.
    */
   if ((old_row != NULL) && (new_row != NULL))
   png_progressive_combine_row(png_ptr, old_row, new_row);

   /*
    * The rows and passes are called in order, so you don't really
    * need the row_num and pass, but I'm supplying them because it
    * may make your life easier.
    *
    * For the non-NULL rows of interlaced images, you must call
    * png_progressive_combine_row() passing in the new row and the
    * old row, as demonstrated above.  You can call this function for
    * NULL rows (it will just return) and for non-interlaced images
    * (it just does the memcpy for you) if it will make the code
    * easier.  Thus, you can just do this for all cases:
    */

   png_progressive_combine_row(png_ptr, old_row, new_row);

   /* where old_row is what was displayed for previous rows.  Note
    * that the first pass (pass == 0 really) will completely cover
    * the old row, so the rows do not have to be initialized.  After
    * the first pass (and only for interlaced images), you will have
    * to pass the current row as new_row, and the function will combine
    * the old row and the new row.
    */
#endif /* READ_INTERLACING */
}

end_callback(png_structp png_ptr, png_infop info)
{
   /* This function is called when the whole image has been read,
    * including any chunks after the image (up to and including
    * the IEND).  You will usually have the same info chunk as you
    * had in the header, although some data may have been added
    * to the comments and time fields.
    *
    * Most people won't do much here, perhaps setting a flag that
    * marks the image as finished.
    */
}

/* Write a png file */
void write_png(char *file_name /* , ... other image information ... */)
{
   FILE *fp;
   png_structp png_ptr;
   png_infop info_ptr;
   png_colorp palette;

   /* Open the file */
   fp = fopen(file_name, "wb");
   if (fp == NULL)
      return (ERROR);

   /* Create and initialize the png_struct with the desired error handler
    * functions.  If you want to use the default stderr and longjump method,
    * you can supply NULL for the last three parameters.  We also check that
    * the library version is compatible with the one used at compile time,
    * in case we are using dynamically linked libraries.  REQUIRED.
    */
   png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING,
      png_voidp user_error_ptr, user_error_fn, user_warning_fn);

   if (png_ptr == NULL)
   {
      fclose(fp);
      return (ERROR);
   }

   /* Allocate/initialize the image information data.  REQUIRED */
   info_ptr = png_create_info_struct(png_ptr);
   if (info_ptr == NULL)
   {
      fclose(fp);
      png_destroy_write_struct(&png_ptr,  NULL);
      return (ERROR);
   }

   /* Set error handling.  REQUIRED if you aren't supplying your own
    * error handling functions in the png_create_write_struct() call.
    */
   if (setjmp(png_jmpbuf(png_ptr)))
   {
      /* If we get here, we had a problem writing the file */
      fclose(fp);
      png_destroy_write_struct(&png_ptr, &info_ptr);
      return (ERROR);
   }

   /* One of the following I/O initialization functions is REQUIRED */

#ifdef streams /* I/O initialization method 1 */
   /* Set up the output control if you are using standard C streams */
   png_init_io(png_ptr, fp);

#else no_streams /* I/O initialization method 2 */
   /* If you are using replacement write functions, instead of calling
    * png_init_io() here you would call
    */
   png_set_write_fn(png_ptr, (void *)user_io_ptr, user_write_fn,
      user_IO_flush_function);
   /* where user_io_ptr is a structure you want available to the callbacks */
#endif no_streams /* Only use one initialization method */

#ifdef hilevel
   /* This is the easy way.  Use it if you already have all the
    * image info living in the structure.  You could "|" many
    * PNG_TRANSFORM flags into the png_transforms integer here.
    */
   png_write_png(png_ptr, info_ptr, png_transforms, NULL);

#else
   /* This is the hard way */

   /* Set the image information here.  Width and height are up to 2^31,
    * bit_depth is one of 1, 2, 4, 8, or 16, but valid values also depend on
    * the color_type selected. color_type is one of PNG_COLOR_TYPE_GRAY,
    * PNG_COLOR_TYPE_GRAY_ALPHA, PNG_COLOR_TYPE_PALETTE, PNG_COLOR_TYPE_RGB,
    * or PNG_COLOR_TYPE_RGB_ALPHA.  interlace is either PNG_INTERLACE_NONE or
    * PNG_INTERLACE_ADAM7, and the compression_type and filter_type MUST
    * currently be PNG_COMPRESSION_TYPE_BASE and PNG_FILTER_TYPE_BASE. REQUIRED
    */
   png_set_IHDR(png_ptr, info_ptr, width, height, bit_depth, PNG_COLOR_TYPE_???,
      PNG_INTERLACE_????, PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);

   /* Set the palette if there is one.  REQUIRED for indexed-color images */
   palette = (png_colorp)png_malloc(png_ptr, PNG_MAX_PALETTE_LENGTH
             * (sizeof (png_color)));
   /* ... Set palette colors ... */
   png_set_PLTE(png_ptr, info_ptr, palette, PNG_MAX_PALETTE_LENGTH);
   /* You must not free palette here, because png_set_PLTE only makes a link to
    * the palette that you malloced.  Wait until you are about to destroy
    * the png structure.
    */

   /* Optional significant bit (sBIT) chunk */
   png_color_8 sig_bit;

   /* If we are dealing with a grayscale image then */
   sig_bit.gray = true_bit_depth;

   /* Otherwise, if we are dealing with a color image then */
   sig_bit.red = true_red_bit_depth;
   sig_bit.green = true_green_bit_depth;
   sig_bit.blue = true_blue_bit_depth;

   /* If the image has an alpha channel then */
   sig_bit.alpha = true_alpha_bit_depth;

   png_set_sBIT(png_ptr, info_ptr, &sig_bit);


   /* Optional gamma chunk is strongly suggested if you have any guess
    * as to the correct gamma of the image.
    */
   png_set_gAMA(png_ptr, info_ptr, gamma);

   /* Optionally write comments into the image */
   {
      png_text text_ptr[3];

      char key0[]="Title";
      char text0[]="Mona Lisa";
      text_ptr[0].key = key0;
      text_ptr[0].text = text0;
      text_ptr[0].compression = PNG_TEXT_COMPRESSION_NONE;
      text_ptr[0].itxt_length = 0;
      text_ptr[0].lang = NULL;
      text_ptr[0].lang_key = NULL;

      char key1[]="Author";
      char text1[]="Leonardo DaVinci";
      text_ptr[1].key = key1;
      text_ptr[1].text = text1;
      text_ptr[1].compression = PNG_TEXT_COMPRESSION_NONE;
      text_ptr[1].itxt_length = 0;
      text_ptr[1].lang = NULL;
      text_ptr[1].lang_key = NULL;

      char key2[]="Description";
      char text2[]="<long text>";
      text_ptr[2].key = key2;
      text_ptr[2].text = text2;
      text_ptr[2].compression = PNG_TEXT_COMPRESSION_zTXt;
      text_ptr[2].itxt_length = 0;
      text_ptr[2].lang = NULL;
      text_ptr[2].lang_key = NULL;

      png_set_text(write_ptr, write_info_ptr, text_ptr, 3);
   }

   /* Other optional chunks like cHRM, bKGD, tRNS, tIME, oFFs, pHYs */

   /* Note that if sRGB is present the gAMA and cHRM chunks must be ignored
    * on read and, if your application chooses to write them, they must
    * be written in accordance with the sRGB profile
    */

   /* Write the file header information.  REQUIRED */
   png_write_info(png_ptr, info_ptr);

   /* If you want, you can write the info in two steps, in case you need to
    * write your private chunk ahead of PLTE:
    *
    *   png_write_info_before_PLTE(write_ptr, write_info_ptr);
    *   write_my_chunk();
    *   png_write_info(png_ptr, info_ptr);
    *
    * However, given the level of known- and unknown-chunk support in 1.2.0
    * and up, this should no longer be necessary.
    */

   /* Once we write out the header, the compression type on the text
    * chunk gets changed to PNG_TEXT_COMPRESSION_NONE_WR or
    * PNG_TEXT_COMPRESSION_zTXt_WR, so it doesn't get written out again
    * at the end.
    */

   /* Set up the transformations you want.  Note that these are
    * all optional.  Only call them if you want them.
    */

   /* Invert monochrome pixels */
   png_set_invert_mono(png_ptr);

   /* Shift the pixels up to a legal bit depth and fill in
    * as appropriate to correctly scale the image.
    */
   png_set_shift(png_ptr, &sig_bit);

   /* Pack pixels into bytes */
   png_set_packing(png_ptr);

   /* Swap location of alpha bytes from ARGB to RGBA */
   png_set_swap_alpha(png_ptr);

   /* Get rid of filler (OR ALPHA) bytes, pack XRGB/RGBX/ARGB/RGBA into
    * RGB (4 channels -> 3 channels). The second parameter is not used.
    */
   png_set_filler(png_ptr, 0, PNG_FILLER_BEFORE);

   /* Flip BGR pixels to RGB */
   png_set_bgr(png_ptr);

   /* Swap bytes of 16-bit files to most significant byte first */
   png_set_swap(png_ptr);

   /* Swap bits of 1-bit, 2-bit, 4-bit packed pixel formats */
   png_set_packswap(png_ptr);

   /* Turn on interlace handling if you are not using png_write_image() */
   if (interlacing != 0)
      number_passes = png_set_interlace_handling(png_ptr);

   else
      number_passes = 1;

   /* The easiest way to write the image (you may have a different memory
    * layout, however, so choose what fits your needs best).  You need to
    * use the first method if you aren't handling interlacing yourself.
    */
   png_uint_32 k, height, width;

   /* In this example, "image" is a one-dimensional array of bytes */
   png_byte image[height*width*bytes_per_pixel];

   png_bytep row_pointers[height];

   if (height > PNG_UINT_32_MAX/(sizeof (png_bytep)))
     png_error (png_ptr, "Image is too tall to process in memory");

   /* Set up pointers into your "image" byte array */
   for (k = 0; k < height; k++)
     row_pointers[k] = image + k*width*bytes_per_pixel;

   /* One of the following output methods is REQUIRED */

#ifdef entire /* Write out the entire image data in one call */
   png_write_image(png_ptr, row_pointers);

   /* The other way to write the image - deal with interlacing */

#else no_entire /* Write out the image data by one or more scanlines */

   /* The number of passes is either 1 for non-interlaced images,
    * or 7 for interlaced images.
    */
   for (pass = 0; pass < number_passes; pass++)
   {
      /* Write a few rows at a time. */
      png_write_rows(png_ptr, &row_pointers[first_row], number_of_rows);

      /* If you are only writing one row at a time, this works */
      for (y = 0; y < height; y++)
         png_write_rows(png_ptr, &row_pointers[y], 1);
   }
#endif no_entire /* Use only one output method */

   /* You can write optional chunks like tEXt, zTXt, and tIME at the end
    * as well.  Shouldn't be necessary in 1.2.0 and up as all the public
    * chunks are supported and you can use png_set_unknown_chunks() to
    * register unknown chunks into the info structure to be written out.
    */

   /* It is REQUIRED to call this to finish writing the rest of the file */
   png_write_end(png_ptr, info_ptr);
#endif hilevel

   /* If you png_malloced a palette, free it here (don't free info_ptr->palette,
    * as recommended in versions 1.0.5m and earlier of this example; if
    * libpng mallocs info_ptr->palette, libpng will free it).  If you
    * allocated it with malloc() instead of png_malloc(), use free() instead
    * of png_free().
    */
   png_free(png_ptr, palette);
   palette = NULL;

   /* Similarly, if you png_malloced any data that you passed in with
    * png_set_something(), such as a hist or trans array, free it here,
    * when you can be sure that libpng is through with it.
    */
   png_free(png_ptr, trans);
   trans = NULL;
   /* Whenever you use png_free() it is a good idea to set the pointer to
    * NULL in case your application inadvertently tries to png_free() it
    * again.  When png_free() sees a NULL it returns without action, thus
    * avoiding the double-free security problem.
    */

   /* Clean up after the write, and free any memory allocated */
   png_destroy_write_struct(&png_ptr, &info_ptr);

   /* Close the file */
   fclose(fp);

   /* That's it */
   return (OK);
}

#endif /* if 0 */
