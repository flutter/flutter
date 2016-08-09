
/* arm_init.c - NEON optimised filter functions
 *
 * Copyright (c) 2014,2016 Glenn Randers-Pehrson
 * Written by Mans Rullgard, 2011.
 * Last changed in libpng 1.6.22 [(PENDING RELEASE)]
 *
 * This code is released under the libpng license.
 * For conditions of distribution and use, see the disclaimer
 * and license in png.h
 */
/* Below, after checking __linux__, various non-C90 POSIX 1003.1 functions are
 * called.
 */
#define _POSIX_SOURCE 1

#include "../pngpriv.h"

#ifdef PNG_READ_SUPPORTED

#if PNG_ARM_NEON_OPT > 0
#ifdef PNG_ARM_NEON_CHECK_SUPPORTED /* Do run-time checks */
/* WARNING: it is strongly recommended that you do not build libpng with
 * run-time checks for CPU features if at all possible.  In the case of the ARM
 * NEON instructions there is no processor-specific way of detecting the
 * presence of the required support, therefore run-time detection is extremely
 * OS specific.
 *
 * You may set the macro PNG_ARM_NEON_FILE to the file name of file containing
 * a fragment of C source code which defines the png_have_neon function.  There
 * are a number of implementations in contrib/arm-neon, but the only one that
 * has partial support is contrib/arm-neon/linux.c - a generic Linux
 * implementation which reads /proc/cpufino.
 */
#ifndef PNG_ARM_NEON_FILE
#  ifdef __linux__
#     define PNG_ARM_NEON_FILE "contrib/arm-neon/linux.c"
#  endif
#endif

#ifdef PNG_ARM_NEON_FILE

#include <signal.h> /* for sig_atomic_t */
static int png_have_neon(png_structp png_ptr);
#include PNG_ARM_NEON_FILE

#else  /* PNG_ARM_NEON_FILE */
#  error "PNG_ARM_NEON_FILE undefined: no support for run-time ARM NEON checks"
#endif /* PNG_ARM_NEON_FILE */
#endif /* PNG_ARM_NEON_CHECK_SUPPORTED */

#ifndef PNG_ALIGNED_MEMORY_SUPPORTED
#  error "ALIGNED_MEMORY is required; set: -DPNG_ALIGNED_MEMORY_SUPPORTED"
#endif

void
png_init_filter_functions_neon(png_structp pp, unsigned int bpp)
{
   /* The switch statement is compiled in for ARM_NEON_API, the call to
    * png_have_neon is compiled in for ARM_NEON_CHECK.  If both are defined
    * the check is only performed if the API has not set the NEON option on
    * or off explicitly.  In this case the check controls what happens.
    *
    * If the CHECK is not compiled in and the option is UNSET the behavior prior
    * to 1.6.7 was to use the NEON code - this was a bug caused by having the
    * wrong order of the 'ON' and 'default' cases.  UNSET now defaults to OFF,
    * as documented in png.h
    */
   png_debug(1, "in png_init_filter_functions_neon");
#ifdef PNG_ARM_NEON_API_SUPPORTED
   switch ((pp->options >> PNG_ARM_NEON) & 3)
   {
      case PNG_OPTION_UNSET:
         /* Allow the run-time check to execute if it has been enabled -
          * thus both API and CHECK can be turned on.  If it isn't supported
          * this case will fall through to the 'default' below, which just
          * returns.
          */
#endif /* PNG_ARM_NEON_API_SUPPORTED */
#ifdef PNG_ARM_NEON_CHECK_SUPPORTED
         {
            static volatile sig_atomic_t no_neon = -1; /* not checked */

            if (no_neon < 0)
               no_neon = !png_have_neon(pp);

            if (no_neon)
               return;
         }
#ifdef PNG_ARM_NEON_API_SUPPORTED
         break;
#endif
#endif /* PNG_ARM_NEON_CHECK_SUPPORTED */

#ifdef PNG_ARM_NEON_API_SUPPORTED
      default: /* OFF or INVALID */
         return;

      case PNG_OPTION_ON:
         /* Option turned on */
         break;
   }
#endif

   /* IMPORTANT: any new external functions used here must be declared using
    * PNG_INTERNAL_FUNCTION in ../pngpriv.h.  This is required so that the
    * 'prefix' option to configure works:
    *
    *    ./configure --with-libpng-prefix=foobar_
    *
    * Verify you have got this right by running the above command, doing a build
    * and examining pngprefix.h; it must contain a #define for every external
    * function you add.  (Notice that this happens automatically for the
    * initialization function.)
    */
   pp->read_filter[PNG_FILTER_VALUE_UP-1] = png_read_filter_row_up_neon;

   if (bpp == 3)
   {
      pp->read_filter[PNG_FILTER_VALUE_SUB-1] = png_read_filter_row_sub3_neon;
      pp->read_filter[PNG_FILTER_VALUE_AVG-1] = png_read_filter_row_avg3_neon;
      pp->read_filter[PNG_FILTER_VALUE_PAETH-1] =
         png_read_filter_row_paeth3_neon;
   }

   else if (bpp == 4)
   {
      pp->read_filter[PNG_FILTER_VALUE_SUB-1] = png_read_filter_row_sub4_neon;
      pp->read_filter[PNG_FILTER_VALUE_AVG-1] = png_read_filter_row_avg4_neon;
      pp->read_filter[PNG_FILTER_VALUE_PAETH-1] =
          png_read_filter_row_paeth4_neon;
   }
}
#endif /* PNG_ARM_NEON_OPT > 0 */
#endif /* READ */
