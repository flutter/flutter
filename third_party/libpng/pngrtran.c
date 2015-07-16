
/* pngrtran.c - transforms the data in a row for PNG readers
 *
 * Last changed in libpng 1.2.45 [July 7, 2011]
 * Copyright (c) 1998-2011 Glenn Randers-Pehrson
 * (Version 0.96 Copyright (c) 1996, 1997 Andreas Dilger)
 * (Version 0.88 Copyright (c) 1995, 1996 Guy Eric Schalnat, Group 42, Inc.)
 *
 * This code is released under the libpng license.
 * For conditions of distribution and use, see the disclaimer
 * and license in png.h
 *
 * This file contains functions optionally called by an application
 * in order to tell libpng how to handle data when reading a PNG.
 * Transformations that are used in both reading and writing are
 * in pngtrans.c.
 */

#define PNG_INTERNAL
#define PNG_NO_PEDANTIC_WARNINGS
#include "png.h"
#ifdef PNG_READ_SUPPORTED

/* Set the action on getting a CRC error for an ancillary or critical chunk. */
void PNGAPI
png_set_crc_action(png_structp png_ptr, int crit_action, int ancil_action)
{
   png_debug(1, "in png_set_crc_action");
 
   if (png_ptr == NULL)
      return;

   /* Tell libpng how we react to CRC errors in critical chunks */
   switch (crit_action)
   {
      case PNG_CRC_NO_CHANGE:                        /* Leave setting as is */
         break;

      case PNG_CRC_WARN_USE:                               /* Warn/use data */
         png_ptr->flags &= ~PNG_FLAG_CRC_CRITICAL_MASK;
         png_ptr->flags |= PNG_FLAG_CRC_CRITICAL_USE;
         break;

      case PNG_CRC_QUIET_USE:                             /* Quiet/use data */
         png_ptr->flags &= ~PNG_FLAG_CRC_CRITICAL_MASK;
         png_ptr->flags |= PNG_FLAG_CRC_CRITICAL_USE |
                           PNG_FLAG_CRC_CRITICAL_IGNORE;
         break;

      case PNG_CRC_WARN_DISCARD:    /* Not a valid action for critical data */
         png_warning(png_ptr,
            "Can't discard critical data on CRC error.");
      case PNG_CRC_ERROR_QUIT:                                /* Error/quit */

      case PNG_CRC_DEFAULT:
      default:
         png_ptr->flags &= ~PNG_FLAG_CRC_CRITICAL_MASK;
         break;
   }

   /* Tell libpng how we react to CRC errors in ancillary chunks */
   switch (ancil_action)
   {
      case PNG_CRC_NO_CHANGE:                       /* Leave setting as is */
         break;

      case PNG_CRC_WARN_USE:                              /* Warn/use data */
         png_ptr->flags &= ~PNG_FLAG_CRC_ANCILLARY_MASK;
         png_ptr->flags |= PNG_FLAG_CRC_ANCILLARY_USE;
         break;

      case PNG_CRC_QUIET_USE:                            /* Quiet/use data */
         png_ptr->flags &= ~PNG_FLAG_CRC_ANCILLARY_MASK;
         png_ptr->flags |= PNG_FLAG_CRC_ANCILLARY_USE |
                           PNG_FLAG_CRC_ANCILLARY_NOWARN;
         break;

      case PNG_CRC_ERROR_QUIT:                               /* Error/quit */
         png_ptr->flags &= ~PNG_FLAG_CRC_ANCILLARY_MASK;
         png_ptr->flags |= PNG_FLAG_CRC_ANCILLARY_NOWARN;
         break;

      case PNG_CRC_WARN_DISCARD:                      /* Warn/discard data */

      case PNG_CRC_DEFAULT:
      default:
         png_ptr->flags &= ~PNG_FLAG_CRC_ANCILLARY_MASK;
         break;
   }
}

#if defined(PNG_READ_BACKGROUND_SUPPORTED) && \
    defined(PNG_FLOATING_POINT_SUPPORTED)
/* Handle alpha and tRNS via a background color */
void PNGAPI
png_set_background(png_structp png_ptr,
   png_color_16p background_color, int background_gamma_code,
   int need_expand, double background_gamma)
{
   png_debug(1, "in png_set_background");
 
   if (png_ptr == NULL)
      return;
   if (background_gamma_code == PNG_BACKGROUND_GAMMA_UNKNOWN)
   {
      png_warning(png_ptr, "Application must supply a known background gamma");
      return;
   }

   png_ptr->transformations |= PNG_BACKGROUND;
   png_memcpy(&(png_ptr->background), background_color,
      png_sizeof(png_color_16));
   png_ptr->background_gamma = (float)background_gamma;
   png_ptr->background_gamma_type = (png_byte)(background_gamma_code);
   png_ptr->transformations |= (need_expand ? PNG_BACKGROUND_EXPAND : 0);
}
#endif

#ifdef PNG_READ_16_TO_8_SUPPORTED
/* Strip 16 bit depth files to 8 bit depth */
void PNGAPI
png_set_strip_16(png_structp png_ptr)
{
   png_debug(1, "in png_set_strip_16");

   if (png_ptr == NULL)
      return;
   png_ptr->transformations |= PNG_16_TO_8;
}
#endif

#ifdef PNG_READ_STRIP_ALPHA_SUPPORTED
void PNGAPI
png_set_strip_alpha(png_structp png_ptr)
{
   png_debug(1, "in png_set_strip_alpha");

   if (png_ptr == NULL)
      return;
   png_ptr->flags |= PNG_FLAG_STRIP_ALPHA;
}
#endif

#ifdef PNG_READ_DITHER_SUPPORTED
/* Dither file to 8 bit.  Supply a palette, the current number
 * of elements in the palette, the maximum number of elements
 * allowed, and a histogram if possible.  If the current number
 * of colors is greater then the maximum number, the palette will be
 * modified to fit in the maximum number.  "full_dither" indicates
 * whether we need a dithering cube set up for RGB images, or if we
 * simply are reducing the number of colors in a paletted image.
 */

typedef struct png_dsort_struct
{
   struct png_dsort_struct FAR * next;
   png_byte left;
   png_byte right;
} png_dsort;
typedef png_dsort FAR *       png_dsortp;
typedef png_dsort FAR * FAR * png_dsortpp;

void PNGAPI
png_set_dither(png_structp png_ptr, png_colorp palette,
   int num_palette, int maximum_colors, png_uint_16p histogram,
   int full_dither)
{
   png_debug(1, "in png_set_dither");

   if (png_ptr == NULL)
      return;
   png_ptr->transformations |= PNG_DITHER;

   if (!full_dither)
   {
      int i;

      png_ptr->dither_index = (png_bytep)png_malloc(png_ptr,
         (png_uint_32)(num_palette * png_sizeof(png_byte)));
      for (i = 0; i < num_palette; i++)
         png_ptr->dither_index[i] = (png_byte)i;
   }

   if (num_palette > maximum_colors)
   {
      if (histogram != NULL)
      {
         /* This is easy enough, just throw out the least used colors.
          * Perhaps not the best solution, but good enough.
          */

         int i;

         /* Initialize an array to sort colors */
         png_ptr->dither_sort = (png_bytep)png_malloc(png_ptr,
            (png_uint_32)(num_palette * png_sizeof(png_byte)));

         /* Initialize the dither_sort array */
         for (i = 0; i < num_palette; i++)
            png_ptr->dither_sort[i] = (png_byte)i;

         /* Find the least used palette entries by starting a
          * bubble sort, and running it until we have sorted
          * out enough colors.  Note that we don't care about
          * sorting all the colors, just finding which are
          * least used.
          */

         for (i = num_palette - 1; i >= maximum_colors; i--)
         {
            int done; /* To stop early if the list is pre-sorted */
            int j;

            done = 1;
            for (j = 0; j < i; j++)
            {
               if (histogram[png_ptr->dither_sort[j]]
                   < histogram[png_ptr->dither_sort[j + 1]])
               {
                  png_byte t;

                  t = png_ptr->dither_sort[j];
                  png_ptr->dither_sort[j] = png_ptr->dither_sort[j + 1];
                  png_ptr->dither_sort[j + 1] = t;
                  done = 0;
               }
            }
            if (done)
               break;
         }

         /* Swap the palette around, and set up a table, if necessary */
         if (full_dither)
         {
            int j = num_palette;

            /* Put all the useful colors within the max, but don't
             * move the others.
             */
            for (i = 0; i < maximum_colors; i++)
            {
               if ((int)png_ptr->dither_sort[i] >= maximum_colors)
               {
                  do
                     j--;
                  while ((int)png_ptr->dither_sort[j] >= maximum_colors);
                  palette[i] = palette[j];
               }
            }
         }
         else
         {
            int j = num_palette;

            /* Move all the used colors inside the max limit, and
             * develop a translation table.
             */
            for (i = 0; i < maximum_colors; i++)
            {
               /* Only move the colors we need to */
               if ((int)png_ptr->dither_sort[i] >= maximum_colors)
               {
                  png_color tmp_color;

                  do
                     j--;
                  while ((int)png_ptr->dither_sort[j] >= maximum_colors);

                  tmp_color = palette[j];
                  palette[j] = palette[i];
                  palette[i] = tmp_color;
                  /* Indicate where the color went */
                  png_ptr->dither_index[j] = (png_byte)i;
                  png_ptr->dither_index[i] = (png_byte)j;
               }
            }

            /* Find closest color for those colors we are not using */
            for (i = 0; i < num_palette; i++)
            {
               if ((int)png_ptr->dither_index[i] >= maximum_colors)
               {
                  int min_d, k, min_k, d_index;

                  /* Find the closest color to one we threw out */
                  d_index = png_ptr->dither_index[i];
                  min_d = PNG_COLOR_DIST(palette[d_index], palette[0]);
                  for (k = 1, min_k = 0; k < maximum_colors; k++)
                  {
                     int d;

                     d = PNG_COLOR_DIST(palette[d_index], palette[k]);

                     if (d < min_d)
                     {
                        min_d = d;
                        min_k = k;
                     }
                  }
                  /* Point to closest color */
                  png_ptr->dither_index[i] = (png_byte)min_k;
               }
            }
         }
         png_free(png_ptr, png_ptr->dither_sort);
         png_ptr->dither_sort = NULL;
      }
      else
      {
         /* This is much harder to do simply (and quickly).  Perhaps
          * we need to go through a median cut routine, but those
          * don't always behave themselves with only a few colors
          * as input.  So we will just find the closest two colors,
          * and throw out one of them (chosen somewhat randomly).
          * [We don't understand this at all, so if someone wants to
          *  work on improving it, be our guest - AED, GRP]
          */
         int i;
         int max_d;
         int num_new_palette;
         png_dsortp t;
         png_dsortpp hash;

         t = NULL;

         /* Initialize palette index arrays */
         png_ptr->index_to_palette = (png_bytep)png_malloc(png_ptr,
            (png_uint_32)(num_palette * png_sizeof(png_byte)));
         png_ptr->palette_to_index = (png_bytep)png_malloc(png_ptr,
            (png_uint_32)(num_palette * png_sizeof(png_byte)));

         /* Initialize the sort array */
         for (i = 0; i < num_palette; i++)
         {
            png_ptr->index_to_palette[i] = (png_byte)i;
            png_ptr->palette_to_index[i] = (png_byte)i;
         }

         hash = (png_dsortpp)png_calloc(png_ptr, (png_uint_32)(769 *
            png_sizeof(png_dsortp)));

         num_new_palette = num_palette;

         /* Initial wild guess at how far apart the farthest pixel
          * pair we will be eliminating will be.  Larger
          * numbers mean more areas will be allocated, Smaller
          * numbers run the risk of not saving enough data, and
          * having to do this all over again.
          *
          * I have not done extensive checking on this number.
          */
         max_d = 96;

         while (num_new_palette > maximum_colors)
         {
            for (i = 0; i < num_new_palette - 1; i++)
            {
               int j;

               for (j = i + 1; j < num_new_palette; j++)
               {
                  int d;

                  d = PNG_COLOR_DIST(palette[i], palette[j]);

                  if (d <= max_d)
                  {

                     t = (png_dsortp)png_malloc_warn(png_ptr,
                         (png_uint_32)(png_sizeof(png_dsort)));
                     if (t == NULL)
                         break;
                     t->next = hash[d];
                     t->left = (png_byte)i;
                     t->right = (png_byte)j;
                     hash[d] = t;
                  }
               }
               if (t == NULL)
                  break;
            }

            if (t != NULL)
            for (i = 0; i <= max_d; i++)
            {
               if (hash[i] != NULL)
               {
                  png_dsortp p;

                  for (p = hash[i]; p; p = p->next)
                  {
                     if ((int)png_ptr->index_to_palette[p->left]
                        < num_new_palette &&
                        (int)png_ptr->index_to_palette[p->right]
                        < num_new_palette)
                     {
                        int j, next_j;

                        if (num_new_palette & 0x01)
                        {
                           j = p->left;
                           next_j = p->right;
                        }
                        else
                        {
                           j = p->right;
                           next_j = p->left;
                        }

                        num_new_palette--;
                        palette[png_ptr->index_to_palette[j]]
                          = palette[num_new_palette];
                        if (!full_dither)
                        {
                           int k;

                           for (k = 0; k < num_palette; k++)
                           {
                              if (png_ptr->dither_index[k] ==
                                 png_ptr->index_to_palette[j])
                                 png_ptr->dither_index[k] =
                                    png_ptr->index_to_palette[next_j];
                              if ((int)png_ptr->dither_index[k] ==
                                 num_new_palette)
                                 png_ptr->dither_index[k] =
                                    png_ptr->index_to_palette[j];
                           }
                        }

                        png_ptr->index_to_palette[png_ptr->palette_to_index
                           [num_new_palette]] = png_ptr->index_to_palette[j];
                        png_ptr->palette_to_index[png_ptr->index_to_palette[j]]
                           = png_ptr->palette_to_index[num_new_palette];

                        png_ptr->index_to_palette[j] =
                            (png_byte)num_new_palette;
                        png_ptr->palette_to_index[num_new_palette] =
                            (png_byte)j;
                     }
                     if (num_new_palette <= maximum_colors)
                        break;
                  }
                  if (num_new_palette <= maximum_colors)
                     break;
               }
            }

            for (i = 0; i < 769; i++)
            {
               if (hash[i] != NULL)
               {
                  png_dsortp p = hash[i];
                  while (p)
                  {
                     t = p->next;
                     png_free(png_ptr, p);
                     p = t;
                  }
               }
               hash[i] = 0;
            }
            max_d += 96;
         }
         png_free(png_ptr, hash);
         png_free(png_ptr, png_ptr->palette_to_index);
         png_free(png_ptr, png_ptr->index_to_palette);
         png_ptr->palette_to_index = NULL;
         png_ptr->index_to_palette = NULL;
      }
      num_palette = maximum_colors;
   }
   if (png_ptr->palette == NULL)
   {
      png_ptr->palette = palette;
   }
   png_ptr->num_palette = (png_uint_16)num_palette;

   if (full_dither)
   {
      int i;
      png_bytep distance;
      int total_bits = PNG_DITHER_RED_BITS + PNG_DITHER_GREEN_BITS +
         PNG_DITHER_BLUE_BITS;
      int num_red = (1 << PNG_DITHER_RED_BITS);
      int num_green = (1 << PNG_DITHER_GREEN_BITS);
      int num_blue = (1 << PNG_DITHER_BLUE_BITS);
      png_size_t num_entries = ((png_size_t)1 << total_bits);

      png_ptr->palette_lookup = (png_bytep )png_calloc(png_ptr,
         (png_uint_32)(num_entries * png_sizeof(png_byte)));

      distance = (png_bytep)png_malloc(png_ptr, (png_uint_32)(num_entries *
         png_sizeof(png_byte)));
      png_memset(distance, 0xff, num_entries * png_sizeof(png_byte));

      for (i = 0; i < num_palette; i++)
      {
         int ir, ig, ib;
         int r = (palette[i].red >> (8 - PNG_DITHER_RED_BITS));
         int g = (palette[i].green >> (8 - PNG_DITHER_GREEN_BITS));
         int b = (palette[i].blue >> (8 - PNG_DITHER_BLUE_BITS));

         for (ir = 0; ir < num_red; ir++)
         {
            /* int dr = abs(ir - r); */
            int dr = ((ir > r) ? ir - r : r - ir);
            int index_r = (ir << (PNG_DITHER_BLUE_BITS +
                PNG_DITHER_GREEN_BITS));

            for (ig = 0; ig < num_green; ig++)
            {
               /* int dg = abs(ig - g); */
               int dg = ((ig > g) ? ig - g : g - ig);
               int dt = dr + dg;
               int dm = ((dr > dg) ? dr : dg);
               int index_g = index_r | (ig << PNG_DITHER_BLUE_BITS);

               for (ib = 0; ib < num_blue; ib++)
               {
                  int d_index = index_g | ib;
                  /* int db = abs(ib - b); */
                  int db = ((ib > b) ? ib - b : b - ib);
                  int dmax = ((dm > db) ? dm : db);
                  int d = dmax + dt + db;

                  if (d < (int)distance[d_index])
                  {
                     distance[d_index] = (png_byte)d;
                     png_ptr->palette_lookup[d_index] = (png_byte)i;
                  }
               }
            }
         }
      }

      png_free(png_ptr, distance);
   }
}
#endif

#if defined(PNG_READ_GAMMA_SUPPORTED) && defined(PNG_FLOATING_POINT_SUPPORTED)
/* Transform the image from the file_gamma to the screen_gamma.  We
 * only do transformations on images where the file_gamma and screen_gamma
 * are not close reciprocals, otherwise it slows things down slightly, and
 * also needlessly introduces small errors.
 *
 * We will turn off gamma transformation later if no semitransparent entries
 * are present in the tRNS array for palette images.  We can't do it here
 * because we don't necessarily have the tRNS chunk yet.
 */
void PNGAPI
png_set_gamma(png_structp png_ptr, double scrn_gamma, double file_gamma)
{
   png_debug(1, "in png_set_gamma");

   if (png_ptr == NULL)
      return;

   if ((fabs(scrn_gamma * file_gamma - 1.0) > PNG_GAMMA_THRESHOLD) ||
       (png_ptr->color_type & PNG_COLOR_MASK_ALPHA) ||
       (png_ptr->color_type == PNG_COLOR_TYPE_PALETTE))
     png_ptr->transformations |= PNG_GAMMA;
   png_ptr->gamma = (float)file_gamma;
   png_ptr->screen_gamma = (float)scrn_gamma;
}
#endif

#ifdef PNG_READ_EXPAND_SUPPORTED
/* Expand paletted images to RGB, expand grayscale images of
 * less than 8-bit depth to 8-bit depth, and expand tRNS chunks
 * to alpha channels.
 */
void PNGAPI
png_set_expand(png_structp png_ptr)
{
   png_debug(1, "in png_set_expand");

   if (png_ptr == NULL)
      return;

   png_ptr->transformations |= (PNG_EXPAND | PNG_EXPAND_tRNS);
   png_ptr->flags &= ~PNG_FLAG_ROW_INIT;
}

/* GRR 19990627:  the following three functions currently are identical
 *  to png_set_expand().  However, it is entirely reasonable that someone
 *  might wish to expand an indexed image to RGB but *not* expand a single,
 *  fully transparent palette entry to a full alpha channel--perhaps instead
 *  convert tRNS to the grayscale/RGB format (16-bit RGB value), or replace
 *  the transparent color with a particular RGB value, or drop tRNS entirely.
 *  IOW, a future version of the library may make the transformations flag
 *  a bit more fine-grained, with separate bits for each of these three
 *  functions.
 *
 *  More to the point, these functions make it obvious what libpng will be
 *  doing, whereas "expand" can (and does) mean any number of things.
 *
 *  GRP 20060307: In libpng-1.2.9, png_set_gray_1_2_4_to_8() was modified
 *  to expand only the sample depth but not to expand the tRNS to alpha
 *  and its name was changed to png_set_expand_gray_1_2_4_to_8().
 */

/* Expand paletted images to RGB. */
void PNGAPI
png_set_palette_to_rgb(png_structp png_ptr)
{
   png_debug(1, "in png_set_palette_to_rgb");

   if (png_ptr == NULL)
      return;

   png_ptr->transformations |= (PNG_EXPAND | PNG_EXPAND_tRNS);
   png_ptr->flags &= ~PNG_FLAG_ROW_INIT;
}

#ifndef PNG_1_0_X
/* Expand grayscale images of less than 8-bit depth to 8 bits. */
void PNGAPI
png_set_expand_gray_1_2_4_to_8(png_structp png_ptr)
{
   png_debug(1, "in png_set_expand_gray_1_2_4_to_8");

   if (png_ptr == NULL)
      return;

   png_ptr->transformations |= PNG_EXPAND;
   png_ptr->flags &= ~PNG_FLAG_ROW_INIT;
}
#endif

#if defined(PNG_1_0_X) || defined(PNG_1_2_X)
/* Expand grayscale images of less than 8-bit depth to 8 bits. */
/* Deprecated as of libpng-1.2.9 */
void PNGAPI
png_set_gray_1_2_4_to_8(png_structp png_ptr)
{
   png_debug(1, "in png_set_gray_1_2_4_to_8");

   if (png_ptr == NULL)
      return;

   png_ptr->transformations |= (PNG_EXPAND | PNG_EXPAND_tRNS);
}
#endif


/* Expand tRNS chunks to alpha channels. */
void PNGAPI
png_set_tRNS_to_alpha(png_structp png_ptr)
{
   png_debug(1, "in png_set_tRNS_to_alpha");

   png_ptr->transformations |= (PNG_EXPAND | PNG_EXPAND_tRNS);
   png_ptr->flags &= ~PNG_FLAG_ROW_INIT;
}
#endif /* defined(PNG_READ_EXPAND_SUPPORTED) */

#ifdef PNG_READ_GRAY_TO_RGB_SUPPORTED
void PNGAPI
png_set_gray_to_rgb(png_structp png_ptr)
{
   png_debug(1, "in png_set_gray_to_rgb");

   png_ptr->transformations |= PNG_GRAY_TO_RGB;
   png_ptr->flags &= ~PNG_FLAG_ROW_INIT;
}
#endif

#ifdef PNG_READ_RGB_TO_GRAY_SUPPORTED
#ifdef PNG_FLOATING_POINT_SUPPORTED
/* Convert a RGB image to a grayscale of the same width.  This allows us,
 * for example, to convert a 24 bpp RGB image into an 8 bpp grayscale image.
 */

void PNGAPI
png_set_rgb_to_gray(png_structp png_ptr, int error_action, double red,
   double green)
{
   int red_fixed, green_fixed;
   if (png_ptr == NULL)
      return;
   if (red > 21474.83647 || red < -21474.83648 ||
       green > 21474.83647 || green < -21474.83648)
   {
      png_warning(png_ptr, "ignoring out of range rgb_to_gray coefficients");
      red_fixed = -1;
      green_fixed = -1;
   }
   else
   {
      red_fixed = (int)((float)red*100000.0 + 0.5);
      green_fixed = (int)((float)green*100000.0 + 0.5);
   }
   png_set_rgb_to_gray_fixed(png_ptr, error_action, red_fixed, green_fixed);
}
#endif

void PNGAPI
png_set_rgb_to_gray_fixed(png_structp png_ptr, int error_action,
   png_fixed_point red, png_fixed_point green)
{
   png_debug(1, "in png_set_rgb_to_gray");

   if (png_ptr == NULL)
      return;

   switch(error_action)
   {
      case 1: png_ptr->transformations |= PNG_RGB_TO_GRAY;
              break;

      case 2: png_ptr->transformations |= PNG_RGB_TO_GRAY_WARN;
              break;

      case 3: png_ptr->transformations |= PNG_RGB_TO_GRAY_ERR;
   }
   if (png_ptr->color_type == PNG_COLOR_TYPE_PALETTE)
#ifdef PNG_READ_EXPAND_SUPPORTED
      png_ptr->transformations |= PNG_EXPAND;
#else
   {
      png_warning(png_ptr,
        "Cannot do RGB_TO_GRAY without EXPAND_SUPPORTED.");
      png_ptr->transformations &= ~PNG_RGB_TO_GRAY;
   }
#endif
   {
      png_uint_16 red_int, green_int;
      if (red < 0 || green < 0)
      {
         red_int   =  6968; /* .212671 * 32768 + .5 */
         green_int = 23434; /* .715160 * 32768 + .5 */
      }
      else if (red + green < 100000L)
      {
         red_int = (png_uint_16)(((png_uint_32)red*32768L)/100000L);
         green_int = (png_uint_16)(((png_uint_32)green*32768L)/100000L);
      }
      else
      {
         png_warning(png_ptr, "ignoring out of range rgb_to_gray coefficients");
         red_int   =  6968;
         green_int = 23434;
      }
      png_ptr->rgb_to_gray_red_coeff   = red_int;
      png_ptr->rgb_to_gray_green_coeff = green_int;
      png_ptr->rgb_to_gray_blue_coeff  =
         (png_uint_16)(32768 - red_int - green_int);
   }
}
#endif

#if defined(PNG_READ_USER_TRANSFORM_SUPPORTED) || \
    defined(PNG_LEGACY_SUPPORTED) || \
    defined(PNG_WRITE_USER_TRANSFORM_SUPPORTED)
void PNGAPI
png_set_read_user_transform_fn(png_structp png_ptr, png_user_transform_ptr
   read_user_transform_fn)
{
   png_debug(1, "in png_set_read_user_transform_fn");

   if (png_ptr == NULL)
      return;

#ifdef PNG_READ_USER_TRANSFORM_SUPPORTED
   png_ptr->transformations |= PNG_USER_TRANSFORM;
   png_ptr->read_user_transform_fn = read_user_transform_fn;
#endif
#ifdef PNG_LEGACY_SUPPORTED
   if (read_user_transform_fn)
      png_warning(png_ptr,
        "This version of libpng does not support user transforms");
#endif
}
#endif

/* Initialize everything needed for the read.  This includes modifying
 * the palette.
 */
void /* PRIVATE */
png_init_read_transformations(png_structp png_ptr)
{
   png_debug(1, "in png_init_read_transformations");

#ifdef PNG_USELESS_TESTS_SUPPORTED
  if (png_ptr != NULL)
#endif
  {
#if defined(PNG_READ_BACKGROUND_SUPPORTED) || \
    defined(PNG_READ_SHIFT_SUPPORTED) || \
    defined(PNG_READ_GAMMA_SUPPORTED)
   int color_type = png_ptr->color_type;
#endif

#if defined(PNG_READ_EXPAND_SUPPORTED) && defined(PNG_READ_BACKGROUND_SUPPORTED)

#ifdef PNG_READ_GRAY_TO_RGB_SUPPORTED
   /* Detect gray background and attempt to enable optimization
    * for gray --> RGB case
    *
    * Note:  if PNG_BACKGROUND_EXPAND is set and color_type is either RGB or
    * RGB_ALPHA (in which case need_expand is superfluous anyway), the
    * background color might actually be gray yet not be flagged as such.
    * This is not a problem for the current code, which uses
    * PNG_BACKGROUND_IS_GRAY only to decide when to do the
    * png_do_gray_to_rgb() transformation.
    */
   if ((png_ptr->transformations & PNG_BACKGROUND_EXPAND) &&
       !(color_type & PNG_COLOR_MASK_COLOR))
   {
          png_ptr->mode |= PNG_BACKGROUND_IS_GRAY;
   } else if ((png_ptr->transformations & PNG_BACKGROUND) &&
              !(png_ptr->transformations & PNG_BACKGROUND_EXPAND) &&
              (png_ptr->transformations & PNG_GRAY_TO_RGB) &&
              png_ptr->background.red == png_ptr->background.green &&
              png_ptr->background.red == png_ptr->background.blue)
   {
          png_ptr->mode |= PNG_BACKGROUND_IS_GRAY;
          png_ptr->background.gray = png_ptr->background.red;
   }
#endif

   if ((png_ptr->transformations & PNG_BACKGROUND_EXPAND) &&
       (png_ptr->transformations & PNG_EXPAND))
   {
      if (!(color_type & PNG_COLOR_MASK_COLOR))  /* i.e., GRAY or GRAY_ALPHA */
      {
         /* Expand background and tRNS chunks */
         switch (png_ptr->bit_depth)
         {
            case 1:
               png_ptr->background.gray *= (png_uint_16)0xff;
               png_ptr->background.red = png_ptr->background.green
                 =  png_ptr->background.blue = png_ptr->background.gray;
               if (!(png_ptr->transformations & PNG_EXPAND_tRNS))
               {
                 png_ptr->trans_values.gray *= (png_uint_16)0xff;
                 png_ptr->trans_values.red = png_ptr->trans_values.green
                   = png_ptr->trans_values.blue = png_ptr->trans_values.gray;
               }
               break;

            case 2:
               png_ptr->background.gray *= (png_uint_16)0x55;
               png_ptr->background.red = png_ptr->background.green
                 = png_ptr->background.blue = png_ptr->background.gray;
               if (!(png_ptr->transformations & PNG_EXPAND_tRNS))
               {
                 png_ptr->trans_values.gray *= (png_uint_16)0x55;
                 png_ptr->trans_values.red = png_ptr->trans_values.green
                   = png_ptr->trans_values.blue = png_ptr->trans_values.gray;
               }
               break;

            case 4:
               png_ptr->background.gray *= (png_uint_16)0x11;
               png_ptr->background.red = png_ptr->background.green
                 = png_ptr->background.blue = png_ptr->background.gray;
               if (!(png_ptr->transformations & PNG_EXPAND_tRNS))
               {
                 png_ptr->trans_values.gray *= (png_uint_16)0x11;
                 png_ptr->trans_values.red = png_ptr->trans_values.green
                   = png_ptr->trans_values.blue = png_ptr->trans_values.gray;
               }
               break;

            case 8:

            case 16:
               png_ptr->background.red = png_ptr->background.green
                 = png_ptr->background.blue = png_ptr->background.gray;
               break;
         }
      }
      else if (color_type == PNG_COLOR_TYPE_PALETTE)
      {
         png_ptr->background.red   =
            png_ptr->palette[png_ptr->background.index].red;
         png_ptr->background.green =
            png_ptr->palette[png_ptr->background.index].green;
         png_ptr->background.blue  =
            png_ptr->palette[png_ptr->background.index].blue;

#ifdef PNG_READ_INVERT_ALPHA_SUPPORTED
        if (png_ptr->transformations & PNG_INVERT_ALPHA)
        {
#ifdef PNG_READ_EXPAND_SUPPORTED
           if (!(png_ptr->transformations & PNG_EXPAND_tRNS))
#endif
           {
           /* Invert the alpha channel (in tRNS) unless the pixels are
            * going to be expanded, in which case leave it for later
            */
              int i, istop;
              istop=(int)png_ptr->num_trans;
              for (i=0; i<istop; i++)
                 png_ptr->trans[i] = (png_byte)(255 - png_ptr->trans[i]);
           }
        }
#endif

      }
   }
#endif

#if defined(PNG_READ_BACKGROUND_SUPPORTED) && defined(PNG_READ_GAMMA_SUPPORTED)
   png_ptr->background_1 = png_ptr->background;
#endif
#if defined(PNG_READ_GAMMA_SUPPORTED) && defined(PNG_FLOATING_POINT_SUPPORTED)

   if ((color_type == PNG_COLOR_TYPE_PALETTE && png_ptr->num_trans != 0)
       && (fabs(png_ptr->screen_gamma * png_ptr->gamma - 1.0)
         < PNG_GAMMA_THRESHOLD))
   {
    int i, k;
    k=0;
    for (i=0; i<png_ptr->num_trans; i++)
    {
      if (png_ptr->trans[i] != 0 && png_ptr->trans[i] != 0xff)
        k=1; /* Partial transparency is present */
    }
    if (k == 0)
      png_ptr->transformations &= ~PNG_GAMMA;
   }

   if ((png_ptr->transformations & (PNG_GAMMA | PNG_RGB_TO_GRAY)) &&
        png_ptr->gamma != 0.0)
   {
      png_build_gamma_table(png_ptr);

#ifdef PNG_READ_BACKGROUND_SUPPORTED
      if (png_ptr->transformations & PNG_BACKGROUND)
      {
         if (color_type == PNG_COLOR_TYPE_PALETTE)
         {
           /* Could skip if no transparency */
            png_color back, back_1;
            png_colorp palette = png_ptr->palette;
            int num_palette = png_ptr->num_palette;
            int i;
            if (png_ptr->background_gamma_type == PNG_BACKGROUND_GAMMA_FILE)
            {
               back.red = png_ptr->gamma_table[png_ptr->background.red];
               back.green = png_ptr->gamma_table[png_ptr->background.green];
               back.blue = png_ptr->gamma_table[png_ptr->background.blue];

               back_1.red = png_ptr->gamma_to_1[png_ptr->background.red];
               back_1.green = png_ptr->gamma_to_1[png_ptr->background.green];
               back_1.blue = png_ptr->gamma_to_1[png_ptr->background.blue];
            }
            else
            {
               double g, gs;

               switch (png_ptr->background_gamma_type)
               {
                  case PNG_BACKGROUND_GAMMA_SCREEN:
                     g = (png_ptr->screen_gamma);
                     gs = 1.0;
                     break;

                  case PNG_BACKGROUND_GAMMA_FILE:
                     g = 1.0 / (png_ptr->gamma);
                     gs = 1.0 / (png_ptr->gamma * png_ptr->screen_gamma);
                     break;

                  case PNG_BACKGROUND_GAMMA_UNIQUE:
                     g = 1.0 / (png_ptr->background_gamma);
                     gs = 1.0 / (png_ptr->background_gamma *
                                 png_ptr->screen_gamma);
                     break;
                  default:
                     g = 1.0;    /* back_1 */
                     gs = 1.0;   /* back */
               }

               if ( fabs(gs - 1.0) < PNG_GAMMA_THRESHOLD)
               {
                  back.red   = (png_byte)png_ptr->background.red;
                  back.green = (png_byte)png_ptr->background.green;
                  back.blue  = (png_byte)png_ptr->background.blue;
               }
               else
               {
                  back.red = (png_byte)(pow(
                     (double)png_ptr->background.red/255, gs) * 255.0 + .5);
                  back.green = (png_byte)(pow(
                     (double)png_ptr->background.green/255, gs) * 255.0
                         + .5);
                  back.blue = (png_byte)(pow(
                     (double)png_ptr->background.blue/255, gs) * 255.0 + .5);
               }

               back_1.red = (png_byte)(pow(
                  (double)png_ptr->background.red/255, g) * 255.0 + .5);
               back_1.green = (png_byte)(pow(
                  (double)png_ptr->background.green/255, g) * 255.0 + .5);
               back_1.blue = (png_byte)(pow(
                  (double)png_ptr->background.blue/255, g) * 255.0 + .5);
            }
            for (i = 0; i < num_palette; i++)
            {
               if (i < (int)png_ptr->num_trans && png_ptr->trans[i] != 0xff)
               {
                  if (png_ptr->trans[i] == 0)
                  {
                     palette[i] = back;
                  }
                  else /* if (png_ptr->trans[i] != 0xff) */
                  {
                     png_byte v, w;

                     v = png_ptr->gamma_to_1[palette[i].red];
                     png_composite(w, v, png_ptr->trans[i], back_1.red);
                     palette[i].red = png_ptr->gamma_from_1[w];

                     v = png_ptr->gamma_to_1[palette[i].green];
                     png_composite(w, v, png_ptr->trans[i], back_1.green);
                     palette[i].green = png_ptr->gamma_from_1[w];

                     v = png_ptr->gamma_to_1[palette[i].blue];
                     png_composite(w, v, png_ptr->trans[i], back_1.blue);
                     palette[i].blue = png_ptr->gamma_from_1[w];
                  }
               }
               else
               {
                  palette[i].red = png_ptr->gamma_table[palette[i].red];
                  palette[i].green = png_ptr->gamma_table[palette[i].green];
                  palette[i].blue = png_ptr->gamma_table[palette[i].blue];
               }
            }
            /* Prevent the transformations being done again, and make sure
             * that the now spurious alpha channel is stripped - the code
             * has just reduced background composition and gamma correction
             * to a simple alpha channel strip.
             */
            png_ptr->transformations &= ~PNG_BACKGROUND;
            png_ptr->transformations &= ~PNG_GAMMA;
            png_ptr->transformations |= PNG_STRIP_ALPHA;
         }
         /* if (png_ptr->background_gamma_type!=PNG_BACKGROUND_GAMMA_UNKNOWN) */
         else
         /* color_type != PNG_COLOR_TYPE_PALETTE */
         {
            double m = (double)(((png_uint_32)1 << png_ptr->bit_depth) - 1);
            double g = 1.0;
            double gs = 1.0;

            switch (png_ptr->background_gamma_type)
            {
               case PNG_BACKGROUND_GAMMA_SCREEN:
                  g = (png_ptr->screen_gamma);
                  gs = 1.0;
                  break;

               case PNG_BACKGROUND_GAMMA_FILE:
                  g = 1.0 / (png_ptr->gamma);
                  gs = 1.0 / (png_ptr->gamma * png_ptr->screen_gamma);
                  break;

               case PNG_BACKGROUND_GAMMA_UNIQUE:
                  g = 1.0 / (png_ptr->background_gamma);
                  gs = 1.0 / (png_ptr->background_gamma *
                     png_ptr->screen_gamma);
                  break;
            }

            png_ptr->background_1.gray = (png_uint_16)(pow(
               (double)png_ptr->background.gray / m, g) * m + .5);
            png_ptr->background.gray = (png_uint_16)(pow(
               (double)png_ptr->background.gray / m, gs) * m + .5);

            if ((png_ptr->background.red != png_ptr->background.green) ||
                (png_ptr->background.red != png_ptr->background.blue) ||
                (png_ptr->background.red != png_ptr->background.gray))
            {
               /* RGB or RGBA with color background */
               png_ptr->background_1.red = (png_uint_16)(pow(
                  (double)png_ptr->background.red / m, g) * m + .5);
               png_ptr->background_1.green = (png_uint_16)(pow(
                  (double)png_ptr->background.green / m, g) * m + .5);
               png_ptr->background_1.blue = (png_uint_16)(pow(
                  (double)png_ptr->background.blue / m, g) * m + .5);
               png_ptr->background.red = (png_uint_16)(pow(
                  (double)png_ptr->background.red / m, gs) * m + .5);
               png_ptr->background.green = (png_uint_16)(pow(
                  (double)png_ptr->background.green / m, gs) * m + .5);
               png_ptr->background.blue = (png_uint_16)(pow(
                  (double)png_ptr->background.blue / m, gs) * m + .5);
            }
            else
            {
               /* GRAY, GRAY ALPHA, RGB, or RGBA with gray background */
               png_ptr->background_1.red = png_ptr->background_1.green
                 = png_ptr->background_1.blue = png_ptr->background_1.gray;
               png_ptr->background.red = png_ptr->background.green
                 = png_ptr->background.blue = png_ptr->background.gray;
            }
         }
      }
      else
      /* Transformation does not include PNG_BACKGROUND */
#endif /* PNG_READ_BACKGROUND_SUPPORTED */
      if (color_type == PNG_COLOR_TYPE_PALETTE)
      {
         png_colorp palette = png_ptr->palette;
         int num_palette = png_ptr->num_palette;
         int i;

         for (i = 0; i < num_palette; i++)
         {
            palette[i].red = png_ptr->gamma_table[palette[i].red];
            palette[i].green = png_ptr->gamma_table[palette[i].green];
            palette[i].blue = png_ptr->gamma_table[palette[i].blue];
         }

         /* Done the gamma correction. */
         png_ptr->transformations &= ~PNG_GAMMA;
      }
   }
#ifdef PNG_READ_BACKGROUND_SUPPORTED
   else
#endif
#endif /* PNG_READ_GAMMA_SUPPORTED && PNG_FLOATING_POINT_SUPPORTED */
#ifdef PNG_READ_BACKGROUND_SUPPORTED
   /* No GAMMA transformation */
   if ((png_ptr->transformations & PNG_BACKGROUND) &&
       (color_type == PNG_COLOR_TYPE_PALETTE))
   {
      int i;
      int istop = (int)png_ptr->num_trans;
      png_color back;
      png_colorp palette = png_ptr->palette;

      back.red   = (png_byte)png_ptr->background.red;
      back.green = (png_byte)png_ptr->background.green;
      back.blue  = (png_byte)png_ptr->background.blue;

      for (i = 0; i < istop; i++)
      {
         if (png_ptr->trans[i] == 0)
         {
            palette[i] = back;
         }
         else if (png_ptr->trans[i] != 0xff)
         {
            /* The png_composite() macro is defined in png.h */
            png_composite(palette[i].red, palette[i].red,
               png_ptr->trans[i], back.red);
            png_composite(palette[i].green, palette[i].green,
               png_ptr->trans[i], back.green);
            png_composite(palette[i].blue, palette[i].blue,
               png_ptr->trans[i], back.blue);
         }
      }

      /* Handled alpha, still need to strip the channel. */
      png_ptr->transformations &= ~PNG_BACKGROUND;
      png_ptr->transformations |= PNG_STRIP_ALPHA;
   }
#endif /* PNG_READ_BACKGROUND_SUPPORTED */

#ifdef PNG_READ_SHIFT_SUPPORTED
   if ((png_ptr->transformations & PNG_SHIFT) &&
      (color_type == PNG_COLOR_TYPE_PALETTE))
   {
      png_uint_16 i;
      png_uint_16 istop = png_ptr->num_palette;
      int sr = 8 - png_ptr->sig_bit.red;
      int sg = 8 - png_ptr->sig_bit.green;
      int sb = 8 - png_ptr->sig_bit.blue;

      if (sr < 0 || sr > 8)
         sr = 0;
      if (sg < 0 || sg > 8)
         sg = 0;
      if (sb < 0 || sb > 8)
         sb = 0;
      for (i = 0; i < istop; i++)
      {
         png_ptr->palette[i].red >>= sr;
         png_ptr->palette[i].green >>= sg;
         png_ptr->palette[i].blue >>= sb;
      }
   }
#endif  /* PNG_READ_SHIFT_SUPPORTED */
 }
#if !defined(PNG_READ_GAMMA_SUPPORTED) && !defined(PNG_READ_SHIFT_SUPPORTED) \
 && !defined(PNG_READ_BACKGROUND_SUPPORTED)
   if (png_ptr)
      return;
#endif
}

/* Modify the info structure to reflect the transformations.  The
 * info should be updated so a PNG file could be written with it,
 * assuming the transformations result in valid PNG data.
 */
void /* PRIVATE */
png_read_transform_info(png_structp png_ptr, png_infop info_ptr)
{
   png_debug(1, "in png_read_transform_info");

#ifdef PNG_READ_EXPAND_SUPPORTED
   if (png_ptr->transformations & PNG_EXPAND)
   {
      if (info_ptr->color_type == PNG_COLOR_TYPE_PALETTE)
      {
         if (png_ptr->num_trans)
            info_ptr->color_type = PNG_COLOR_TYPE_RGB_ALPHA;
         else
            info_ptr->color_type = PNG_COLOR_TYPE_RGB;
         info_ptr->bit_depth = 8;
         info_ptr->num_trans = 0;
      }
      else
      {
         if (png_ptr->num_trans)
         {
            if (png_ptr->transformations & PNG_EXPAND_tRNS)
              info_ptr->color_type |= PNG_COLOR_MASK_ALPHA;
         }
         if (info_ptr->bit_depth < 8)
            info_ptr->bit_depth = 8;
         info_ptr->num_trans = 0;
      }
   }
#endif

#ifdef PNG_READ_BACKGROUND_SUPPORTED
   if (png_ptr->transformations & PNG_BACKGROUND)
   {
      info_ptr->color_type &= ~PNG_COLOR_MASK_ALPHA;
      info_ptr->num_trans = 0;
      info_ptr->background = png_ptr->background;
   }
#endif

#ifdef PNG_READ_GAMMA_SUPPORTED
   if (png_ptr->transformations & PNG_GAMMA)
   {
#ifdef PNG_FLOATING_POINT_SUPPORTED
      info_ptr->gamma = png_ptr->gamma;
#endif
#ifdef PNG_FIXED_POINT_SUPPORTED
      info_ptr->int_gamma = png_ptr->int_gamma;
#endif
   }
#endif

#ifdef PNG_READ_16_TO_8_SUPPORTED
   if ((png_ptr->transformations & PNG_16_TO_8) && (info_ptr->bit_depth == 16))
      info_ptr->bit_depth = 8;
#endif

#ifdef PNG_READ_GRAY_TO_RGB_SUPPORTED
   if (png_ptr->transformations & PNG_GRAY_TO_RGB)
      info_ptr->color_type |= PNG_COLOR_MASK_COLOR;
#endif

#ifdef PNG_READ_RGB_TO_GRAY_SUPPORTED
   if (png_ptr->transformations & PNG_RGB_TO_GRAY)
      info_ptr->color_type &= ~PNG_COLOR_MASK_COLOR;
#endif

#ifdef PNG_READ_DITHER_SUPPORTED
   if (png_ptr->transformations & PNG_DITHER)
   {
      if (((info_ptr->color_type == PNG_COLOR_TYPE_RGB) ||
          (info_ptr->color_type == PNG_COLOR_TYPE_RGB_ALPHA)) &&
          png_ptr->palette_lookup && info_ptr->bit_depth == 8)
      {
         info_ptr->color_type = PNG_COLOR_TYPE_PALETTE;
      }
   }
#endif

#ifdef PNG_READ_PACK_SUPPORTED
   if ((png_ptr->transformations & PNG_PACK) && (info_ptr->bit_depth < 8))
      info_ptr->bit_depth = 8;
#endif

   if (info_ptr->color_type == PNG_COLOR_TYPE_PALETTE)
      info_ptr->channels = 1;
   else if (info_ptr->color_type & PNG_COLOR_MASK_COLOR)
      info_ptr->channels = 3;
   else
      info_ptr->channels = 1;

#ifdef PNG_READ_STRIP_ALPHA_SUPPORTED
   if (png_ptr->flags & PNG_FLAG_STRIP_ALPHA)
      info_ptr->color_type &= ~PNG_COLOR_MASK_ALPHA;
#endif

   if (info_ptr->color_type & PNG_COLOR_MASK_ALPHA)
      info_ptr->channels++;

#ifdef PNG_READ_FILLER_SUPPORTED
   /* STRIP_ALPHA and FILLER allowed:  MASK_ALPHA bit stripped above */
   if ((png_ptr->transformations & PNG_FILLER) &&
       ((info_ptr->color_type == PNG_COLOR_TYPE_RGB) ||
       (info_ptr->color_type == PNG_COLOR_TYPE_GRAY)))
   {
      info_ptr->channels++;
      /* If adding a true alpha channel not just filler */
#ifndef PNG_1_0_X
      if (png_ptr->transformations & PNG_ADD_ALPHA)
        info_ptr->color_type |= PNG_COLOR_MASK_ALPHA;
#endif
   }
#endif

#if defined(PNG_USER_TRANSFORM_PTR_SUPPORTED) && \
defined(PNG_READ_USER_TRANSFORM_SUPPORTED)
   if (png_ptr->transformations & PNG_USER_TRANSFORM)
     {
       if (info_ptr->bit_depth < png_ptr->user_transform_depth)
         info_ptr->bit_depth = png_ptr->user_transform_depth;
       if (info_ptr->channels < png_ptr->user_transform_channels)
         info_ptr->channels = png_ptr->user_transform_channels;
     }
#endif

   info_ptr->pixel_depth = (png_byte)(info_ptr->channels *
      info_ptr->bit_depth);

   info_ptr->rowbytes = PNG_ROWBYTES(info_ptr->pixel_depth, info_ptr->width);

#ifndef PNG_READ_EXPAND_SUPPORTED
   if (png_ptr)
      return;
#endif
}

/* Transform the row.  The order of transformations is significant,
 * and is very touchy.  If you add a transformation, take care to
 * decide how it fits in with the other transformations here.
 */
void /* PRIVATE */
png_do_read_transformations(png_structp png_ptr)
{
   png_debug(1, "in png_do_read_transformations");

   if (png_ptr->row_buf == NULL)
   {
#if defined(PNG_STDIO_SUPPORTED) && !defined(_WIN32_WCE)
      char msg[50];

      png_snprintf2(msg, 50,
         "NULL row buffer for row %ld, pass %d", (long)png_ptr->row_number,
         png_ptr->pass);
      png_error(png_ptr, msg);
#else
      png_error(png_ptr, "NULL row buffer");
#endif
   }
#ifdef PNG_WARN_UNINITIALIZED_ROW
   if (!(png_ptr->flags & PNG_FLAG_ROW_INIT))
      /* Application has failed to call either png_read_start_image()
       * or png_read_update_info() after setting transforms that expand
       * pixels.  This check added to libpng-1.2.19
       */
#if (PNG_WARN_UNINITIALIZED_ROW==1)
      png_error(png_ptr, "Uninitialized row");
#else
      png_warning(png_ptr, "Uninitialized row");
#endif
#endif

#ifdef PNG_READ_EXPAND_SUPPORTED
   if (png_ptr->transformations & PNG_EXPAND)
   {
      if (png_ptr->row_info.color_type == PNG_COLOR_TYPE_PALETTE)
      {
         png_do_expand_palette(&(png_ptr->row_info), png_ptr->row_buf + 1,
            png_ptr->palette, png_ptr->trans, png_ptr->num_trans);
      }
      else
      {
         if (png_ptr->num_trans &&
             (png_ptr->transformations & PNG_EXPAND_tRNS))
            png_do_expand(&(png_ptr->row_info), png_ptr->row_buf + 1,
               &(png_ptr->trans_values));
         else
            png_do_expand(&(png_ptr->row_info), png_ptr->row_buf + 1,
               NULL);
      }
   }
#endif

#ifdef PNG_READ_STRIP_ALPHA_SUPPORTED
   if (png_ptr->flags & PNG_FLAG_STRIP_ALPHA)
      png_do_strip_filler(&(png_ptr->row_info), png_ptr->row_buf + 1,
         PNG_FLAG_FILLER_AFTER | (png_ptr->flags & PNG_FLAG_STRIP_ALPHA));
#endif

#ifdef PNG_READ_RGB_TO_GRAY_SUPPORTED
   if (png_ptr->transformations & PNG_RGB_TO_GRAY)
   {
      int rgb_error =
         png_do_rgb_to_gray(png_ptr, &(png_ptr->row_info),
             png_ptr->row_buf + 1);
      if (rgb_error)
      {
         png_ptr->rgb_to_gray_status=1;
         if ((png_ptr->transformations & PNG_RGB_TO_GRAY) ==
             PNG_RGB_TO_GRAY_WARN)
            png_warning(png_ptr, "png_do_rgb_to_gray found nongray pixel");
         if ((png_ptr->transformations & PNG_RGB_TO_GRAY) ==
             PNG_RGB_TO_GRAY_ERR)
            png_error(png_ptr, "png_do_rgb_to_gray found nongray pixel");
      }
   }
#endif

/* From Andreas Dilger e-mail to png-implement, 26 March 1998:
 *
 *   In most cases, the "simple transparency" should be done prior to doing
 *   gray-to-RGB, or you will have to test 3x as many bytes to check if a
 *   pixel is transparent.  You would also need to make sure that the
 *   transparency information is upgraded to RGB.
 *
 *   To summarize, the current flow is:
 *   - Gray + simple transparency -> compare 1 or 2 gray bytes and composite
 *                                   with background "in place" if transparent,
 *                                   convert to RGB if necessary
 *   - Gray + alpha -> composite with gray background and remove alpha bytes,
 *                                   convert to RGB if necessary
 *
 *   To support RGB backgrounds for gray images we need:
 *   - Gray + simple transparency -> convert to RGB + simple transparency,
 *                                   compare 3 or 6 bytes and composite with
 *                                   background "in place" if transparent
 *                                   (3x compare/pixel compared to doing
 *                                   composite with gray bkgrnd)
 *   - Gray + alpha -> convert to RGB + alpha, composite with background and
 *                                   remove alpha bytes (3x float
 *                                   operations/pixel compared with composite
 *                                   on gray background)
 *
 *  Greg's change will do this.  The reason it wasn't done before is for
 *  performance, as this increases the per-pixel operations.  If we would check
 *  in advance if the background was gray or RGB, and position the gray-to-RGB
 *  transform appropriately, then it would save a lot of work/time.
 */

#ifdef PNG_READ_GRAY_TO_RGB_SUPPORTED
   /* If gray -> RGB, do so now only if background is non-gray; else do later
    * for performance reasons
    */
   if ((png_ptr->transformations & PNG_GRAY_TO_RGB) &&
       !(png_ptr->mode & PNG_BACKGROUND_IS_GRAY))
      png_do_gray_to_rgb(&(png_ptr->row_info), png_ptr->row_buf + 1);
#endif

#ifdef PNG_READ_BACKGROUND_SUPPORTED
   if ((png_ptr->transformations & PNG_BACKGROUND) &&
      ((png_ptr->num_trans != 0 ) ||
      (png_ptr->color_type & PNG_COLOR_MASK_ALPHA)))
      png_do_background(&(png_ptr->row_info), png_ptr->row_buf + 1,
         &(png_ptr->trans_values), &(png_ptr->background)
#ifdef PNG_READ_GAMMA_SUPPORTED
         , &(png_ptr->background_1),
         png_ptr->gamma_table, png_ptr->gamma_from_1,
         png_ptr->gamma_to_1, png_ptr->gamma_16_table,
         png_ptr->gamma_16_from_1, png_ptr->gamma_16_to_1,
         png_ptr->gamma_shift
#endif
);
#endif

#ifdef PNG_READ_GAMMA_SUPPORTED
   if ((png_ptr->transformations & PNG_GAMMA) &&
#ifdef PNG_READ_BACKGROUND_SUPPORTED
       !((png_ptr->transformations & PNG_BACKGROUND) &&
       ((png_ptr->num_trans != 0) ||
       (png_ptr->color_type & PNG_COLOR_MASK_ALPHA))) &&
#endif
       (png_ptr->color_type != PNG_COLOR_TYPE_PALETTE))
      png_do_gamma(&(png_ptr->row_info), png_ptr->row_buf + 1,
          png_ptr->gamma_table, png_ptr->gamma_16_table,
          png_ptr->gamma_shift);
#endif

#ifdef PNG_READ_16_TO_8_SUPPORTED
   if (png_ptr->transformations & PNG_16_TO_8)
      png_do_chop(&(png_ptr->row_info), png_ptr->row_buf + 1);
#endif

#ifdef PNG_READ_DITHER_SUPPORTED
   if (png_ptr->transformations & PNG_DITHER)
   {
      png_do_dither((png_row_infop)&(png_ptr->row_info), png_ptr->row_buf + 1,
         png_ptr->palette_lookup, png_ptr->dither_index);
      if (png_ptr->row_info.rowbytes == (png_uint_32)0)
         png_error(png_ptr, "png_do_dither returned rowbytes=0");
   }
#endif

#ifdef PNG_READ_INVERT_SUPPORTED
   if (png_ptr->transformations & PNG_INVERT_MONO)
      png_do_invert(&(png_ptr->row_info), png_ptr->row_buf + 1);
#endif

#ifdef PNG_READ_SHIFT_SUPPORTED
   if (png_ptr->transformations & PNG_SHIFT)
      png_do_unshift(&(png_ptr->row_info), png_ptr->row_buf + 1,
         &(png_ptr->shift));
#endif

#ifdef PNG_READ_PACK_SUPPORTED
   if (png_ptr->transformations & PNG_PACK)
      png_do_unpack(&(png_ptr->row_info), png_ptr->row_buf + 1);
#endif

#ifdef PNG_READ_BGR_SUPPORTED
   if (png_ptr->transformations & PNG_BGR)
      png_do_bgr(&(png_ptr->row_info), png_ptr->row_buf + 1);
#endif

#ifdef PNG_READ_PACKSWAP_SUPPORTED
   if (png_ptr->transformations & PNG_PACKSWAP)
      png_do_packswap(&(png_ptr->row_info), png_ptr->row_buf + 1);
#endif

#ifdef PNG_READ_GRAY_TO_RGB_SUPPORTED
   /* If gray -> RGB, do so now only if we did not do so above */
   if ((png_ptr->transformations & PNG_GRAY_TO_RGB) &&
       (png_ptr->mode & PNG_BACKGROUND_IS_GRAY))
      png_do_gray_to_rgb(&(png_ptr->row_info), png_ptr->row_buf + 1);
#endif

#ifdef PNG_READ_FILLER_SUPPORTED
   if (png_ptr->transformations & PNG_FILLER)
      png_do_read_filler(&(png_ptr->row_info), png_ptr->row_buf + 1,
         (png_uint_32)png_ptr->filler, png_ptr->flags);
#endif

#ifdef PNG_READ_INVERT_ALPHA_SUPPORTED
   if (png_ptr->transformations & PNG_INVERT_ALPHA)
      png_do_read_invert_alpha(&(png_ptr->row_info), png_ptr->row_buf + 1);
#endif

#ifdef PNG_READ_SWAP_ALPHA_SUPPORTED
   if (png_ptr->transformations & PNG_SWAP_ALPHA)
      png_do_read_swap_alpha(&(png_ptr->row_info), png_ptr->row_buf + 1);
#endif

#ifdef PNG_READ_SWAP_SUPPORTED
   if (png_ptr->transformations & PNG_SWAP_BYTES)
      png_do_swap(&(png_ptr->row_info), png_ptr->row_buf + 1);
#endif

#ifdef PNG_READ_USER_TRANSFORM_SUPPORTED
   if (png_ptr->transformations & PNG_USER_TRANSFORM)
    {
      if (png_ptr->read_user_transform_fn != NULL)
         (*(png_ptr->read_user_transform_fn)) /* User read transform function */
            (png_ptr,                    /* png_ptr */
               &(png_ptr->row_info),     /* row_info: */
               /*  png_uint_32 width;       width of row */
               /*  png_uint_32 rowbytes;    number of bytes in row */
               /*  png_byte color_type;     color type of pixels */
               /*  png_byte bit_depth;      bit depth of samples */
               /*  png_byte channels;       number of channels (1-4) */
               /*  png_byte pixel_depth;    bits per pixel (depth*channels) */
               png_ptr->row_buf + 1);    /* start of pixel data for row */
#ifdef PNG_USER_TRANSFORM_PTR_SUPPORTED
      if (png_ptr->user_transform_depth)
         png_ptr->row_info.bit_depth = png_ptr->user_transform_depth;
      if (png_ptr->user_transform_channels)
         png_ptr->row_info.channels = png_ptr->user_transform_channels;
#endif
      png_ptr->row_info.pixel_depth = (png_byte)(png_ptr->row_info.bit_depth *
         png_ptr->row_info.channels);
      png_ptr->row_info.rowbytes = PNG_ROWBYTES(png_ptr->row_info.pixel_depth,
         png_ptr->row_info.width);
   }
#endif

}

#ifdef PNG_READ_PACK_SUPPORTED
/* Unpack pixels of 1, 2, or 4 bits per pixel into 1 byte per pixel,
 * without changing the actual values.  Thus, if you had a row with
 * a bit depth of 1, you would end up with bytes that only contained
 * the numbers 0 or 1.  If you would rather they contain 0 and 255, use
 * png_do_shift() after this.
 */
void /* PRIVATE */
png_do_unpack(png_row_infop row_info, png_bytep row)
{
   png_debug(1, "in png_do_unpack");

#ifdef PNG_USELESS_TESTS_SUPPORTED
   if (row != NULL && row_info != NULL && row_info->bit_depth < 8)
#else
   if (row_info->bit_depth < 8)
#endif
   {
      png_uint_32 i;
      png_uint_32 row_width=row_info->width;

      switch (row_info->bit_depth)
      {
         case 1:
         {
            png_bytep sp = row + (png_size_t)((row_width - 1) >> 3);
            png_bytep dp = row + (png_size_t)row_width - 1;
            png_uint_32 shift = 7 - (int)((row_width + 7) & 0x07);
            for (i = 0; i < row_width; i++)
            {
               *dp = (png_byte)((*sp >> shift) & 0x01);
               if (shift == 7)
               {
                  shift = 0;
                  sp--;
               }
               else
                  shift++;

               dp--;
            }
            break;
         }

         case 2:
         {

            png_bytep sp = row + (png_size_t)((row_width - 1) >> 2);
            png_bytep dp = row + (png_size_t)row_width - 1;
            png_uint_32 shift = (int)((3 - ((row_width + 3) & 0x03)) << 1);
            for (i = 0; i < row_width; i++)
            {
               *dp = (png_byte)((*sp >> shift) & 0x03);
               if (shift == 6)
               {
                  shift = 0;
                  sp--;
               }
               else
                  shift += 2;

               dp--;
            }
            break;
         }

         case 4:
         {
            png_bytep sp = row + (png_size_t)((row_width - 1) >> 1);
            png_bytep dp = row + (png_size_t)row_width - 1;
            png_uint_32 shift = (int)((1 - ((row_width + 1) & 0x01)) << 2);
            for (i = 0; i < row_width; i++)
            {
               *dp = (png_byte)((*sp >> shift) & 0x0f);
               if (shift == 4)
               {
                  shift = 0;
                  sp--;
               }
               else
                  shift = 4;

               dp--;
            }
            break;
         }
      }
      row_info->bit_depth = 8;
      row_info->pixel_depth = (png_byte)(8 * row_info->channels);
      row_info->rowbytes = row_width * row_info->channels;
   }
}
#endif

#ifdef PNG_READ_SHIFT_SUPPORTED
/* Reverse the effects of png_do_shift.  This routine merely shifts the
 * pixels back to their significant bits values.  Thus, if you have
 * a row of bit depth 8, but only 5 are significant, this will shift
 * the values back to 0 through 31.
 */
void /* PRIVATE */
png_do_unshift(png_row_infop row_info, png_bytep row, png_color_8p sig_bits)
{
   png_debug(1, "in png_do_unshift");

   if (
#ifdef PNG_USELESS_TESTS_SUPPORTED
       row != NULL && row_info != NULL && sig_bits != NULL &&
#endif
       row_info->color_type != PNG_COLOR_TYPE_PALETTE)
   {
      int shift[4];
      int channels = 0;
      int c;
      png_uint_16 value = 0;
      png_uint_32 row_width = row_info->width;

      if (row_info->color_type & PNG_COLOR_MASK_COLOR)
      {
         shift[channels++] = row_info->bit_depth - sig_bits->red;
         shift[channels++] = row_info->bit_depth - sig_bits->green;
         shift[channels++] = row_info->bit_depth - sig_bits->blue;
      }
      else
      {
         shift[channels++] = row_info->bit_depth - sig_bits->gray;
      }
      if (row_info->color_type & PNG_COLOR_MASK_ALPHA)
      {
         shift[channels++] = row_info->bit_depth - sig_bits->alpha;
      }

      for (c = 0; c < channels; c++)
      {
         if (shift[c] <= 0)
            shift[c] = 0;
         else
            value = 1;
      }

      if (!value)
         return;

      switch (row_info->bit_depth)
      {
         case 2:
         {
            png_bytep bp;
            png_uint_32 i;
            png_uint_32 istop = row_info->rowbytes;

            for (bp = row, i = 0; i < istop; i++)
            {
               *bp >>= 1;
               *bp++ &= 0x55;
            }
            break;
         }

         case 4:
         {
            png_bytep bp = row;
            png_uint_32 i;
            png_uint_32 istop = row_info->rowbytes;
            png_byte mask = (png_byte)((((int)0xf0 >> shift[0]) & (int)0xf0) |
               (png_byte)((int)0xf >> shift[0]));

            for (i = 0; i < istop; i++)
            {
               *bp >>= shift[0];
               *bp++ &= mask;
            }
            break;
         }

         case 8:
         {
            png_bytep bp = row;
            png_uint_32 i;
            png_uint_32 istop = row_width * channels;

            for (i = 0; i < istop; i++)
            {
               *bp++ >>= shift[i%channels];
            }
            break;
         }

         case 16:
         {
            png_bytep bp = row;
            png_uint_32 i;
            png_uint_32 istop = channels * row_width;

            for (i = 0; i < istop; i++)
            {
               value = (png_uint_16)((*bp << 8) + *(bp + 1));
               value >>= shift[i%channels];
               *bp++ = (png_byte)(value >> 8);
               *bp++ = (png_byte)(value & 0xff);
            }
            break;
         }
      }
   }
}
#endif

#ifdef PNG_READ_16_TO_8_SUPPORTED
/* Chop rows of bit depth 16 down to 8 */
void /* PRIVATE */
png_do_chop(png_row_infop row_info, png_bytep row)
{
   png_debug(1, "in png_do_chop");

#ifdef PNG_USELESS_TESTS_SUPPORTED
   if (row != NULL && row_info != NULL && row_info->bit_depth == 16)
#else
   if (row_info->bit_depth == 16)
#endif
   {
      png_bytep sp = row;
      png_bytep dp = row;
      png_uint_32 i;
      png_uint_32 istop = row_info->width * row_info->channels;

      for (i = 0; i<istop; i++, sp += 2, dp++)
      {
#ifdef PNG_READ_16_TO_8_ACCURATE_SCALE_SUPPORTED
      /* This does a more accurate scaling of the 16-bit color
       * value, rather than a simple low-byte truncation.
       *
       * What the ideal calculation should be:
       *   *dp = (((((png_uint_32)(*sp) << 8) |
       *          (png_uint_32)(*(sp + 1))) * 255 + 127)
       *          / (png_uint_32)65535L;
       *
       * GRR: no, I think this is what it really should be:
       *   *dp = (((((png_uint_32)(*sp) << 8) |
       *           (png_uint_32)(*(sp + 1))) + 128L)
       *           / (png_uint_32)257L;
       *
       * GRR: here's the exact calculation with shifts:
       *   temp = (((png_uint_32)(*sp) << 8) |
       *           (png_uint_32)(*(sp + 1))) + 128L;
       *   *dp = (temp - (temp >> 8)) >> 8;
       *
       * Approximate calculation with shift/add instead of multiply/divide:
       *   *dp = ((((png_uint_32)(*sp) << 8) |
       *          (png_uint_32)((int)(*(sp + 1)) - *sp)) + 128) >> 8;
       *
       * What we actually do to avoid extra shifting and conversion:
       */

         *dp = *sp + ((((int)(*(sp + 1)) - *sp) > 128) ? 1 : 0);
#else
       /* Simply discard the low order byte */
         *dp = *sp;
#endif
      }
      row_info->bit_depth = 8;
      row_info->pixel_depth = (png_byte)(8 * row_info->channels);
      row_info->rowbytes = row_info->width * row_info->channels;
   }
}
#endif

#ifdef PNG_READ_SWAP_ALPHA_SUPPORTED
void /* PRIVATE */
png_do_read_swap_alpha(png_row_infop row_info, png_bytep row)
{
   png_debug(1, "in png_do_read_swap_alpha");

#ifdef PNG_USELESS_TESTS_SUPPORTED
   if (row != NULL && row_info != NULL)
#endif
   {
      png_uint_32 row_width = row_info->width;
      if (row_info->color_type == PNG_COLOR_TYPE_RGB_ALPHA)
      {
         /* This converts from RGBA to ARGB */
         if (row_info->bit_depth == 8)
         {
            png_bytep sp = row + row_info->rowbytes;
            png_bytep dp = sp;
            png_byte save;
            png_uint_32 i;

            for (i = 0; i < row_width; i++)
            {
               save = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = save;
            }
         }
         /* This converts from RRGGBBAA to AARRGGBB */
         else
         {
            png_bytep sp = row + row_info->rowbytes;
            png_bytep dp = sp;
            png_byte save[2];
            png_uint_32 i;

            for (i = 0; i < row_width; i++)
            {
               save[0] = *(--sp);
               save[1] = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = save[0];
               *(--dp) = save[1];
            }
         }
      }
      else if (row_info->color_type == PNG_COLOR_TYPE_GRAY_ALPHA)
      {
         /* This converts from GA to AG */
         if (row_info->bit_depth == 8)
         {
            png_bytep sp = row + row_info->rowbytes;
            png_bytep dp = sp;
            png_byte save;
            png_uint_32 i;

            for (i = 0; i < row_width; i++)
            {
               save = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = save;
            }
         }
         /* This converts from GGAA to AAGG */
         else
         {
            png_bytep sp = row + row_info->rowbytes;
            png_bytep dp = sp;
            png_byte save[2];
            png_uint_32 i;

            for (i = 0; i < row_width; i++)
            {
               save[0] = *(--sp);
               save[1] = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = save[0];
               *(--dp) = save[1];
            }
         }
      }
   }
}
#endif

#ifdef PNG_READ_INVERT_ALPHA_SUPPORTED
void /* PRIVATE */
png_do_read_invert_alpha(png_row_infop row_info, png_bytep row)
{
   png_debug(1, "in png_do_read_invert_alpha");

#ifdef PNG_USELESS_TESTS_SUPPORTED
   if (row != NULL && row_info != NULL)
#endif
   {
      png_uint_32 row_width = row_info->width;
      if (row_info->color_type == PNG_COLOR_TYPE_RGB_ALPHA)
      {
         /* This inverts the alpha channel in RGBA */
         if (row_info->bit_depth == 8)
         {
            png_bytep sp = row + row_info->rowbytes;
            png_bytep dp = sp;
            png_uint_32 i;

            for (i = 0; i < row_width; i++)
            {
               *(--dp) = (png_byte)(255 - *(--sp));

/*             This does nothing:
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               We can replace it with:
*/
               sp-=3;
               dp=sp;
            }
         }
         /* This inverts the alpha channel in RRGGBBAA */
         else
         {
            png_bytep sp = row + row_info->rowbytes;
            png_bytep dp = sp;
            png_uint_32 i;

            for (i = 0; i < row_width; i++)
            {
               *(--dp) = (png_byte)(255 - *(--sp));
               *(--dp) = (png_byte)(255 - *(--sp));

/*             This does nothing:
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               We can replace it with:
*/
               sp-=6;
               dp=sp;
            }
         }
      }
      else if (row_info->color_type == PNG_COLOR_TYPE_GRAY_ALPHA)
      {
         /* This inverts the alpha channel in GA */
         if (row_info->bit_depth == 8)
         {
            png_bytep sp = row + row_info->rowbytes;
            png_bytep dp = sp;
            png_uint_32 i;

            for (i = 0; i < row_width; i++)
            {
               *(--dp) = (png_byte)(255 - *(--sp));
               *(--dp) = *(--sp);
            }
         }
         /* This inverts the alpha channel in GGAA */
         else
         {
            png_bytep sp  = row + row_info->rowbytes;
            png_bytep dp = sp;
            png_uint_32 i;

            for (i = 0; i < row_width; i++)
            {
               *(--dp) = (png_byte)(255 - *(--sp));
               *(--dp) = (png_byte)(255 - *(--sp));
/*
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
*/
               sp-=2;
               dp=sp;
            }
         }
      }
   }
}
#endif

#ifdef PNG_READ_FILLER_SUPPORTED
/* Add filler channel if we have RGB color */
void /* PRIVATE */
png_do_read_filler(png_row_infop row_info, png_bytep row,
   png_uint_32 filler, png_uint_32 flags)
{
   png_uint_32 i;
   png_uint_32 row_width = row_info->width;

   png_byte hi_filler = (png_byte)((filler>>8) & 0xff);
   png_byte lo_filler = (png_byte)(filler & 0xff);

   png_debug(1, "in png_do_read_filler");

   if (
#ifdef PNG_USELESS_TESTS_SUPPORTED
       row != NULL  && row_info != NULL &&
#endif
       row_info->color_type == PNG_COLOR_TYPE_GRAY)
   {
      if (row_info->bit_depth == 8)
      {
         /* This changes the data from G to GX */
         if (flags & PNG_FLAG_FILLER_AFTER)
         {
            png_bytep sp = row + (png_size_t)row_width;
            png_bytep dp =  sp + (png_size_t)row_width;
            for (i = 1; i < row_width; i++)
            {
               *(--dp) = lo_filler;
               *(--dp) = *(--sp);
            }
            *(--dp) = lo_filler;
            row_info->channels = 2;
            row_info->pixel_depth = 16;
            row_info->rowbytes = row_width * 2;
         }
      /* This changes the data from G to XG */
         else
         {
            png_bytep sp = row + (png_size_t)row_width;
            png_bytep dp = sp  + (png_size_t)row_width;
            for (i = 0; i < row_width; i++)
            {
               *(--dp) = *(--sp);
               *(--dp) = lo_filler;
            }
            row_info->channels = 2;
            row_info->pixel_depth = 16;
            row_info->rowbytes = row_width * 2;
         }
      }
      else if (row_info->bit_depth == 16)
      {
         /* This changes the data from GG to GGXX */
         if (flags & PNG_FLAG_FILLER_AFTER)
         {
            png_bytep sp = row + (png_size_t)row_width * 2;
            png_bytep dp = sp  + (png_size_t)row_width * 2;
            for (i = 1; i < row_width; i++)
            {
               *(--dp) = hi_filler;
               *(--dp) = lo_filler;
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
            }
            *(--dp) = hi_filler;
            *(--dp) = lo_filler;
            row_info->channels = 2;
            row_info->pixel_depth = 32;
            row_info->rowbytes = row_width * 4;
         }
         /* This changes the data from GG to XXGG */
         else
         {
            png_bytep sp = row + (png_size_t)row_width * 2;
            png_bytep dp = sp  + (png_size_t)row_width * 2;
            for (i = 0; i < row_width; i++)
            {
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = hi_filler;
               *(--dp) = lo_filler;
            }
            row_info->channels = 2;
            row_info->pixel_depth = 32;
            row_info->rowbytes = row_width * 4;
         }
      }
   } /* COLOR_TYPE == GRAY */
   else if (row_info->color_type == PNG_COLOR_TYPE_RGB)
   {
      if (row_info->bit_depth == 8)
      {
         /* This changes the data from RGB to RGBX */
         if (flags & PNG_FLAG_FILLER_AFTER)
         {
            png_bytep sp = row + (png_size_t)row_width * 3;
            png_bytep dp = sp  + (png_size_t)row_width;
            for (i = 1; i < row_width; i++)
            {
               *(--dp) = lo_filler;
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
            }
            *(--dp) = lo_filler;
            row_info->channels = 4;
            row_info->pixel_depth = 32;
            row_info->rowbytes = row_width * 4;
         }
      /* This changes the data from RGB to XRGB */
         else
         {
            png_bytep sp = row + (png_size_t)row_width * 3;
            png_bytep dp = sp + (png_size_t)row_width;
            for (i = 0; i < row_width; i++)
            {
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = lo_filler;
            }
            row_info->channels = 4;
            row_info->pixel_depth = 32;
            row_info->rowbytes = row_width * 4;
         }
      }
      else if (row_info->bit_depth == 16)
      {
         /* This changes the data from RRGGBB to RRGGBBXX */
         if (flags & PNG_FLAG_FILLER_AFTER)
         {
            png_bytep sp = row + (png_size_t)row_width * 6;
            png_bytep dp = sp  + (png_size_t)row_width * 2;
            for (i = 1; i < row_width; i++)
            {
               *(--dp) = hi_filler;
               *(--dp) = lo_filler;
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
            }
            *(--dp) = hi_filler;
            *(--dp) = lo_filler;
            row_info->channels = 4;
            row_info->pixel_depth = 64;
            row_info->rowbytes = row_width * 8;
         }
         /* This changes the data from RRGGBB to XXRRGGBB */
         else
         {
            png_bytep sp = row + (png_size_t)row_width * 6;
            png_bytep dp = sp  + (png_size_t)row_width * 2;
            for (i = 0; i < row_width; i++)
            {
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = *(--sp);
               *(--dp) = hi_filler;
               *(--dp) = lo_filler;
            }
            row_info->channels = 4;
            row_info->pixel_depth = 64;
            row_info->rowbytes = row_width * 8;
         }
      }
   } /* COLOR_TYPE == RGB */
}
#endif

#ifdef PNG_READ_GRAY_TO_RGB_SUPPORTED
/* Expand grayscale files to RGB, with or without alpha */
void /* PRIVATE */
png_do_gray_to_rgb(png_row_infop row_info, png_bytep row)
{
   png_uint_32 i;
   png_uint_32 row_width = row_info->width;

   png_debug(1, "in png_do_gray_to_rgb");

   if (row_info->bit_depth >= 8 &&
#ifdef PNG_USELESS_TESTS_SUPPORTED
       row != NULL && row_info != NULL &&
#endif
      !(row_info->color_type & PNG_COLOR_MASK_COLOR))
   {
      if (row_info->color_type == PNG_COLOR_TYPE_GRAY)
      {
         if (row_info->bit_depth == 8)
         {
            png_bytep sp = row + (png_size_t)row_width - 1;
            png_bytep dp = sp  + (png_size_t)row_width * 2;
            for (i = 0; i < row_width; i++)
            {
               *(dp--) = *sp;
               *(dp--) = *sp;
               *(dp--) = *(sp--);
            }
         }
         else
         {
            png_bytep sp = row + (png_size_t)row_width * 2 - 1;
            png_bytep dp = sp  + (png_size_t)row_width * 4;
            for (i = 0; i < row_width; i++)
            {
               *(dp--) = *sp;
               *(dp--) = *(sp - 1);
               *(dp--) = *sp;
               *(dp--) = *(sp - 1);
               *(dp--) = *(sp--);
               *(dp--) = *(sp--);
            }
         }
      }
      else if (row_info->color_type == PNG_COLOR_TYPE_GRAY_ALPHA)
      {
         if (row_info->bit_depth == 8)
         {
            png_bytep sp = row + (png_size_t)row_width * 2 - 1;
            png_bytep dp = sp  + (png_size_t)row_width * 2;
            for (i = 0; i < row_width; i++)
            {
               *(dp--) = *(sp--);
               *(dp--) = *sp;
               *(dp--) = *sp;
               *(dp--) = *(sp--);
            }
         }
         else
         {
            png_bytep sp = row + (png_size_t)row_width * 4 - 1;
            png_bytep dp = sp  + (png_size_t)row_width * 4;
            for (i = 0; i < row_width; i++)
            {
               *(dp--) = *(sp--);
               *(dp--) = *(sp--);
               *(dp--) = *sp;
               *(dp--) = *(sp - 1);
               *(dp--) = *sp;
               *(dp--) = *(sp - 1);
               *(dp--) = *(sp--);
               *(dp--) = *(sp--);
            }
         }
      }
      row_info->channels += (png_byte)2;
      row_info->color_type |= PNG_COLOR_MASK_COLOR;
      row_info->pixel_depth = (png_byte)(row_info->channels *
         row_info->bit_depth);
      row_info->rowbytes = PNG_ROWBYTES(row_info->pixel_depth, row_width);
   }
}
#endif

#ifdef PNG_READ_RGB_TO_GRAY_SUPPORTED
/* Reduce RGB files to grayscale, with or without alpha
 * using the equation given in Poynton's ColorFAQ at
 * <http://www.inforamp.net/~poynton/>  (THIS LINK IS DEAD June 2008)
 * New link:
 * <http://www.poynton.com/notes/colour_and_gamma/>
 * Charles Poynton poynton at poynton.com
 *
 *     Y = 0.212671 * R + 0.715160 * G + 0.072169 * B
 *
 *  We approximate this with
 *
 *     Y = 0.21268 * R    + 0.7151 * G    + 0.07217 * B
 *
 *  which can be expressed with integers as
 *
 *     Y = (6969 * R + 23434 * G + 2365 * B)/32768
 *
 *  The calculation is to be done in a linear colorspace.
 *
 *  Other integer coefficents can be used via png_set_rgb_to_gray().
 */
int /* PRIVATE */
png_do_rgb_to_gray(png_structp png_ptr, png_row_infop row_info, png_bytep row)

{
   png_uint_32 i;

   png_uint_32 row_width = row_info->width;
   int rgb_error = 0;

   png_debug(1, "in png_do_rgb_to_gray");

   if (
#ifdef PNG_USELESS_TESTS_SUPPORTED
       row != NULL && row_info != NULL &&
#endif
      (row_info->color_type & PNG_COLOR_MASK_COLOR))
   {
      png_uint_32 rc = png_ptr->rgb_to_gray_red_coeff;
      png_uint_32 gc = png_ptr->rgb_to_gray_green_coeff;
      png_uint_32 bc = png_ptr->rgb_to_gray_blue_coeff;

      if (row_info->color_type == PNG_COLOR_TYPE_RGB)
      {
         if (row_info->bit_depth == 8)
         {
#if defined(PNG_READ_GAMMA_SUPPORTED) || defined(PNG_READ_BACKGROUND_SUPPORTED)
            if (png_ptr->gamma_from_1 != NULL && png_ptr->gamma_to_1 != NULL)
            {
               png_bytep sp = row;
               png_bytep dp = row;

               for (i = 0; i < row_width; i++)
               {
                  png_byte red   = png_ptr->gamma_to_1[*(sp++)];
                  png_byte green = png_ptr->gamma_to_1[*(sp++)];
                  png_byte blue  = png_ptr->gamma_to_1[*(sp++)];
                  if (red != green || red != blue)
                  {
                     rgb_error |= 1;
                     *(dp++) = png_ptr->gamma_from_1[
                       (rc*red + gc*green + bc*blue)>>15];
                  }
                  else
                     *(dp++) = *(sp - 1);
               }
            }
            else
#endif
            {
               png_bytep sp = row;
               png_bytep dp = row;
               for (i = 0; i < row_width; i++)
               {
                  png_byte red   = *(sp++);
                  png_byte green = *(sp++);
                  png_byte blue  = *(sp++);
                  if (red != green || red != blue)
                  {
                     rgb_error |= 1;
                     *(dp++) = (png_byte)((rc*red + gc*green + bc*blue)>>15);
                  }
                  else
                     *(dp++) = *(sp - 1);
               }
            }
         }

         else /* RGB bit_depth == 16 */
         {
#if defined(PNG_READ_GAMMA_SUPPORTED) || defined(PNG_READ_BACKGROUND_SUPPORTED)
            if (png_ptr->gamma_16_to_1 != NULL &&
                png_ptr->gamma_16_from_1 != NULL)
            {
               png_bytep sp = row;
               png_bytep dp = row;
               for (i = 0; i < row_width; i++)
               {
                  png_uint_16 red, green, blue, w;

                  red   = (png_uint_16)(((*(sp))<<8) | *(sp+1)); sp+=2;
                  green = (png_uint_16)(((*(sp))<<8) | *(sp+1)); sp+=2;
                  blue  = (png_uint_16)(((*(sp))<<8) | *(sp+1)); sp+=2;

                  if (red == green && red == blue)
                     w = red;
                  else
                  {
                     png_uint_16 red_1   = png_ptr->gamma_16_to_1[(red&0xff) >>
                                  png_ptr->gamma_shift][red>>8];
                     png_uint_16 green_1 =
                         png_ptr->gamma_16_to_1[(green&0xff) >>
                                  png_ptr->gamma_shift][green>>8];
                     png_uint_16 blue_1  = png_ptr->gamma_16_to_1[(blue&0xff) >>
                                  png_ptr->gamma_shift][blue>>8];
                     png_uint_16 gray16  = (png_uint_16)((rc*red_1 + gc*green_1
                                  + bc*blue_1)>>15);
                     w = png_ptr->gamma_16_from_1[(gray16&0xff) >>
                         png_ptr->gamma_shift][gray16 >> 8];
                     rgb_error |= 1;
                  }

                  *(dp++) = (png_byte)((w>>8) & 0xff);
                  *(dp++) = (png_byte)(w & 0xff);
               }
            }
            else
#endif
            {
               png_bytep sp = row;
               png_bytep dp = row;
               for (i = 0; i < row_width; i++)
               {
                  png_uint_16 red, green, blue, gray16;

                  red   = (png_uint_16)(((*(sp))<<8) | *(sp+1)); sp+=2;
                  green = (png_uint_16)(((*(sp))<<8) | *(sp+1)); sp+=2;
                  blue  = (png_uint_16)(((*(sp))<<8) | *(sp+1)); sp+=2;

                  if (red != green || red != blue)
                     rgb_error |= 1;
                  gray16  = (png_uint_16)((rc*red + gc*green + bc*blue)>>15);
                  *(dp++) = (png_byte)((gray16>>8) & 0xff);
                  *(dp++) = (png_byte)(gray16 & 0xff);
               }
            }
         }
      }
      if (row_info->color_type == PNG_COLOR_TYPE_RGB_ALPHA)
      {
         if (row_info->bit_depth == 8)
         {
#if defined(PNG_READ_GAMMA_SUPPORTED) || defined(PNG_READ_BACKGROUND_SUPPORTED)
            if (png_ptr->gamma_from_1 != NULL && png_ptr->gamma_to_1 != NULL)
            {
               png_bytep sp = row;
               png_bytep dp = row;
               for (i = 0; i < row_width; i++)
               {
                  png_byte red   = png_ptr->gamma_to_1[*(sp++)];
                  png_byte green = png_ptr->gamma_to_1[*(sp++)];
                  png_byte blue  = png_ptr->gamma_to_1[*(sp++)];
                  if (red != green || red != blue)
                     rgb_error |= 1;
                  *(dp++) =  png_ptr->gamma_from_1
                             [(rc*red + gc*green + bc*blue)>>15];
                  *(dp++) = *(sp++);  /* alpha */
               }
            }
            else
#endif
            {
               png_bytep sp = row;
               png_bytep dp = row;
               for (i = 0; i < row_width; i++)
               {
                  png_byte red   = *(sp++);
                  png_byte green = *(sp++);
                  png_byte blue  = *(sp++);
                  if (red != green || red != blue)
                     rgb_error |= 1;
                  *(dp++) =  (png_byte)((rc*red + gc*green + bc*blue)>>15);
                  *(dp++) = *(sp++);  /* alpha */
               }
            }
         }
         else /* RGBA bit_depth == 16 */
         {
#if defined(PNG_READ_GAMMA_SUPPORTED) || defined(PNG_READ_BACKGROUND_SUPPORTED)
            if (png_ptr->gamma_16_to_1 != NULL &&
                png_ptr->gamma_16_from_1 != NULL)
            {
               png_bytep sp = row;
               png_bytep dp = row;
               for (i = 0; i < row_width; i++)
               {
                  png_uint_16 red, green, blue, w;

                  red   = (png_uint_16)(((*(sp))<<8) | *(sp+1)); sp+=2;
                  green = (png_uint_16)(((*(sp))<<8) | *(sp+1)); sp+=2;
                  blue  = (png_uint_16)(((*(sp))<<8) | *(sp+1)); sp+=2;

                  if (red == green && red == blue)
                     w = red;
                  else
                  {
                     png_uint_16 red_1   = png_ptr->gamma_16_to_1[(red&0xff) >>
                         png_ptr->gamma_shift][red>>8];
                     png_uint_16 green_1 =
                         png_ptr->gamma_16_to_1[(green&0xff) >>
                         png_ptr->gamma_shift][green>>8];
                     png_uint_16 blue_1  = png_ptr->gamma_16_to_1[(blue&0xff) >>
                         png_ptr->gamma_shift][blue>>8];
                     png_uint_16 gray16  = (png_uint_16)((rc * red_1
                         + gc * green_1 + bc * blue_1)>>15);
                     w = png_ptr->gamma_16_from_1[(gray16&0xff) >>
                         png_ptr->gamma_shift][gray16 >> 8];
                     rgb_error |= 1;
                  }

                  *(dp++) = (png_byte)((w>>8) & 0xff);
                  *(dp++) = (png_byte)(w & 0xff);
                  *(dp++) = *(sp++);  /* alpha */
                  *(dp++) = *(sp++);
               }
            }
            else
#endif
            {
               png_bytep sp = row;
               png_bytep dp = row;
               for (i = 0; i < row_width; i++)
               {
                  png_uint_16 red, green, blue, gray16;
                  red   = (png_uint_16)((*(sp)<<8) | *(sp+1)); sp+=2;
                  green = (png_uint_16)((*(sp)<<8) | *(sp+1)); sp+=2;
                  blue  = (png_uint_16)((*(sp)<<8) | *(sp+1)); sp+=2;
                  if (red != green || red != blue)
                     rgb_error |= 1;
                  gray16  = (png_uint_16)((rc*red + gc*green + bc*blue)>>15);
                  *(dp++) = (png_byte)((gray16>>8) & 0xff);
                  *(dp++) = (png_byte)(gray16 & 0xff);
                  *(dp++) = *(sp++);  /* alpha */
                  *(dp++) = *(sp++);
               }
            }
         }
      }
   row_info->channels -= (png_byte)2;
      row_info->color_type &= ~PNG_COLOR_MASK_COLOR;
      row_info->pixel_depth = (png_byte)(row_info->channels *
         row_info->bit_depth);
      row_info->rowbytes = PNG_ROWBYTES(row_info->pixel_depth, row_width);
   }
   return rgb_error;
}
#endif

/* Build a grayscale palette.  Palette is assumed to be 1 << bit_depth
 * large of png_color.  This lets grayscale images be treated as
 * paletted.  Most useful for gamma correction and simplification
 * of code.
 */
void PNGAPI
png_build_grayscale_palette(int bit_depth, png_colorp palette)
{
   int num_palette;
   int color_inc;
   int i;
   int v;

   png_debug(1, "in png_do_build_grayscale_palette");

   if (palette == NULL)
      return;

   switch (bit_depth)
   {
      case 1:
         num_palette = 2;
         color_inc = 0xff;
         break;

      case 2:
         num_palette = 4;
         color_inc = 0x55;
         break;

      case 4:
         num_palette = 16;
         color_inc = 0x11;
         break;

      case 8:
         num_palette = 256;
         color_inc = 1;
         break;

      default:
         num_palette = 0;
         color_inc = 0;
         break;
   }

   for (i = 0, v = 0; i < num_palette; i++, v += color_inc)
   {
      palette[i].red = (png_byte)v;
      palette[i].green = (png_byte)v;
      palette[i].blue = (png_byte)v;
   }
}

/* This function is currently unused.  Do we really need it? */
#if defined(PNG_READ_DITHER_SUPPORTED) && \
  defined(PNG_CORRECT_PALETTE_SUPPORTED)
void /* PRIVATE */
png_correct_palette(png_structp png_ptr, png_colorp palette,
   int num_palette)
{
   png_debug(1, "in png_correct_palette");

#if defined(PNG_READ_BACKGROUND_SUPPORTED) && \
    defined(PNG_READ_GAMMA_SUPPORTED) && \
  defined(PNG_FLOATING_POINT_SUPPORTED)
   if (png_ptr->transformations & (PNG_GAMMA | PNG_BACKGROUND))
   {
      png_color back, back_1;

      if (png_ptr->background_gamma_type == PNG_BACKGROUND_GAMMA_FILE)
      {
         back.red = png_ptr->gamma_table[png_ptr->background.red];
         back.green = png_ptr->gamma_table[png_ptr->background.green];
         back.blue = png_ptr->gamma_table[png_ptr->background.blue];

         back_1.red = png_ptr->gamma_to_1[png_ptr->background.red];
         back_1.green = png_ptr->gamma_to_1[png_ptr->background.green];
         back_1.blue = png_ptr->gamma_to_1[png_ptr->background.blue];
      }
      else
      {
         double g;

         g = 1.0 / (png_ptr->background_gamma * png_ptr->screen_gamma);

         if (png_ptr->background_gamma_type == PNG_BACKGROUND_GAMMA_SCREEN
             || fabs(g - 1.0) < PNG_GAMMA_THRESHOLD)
         {
            back.red = png_ptr->background.red;
            back.green = png_ptr->background.green;
            back.blue = png_ptr->background.blue;
         }
         else
         {
            back.red =
               (png_byte)(pow((double)png_ptr->background.red/255, g) *
                255.0 + 0.5);
            back.green =
               (png_byte)(pow((double)png_ptr->background.green/255, g) *
                255.0 + 0.5);
            back.blue =
               (png_byte)(pow((double)png_ptr->background.blue/255, g) *
                255.0 + 0.5);
         }

         g = 1.0 / png_ptr->background_gamma;

         back_1.red =
            (png_byte)(pow((double)png_ptr->background.red/255, g) *
             255.0 + 0.5);
         back_1.green =
            (png_byte)(pow((double)png_ptr->background.green/255, g) *
             255.0 + 0.5);
         back_1.blue =
            (png_byte)(pow((double)png_ptr->background.blue/255, g) *
             255.0 + 0.5);
      }

      if (png_ptr->color_type == PNG_COLOR_TYPE_PALETTE)
      {
         png_uint_32 i;

         for (i = 0; i < (png_uint_32)num_palette; i++)
         {
            if (i < png_ptr->num_trans && png_ptr->trans[i] == 0)
            {
               palette[i] = back;
            }
            else if (i < png_ptr->num_trans && png_ptr->trans[i] != 0xff)
            {
               png_byte v, w;

               v = png_ptr->gamma_to_1[png_ptr->palette[i].red];
               png_composite(w, v, png_ptr->trans[i], back_1.red);
               palette[i].red = png_ptr->gamma_from_1[w];

               v = png_ptr->gamma_to_1[png_ptr->palette[i].green];
               png_composite(w, v, png_ptr->trans[i], back_1.green);
               palette[i].green = png_ptr->gamma_from_1[w];

               v = png_ptr->gamma_to_1[png_ptr->palette[i].blue];
               png_composite(w, v, png_ptr->trans[i], back_1.blue);
               palette[i].blue = png_ptr->gamma_from_1[w];
            }
            else
            {
               palette[i].red = png_ptr->gamma_table[palette[i].red];
               palette[i].green = png_ptr->gamma_table[palette[i].green];
               palette[i].blue = png_ptr->gamma_table[palette[i].blue];
            }
         }
      }
      else
      {
         int i;

         for (i = 0; i < num_palette; i++)
         {
            if (palette[i].red == (png_byte)png_ptr->trans_values.gray)
            {
               palette[i] = back;
            }
            else
            {
               palette[i].red = png_ptr->gamma_table[palette[i].red];
               palette[i].green = png_ptr->gamma_table[palette[i].green];
               palette[i].blue = png_ptr->gamma_table[palette[i].blue];
            }
         }
      }
   }
   else
#endif
#ifdef PNG_READ_GAMMA_SUPPORTED
   if (png_ptr->transformations & PNG_GAMMA)
   {
      int i;

      for (i = 0; i < num_palette; i++)
      {
         palette[i].red = png_ptr->gamma_table[palette[i].red];
         palette[i].green = png_ptr->gamma_table[palette[i].green];
         palette[i].blue = png_ptr->gamma_table[palette[i].blue];
      }
   }
#ifdef PNG_READ_BACKGROUND_SUPPORTED
   else
#endif
#endif
#ifdef PNG_READ_BACKGROUND_SUPPORTED
   if (png_ptr->transformations & PNG_BACKGROUND)
   {
      if (png_ptr->color_type == PNG_COLOR_TYPE_PALETTE)
      {
         png_color back;

         back.red   = (png_byte)png_ptr->background.red;
         back.green = (png_byte)png_ptr->background.green;
         back.blue  = (png_byte)png_ptr->background.blue;

         for (i = 0; i < (int)png_ptr->num_trans; i++)
         {
            if (png_ptr->trans[i] == 0)
            {
               palette[i].red = back.red;
               palette[i].green = back.green;
               palette[i].blue = back.blue;
            }
            else if (png_ptr->trans[i] != 0xff)
            {
               png_composite(palette[i].red, png_ptr->palette[i].red,
                  png_ptr->trans[i], back.red);
               png_composite(palette[i].green, png_ptr->palette[i].green,
                  png_ptr->trans[i], back.green);
               png_composite(palette[i].blue, png_ptr->palette[i].blue,
                  png_ptr->trans[i], back.blue);
            }
         }
      }
      else /* Assume grayscale palette (what else could it be?) */
      {
         int i;

         for (i = 0; i < num_palette; i++)
         {
            if (i == (png_byte)png_ptr->trans_values.gray)
            {
               palette[i].red = (png_byte)png_ptr->background.red;
               palette[i].green = (png_byte)png_ptr->background.green;
               palette[i].blue = (png_byte)png_ptr->background.blue;
            }
         }
      }
   }
#endif
}
#endif

#ifdef PNG_READ_BACKGROUND_SUPPORTED
/* Replace any alpha or transparency with the supplied background color.
 * "background" is already in the screen gamma, while "background_1" is
 * at a gamma of 1.0.  Paletted files have already been taken care of.
 */
void /* PRIVATE */
png_do_background(png_row_infop row_info, png_bytep row,
   png_color_16p trans_values, png_color_16p background
#ifdef PNG_READ_GAMMA_SUPPORTED
   , png_color_16p background_1,
   png_bytep gamma_table, png_bytep gamma_from_1, png_bytep gamma_to_1,
   png_uint_16pp gamma_16, png_uint_16pp gamma_16_from_1,
   png_uint_16pp gamma_16_to_1, int gamma_shift
#endif
   )
{
   png_bytep sp, dp;
   png_uint_32 i;
   png_uint_32 row_width=row_info->width;
   int shift;

   png_debug(1, "in png_do_background");

   if (background != NULL &&
#ifdef PNG_USELESS_TESTS_SUPPORTED
       row != NULL && row_info != NULL &&
#endif
      (!(row_info->color_type & PNG_COLOR_MASK_ALPHA) ||
      (row_info->color_type != PNG_COLOR_TYPE_PALETTE && trans_values)))
   {
      switch (row_info->color_type)
      {
         case PNG_COLOR_TYPE_GRAY:
         {
            switch (row_info->bit_depth)
            {
               case 1:
               {
                  sp = row;
                  shift = 7;
                  for (i = 0; i < row_width; i++)
                  {
                     if ((png_uint_16)((*sp >> shift) & 0x01)
                        == trans_values->gray)
                     {
                        *sp &= (png_byte)((0x7f7f >> (7 - shift)) & 0xff);
                        *sp |= (png_byte)(background->gray << shift);
                     }
                     if (!shift)
                     {
                        shift = 7;
                        sp++;
                     }
                     else
                        shift--;
                  }
                  break;
               }

               case 2:
               {
#ifdef PNG_READ_GAMMA_SUPPORTED
                  if (gamma_table != NULL)
                  {
                     sp = row;
                     shift = 6;
                     for (i = 0; i < row_width; i++)
                     {
                        if ((png_uint_16)((*sp >> shift) & 0x03)
                            == trans_values->gray)
                        {
                           *sp &= (png_byte)((0x3f3f >> (6 - shift)) & 0xff);
                           *sp |= (png_byte)(background->gray << shift);
                        }
                        else
                        {
                           png_byte p = (png_byte)((*sp >> shift) & 0x03);
                           png_byte g = (png_byte)((gamma_table [p | (p << 2) |
                               (p << 4) | (p << 6)] >> 6) & 0x03);
                           *sp &= (png_byte)((0x3f3f >> (6 - shift)) & 0xff);
                           *sp |= (png_byte)(g << shift);
                        }
                        if (!shift)
                        {
                           shift = 6;
                           sp++;
                        }
                        else
                           shift -= 2;
                     }
                  }
                  else
#endif
                  {
                     sp = row;
                     shift = 6;
                     for (i = 0; i < row_width; i++)
                     {
                        if ((png_uint_16)((*sp >> shift) & 0x03)
                            == trans_values->gray)
                        {
                           *sp &= (png_byte)((0x3f3f >> (6 - shift)) & 0xff);
                           *sp |= (png_byte)(background->gray << shift);
                        }
                        if (!shift)
                        {
                           shift = 6;
                           sp++;
                        }
                        else
                           shift -= 2;
                     }
                  }
                  break;
               }

               case 4:
               {
#ifdef PNG_READ_GAMMA_SUPPORTED
                  if (gamma_table != NULL)
                  {
                     sp = row;
                     shift = 4;
                     for (i = 0; i < row_width; i++)
                     {
                        if ((png_uint_16)((*sp >> shift) & 0x0f)
                            == trans_values->gray)
                        {
                           *sp &= (png_byte)((0xf0f >> (4 - shift)) & 0xff);
                           *sp |= (png_byte)(background->gray << shift);
                        }
                        else
                        {
                           png_byte p = (png_byte)((*sp >> shift) & 0x0f);
                           png_byte g = (png_byte)((gamma_table[p |
                             (p << 4)] >> 4) & 0x0f);
                           *sp &= (png_byte)((0xf0f >> (4 - shift)) & 0xff);
                           *sp |= (png_byte)(g << shift);
                        }
                        if (!shift)
                        {
                           shift = 4;
                           sp++;
                        }
                        else
                           shift -= 4;
                     }
                  }
                  else
#endif
                  {
                     sp = row;
                     shift = 4;
                     for (i = 0; i < row_width; i++)
                     {
                        if ((png_uint_16)((*sp >> shift) & 0x0f)
                            == trans_values->gray)
                        {
                           *sp &= (png_byte)((0xf0f >> (4 - shift)) & 0xff);
                           *sp |= (png_byte)(background->gray << shift);
                        }
                        if (!shift)
                        {
                           shift = 4;
                           sp++;
                        }
                        else
                           shift -= 4;
                     }
                  }
                  break;
               }

               case 8:
               {
#ifdef PNG_READ_GAMMA_SUPPORTED
                  if (gamma_table != NULL)
                  {
                     sp = row;
                     for (i = 0; i < row_width; i++, sp++)
                     {
                        if (*sp == trans_values->gray)
                        {
                           *sp = (png_byte)background->gray;
                        }
                        else
                        {
                           *sp = gamma_table[*sp];
                        }
                     }
                  }
                  else
#endif
                  {
                     sp = row;
                     for (i = 0; i < row_width; i++, sp++)
                     {
                        if (*sp == trans_values->gray)
                        {
                           *sp = (png_byte)background->gray;
                        }
                     }
                  }
                  break;
               }

               case 16:
               {
#ifdef PNG_READ_GAMMA_SUPPORTED
                  if (gamma_16 != NULL)
                  {
                     sp = row;
                     for (i = 0; i < row_width; i++, sp += 2)
                     {
                        png_uint_16 v;

                        v = (png_uint_16)(((*sp) << 8) + *(sp + 1));
                        if (v == trans_values->gray)
                        {
                           /* Background is already in screen gamma */
                           *sp = (png_byte)((background->gray >> 8) & 0xff);
                           *(sp + 1) = (png_byte)(background->gray & 0xff);
                        }
                        else
                        {
                           v = gamma_16[*(sp + 1) >> gamma_shift][*sp];
                           *sp = (png_byte)((v >> 8) & 0xff);
                           *(sp + 1) = (png_byte)(v & 0xff);
                        }
                     }
                  }
                  else
#endif
                  {
                     sp = row;
                     for (i = 0; i < row_width; i++, sp += 2)
                     {
                        png_uint_16 v;

                        v = (png_uint_16)(((*sp) << 8) + *(sp + 1));
                        if (v == trans_values->gray)
                        {
                           *sp = (png_byte)((background->gray >> 8) & 0xff);
                           *(sp + 1) = (png_byte)(background->gray & 0xff);
                        }
                     }
                  }
                  break;
               }
            }
            break;
         }

         case PNG_COLOR_TYPE_RGB:
         {
            if (row_info->bit_depth == 8)
            {
#ifdef PNG_READ_GAMMA_SUPPORTED
               if (gamma_table != NULL)
               {
                  sp = row;
                  for (i = 0; i < row_width; i++, sp += 3)
                  {
                     if (*sp == trans_values->red &&
                        *(sp + 1) == trans_values->green &&
                        *(sp + 2) == trans_values->blue)
                     {
                        *sp = (png_byte)background->red;
                        *(sp + 1) = (png_byte)background->green;
                        *(sp + 2) = (png_byte)background->blue;
                     }
                     else
                     {
                        *sp = gamma_table[*sp];
                        *(sp + 1) = gamma_table[*(sp + 1)];
                        *(sp + 2) = gamma_table[*(sp + 2)];
                     }
                  }
               }
               else
#endif
               {
                  sp = row;
                  for (i = 0; i < row_width; i++, sp += 3)
                  {
                     if (*sp == trans_values->red &&
                        *(sp + 1) == trans_values->green &&
                        *(sp + 2) == trans_values->blue)
                     {
                        *sp = (png_byte)background->red;
                        *(sp + 1) = (png_byte)background->green;
                        *(sp + 2) = (png_byte)background->blue;
                     }
                  }
               }
            }
            else /* if (row_info->bit_depth == 16) */
            {
#ifdef PNG_READ_GAMMA_SUPPORTED
               if (gamma_16 != NULL)
               {
                  sp = row;
                  for (i = 0; i < row_width; i++, sp += 6)
                  {
                     png_uint_16 r = (png_uint_16)(((*sp) << 8) + *(sp + 1));
                     png_uint_16 g = (png_uint_16)(((*(sp+2)) << 8) + *(sp+3));
                     png_uint_16 b = (png_uint_16)(((*(sp+4)) << 8) + *(sp+5));
                     if (r == trans_values->red && g == trans_values->green &&
                        b == trans_values->blue)
                     {
                        /* Background is already in screen gamma */
                        *sp = (png_byte)((background->red >> 8) & 0xff);
                        *(sp + 1) = (png_byte)(background->red & 0xff);
                        *(sp + 2) = (png_byte)((background->green >> 8) & 0xff);
                        *(sp + 3) = (png_byte)(background->green & 0xff);
                        *(sp + 4) = (png_byte)((background->blue >> 8) & 0xff);
                        *(sp + 5) = (png_byte)(background->blue & 0xff);
                     }
                     else
                     {
                        png_uint_16 v = gamma_16[*(sp + 1) >> gamma_shift][*sp];
                        *sp = (png_byte)((v >> 8) & 0xff);
                        *(sp + 1) = (png_byte)(v & 0xff);
                        v = gamma_16[*(sp + 3) >> gamma_shift][*(sp + 2)];
                        *(sp + 2) = (png_byte)((v >> 8) & 0xff);
                        *(sp + 3) = (png_byte)(v & 0xff);
                        v = gamma_16[*(sp + 5) >> gamma_shift][*(sp + 4)];
                        *(sp + 4) = (png_byte)((v >> 8) & 0xff);
                        *(sp + 5) = (png_byte)(v & 0xff);
                     }
                  }
               }
               else
#endif
               {
                  sp = row;
                  for (i = 0; i < row_width; i++, sp += 6)
                  {
                     png_uint_16 r = (png_uint_16)(((*sp) << 8) + *(sp+1));
                     png_uint_16 g = (png_uint_16)(((*(sp+2)) << 8) + *(sp+3));
                     png_uint_16 b = (png_uint_16)(((*(sp+4)) << 8) + *(sp+5));

                     if (r == trans_values->red && g == trans_values->green &&
                        b == trans_values->blue)
                     {
                        *sp = (png_byte)((background->red >> 8) & 0xff);
                        *(sp + 1) = (png_byte)(background->red & 0xff);
                        *(sp + 2) = (png_byte)((background->green >> 8) & 0xff);
                        *(sp + 3) = (png_byte)(background->green & 0xff);
                        *(sp + 4) = (png_byte)((background->blue >> 8) & 0xff);
                        *(sp + 5) = (png_byte)(background->blue & 0xff);
                     }
                  }
               }
            }
            break;
         }

         case PNG_COLOR_TYPE_GRAY_ALPHA:
         {
            if (row_info->bit_depth == 8)
            {
#ifdef PNG_READ_GAMMA_SUPPORTED
               if (gamma_to_1 != NULL && gamma_from_1 != NULL &&
                   gamma_table != NULL)
               {
                  sp = row;
                  dp = row;
                  for (i = 0; i < row_width; i++, sp += 2, dp++)
                  {
                     png_uint_16 a = *(sp + 1);

                     if (a == 0xff)
                     {
                        *dp = gamma_table[*sp];
                     }
                     else if (a == 0)
                     {
                        /* Background is already in screen gamma */
                        *dp = (png_byte)background->gray;
                     }
                     else
                     {
                        png_byte v, w;

                        v = gamma_to_1[*sp];
                        png_composite(w, v, a, background_1->gray);
                        *dp = gamma_from_1[w];
                     }
                  }
               }
               else
#endif
               {
                  sp = row;
                  dp = row;
                  for (i = 0; i < row_width; i++, sp += 2, dp++)
                  {
                     png_byte a = *(sp + 1);

                     if (a == 0xff)
                     {
                        *dp = *sp;
                     }
#ifdef PNG_READ_GAMMA_SUPPORTED
                     else if (a == 0)
                     {
                        *dp = (png_byte)background->gray;
                     }
                     else
                     {
                        png_composite(*dp, *sp, a, background_1->gray);
                     }
#else
                     *dp = (png_byte)background->gray;
#endif
                  }
               }
            }
            else /* if (png_ptr->bit_depth == 16) */
            {
#ifdef PNG_READ_GAMMA_SUPPORTED
               if (gamma_16 != NULL && gamma_16_from_1 != NULL &&
                   gamma_16_to_1 != NULL)
               {
                  sp = row;
                  dp = row;
                  for (i = 0; i < row_width; i++, sp += 4, dp += 2)
                  {
                     png_uint_16 a = (png_uint_16)(((*(sp+2)) << 8) + *(sp+3));

                     if (a == (png_uint_16)0xffff)
                     {
                        png_uint_16 v;

                        v = gamma_16[*(sp + 1) >> gamma_shift][*sp];
                        *dp = (png_byte)((v >> 8) & 0xff);
                        *(dp + 1) = (png_byte)(v & 0xff);
                     }
#ifdef PNG_READ_GAMMA_SUPPORTED
                     else if (a == 0)
#else
                     else
#endif
                     {
                        /* Background is already in screen gamma */
                        *dp = (png_byte)((background->gray >> 8) & 0xff);
                        *(dp + 1) = (png_byte)(background->gray & 0xff);
                     }
#ifdef PNG_READ_GAMMA_SUPPORTED
                     else
                     {
                        png_uint_16 g, v, w;

                        g = gamma_16_to_1[*(sp + 1) >> gamma_shift][*sp];
                        png_composite_16(v, g, a, background_1->gray);
                        w = gamma_16_from_1[(v&0xff) >> gamma_shift][v >> 8];
                        *dp = (png_byte)((w >> 8) & 0xff);
                        *(dp + 1) = (png_byte)(w & 0xff);
                     }
#endif
                  }
               }
               else
#endif
               {
                  sp = row;
                  dp = row;
                  for (i = 0; i < row_width; i++, sp += 4, dp += 2)
                  {
                     png_uint_16 a = (png_uint_16)(((*(sp+2)) << 8) + *(sp+3));
                     if (a == (png_uint_16)0xffff)
                     {
                        png_memcpy(dp, sp, 2);
                     }
#ifdef PNG_READ_GAMMA_SUPPORTED
                     else if (a == 0)
#else
                     else
#endif
                     {
                        *dp = (png_byte)((background->gray >> 8) & 0xff);
                        *(dp + 1) = (png_byte)(background->gray & 0xff);
                     }
#ifdef PNG_READ_GAMMA_SUPPORTED
                     else
                     {
                        png_uint_16 g, v;

                        g = (png_uint_16)(((*sp) << 8) + *(sp + 1));
                        png_composite_16(v, g, a, background_1->gray);
                        *dp = (png_byte)((v >> 8) & 0xff);
                        *(dp + 1) = (png_byte)(v & 0xff);
                     }
#endif
                  }
               }
            }
            break;
         }

         case PNG_COLOR_TYPE_RGB_ALPHA:
         {
            if (row_info->bit_depth == 8)
            {
#ifdef PNG_READ_GAMMA_SUPPORTED
               if (gamma_to_1 != NULL && gamma_from_1 != NULL &&
                   gamma_table != NULL)
               {
                  sp = row;
                  dp = row;
                  for (i = 0; i < row_width; i++, sp += 4, dp += 3)
                  {
                     png_byte a = *(sp + 3);

                     if (a == 0xff)
                     {
                        *dp = gamma_table[*sp];
                        *(dp + 1) = gamma_table[*(sp + 1)];
                        *(dp + 2) = gamma_table[*(sp + 2)];
                     }
                     else if (a == 0)
                     {
                        /* Background is already in screen gamma */
                        *dp = (png_byte)background->red;
                        *(dp + 1) = (png_byte)background->green;
                        *(dp + 2) = (png_byte)background->blue;
                     }
                     else
                     {
                        png_byte v, w;

                        v = gamma_to_1[*sp];
                        png_composite(w, v, a, background_1->red);
                        *dp = gamma_from_1[w];
                        v = gamma_to_1[*(sp + 1)];
                        png_composite(w, v, a, background_1->green);
                        *(dp + 1) = gamma_from_1[w];
                        v = gamma_to_1[*(sp + 2)];
                        png_composite(w, v, a, background_1->blue);
                        *(dp + 2) = gamma_from_1[w];
                     }
                  }
               }
               else
#endif
               {
                  sp = row;
                  dp = row;
                  for (i = 0; i < row_width; i++, sp += 4, dp += 3)
                  {
                     png_byte a = *(sp + 3);

                     if (a == 0xff)
                     {
                        *dp = *sp;
                        *(dp + 1) = *(sp + 1);
                        *(dp + 2) = *(sp + 2);
                     }
                     else if (a == 0)
                     {
                        *dp = (png_byte)background->red;
                        *(dp + 1) = (png_byte)background->green;
                        *(dp + 2) = (png_byte)background->blue;
                     }
                     else
                     {
                        png_composite(*dp, *sp, a, background->red);
                        png_composite(*(dp + 1), *(sp + 1), a,
                           background->green);
                        png_composite(*(dp + 2), *(sp + 2), a,
                           background->blue);
                     }
                  }
               }
            }
            else /* if (row_info->bit_depth == 16) */
            {
#ifdef PNG_READ_GAMMA_SUPPORTED
               if (gamma_16 != NULL && gamma_16_from_1 != NULL &&
                   gamma_16_to_1 != NULL)
               {
                  sp = row;
                  dp = row;
                  for (i = 0; i < row_width; i++, sp += 8, dp += 6)
                  {
                     png_uint_16 a = (png_uint_16)(((png_uint_16)(*(sp + 6))
                         << 8) + (png_uint_16)(*(sp + 7)));
                     if (a == (png_uint_16)0xffff)
                     {
                        png_uint_16 v;

                        v = gamma_16[*(sp + 1) >> gamma_shift][*sp];
                        *dp = (png_byte)((v >> 8) & 0xff);
                        *(dp + 1) = (png_byte)(v & 0xff);
                        v = gamma_16[*(sp + 3) >> gamma_shift][*(sp + 2)];
                        *(dp + 2) = (png_byte)((v >> 8) & 0xff);
                        *(dp + 3) = (png_byte)(v & 0xff);
                        v = gamma_16[*(sp + 5) >> gamma_shift][*(sp + 4)];
                        *(dp + 4) = (png_byte)((v >> 8) & 0xff);
                        *(dp + 5) = (png_byte)(v & 0xff);
                     }
                     else if (a == 0)
                     {
                        /* Background is already in screen gamma */
                        *dp = (png_byte)((background->red >> 8) & 0xff);
                        *(dp + 1) = (png_byte)(background->red & 0xff);
                        *(dp + 2) = (png_byte)((background->green >> 8) & 0xff);
                        *(dp + 3) = (png_byte)(background->green & 0xff);
                        *(dp + 4) = (png_byte)((background->blue >> 8) & 0xff);
                        *(dp + 5) = (png_byte)(background->blue & 0xff);
                     }
                     else
                     {
                        png_uint_16 v, w, x;

                        v = gamma_16_to_1[*(sp + 1) >> gamma_shift][*sp];
                        png_composite_16(w, v, a, background_1->red);
                        x = gamma_16_from_1[((w&0xff) >> gamma_shift)][w >> 8];
                        *dp = (png_byte)((x >> 8) & 0xff);
                        *(dp + 1) = (png_byte)(x & 0xff);
                        v = gamma_16_to_1[*(sp + 3) >> gamma_shift][*(sp + 2)];
                        png_composite_16(w, v, a, background_1->green);
                        x = gamma_16_from_1[((w&0xff) >> gamma_shift)][w >> 8];
                        *(dp + 2) = (png_byte)((x >> 8) & 0xff);
                        *(dp + 3) = (png_byte)(x & 0xff);
                        v = gamma_16_to_1[*(sp + 5) >> gamma_shift][*(sp + 4)];
                        png_composite_16(w, v, a, background_1->blue);
                        x = gamma_16_from_1[(w & 0xff) >> gamma_shift][w >> 8];
                        *(dp + 4) = (png_byte)((x >> 8) & 0xff);
                        *(dp + 5) = (png_byte)(x & 0xff);
                     }
                  }
               }
               else
#endif
               {
                  sp = row;
                  dp = row;
                  for (i = 0; i < row_width; i++, sp += 8, dp += 6)
                  {
                     png_uint_16 a = (png_uint_16)(((png_uint_16)(*(sp + 6))
                        << 8) + (png_uint_16)(*(sp + 7)));
                     if (a == (png_uint_16)0xffff)
                     {
                        png_memcpy(dp, sp, 6);
                     }
                     else if (a == 0)
                     {
                        *dp = (png_byte)((background->red >> 8) & 0xff);
                        *(dp + 1) = (png_byte)(background->red & 0xff);
                        *(dp + 2) = (png_byte)((background->green >> 8) & 0xff);
                        *(dp + 3) = (png_byte)(background->green & 0xff);
                        *(dp + 4) = (png_byte)((background->blue >> 8) & 0xff);
                        *(dp + 5) = (png_byte)(background->blue & 0xff);
                     }
                     else
                     {
                        png_uint_16 v;

                        png_uint_16 r = (png_uint_16)(((*sp) << 8) + *(sp + 1));
                        png_uint_16 g = (png_uint_16)(((*(sp + 2)) << 8)
                            + *(sp + 3));
                        png_uint_16 b = (png_uint_16)(((*(sp + 4)) << 8)
                            + *(sp + 5));

                        png_composite_16(v, r, a, background->red);
                        *dp = (png_byte)((v >> 8) & 0xff);
                        *(dp + 1) = (png_byte)(v & 0xff);
                        png_composite_16(v, g, a, background->green);
                        *(dp + 2) = (png_byte)((v >> 8) & 0xff);
                        *(dp + 3) = (png_byte)(v & 0xff);
                        png_composite_16(v, b, a, background->blue);
                        *(dp + 4) = (png_byte)((v >> 8) & 0xff);
                        *(dp + 5) = (png_byte)(v & 0xff);
                     }
                  }
               }
            }
            break;
         }
      }

      if (row_info->color_type & PNG_COLOR_MASK_ALPHA)
      {
         row_info->color_type &= ~PNG_COLOR_MASK_ALPHA;
         row_info->channels--;
         row_info->pixel_depth = (png_byte)(row_info->channels *
            row_info->bit_depth);
         row_info->rowbytes = PNG_ROWBYTES(row_info->pixel_depth, row_width);
      }
   }
}
#endif

#ifdef PNG_READ_GAMMA_SUPPORTED
/* Gamma correct the image, avoiding the alpha channel.  Make sure
 * you do this after you deal with the transparency issue on grayscale
 * or RGB images. If your bit depth is 8, use gamma_table, if it
 * is 16, use gamma_16_table and gamma_shift.  Build these with
 * build_gamma_table().
 */
void /* PRIVATE */
png_do_gamma(png_row_infop row_info, png_bytep row,
   png_bytep gamma_table, png_uint_16pp gamma_16_table,
   int gamma_shift)
{
   png_bytep sp;
   png_uint_32 i;
   png_uint_32 row_width=row_info->width;

   png_debug(1, "in png_do_gamma");

   if (
#ifdef PNG_USELESS_TESTS_SUPPORTED
       row != NULL && row_info != NULL &&
#endif
       ((row_info->bit_depth <= 8 && gamma_table != NULL) ||
        (row_info->bit_depth == 16 && gamma_16_table != NULL)))
   {
      switch (row_info->color_type)
      {
         case PNG_COLOR_TYPE_RGB:
         {
            if (row_info->bit_depth == 8)
            {
               sp = row;
               for (i = 0; i < row_width; i++)
               {
                  *sp = gamma_table[*sp];
                  sp++;
                  *sp = gamma_table[*sp];
                  sp++;
                  *sp = gamma_table[*sp];
                  sp++;
               }
            }
            else /* if (row_info->bit_depth == 16) */
            {
               sp = row;
               for (i = 0; i < row_width; i++)
               {
                  png_uint_16 v;

                  v = gamma_16_table[*(sp + 1) >> gamma_shift][*sp];
                  *sp = (png_byte)((v >> 8) & 0xff);
                  *(sp + 1) = (png_byte)(v & 0xff);
                  sp += 2;
                  v = gamma_16_table[*(sp + 1) >> gamma_shift][*sp];
                  *sp = (png_byte)((v >> 8) & 0xff);
                  *(sp + 1) = (png_byte)(v & 0xff);
                  sp += 2;
                  v = gamma_16_table[*(sp + 1) >> gamma_shift][*sp];
                  *sp = (png_byte)((v >> 8) & 0xff);
                  *(sp + 1) = (png_byte)(v & 0xff);
                  sp += 2;
               }
            }
            break;
         }

         case PNG_COLOR_TYPE_RGB_ALPHA:
         {
            if (row_info->bit_depth == 8)
            {
               sp = row;
               for (i = 0; i < row_width; i++)
               {
                  *sp = gamma_table[*sp];
                  sp++;
                  *sp = gamma_table[*sp];
                  sp++;
                  *sp = gamma_table[*sp];
                  sp++;
                  sp++;
               }
            }
            else /* if (row_info->bit_depth == 16) */
            {
               sp = row;
               for (i = 0; i < row_width; i++)
               {
                  png_uint_16 v = gamma_16_table[*(sp + 1) >> gamma_shift][*sp];
                  *sp = (png_byte)((v >> 8) & 0xff);
                  *(sp + 1) = (png_byte)(v & 0xff);
                  sp += 2;
                  v = gamma_16_table[*(sp + 1) >> gamma_shift][*sp];
                  *sp = (png_byte)((v >> 8) & 0xff);
                  *(sp + 1) = (png_byte)(v & 0xff);
                  sp += 2;
                  v = gamma_16_table[*(sp + 1) >> gamma_shift][*sp];
                  *sp = (png_byte)((v >> 8) & 0xff);
                  *(sp + 1) = (png_byte)(v & 0xff);
                  sp += 4;
               }
            }
            break;
         }

         case PNG_COLOR_TYPE_GRAY_ALPHA:
         {
            if (row_info->bit_depth == 8)
            {
               sp = row;
               for (i = 0; i < row_width; i++)
               {
                  *sp = gamma_table[*sp];
                  sp += 2;
               }
            }
            else /* if (row_info->bit_depth == 16) */
            {
               sp = row;
               for (i = 0; i < row_width; i++)
               {
                  png_uint_16 v = gamma_16_table[*(sp + 1) >> gamma_shift][*sp];
                  *sp = (png_byte)((v >> 8) & 0xff);
                  *(sp + 1) = (png_byte)(v & 0xff);
                  sp += 4;
               }
            }
            break;
         }

         case PNG_COLOR_TYPE_GRAY:
         {
            if (row_info->bit_depth == 2)
            {
               sp = row;
               for (i = 0; i < row_width; i += 4)
               {
                  int a = *sp & 0xc0;
                  int b = *sp & 0x30;
                  int c = *sp & 0x0c;
                  int d = *sp & 0x03;

                  *sp = (png_byte)(
                      ((((int)gamma_table[a|(a>>2)|(a>>4)|(a>>6)])   ) & 0xc0)|
                      ((((int)gamma_table[(b<<2)|b|(b>>2)|(b>>4)])>>2) & 0x30)|
                      ((((int)gamma_table[(c<<4)|(c<<2)|c|(c>>2)])>>4) & 0x0c)|
                      ((((int)gamma_table[(d<<6)|(d<<4)|(d<<2)|d])>>6) ));
                  sp++;
               }
            }

            if (row_info->bit_depth == 4)
            {
               sp = row;
               for (i = 0; i < row_width; i += 2)
               {
                  int msb = *sp & 0xf0;
                  int lsb = *sp & 0x0f;

                  *sp = (png_byte)((((int)gamma_table[msb | (msb >> 4)]) & 0xf0)
                      | (((int)gamma_table[(lsb << 4) | lsb]) >> 4));
                  sp++;
               }
            }

            else if (row_info->bit_depth == 8)
            {
               sp = row;
               for (i = 0; i < row_width; i++)
               {
                  *sp = gamma_table[*sp];
                  sp++;
               }
            }

            else if (row_info->bit_depth == 16)
            {
               sp = row;
               for (i = 0; i < row_width; i++)
               {
                  png_uint_16 v = gamma_16_table[*(sp + 1) >> gamma_shift][*sp];
                  *sp = (png_byte)((v >> 8) & 0xff);
                  *(sp + 1) = (png_byte)(v & 0xff);
                  sp += 2;
               }
            }
            break;
         }
      }
   }
}
#endif

#ifdef PNG_READ_EXPAND_SUPPORTED
/* Expands a palette row to an RGB or RGBA row depending
 * upon whether you supply trans and num_trans.
 */
void /* PRIVATE */
png_do_expand_palette(png_row_infop row_info, png_bytep row,
   png_colorp palette, png_bytep trans, int num_trans)
{
   int shift, value;
   png_bytep sp, dp;
   png_uint_32 i;
   png_uint_32 row_width=row_info->width;

   png_debug(1, "in png_do_expand_palette");

   if (
#ifdef PNG_USELESS_TESTS_SUPPORTED
       row != NULL && row_info != NULL &&
#endif
       row_info->color_type == PNG_COLOR_TYPE_PALETTE)
   {
      if (row_info->bit_depth < 8)
      {
         switch (row_info->bit_depth)
         {
            case 1:
            {
               sp = row + (png_size_t)((row_width - 1) >> 3);
               dp = row + (png_size_t)row_width - 1;
               shift = 7 - (int)((row_width + 7) & 0x07);
               for (i = 0; i < row_width; i++)
               {
                  if ((*sp >> shift) & 0x01)
                     *dp = 1;
                  else
                     *dp = 0;
                  if (shift == 7)
                  {
                     shift = 0;
                     sp--;
                  }
                  else
                     shift++;

                  dp--;
               }
               break;
            }

            case 2:
            {
               sp = row + (png_size_t)((row_width - 1) >> 2);
               dp = row + (png_size_t)row_width - 1;
               shift = (int)((3 - ((row_width + 3) & 0x03)) << 1);
               for (i = 0; i < row_width; i++)
               {
                  value = (*sp >> shift) & 0x03;
                  *dp = (png_byte)value;
                  if (shift == 6)
                  {
                     shift = 0;
                     sp--;
                  }
                  else
                     shift += 2;

                  dp--;
               }
               break;
            }

            case 4:
            {
               sp = row + (png_size_t)((row_width - 1) >> 1);
               dp = row + (png_size_t)row_width - 1;
               shift = (int)((row_width & 0x01) << 2);
               for (i = 0; i < row_width; i++)
               {
                  value = (*sp >> shift) & 0x0f;
                  *dp = (png_byte)value;
                  if (shift == 4)
                  {
                     shift = 0;
                     sp--;
                  }
                  else
                     shift += 4;

                  dp--;
               }
               break;
            }
         }
         row_info->bit_depth = 8;
         row_info->pixel_depth = 8;
         row_info->rowbytes = row_width;
      }
      switch (row_info->bit_depth)
      {
         case 8:
         {
            if (trans != NULL)
            {
               sp = row + (png_size_t)row_width - 1;
               dp = row + (png_size_t)(row_width << 2) - 1;

               for (i = 0; i < row_width; i++)
               {
                  if ((int)(*sp) >= num_trans)
                     *dp-- = 0xff;
                  else
                     *dp-- = trans[*sp];
                  *dp-- = palette[*sp].blue;
                  *dp-- = palette[*sp].green;
                  *dp-- = palette[*sp].red;
                  sp--;
               }
               row_info->bit_depth = 8;
               row_info->pixel_depth = 32;
               row_info->rowbytes = row_width * 4;
               row_info->color_type = 6;
               row_info->channels = 4;
            }
            else
            {
               sp = row + (png_size_t)row_width - 1;
               dp = row + (png_size_t)(row_width * 3) - 1;

               for (i = 0; i < row_width; i++)
               {
                  *dp-- = palette[*sp].blue;
                  *dp-- = palette[*sp].green;
                  *dp-- = palette[*sp].red;
                  sp--;
               }

               row_info->bit_depth = 8;
               row_info->pixel_depth = 24;
               row_info->rowbytes = row_width * 3;
               row_info->color_type = 2;
               row_info->channels = 3;
            }
            break;
         }
      }
   }
}

/* If the bit depth < 8, it is expanded to 8.  Also, if the already
 * expanded transparency value is supplied, an alpha channel is built.
 */
void /* PRIVATE */
png_do_expand(png_row_infop row_info, png_bytep row,
   png_color_16p trans_value)
{
   int shift, value;
   png_bytep sp, dp;
   png_uint_32 i;
   png_uint_32 row_width=row_info->width;

   png_debug(1, "in png_do_expand");

#ifdef PNG_USELESS_TESTS_SUPPORTED
   if (row != NULL && row_info != NULL)
#endif
   {
      if (row_info->color_type == PNG_COLOR_TYPE_GRAY)
      {
         png_uint_16 gray = (png_uint_16)(trans_value ? trans_value->gray : 0);

         if (row_info->bit_depth < 8)
         {
            switch (row_info->bit_depth)
            {
               case 1:
               {
                  gray = (png_uint_16)((gray&0x01)*0xff);
                  sp = row + (png_size_t)((row_width - 1) >> 3);
                  dp = row + (png_size_t)row_width - 1;
                  shift = 7 - (int)((row_width + 7) & 0x07);
                  for (i = 0; i < row_width; i++)
                  {
                     if ((*sp >> shift) & 0x01)
                        *dp = 0xff;
                     else
                        *dp = 0;
                     if (shift == 7)
                     {
                        shift = 0;
                        sp--;
                     }
                     else
                        shift++;

                     dp--;
                  }
                  break;
               }

               case 2:
               {
                  gray = (png_uint_16)((gray&0x03)*0x55);
                  sp = row + (png_size_t)((row_width - 1) >> 2);
                  dp = row + (png_size_t)row_width - 1;
                  shift = (int)((3 - ((row_width + 3) & 0x03)) << 1);
                  for (i = 0; i < row_width; i++)
                  {
                     value = (*sp >> shift) & 0x03;
                     *dp = (png_byte)(value | (value << 2) | (value << 4) |
                        (value << 6));
                     if (shift == 6)
                     {
                        shift = 0;
                        sp--;
                     }
                     else
                        shift += 2;

                     dp--;
                  }
                  break;
               }

               case 4:
               {
                  gray = (png_uint_16)((gray&0x0f)*0x11);
                  sp = row + (png_size_t)((row_width - 1) >> 1);
                  dp = row + (png_size_t)row_width - 1;
                  shift = (int)((1 - ((row_width + 1) & 0x01)) << 2);
                  for (i = 0; i < row_width; i++)
                  {
                     value = (*sp >> shift) & 0x0f;
                     *dp = (png_byte)(value | (value << 4));
                     if (shift == 4)
                     {
                        shift = 0;
                        sp--;
                     }
                     else
                        shift = 4;

                     dp--;
                  }
                  break;
               }
            }

            row_info->bit_depth = 8;
            row_info->pixel_depth = 8;
            row_info->rowbytes = row_width;
         }

         if (trans_value != NULL)
         {
            if (row_info->bit_depth == 8)
            {
               gray = gray & 0xff;
               sp = row + (png_size_t)row_width - 1;
               dp = row + (png_size_t)(row_width << 1) - 1;
               for (i = 0; i < row_width; i++)
               {
                  if (*sp == gray)
                     *dp-- = 0;
                  else
                     *dp-- = 0xff;
                  *dp-- = *sp--;
               }
            }

            else if (row_info->bit_depth == 16)
            {
               png_byte gray_high = (gray >> 8) & 0xff;
               png_byte gray_low = gray & 0xff;
               sp = row + row_info->rowbytes - 1;
               dp = row + (row_info->rowbytes << 1) - 1;
               for (i = 0; i < row_width; i++)
               {
                  if (*(sp - 1) == gray_high && *(sp) == gray_low)
                  {
                     *dp-- = 0;
                     *dp-- = 0;
                  }
                  else
                  {
                     *dp-- = 0xff;
                     *dp-- = 0xff;
                  }
                  *dp-- = *sp--;
                  *dp-- = *sp--;
               }
            }

            row_info->color_type = PNG_COLOR_TYPE_GRAY_ALPHA;
            row_info->channels = 2;
            row_info->pixel_depth = (png_byte)(row_info->bit_depth << 1);
            row_info->rowbytes = PNG_ROWBYTES(row_info->pixel_depth,
               row_width);
         }
      }
      else if (row_info->color_type == PNG_COLOR_TYPE_RGB && trans_value)
      {
         if (row_info->bit_depth == 8)
         {
            png_byte red = trans_value->red & 0xff;
            png_byte green = trans_value->green & 0xff;
            png_byte blue = trans_value->blue & 0xff;
            sp = row + (png_size_t)row_info->rowbytes - 1;
            dp = row + (png_size_t)(row_width << 2) - 1;
            for (i = 0; i < row_width; i++)
            {
               if (*(sp - 2) == red && *(sp - 1) == green && *(sp) == blue)
                  *dp-- = 0;
               else
                  *dp-- = 0xff;
               *dp-- = *sp--;
               *dp-- = *sp--;
               *dp-- = *sp--;
            }
         }
         else if (row_info->bit_depth == 16)
         {
            png_byte red_high = (trans_value->red >> 8) & 0xff;
            png_byte green_high = (trans_value->green >> 8) & 0xff;
            png_byte blue_high = (trans_value->blue >> 8) & 0xff;
            png_byte red_low = trans_value->red & 0xff;
            png_byte green_low = trans_value->green & 0xff;
            png_byte blue_low = trans_value->blue & 0xff;
            sp = row + row_info->rowbytes - 1;
            dp = row + (png_size_t)(row_width << 3) - 1;
            for (i = 0; i < row_width; i++)
            {
               if (*(sp - 5) == red_high &&
                  *(sp - 4) == red_low &&
                  *(sp - 3) == green_high &&
                  *(sp - 2) == green_low &&
                  *(sp - 1) == blue_high &&
                  *(sp    ) == blue_low)
               {
                  *dp-- = 0;
                  *dp-- = 0;
               }
               else
               {
                  *dp-- = 0xff;
                  *dp-- = 0xff;
               }
               *dp-- = *sp--;
               *dp-- = *sp--;
               *dp-- = *sp--;
               *dp-- = *sp--;
               *dp-- = *sp--;
               *dp-- = *sp--;
            }
         }
         row_info->color_type = PNG_COLOR_TYPE_RGB_ALPHA;
         row_info->channels = 4;
         row_info->pixel_depth = (png_byte)(row_info->bit_depth << 2);
         row_info->rowbytes = PNG_ROWBYTES(row_info->pixel_depth, row_width);
      }
   }
}
#endif

#ifdef PNG_READ_DITHER_SUPPORTED
void /* PRIVATE */
png_do_dither(png_row_infop row_info, png_bytep row,
    png_bytep palette_lookup, png_bytep dither_lookup)
{
   png_bytep sp, dp;
   png_uint_32 i;
   png_uint_32 row_width=row_info->width;

   png_debug(1, "in png_do_dither");

#ifdef PNG_USELESS_TESTS_SUPPORTED
   if (row != NULL && row_info != NULL)
#endif
   {
      if (row_info->color_type == PNG_COLOR_TYPE_RGB &&
         palette_lookup && row_info->bit_depth == 8)
      {
         int r, g, b, p;
         sp = row;
         dp = row;
         for (i = 0; i < row_width; i++)
         {
            r = *sp++;
            g = *sp++;
            b = *sp++;

            /* This looks real messy, but the compiler will reduce
             * it down to a reasonable formula.  For example, with
             * 5 bits per color, we get:
             * p = (((r >> 3) & 0x1f) << 10) |
             *    (((g >> 3) & 0x1f) << 5) |
             *    ((b >> 3) & 0x1f);
             */
            p = (((r >> (8 - PNG_DITHER_RED_BITS)) &
               ((1 << PNG_DITHER_RED_BITS) - 1)) <<
               (PNG_DITHER_GREEN_BITS + PNG_DITHER_BLUE_BITS)) |
               (((g >> (8 - PNG_DITHER_GREEN_BITS)) &
               ((1 << PNG_DITHER_GREEN_BITS) - 1)) <<
               (PNG_DITHER_BLUE_BITS)) |
               ((b >> (8 - PNG_DITHER_BLUE_BITS)) &
               ((1 << PNG_DITHER_BLUE_BITS) - 1));

            *dp++ = palette_lookup[p];
         }
         row_info->color_type = PNG_COLOR_TYPE_PALETTE;
         row_info->channels = 1;
         row_info->pixel_depth = row_info->bit_depth;
         row_info->rowbytes = PNG_ROWBYTES(row_info->pixel_depth, row_width);
      }
      else if (row_info->color_type == PNG_COLOR_TYPE_RGB_ALPHA &&
         palette_lookup != NULL && row_info->bit_depth == 8)
      {
         int r, g, b, p;
         sp = row;
         dp = row;
         for (i = 0; i < row_width; i++)
         {
            r = *sp++;
            g = *sp++;
            b = *sp++;
            sp++;

            p = (((r >> (8 - PNG_DITHER_RED_BITS)) &
               ((1 << PNG_DITHER_RED_BITS) - 1)) <<
               (PNG_DITHER_GREEN_BITS + PNG_DITHER_BLUE_BITS)) |
               (((g >> (8 - PNG_DITHER_GREEN_BITS)) &
               ((1 << PNG_DITHER_GREEN_BITS) - 1)) <<
               (PNG_DITHER_BLUE_BITS)) |
               ((b >> (8 - PNG_DITHER_BLUE_BITS)) &
               ((1 << PNG_DITHER_BLUE_BITS) - 1));

            *dp++ = palette_lookup[p];
         }
         row_info->color_type = PNG_COLOR_TYPE_PALETTE;
         row_info->channels = 1;
         row_info->pixel_depth = row_info->bit_depth;
         row_info->rowbytes = PNG_ROWBYTES(row_info->pixel_depth, row_width);
      }
      else if (row_info->color_type == PNG_COLOR_TYPE_PALETTE &&
         dither_lookup && row_info->bit_depth == 8)
      {
         sp = row;
         for (i = 0; i < row_width; i++, sp++)
         {
            *sp = dither_lookup[*sp];
         }
      }
   }
}
#endif

#ifdef PNG_FLOATING_POINT_SUPPORTED
#ifdef PNG_READ_GAMMA_SUPPORTED
static PNG_CONST int png_gamma_shift[] =
   {0x10, 0x21, 0x42, 0x84, 0x110, 0x248, 0x550, 0xff0, 0x00};

/* We build the 8- or 16-bit gamma tables here.  Note that for 16-bit
 * tables, we don't make a full table if we are reducing to 8-bit in
 * the future.  Note also how the gamma_16 tables are segmented so that
 * we don't need to allocate > 64K chunks for a full 16-bit table.
 *
 * See the PNG extensions document for an integer algorithm for creating
 * the gamma tables.  Maybe we will implement that here someday.
 *
 * We should only reach this point if
 *
 *      the file_gamma is known (i.e., the gAMA or sRGB chunk is present,
 *      or the application has provided a file_gamma)
 *
 *   AND
 *      {
 *         the screen_gamma is known
 *      OR
 *
 *         RGB_to_gray transformation is being performed
 *      }
 *
 *   AND
 *      {
 *         the screen_gamma is different from the reciprocal of the
 *         file_gamma by more than the specified threshold
 *
 *      OR
 *
 *         a background color has been specified and the file_gamma
 *         and screen_gamma are not 1.0, within the specified threshold.
 *      }
 */

void /* PRIVATE */
png_build_gamma_table(png_structp png_ptr)
{
  png_debug(1, "in png_build_gamma_table");

  if (png_ptr->bit_depth <= 8)
  {
     int i;
     double g;

     if (png_ptr->screen_gamma > .000001)
        g = 1.0 / (png_ptr->gamma * png_ptr->screen_gamma);

     else
        g = 1.0;

     png_ptr->gamma_table = (png_bytep)png_malloc(png_ptr,
        (png_uint_32)256);

     for (i = 0; i < 256; i++)
     {
        png_ptr->gamma_table[i] = (png_byte)(pow((double)i / 255.0,
           g) * 255.0 + .5);
     }

#if defined(PNG_READ_BACKGROUND_SUPPORTED) || \
   defined(PNG_READ_RGB_TO_GRAY_SUPPORTED)
     if (png_ptr->transformations & ((PNG_BACKGROUND) | PNG_RGB_TO_GRAY))
     {

        g = 1.0 / (png_ptr->gamma);

        png_ptr->gamma_to_1 = (png_bytep)png_malloc(png_ptr,
           (png_uint_32)256);

        for (i = 0; i < 256; i++)
        {
           png_ptr->gamma_to_1[i] = (png_byte)(pow((double)i / 255.0,
              g) * 255.0 + .5);
        }


        png_ptr->gamma_from_1 = (png_bytep)png_malloc(png_ptr,
           (png_uint_32)256);

        if (png_ptr->screen_gamma > 0.000001)
           g = 1.0 / png_ptr->screen_gamma;

        else
           g = png_ptr->gamma;   /* Probably doing rgb_to_gray */

        for (i = 0; i < 256; i++)
        {
           png_ptr->gamma_from_1[i] = (png_byte)(pow((double)i / 255.0,
              g) * 255.0 + .5);

        }
     }
#endif /* PNG_READ_BACKGROUND_SUPPORTED || PNG_RGB_TO_GRAY_SUPPORTED */
  }
  else
  {
     double g;
     int i, j, shift, num;
     int sig_bit;
     png_uint_32 ig;

     if (png_ptr->color_type & PNG_COLOR_MASK_COLOR)
     {
        sig_bit = (int)png_ptr->sig_bit.red;

        if ((int)png_ptr->sig_bit.green > sig_bit)
           sig_bit = png_ptr->sig_bit.green;

        if ((int)png_ptr->sig_bit.blue > sig_bit)
           sig_bit = png_ptr->sig_bit.blue;
     }
     else
     {
        sig_bit = (int)png_ptr->sig_bit.gray;
     }

     if (sig_bit > 0)
        shift = 16 - sig_bit;

     else
        shift = 0;

     if (png_ptr->transformations & PNG_16_TO_8)
     {
        if (shift < (16 - PNG_MAX_GAMMA_8))
           shift = (16 - PNG_MAX_GAMMA_8);
     }

     if (shift > 8)
        shift = 8;

     if (shift < 0)
        shift = 0;

     png_ptr->gamma_shift = (png_byte)shift;

     num = (1 << (8 - shift));

     if (png_ptr->screen_gamma > .000001)
        g = 1.0 / (png_ptr->gamma * png_ptr->screen_gamma);
     else
        g = 1.0;

     png_ptr->gamma_16_table = (png_uint_16pp)png_calloc(png_ptr,
        (png_uint_32)(num * png_sizeof(png_uint_16p)));

     if (png_ptr->transformations & (PNG_16_TO_8 | PNG_BACKGROUND))
     {
        double fin, fout;
        png_uint_32 last, max;

        for (i = 0; i < num; i++)
        {
           png_ptr->gamma_16_table[i] = (png_uint_16p)png_malloc(png_ptr,
              (png_uint_32)(256 * png_sizeof(png_uint_16)));
        }

        g = 1.0 / g;
        last = 0;
        for (i = 0; i < 256; i++)
        {
           fout = ((double)i + 0.5) / 256.0;
           fin = pow(fout, g);
           max = (png_uint_32)(fin * (double)((png_uint_32)num << 8));
           while (last <= max)
           {
              png_ptr->gamma_16_table[(int)(last & (0xff >> shift))]
                 [(int)(last >> (8 - shift))] = (png_uint_16)(
                 (png_uint_16)i | ((png_uint_16)i << 8));
              last++;
           }
        }
        while (last < ((png_uint_32)num << 8))
        {
           png_ptr->gamma_16_table[(int)(last & (0xff >> shift))]
              [(int)(last >> (8 - shift))] = (png_uint_16)65535L;
           last++;
        }
     }
     else
     {
        for (i = 0; i < num; i++)
        {
           png_ptr->gamma_16_table[i] = (png_uint_16p)png_malloc(png_ptr,
              (png_uint_32)(256 * png_sizeof(png_uint_16)));

           ig = (((png_uint_32)i * (png_uint_32)png_gamma_shift[shift]) >> 4);

           for (j = 0; j < 256; j++)
           {
              png_ptr->gamma_16_table[i][j] =
                 (png_uint_16)(pow((double)(ig + ((png_uint_32)j << 8)) /
                    65535.0, g) * 65535.0 + .5);
           }
        }
     }

#if defined(PNG_READ_BACKGROUND_SUPPORTED) || \
   defined(PNG_READ_RGB_TO_GRAY_SUPPORTED)
     if (png_ptr->transformations & (PNG_BACKGROUND | PNG_RGB_TO_GRAY))
     {

        g = 1.0 / (png_ptr->gamma);

        png_ptr->gamma_16_to_1 = (png_uint_16pp)png_calloc(png_ptr,
           (png_uint_32)(num * png_sizeof(png_uint_16p )));

        for (i = 0; i < num; i++)
        {
           png_ptr->gamma_16_to_1[i] = (png_uint_16p)png_malloc(png_ptr,
              (png_uint_32)(256 * png_sizeof(png_uint_16)));

           ig = (((png_uint_32)i *
              (png_uint_32)png_gamma_shift[shift]) >> 4);
           for (j = 0; j < 256; j++)
           {
              png_ptr->gamma_16_to_1[i][j] =
                 (png_uint_16)(pow((double)(ig + ((png_uint_32)j << 8)) /
                    65535.0, g) * 65535.0 + .5);
           }
        }

        if (png_ptr->screen_gamma > 0.000001)
           g = 1.0 / png_ptr->screen_gamma;

        else
           g = png_ptr->gamma;   /* Probably doing rgb_to_gray */

        png_ptr->gamma_16_from_1 = (png_uint_16pp)png_calloc(png_ptr,
           (png_uint_32)(num * png_sizeof(png_uint_16p)));

        for (i = 0; i < num; i++)
        {
           png_ptr->gamma_16_from_1[i] = (png_uint_16p)png_malloc(png_ptr,
              (png_uint_32)(256 * png_sizeof(png_uint_16)));

           ig = (((png_uint_32)i *
              (png_uint_32)png_gamma_shift[shift]) >> 4);

           for (j = 0; j < 256; j++)
           {
              png_ptr->gamma_16_from_1[i][j] =
                 (png_uint_16)(pow((double)(ig + ((png_uint_32)j << 8)) /
                    65535.0, g) * 65535.0 + .5);
           }
        }
     }
#endif /* PNG_READ_BACKGROUND_SUPPORTED || PNG_RGB_TO_GRAY_SUPPORTED */
  }
}
#endif
/* To do: install integer version of png_build_gamma_table here */
#endif

#ifdef PNG_MNG_FEATURES_SUPPORTED
/* Undoes intrapixel differencing  */
void /* PRIVATE */
png_do_read_intrapixel(png_row_infop row_info, png_bytep row)
{
   png_debug(1, "in png_do_read_intrapixel");

   if (
#ifdef PNG_USELESS_TESTS_SUPPORTED
       row != NULL && row_info != NULL &&
#endif
       (row_info->color_type & PNG_COLOR_MASK_COLOR))
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
            *(rp) = (png_byte)((256 + *rp + *(rp+1))&0xff);
            *(rp+2) = (png_byte)((256 + *(rp+2) + *(rp+1))&0xff);
         }
      }
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
            png_uint_32 red  = (png_uint_32)((s0 + s1 + 65536L) & 0xffffL);
            png_uint_32 blue = (png_uint_32)((s2 + s1 + 65536L) & 0xffffL);
            *(rp  ) = (png_byte)((red >> 8) & 0xff);
            *(rp+1) = (png_byte)(red & 0xff);
            *(rp+4) = (png_byte)((blue >> 8) & 0xff);
            *(rp+5) = (png_byte)(blue & 0xff);
         }
      }
   }
}
#endif /* PNG_MNG_FEATURES_SUPPORTED */
#endif /* PNG_READ_SUPPORTED */
