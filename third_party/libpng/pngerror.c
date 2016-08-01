
/* pngerror.c - stub functions for i/o and memory allocation
 *
 * Last changed in libpng 1.6.15 [November 20, 2014]
 * Copyright (c) 1998-2002,2004,2006-2014 Glenn Randers-Pehrson
 * (Version 0.96 Copyright (c) 1996, 1997 Andreas Dilger)
 * (Version 0.88 Copyright (c) 1995, 1996 Guy Eric Schalnat, Group 42, Inc.)
 *
 * This code is released under the libpng license.
 * For conditions of distribution and use, see the disclaimer
 * and license in png.h
 *
 * This file provides a location for all error handling.  Users who
 * need special error handling are expected to write replacement functions
 * and use png_set_error_fn() to use those functions.  See the instructions
 * at each function.
 */

#include "pngpriv.h"

#if defined(PNG_READ_SUPPORTED) || defined(PNG_WRITE_SUPPORTED)

static PNG_FUNCTION(void, png_default_error,PNGARG((png_const_structrp png_ptr,
    png_const_charp error_message)),PNG_NORETURN);

#ifdef PNG_WARNINGS_SUPPORTED
static void /* PRIVATE */
png_default_warning PNGARG((png_const_structrp png_ptr,
   png_const_charp warning_message));
#endif /* WARNINGS */

/* This function is called whenever there is a fatal error.  This function
 * should not be changed.  If there is a need to handle errors differently,
 * you should supply a replacement error function and use png_set_error_fn()
 * to replace the error function at run-time.
 */
#ifdef PNG_ERROR_TEXT_SUPPORTED
PNG_FUNCTION(void,PNGAPI
png_error,(png_const_structrp png_ptr, png_const_charp error_message),
   PNG_NORETURN)
{
#ifdef PNG_ERROR_NUMBERS_SUPPORTED
   char msg[16];
   if (png_ptr != NULL)
   {
      if ((png_ptr->flags &
         (PNG_FLAG_STRIP_ERROR_NUMBERS|PNG_FLAG_STRIP_ERROR_TEXT)) != 0
      {
         if (*error_message == PNG_LITERAL_SHARP)
         {
            /* Strip "#nnnn " from beginning of error message. */
            int offset;
            for (offset = 1; offset<15; offset++)
               if (error_message[offset] == ' ')
                  break;

            if ((png_ptr->flags & PNG_FLAG_STRIP_ERROR_TEXT) != 0)
            {
               int i;
               for (i = 0; i < offset - 1; i++)
                  msg[i] = error_message[i + 1];
               msg[i - 1] = '\0';
               error_message = msg;
            }

            else
               error_message += offset;
      }

      else
      {
         if ((png_ptr->flags & PNG_FLAG_STRIP_ERROR_TEXT) != 0)
         {
            msg[0] = '0';
            msg[1] = '\0';
            error_message = msg;
         }
       }
     }
   }
#endif
   if (png_ptr != NULL && png_ptr->error_fn != NULL)
      (*(png_ptr->error_fn))(png_constcast(png_structrp,png_ptr),
          error_message);

   /* If the custom handler doesn't exist, or if it returns,
      use the default handler, which will not return. */
   png_default_error(png_ptr, error_message);
}
#else
PNG_FUNCTION(void,PNGAPI
png_err,(png_const_structrp png_ptr),PNG_NORETURN)
{
   /* Prior to 1.5.2 the error_fn received a NULL pointer, expressed
    * erroneously as '\0', instead of the empty string "".  This was
    * apparently an error, introduced in libpng-1.2.20, and png_default_error
    * will crash in this case.
    */
   if (png_ptr != NULL && png_ptr->error_fn != NULL)
      (*(png_ptr->error_fn))(png_constcast(png_structrp,png_ptr), "");

   /* If the custom handler doesn't exist, or if it returns,
      use the default handler, which will not return. */
   png_default_error(png_ptr, "");
}
#endif /* ERROR_TEXT */

/* Utility to safely appends strings to a buffer.  This never errors out so
 * error checking is not required in the caller.
 */
size_t
png_safecat(png_charp buffer, size_t bufsize, size_t pos,
   png_const_charp string)
{
   if (buffer != NULL && pos < bufsize)
   {
      if (string != NULL)
         while (*string != '\0' && pos < bufsize-1)
           buffer[pos++] = *string++;

      buffer[pos] = '\0';
   }

   return pos;
}

#if defined(PNG_WARNINGS_SUPPORTED) || defined(PNG_TIME_RFC1123_SUPPORTED)
/* Utility to dump an unsigned value into a buffer, given a start pointer and
 * and end pointer (which should point just *beyond* the end of the buffer!)
 * Returns the pointer to the start of the formatted string.
 */
png_charp
png_format_number(png_const_charp start, png_charp end, int format,
   png_alloc_size_t number)
{
   int count = 0;    /* number of digits output */
   int mincount = 1; /* minimum number required */
   int output = 0;   /* digit output (for the fixed point format) */

   *--end = '\0';

   /* This is written so that the loop always runs at least once, even with
    * number zero.
    */
   while (end > start && (number != 0 || count < mincount))
   {

      static const char digits[] = "0123456789ABCDEF";

      switch (format)
      {
         case PNG_NUMBER_FORMAT_fixed:
            /* Needs five digits (the fraction) */
            mincount = 5;
            if (output != 0 || number % 10 != 0)
            {
               *--end = digits[number % 10];
               output = 1;
            }
            number /= 10;
            break;

         case PNG_NUMBER_FORMAT_02u:
            /* Expects at least 2 digits. */
            mincount = 2;
            /* FALL THROUGH */

         case PNG_NUMBER_FORMAT_u:
            *--end = digits[number % 10];
            number /= 10;
            break;

         case PNG_NUMBER_FORMAT_02x:
            /* This format expects at least two digits */
            mincount = 2;
            /* FALL THROUGH */

         case PNG_NUMBER_FORMAT_x:
            *--end = digits[number & 0xf];
            number >>= 4;
            break;

         default: /* an error */
            number = 0;
            break;
      }

      /* Keep track of the number of digits added */
      ++count;

      /* Float a fixed number here: */
      if ((format == PNG_NUMBER_FORMAT_fixed) && (count == 5) && (end > start))
      {
         /* End of the fraction, but maybe nothing was output?  In that case
          * drop the decimal point.  If the number is a true zero handle that
          * here.
          */
         if (output != 0)
            *--end = '.';
         else if (number == 0) /* and !output */
            *--end = '0';
      }
   }

   return end;
}
#endif

#ifdef PNG_WARNINGS_SUPPORTED
/* This function is called whenever there is a non-fatal error.  This function
 * should not be changed.  If there is a need to handle warnings differently,
 * you should supply a replacement warning function and use
 * png_set_error_fn() to replace the warning function at run-time.
 */
void PNGAPI
png_warning(png_const_structrp png_ptr, png_const_charp warning_message)
{
   int offset = 0;
   if (png_ptr != NULL)
   {
#ifdef PNG_ERROR_NUMBERS_SUPPORTED
   if ((png_ptr->flags &
       (PNG_FLAG_STRIP_ERROR_NUMBERS|PNG_FLAG_STRIP_ERROR_TEXT)) != 0)
#endif
      {
         if (*warning_message == PNG_LITERAL_SHARP)
         {
            for (offset = 1; offset < 15; offset++)
               if (warning_message[offset] == ' ')
                  break;
         }
      }
   }
   if (png_ptr != NULL && png_ptr->warning_fn != NULL)
      (*(png_ptr->warning_fn))(png_constcast(png_structrp,png_ptr),
         warning_message + offset);
   else
      png_default_warning(png_ptr, warning_message + offset);
}

/* These functions support 'formatted' warning messages with up to
 * PNG_WARNING_PARAMETER_COUNT parameters.  In the format string the parameter
 * is introduced by @<number>, where 'number' starts at 1.  This follows the
 * standard established by X/Open for internationalizable error messages.
 */
void
png_warning_parameter(png_warning_parameters p, int number,
   png_const_charp string)
{
   if (number > 0 && number <= PNG_WARNING_PARAMETER_COUNT)
      (void)png_safecat(p[number-1], (sizeof p[number-1]), 0, string);
}

void
png_warning_parameter_unsigned(png_warning_parameters p, int number, int format,
   png_alloc_size_t value)
{
   char buffer[PNG_NUMBER_BUFFER_SIZE];
   png_warning_parameter(p, number, PNG_FORMAT_NUMBER(buffer, format, value));
}

void
png_warning_parameter_signed(png_warning_parameters p, int number, int format,
   png_int_32 value)
{
   png_alloc_size_t u;
   png_charp str;
   char buffer[PNG_NUMBER_BUFFER_SIZE];

   /* Avoid overflow by doing the negate in a png_alloc_size_t: */
   u = (png_alloc_size_t)value;
   if (value < 0)
      u = ~u + 1;

   str = PNG_FORMAT_NUMBER(buffer, format, u);

   if (value < 0 && str > buffer)
      *--str = '-';

   png_warning_parameter(p, number, str);
}

void
png_formatted_warning(png_const_structrp png_ptr, png_warning_parameters p,
   png_const_charp message)
{
   /* The internal buffer is just 192 bytes - enough for all our messages,
    * overflow doesn't happen because this code checks!  If someone figures
    * out how to send us a message longer than 192 bytes, all that will
    * happen is that the message will be truncated appropriately.
    */
   size_t i = 0; /* Index in the msg[] buffer: */
   char msg[192];

   /* Each iteration through the following loop writes at most one character
    * to msg[i++] then returns here to validate that there is still space for
    * the trailing '\0'.  It may (in the case of a parameter) read more than
    * one character from message[]; it must check for '\0' and continue to the
    * test if it finds the end of string.
    */
   while (i<(sizeof msg)-1 && *message != '\0')
   {
      /* '@' at end of string is now just printed (previously it was skipped);
       * it is an error in the calling code to terminate the string with @.
       */
      if (p != NULL && *message == '@' && message[1] != '\0')
      {
         int parameter_char = *++message; /* Consume the '@' */
         static const char valid_parameters[] = "123456789";
         int parameter = 0;

         /* Search for the parameter digit, the index in the string is the
          * parameter to use.
          */
         while (valid_parameters[parameter] != parameter_char &&
            valid_parameters[parameter] != '\0')
            ++parameter;

         /* If the parameter digit is out of range it will just get printed. */
         if (parameter < PNG_WARNING_PARAMETER_COUNT)
         {
            /* Append this parameter */
            png_const_charp parm = p[parameter];
            png_const_charp pend = p[parameter] + (sizeof p[parameter]);

            /* No need to copy the trailing '\0' here, but there is no guarantee
             * that parm[] has been initialized, so there is no guarantee of a
             * trailing '\0':
             */
            while (i<(sizeof msg)-1 && *parm != '\0' && parm < pend)
               msg[i++] = *parm++;

            /* Consume the parameter digit too: */
            ++message;
            continue;
         }

         /* else not a parameter and there is a character after the @ sign; just
          * copy that.  This is known not to be '\0' because of the test above.
          */
      }

      /* At this point *message can't be '\0', even in the bad parameter case
       * above where there is a lone '@' at the end of the message string.
       */
      msg[i++] = *message++;
   }

   /* i is always less than (sizeof msg), so: */
   msg[i] = '\0';

   /* And this is the formatted message. It may be larger than
    * PNG_MAX_ERROR_TEXT, but that is only used for 'chunk' errors and these
    * are not (currently) formatted.
    */
   png_warning(png_ptr, msg);
}
#endif /* WARNINGS */

#ifdef PNG_BENIGN_ERRORS_SUPPORTED
void PNGAPI
png_benign_error(png_const_structrp png_ptr, png_const_charp error_message)
{
   if ((png_ptr->flags & PNG_FLAG_BENIGN_ERRORS_WARN) != 0)
   {
#     ifdef PNG_READ_SUPPORTED
         if ((png_ptr->mode & PNG_IS_READ_STRUCT) != 0 &&
            png_ptr->chunk_name != 0)
            png_chunk_warning(png_ptr, error_message);
         else
#     endif
      png_warning(png_ptr, error_message);
   }

   else
   {
#     ifdef PNG_READ_SUPPORTED
         if ((png_ptr->mode & PNG_IS_READ_STRUCT) != 0 &&
            png_ptr->chunk_name != 0)
            png_chunk_error(png_ptr, error_message);
         else
#     endif
      png_error(png_ptr, error_message);
   }

#  ifndef PNG_ERROR_TEXT_SUPPORTED
      PNG_UNUSED(error_message)
#  endif
}

void /* PRIVATE */
png_app_warning(png_const_structrp png_ptr, png_const_charp error_message)
{
  if ((png_ptr->flags & PNG_FLAG_APP_WARNINGS_WARN) != 0)
     png_warning(png_ptr, error_message);
  else
     png_error(png_ptr, error_message);

#  ifndef PNG_ERROR_TEXT_SUPPORTED
      PNG_UNUSED(error_message)
#  endif
}

void /* PRIVATE */
png_app_error(png_const_structrp png_ptr, png_const_charp error_message)
{
  if ((png_ptr->flags & PNG_FLAG_APP_ERRORS_WARN) != 0)
     png_warning(png_ptr, error_message);
  else
     png_error(png_ptr, error_message);

#  ifndef PNG_ERROR_TEXT_SUPPORTED
      PNG_UNUSED(error_message)
#  endif
}
#endif /* BENIGN_ERRORS */

#define PNG_MAX_ERROR_TEXT 196 /* Currently limited by profile_error in png.c */
#if defined(PNG_WARNINGS_SUPPORTED) || \
   (defined(PNG_READ_SUPPORTED) && defined(PNG_ERROR_TEXT_SUPPORTED))
/* These utilities are used internally to build an error message that relates
 * to the current chunk.  The chunk name comes from png_ptr->chunk_name,
 * which is used to prefix the message.  The message is limited in length
 * to 63 bytes. The name characters are output as hex digits wrapped in []
 * if the character is invalid.
 */
#define isnonalpha(c) ((c) < 65 || (c) > 122 || ((c) > 90 && (c) < 97))
static PNG_CONST char png_digit[16] = {
   '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
   'A', 'B', 'C', 'D', 'E', 'F'
};

static void /* PRIVATE */
png_format_buffer(png_const_structrp png_ptr, png_charp buffer, png_const_charp
    error_message)
{
   png_uint_32 chunk_name = png_ptr->chunk_name;
   int iout = 0, ishift = 24;

   while (ishift >= 0)
   {
      int c = (int)(chunk_name >> ishift) & 0xff;

      ishift -= 8;
      if (isnonalpha(c) != 0)
      {
         buffer[iout++] = PNG_LITERAL_LEFT_SQUARE_BRACKET;
         buffer[iout++] = png_digit[(c & 0xf0) >> 4];
         buffer[iout++] = png_digit[c & 0x0f];
         buffer[iout++] = PNG_LITERAL_RIGHT_SQUARE_BRACKET;
      }

      else
      {
         buffer[iout++] = (char)c;
      }
   }

   if (error_message == NULL)
      buffer[iout] = '\0';

   else
   {
      int iin = 0;

      buffer[iout++] = ':';
      buffer[iout++] = ' ';

      while (iin < PNG_MAX_ERROR_TEXT-1 && error_message[iin] != '\0')
         buffer[iout++] = error_message[iin++];

      /* iin < PNG_MAX_ERROR_TEXT, so the following is safe: */
      buffer[iout] = '\0';
   }
}
#endif /* WARNINGS || ERROR_TEXT */

#if defined(PNG_READ_SUPPORTED) && defined(PNG_ERROR_TEXT_SUPPORTED)
PNG_FUNCTION(void,PNGAPI
png_chunk_error,(png_const_structrp png_ptr, png_const_charp error_message),
   PNG_NORETURN)
{
   char msg[18+PNG_MAX_ERROR_TEXT];
   if (png_ptr == NULL)
      png_error(png_ptr, error_message);

   else
   {
      png_format_buffer(png_ptr, msg, error_message);
      png_error(png_ptr, msg);
   }
}
#endif /* READ && ERROR_TEXT */

#ifdef PNG_WARNINGS_SUPPORTED
void PNGAPI
png_chunk_warning(png_const_structrp png_ptr, png_const_charp warning_message)
{
   char msg[18+PNG_MAX_ERROR_TEXT];
   if (png_ptr == NULL)
      png_warning(png_ptr, warning_message);

   else
   {
      png_format_buffer(png_ptr, msg, warning_message);
      png_warning(png_ptr, msg);
   }
}
#endif /* WARNINGS */

#ifdef PNG_READ_SUPPORTED
#ifdef PNG_BENIGN_ERRORS_SUPPORTED
void PNGAPI
png_chunk_benign_error(png_const_structrp png_ptr, png_const_charp
    error_message)
{
   if ((png_ptr->flags & PNG_FLAG_BENIGN_ERRORS_WARN) != 0)
      png_chunk_warning(png_ptr, error_message);

   else
      png_chunk_error(png_ptr, error_message);

#  ifndef PNG_ERROR_TEXT_SUPPORTED
      PNG_UNUSED(error_message)
#  endif
}
#endif
#endif /* READ */

void /* PRIVATE */
png_chunk_report(png_const_structrp png_ptr, png_const_charp message, int error)
{
#  ifndef PNG_WARNINGS_SUPPORTED
      PNG_UNUSED(message)
#  endif

   /* This is always supported, but for just read or just write it
    * unconditionally does the right thing.
    */
#  if defined(PNG_READ_SUPPORTED) && defined(PNG_WRITE_SUPPORTED)
      if ((png_ptr->mode & PNG_IS_READ_STRUCT) != 0)
#  endif

#  ifdef PNG_READ_SUPPORTED
      {
         if (error < PNG_CHUNK_ERROR)
            png_chunk_warning(png_ptr, message);

         else
            png_chunk_benign_error(png_ptr, message);
      }
#  endif

#  if defined(PNG_READ_SUPPORTED) && defined(PNG_WRITE_SUPPORTED)
      else if ((png_ptr->mode & PNG_IS_READ_STRUCT) == 0)
#  endif

#  ifdef PNG_WRITE_SUPPORTED
      {
         if (error < PNG_CHUNK_WRITE_ERROR)
            png_app_warning(png_ptr, message);

         else
            png_app_error(png_ptr, message);
      }
#  endif
}

#ifdef PNG_ERROR_TEXT_SUPPORTED
#ifdef PNG_FLOATING_POINT_SUPPORTED
PNG_FUNCTION(void,
png_fixed_error,(png_const_structrp png_ptr, png_const_charp name),PNG_NORETURN)
{
#  define fixed_message "fixed point overflow in "
#  define fixed_message_ln ((sizeof fixed_message)-1)
   int  iin;
   char msg[fixed_message_ln+PNG_MAX_ERROR_TEXT];
   memcpy(msg, fixed_message, fixed_message_ln);
   iin = 0;
   if (name != NULL)
      while (iin < (PNG_MAX_ERROR_TEXT-1) && name[iin] != 0)
      {
         msg[fixed_message_ln + iin] = name[iin];
         ++iin;
      }
   msg[fixed_message_ln + iin] = 0;
   png_error(png_ptr, msg);
}
#endif
#endif

#ifdef PNG_SETJMP_SUPPORTED
/* This API only exists if ANSI-C style error handling is used,
 * otherwise it is necessary for png_default_error to be overridden.
 */
jmp_buf* PNGAPI
png_set_longjmp_fn(png_structrp png_ptr, png_longjmp_ptr longjmp_fn,
    size_t jmp_buf_size)
{
   /* From libpng 1.6.0 the app gets one chance to set a 'jmpbuf_size' value
    * and it must not change after that.  Libpng doesn't care how big the
    * buffer is, just that it doesn't change.
    *
    * If the buffer size is no *larger* than the size of jmp_buf when libpng is
    * compiled a built in jmp_buf is returned; this preserves the pre-1.6.0
    * semantics that this call will not fail.  If the size is larger, however,
    * the buffer is allocated and this may fail, causing the function to return
    * NULL.
    */
   if (png_ptr == NULL)
      return NULL;

   if (png_ptr->jmp_buf_ptr == NULL)
   {
      png_ptr->jmp_buf_size = 0; /* not allocated */

      if (jmp_buf_size <= (sizeof png_ptr->jmp_buf_local))
         png_ptr->jmp_buf_ptr = &png_ptr->jmp_buf_local;

      else
      {
         png_ptr->jmp_buf_ptr = png_voidcast(jmp_buf *,
            png_malloc_warn(png_ptr, jmp_buf_size));

         if (png_ptr->jmp_buf_ptr == NULL)
            return NULL; /* new NULL return on OOM */

         png_ptr->jmp_buf_size = jmp_buf_size;
      }
   }

   else /* Already allocated: check the size */
   {
      size_t size = png_ptr->jmp_buf_size;

      if (size == 0)
      {
         size = (sizeof png_ptr->jmp_buf_local);
         if (png_ptr->jmp_buf_ptr != &png_ptr->jmp_buf_local)
         {
            /* This is an internal error in libpng: somehow we have been left
             * with a stack allocated jmp_buf when the application regained
             * control.  It's always possible to fix this up, but for the moment
             * this is a png_error because that makes it easy to detect.
             */
            png_error(png_ptr, "Libpng jmp_buf still allocated");
            /* png_ptr->jmp_buf_ptr = &png_ptr->jmp_buf_local; */
         }
      }

      if (size != jmp_buf_size)
      {
         png_warning(png_ptr, "Application jmp_buf size changed");
         return NULL; /* caller will probably crash: no choice here */
      }
   }

   /* Finally fill in the function, now we have a satisfactory buffer. It is
    * valid to change the function on every call.
    */
   png_ptr->longjmp_fn = longjmp_fn;
   return png_ptr->jmp_buf_ptr;
}

void /* PRIVATE */
png_free_jmpbuf(png_structrp png_ptr)
{
   if (png_ptr != NULL)
   {
      jmp_buf *jb = png_ptr->jmp_buf_ptr;

      /* A size of 0 is used to indicate a local, stack, allocation of the
       * pointer; used here and in png.c
       */
      if (jb != NULL && png_ptr->jmp_buf_size > 0)
      {

         /* This stuff is so that a failure to free the error control structure
          * does not leave libpng in a state with no valid error handling: the
          * free always succeeds, if there is an error it gets ignored.
          */
         if (jb != &png_ptr->jmp_buf_local)
         {
            /* Make an internal, libpng, jmp_buf to return here */
            jmp_buf free_jmp_buf;

            if (!setjmp(free_jmp_buf))
            {
               png_ptr->jmp_buf_ptr = &free_jmp_buf; /* come back here */
               png_ptr->jmp_buf_size = 0; /* stack allocation */
               png_ptr->longjmp_fn = longjmp;
               png_free(png_ptr, jb); /* Return to setjmp on error */
            }
         }
      }

      /* *Always* cancel everything out: */
      png_ptr->jmp_buf_size = 0;
      png_ptr->jmp_buf_ptr = NULL;
      png_ptr->longjmp_fn = 0;
   }
}
#endif

/* This is the default error handling function.  Note that replacements for
 * this function MUST NOT RETURN, or the program will likely crash.  This
 * function is used by default, or if the program supplies NULL for the
 * error function pointer in png_set_error_fn().
 */
static PNG_FUNCTION(void /* PRIVATE */,
png_default_error,(png_const_structrp png_ptr, png_const_charp error_message),
   PNG_NORETURN)
{
#ifdef PNG_CONSOLE_IO_SUPPORTED
#ifdef PNG_ERROR_NUMBERS_SUPPORTED
   /* Check on NULL only added in 1.5.4 */
   if (error_message != NULL && *error_message == PNG_LITERAL_SHARP)
   {
      /* Strip "#nnnn " from beginning of error message. */
      int offset;
      char error_number[16];
      for (offset = 0; offset<15; offset++)
      {
         error_number[offset] = error_message[offset + 1];
         if (error_message[offset] == ' ')
            break;
      }

      if ((offset > 1) && (offset < 15))
      {
         error_number[offset - 1] = '\0';
         fprintf(stderr, "libpng error no. %s: %s",
             error_number, error_message + offset + 1);
         fprintf(stderr, PNG_STRING_NEWLINE);
      }

      else
      {
         fprintf(stderr, "libpng error: %s, offset=%d",
             error_message, offset);
         fprintf(stderr, PNG_STRING_NEWLINE);
      }
   }
   else
#endif
   {
      fprintf(stderr, "libpng error: %s", error_message ? error_message :
         "undefined");
      fprintf(stderr, PNG_STRING_NEWLINE);
   }
#else
   PNG_UNUSED(error_message) /* Make compiler happy */
#endif
   png_longjmp(png_ptr, 1);
}

PNG_FUNCTION(void,PNGAPI
png_longjmp,(png_const_structrp png_ptr, int val),PNG_NORETURN)
{
#ifdef PNG_SETJMP_SUPPORTED
   if (png_ptr != NULL && png_ptr->longjmp_fn != NULL &&
       png_ptr->jmp_buf_ptr != NULL)
      png_ptr->longjmp_fn(*png_ptr->jmp_buf_ptr, val);
#else
   PNG_UNUSED(png_ptr)
   PNG_UNUSED(val)
#endif

   /* If control reaches this point, png_longjmp() must not return. The only
    * choice is to terminate the whole process (or maybe the thread); to do
    * this the ANSI-C abort() function is used unless a different method is
    * implemented by overriding the default configuration setting for
    * PNG_ABORT().
    */
   PNG_ABORT();
}

#ifdef PNG_WARNINGS_SUPPORTED
/* This function is called when there is a warning, but the library thinks
 * it can continue anyway.  Replacement functions don't have to do anything
 * here if you don't want them to.  In the default configuration, png_ptr is
 * not used, but it is passed in case it may be useful.
 */
static void /* PRIVATE */
png_default_warning(png_const_structrp png_ptr, png_const_charp warning_message)
{
#ifdef PNG_CONSOLE_IO_SUPPORTED
#  ifdef PNG_ERROR_NUMBERS_SUPPORTED
   if (*warning_message == PNG_LITERAL_SHARP)
   {
      int offset;
      char warning_number[16];
      for (offset = 0; offset < 15; offset++)
      {
         warning_number[offset] = warning_message[offset + 1];
         if (warning_message[offset] == ' ')
            break;
      }

      if ((offset > 1) && (offset < 15))
      {
         warning_number[offset + 1] = '\0';
         fprintf(stderr, "libpng warning no. %s: %s",
             warning_number, warning_message + offset);
         fprintf(stderr, PNG_STRING_NEWLINE);
      }

      else
      {
         fprintf(stderr, "libpng warning: %s",
             warning_message);
         fprintf(stderr, PNG_STRING_NEWLINE);
      }
   }
   else
#  endif

   {
      fprintf(stderr, "libpng warning: %s", warning_message);
      fprintf(stderr, PNG_STRING_NEWLINE);
   }
#else
   PNG_UNUSED(warning_message) /* Make compiler happy */
#endif
   PNG_UNUSED(png_ptr) /* Make compiler happy */
}
#endif /* WARNINGS */

/* This function is called when the application wants to use another method
 * of handling errors and warnings.  Note that the error function MUST NOT
 * return to the calling routine or serious problems will occur.  The return
 * method used in the default routine calls longjmp(png_ptr->jmp_buf_ptr, 1)
 */
void PNGAPI
png_set_error_fn(png_structrp png_ptr, png_voidp error_ptr,
    png_error_ptr error_fn, png_error_ptr warning_fn)
{
   if (png_ptr == NULL)
      return;

   png_ptr->error_ptr = error_ptr;
   png_ptr->error_fn = error_fn;
#ifdef PNG_WARNINGS_SUPPORTED
   png_ptr->warning_fn = warning_fn;
#else
   PNG_UNUSED(warning_fn)
#endif
}


/* This function returns a pointer to the error_ptr associated with the user
 * functions.  The application should free any memory associated with this
 * pointer before png_write_destroy and png_read_destroy are called.
 */
png_voidp PNGAPI
png_get_error_ptr(png_const_structrp png_ptr)
{
   if (png_ptr == NULL)
      return NULL;

   return ((png_voidp)png_ptr->error_ptr);
}


#ifdef PNG_ERROR_NUMBERS_SUPPORTED
void PNGAPI
png_set_strip_error_numbers(png_structrp png_ptr, png_uint_32 strip_mode)
{
   if (png_ptr != NULL)
   {
      png_ptr->flags &=
         ((~(PNG_FLAG_STRIP_ERROR_NUMBERS |
         PNG_FLAG_STRIP_ERROR_TEXT))&strip_mode);
   }
}
#endif

#if defined(PNG_SIMPLIFIED_READ_SUPPORTED) ||\
   defined(PNG_SIMPLIFIED_WRITE_SUPPORTED)
   /* Currently the above both depend on SETJMP_SUPPORTED, however it would be
    * possible to implement without setjmp support just so long as there is some
    * way to handle the error return here:
    */
PNG_FUNCTION(void /* PRIVATE */, (PNGCBAPI
png_safe_error),(png_structp png_nonconst_ptr, png_const_charp error_message),
   PNG_NORETURN)
{
   const png_const_structrp png_ptr = png_nonconst_ptr;
   png_imagep image = png_voidcast(png_imagep, png_ptr->error_ptr);

   /* An error is always logged here, overwriting anything (typically a warning)
    * that is already there:
    */
   if (image != NULL)
   {
      png_safecat(image->message, (sizeof image->message), 0, error_message);
      image->warning_or_error |= PNG_IMAGE_ERROR;

      /* Retrieve the jmp_buf from within the png_control, making this work for
       * C++ compilation too is pretty tricky: C++ wants a pointer to the first
       * element of a jmp_buf, but C doesn't tell us the type of that.
       */
      if (image->opaque != NULL && image->opaque->error_buf != NULL)
         longjmp(png_control_jmp_buf(image->opaque), 1);

      /* Missing longjmp buffer, the following is to help debugging: */
      {
         size_t pos = png_safecat(image->message, (sizeof image->message), 0,
            "bad longjmp: ");
         png_safecat(image->message, (sizeof image->message), pos,
             error_message);
      }
   }

   /* Here on an internal programming error. */
   abort();
}

#ifdef PNG_WARNINGS_SUPPORTED
void /* PRIVATE */ PNGCBAPI
png_safe_warning(png_structp png_nonconst_ptr, png_const_charp warning_message)
{
   const png_const_structrp png_ptr = png_nonconst_ptr;
   png_imagep image = png_voidcast(png_imagep, png_ptr->error_ptr);

   /* A warning is only logged if there is no prior warning or error. */
   if (image->warning_or_error == 0)
   {
      png_safecat(image->message, (sizeof image->message), 0, warning_message);
      image->warning_or_error |= PNG_IMAGE_WARNING;
   }
}
#endif

int /* PRIVATE */
png_safe_execute(png_imagep image_in, int (*function)(png_voidp), png_voidp arg)
{
   volatile png_imagep image = image_in;
   volatile int result;
   volatile png_voidp saved_error_buf;
   jmp_buf safe_jmpbuf;

   /* Safely execute function(arg) with png_error returning to this function. */
   saved_error_buf = image->opaque->error_buf;
   result = setjmp(safe_jmpbuf) == 0;

   if (result != 0)
   {

      image->opaque->error_buf = safe_jmpbuf;
      result = function(arg);
   }

   image->opaque->error_buf = saved_error_buf;

   /* And do the cleanup prior to any failure return. */
   if (result == 0)
      png_image_free(image);

   return result;
}
#endif /* SIMPLIFIED READ || SIMPLIFIED_WRITE */
#endif /* READ || WRITE */
