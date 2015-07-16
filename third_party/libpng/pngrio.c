
/* pngrio.c - functions for data input
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
 * This file provides a location for all input.  Users who need
 * special handling are expected to write a function that has the same
 * arguments as this and performs a similar function, but that possibly
 * has a different input method.  Note that you shouldn't change this
 * function, but rather write a replacement function and then make
 * libpng use it at run time with png_set_read_fn(...).
 */

#define PNG_INTERNAL
#define PNG_NO_PEDANTIC_WARNINGS
#include "png.h"
#ifdef PNG_READ_SUPPORTED

/* Read the data from whatever input you are using.  The default routine
 * reads from a file pointer.  Note that this routine sometimes gets called
 * with very small lengths, so you should implement some kind of simple
 * buffering if you are using unbuffered reads.  This should never be asked
 * to read more then 64K on a 16 bit machine.
 */
void /* PRIVATE */
png_read_data(png_structp png_ptr, png_bytep data, png_size_t length)
{
   png_debug1(4, "reading %d bytes", (int)length);
 
   if (png_ptr->read_data_fn != NULL)
      (*(png_ptr->read_data_fn))(png_ptr, data, length);
   else
      png_error(png_ptr, "Call to NULL read function");
}

#ifdef PNG_STDIO_SUPPORTED
/* This is the function that does the actual reading of data.  If you are
 * not reading from a standard C stream, you should create a replacement
 * read_data function and use it at run time with png_set_read_fn(), rather
 * than changing the library.
 */
#ifndef USE_FAR_KEYWORD
void PNGAPI
png_default_read_data(png_structp png_ptr, png_bytep data, png_size_t length)
{
   png_size_t check;

   if (png_ptr == NULL)
      return;
   /* fread() returns 0 on error, so it is OK to store this in a png_size_t
    * instead of an int, which is what fread() actually returns.
    */
#ifdef _WIN32_WCE
   if ( !ReadFile((HANDLE)(png_ptr->io_ptr), data, length, &check, NULL) )
      check = 0;
#else
   check = (png_size_t)fread(data, (png_size_t)1, length,
      (png_FILE_p)png_ptr->io_ptr);
#endif

   if (check != length)
      png_error(png_ptr, "Read Error");
}
#else
/* This is the model-independent version. Since the standard I/O library
   can't handle far buffers in the medium and small models, we have to copy
   the data.
*/

#define NEAR_BUF_SIZE 1024
#define MIN(a,b) (a <= b ? a : b)

static void PNGAPI
png_default_read_data(png_structp png_ptr, png_bytep data, png_size_t length)
{
   int check;
   png_byte *n_data;
   png_FILE_p io_ptr;

   if (png_ptr == NULL)
      return;
   /* Check if data really is near. If so, use usual code. */
   n_data = (png_byte *)CVT_PTR_NOCHECK(data);
   io_ptr = (png_FILE_p)CVT_PTR(png_ptr->io_ptr);
   if ((png_bytep)n_data == data)
   {
#ifdef _WIN32_WCE
      if ( !ReadFile((HANDLE)(png_ptr->io_ptr), data, length, &check,
          NULL) )
         check = 0;
#else
      check = fread(n_data, 1, length, io_ptr);
#endif
   }
   else
   {
      png_byte buf[NEAR_BUF_SIZE];
      png_size_t read, remaining, err;
      check = 0;
      remaining = length;
      do
      {
         read = MIN(NEAR_BUF_SIZE, remaining);
#ifdef _WIN32_WCE
         if ( !ReadFile((HANDLE)(io_ptr), buf, read, &err, NULL) )
            err = 0;
#else
         err = fread(buf, (png_size_t)1, read, io_ptr);
#endif
         png_memcpy(data, buf, read); /* copy far buffer to near buffer */
         if (err != read)
            break;
         else
            check += err;
         data += read;
         remaining -= read;
      }
      while (remaining != 0);
   }
   if ((png_uint_32)check != (png_uint_32)length)
      png_error(png_ptr, "read Error");
}
#endif
#endif

/* This function allows the application to supply a new input function
 * for libpng if standard C streams aren't being used.
 *
 * This function takes as its arguments:
 * png_ptr      - pointer to a png input data structure
 * io_ptr       - pointer to user supplied structure containing info about
 *                the input functions.  May be NULL.
 * read_data_fn - pointer to a new input function that takes as its
 *                arguments a pointer to a png_struct, a pointer to
 *                a location where input data can be stored, and a 32-bit
 *                unsigned int that is the number of bytes to be read.
 *                To exit and output any fatal error messages the new write
 *                function should call png_error(png_ptr, "Error msg").
 *                May be NULL, in which case libpng's default function will
 *                be used.
 */
void PNGAPI
png_set_read_fn(png_structp png_ptr, png_voidp io_ptr,
   png_rw_ptr read_data_fn)
{
   if (png_ptr == NULL)
      return;
   png_ptr->io_ptr = io_ptr;

#ifdef PNG_STDIO_SUPPORTED
   if (read_data_fn != NULL)
      png_ptr->read_data_fn = read_data_fn;
   else
      png_ptr->read_data_fn = png_default_read_data;
#else
   png_ptr->read_data_fn = read_data_fn;
#endif

   /* It is an error to write to a read device */
   if (png_ptr->write_data_fn != NULL)
   {
      png_ptr->write_data_fn = NULL;
      png_warning(png_ptr,
         "It's an error to set both read_data_fn and write_data_fn in the ");
      png_warning(png_ptr,
         "same structure.  Resetting write_data_fn to NULL.");
   }

#ifdef PNG_WRITE_FLUSH_SUPPORTED
   png_ptr->output_flush_fn = NULL;
#endif
}
#endif /* PNG_READ_SUPPORTED */
