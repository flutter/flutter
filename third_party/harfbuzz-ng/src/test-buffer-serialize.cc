/*
 * Copyright © 2010,2011,2013  Google, Inc.
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
#ifdef HAVE_FREETYPE
#include "hb-ft.h"
#endif

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

  hb_face_t *face = hb_face_create (blob, 0 /* first face */);
  hb_blob_destroy (blob);
  blob = NULL;

  unsigned int upem = hb_face_get_upem (face);
  hb_font_t *font = hb_font_create (face);
  hb_face_destroy (face);
  hb_font_set_scale (font, upem, upem);
#ifdef HAVE_FREETYPE
  hb_ft_font_set_funcs (font);
#endif

  hb_buffer_t *buf;
  buf = hb_buffer_create ();

  bool ret = true;
  char line[BUFSIZ], out[BUFSIZ];
  while (fgets (line, sizeof(line), stdin) != 0)
  {
    hb_buffer_clear_contents (buf);

    const char *p = line;
    while (hb_buffer_deserialize_glyphs (buf,
					 p, -1, &p,
					 font,
					 HB_BUFFER_SERIALIZE_FORMAT_JSON))
      ;
    if (*p && *p != '\n')
      ret = false;

    hb_buffer_serialize_glyphs (buf, 0, hb_buffer_get_length (buf),
				out, sizeof (out), NULL,
				font, HB_BUFFER_SERIALIZE_FORMAT_JSON,
				HB_BUFFER_SERIALIZE_FLAG_DEFAULT);
    puts (out);
  }

  hb_buffer_destroy (buf);

  hb_font_destroy (font);

  return !ret;
}
