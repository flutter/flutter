/*
 * Copyright © 2010,2011  Google, Inc.
 *
 *  This is part of HarfBuzz, a text shaping library.
 *
 * Permission is hereby granted, without written agreement and without
 * license or royalty fees, to use, copy, modify, and distribute this
 * software and its documentation for any purpose, provided that the
 * above copyright notice and the following two paragraphs appear in
 * all copies of this software.
 *
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF THE COPYRIGHT HOLDER HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 *
 * THE COPYRIGHT HOLDER SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING,
 * BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDER HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Google Author(s): Behdad Esfahbod
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "hb.h"
#include "hb-ot.h"

#ifdef HAVE_GLIB
# include <glib.h>
# if !GLIB_CHECK_VERSION (2, 22, 0)
#  define g_mapped_file_unref g_mapped_file_free
# endif
#endif
#include <stdlib.h>
#include <stdio.h>

int
main (int argc, char **argv)
{
  hb_blob_t *blob = NULL;

  if (argc != 2) {
    fprintf (stderr, "usage: %s font-file\n", argv[0]);
    exit (1);
  }

  /* Create the blob */
  {
    const char *font_data;
    unsigned int len;
    hb_destroy_func_t destroy;
    void *user_data;
    hb_memory_mode_t mm;

#ifdef HAVE_GLIB
    GMappedFile *mf = g_mapped_file_new (argv[1], false, NULL);
    font_data = g_mapped_file_get_contents (mf);
    len = g_mapped_file_get_length (mf);
    destroy = (hb_destroy_func_t) g_mapped_file_unref;
    user_data = (void *) mf;
    mm = HB_MEMORY_MODE_READONLY_MAY_MAKE_WRITABLE;
#else
    FILE *f = fopen (argv[1], "rb");
    fseek (f, 0, SEEK_END);
    len = ftell (f);
    fseek (f, 0, SEEK_SET);
    font_data = (const char *) malloc (len);
    if (!font_data) len = 0;
    len = fread ((char *) font_data, 1, len, f);
    destroy = free;
    user_data = (void *) font_data;
    fclose (f);
    mm = HB_MEMORY_MODE_WRITABLE;
#endif

    blob = hb_blob_create (font_data, len, mm, user_data, destroy);
  }

  /* Create the face */
  hb_face_t *face = hb_face_create (blob, 0 /* first face */);
  hb_blob_destroy (blob);
  blob = NULL;

  unsigned int p[5];
  bool ret = hb_ot_layout_get_size_params (face, p, p+1, p+2, p+3, p+4);

  printf ("%g %u %u %g %g\n", p[0]/10., p[1], p[2], p[3]/10., p[4]/10.);

  return !ret;
}
