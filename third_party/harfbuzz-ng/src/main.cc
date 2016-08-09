/*
 * Copyright © 2007,2008,2009  Red Hat, Inc.
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
 * Red Hat Author(s): Behdad Esfahbod
 */

#include "hb-mutex-private.hh"
#include "hb-open-file-private.hh"
#include "hb-ot-layout-gdef-table.hh"
#include "hb-ot-layout-gsubgpos-private.hh"

#ifdef HAVE_GLIB
#include <glib.h>
#endif
#include <stdlib.h>
#include <stdio.h>


using namespace OT;


int
main (int argc, char **argv)
{
  if (argc != 2) {
    fprintf (stderr, "usage: %s font-file.ttf\n", argv[0]);
    exit (1);
  }

  const char *font_data = NULL;
  int len = 0;

#ifdef HAVE_GLIB
  GMappedFile *mf = g_mapped_file_new (argv[1], false, NULL);
  font_data = g_mapped_file_get_contents (mf);
  len = g_mapped_file_get_length (mf);
#else
  FILE *f = fopen (argv[1], "rb");
  fseek (f, 0, SEEK_END);
  len = ftell (f);
  fseek (f, 0, SEEK_SET);
  font_data = (const char *) malloc (len);
  len = fread ((char *) font_data, 1, len, f);
#endif

  printf ("Opened font file %s: %d bytes long\n", argv[1], len);

  const OpenTypeFontFile &ot = *CastP<OpenTypeFontFile> (font_data);

  switch (ot.get_tag ()) {
  case OpenTypeFontFile::TrueTypeTag:
    printf ("OpenType font with TrueType outlines\n");
    break;
  case OpenTypeFontFile::CFFTag:
    printf ("OpenType font with CFF (Type1) outlines\n");
    break;
  case OpenTypeFontFile::TTCTag:
    printf ("TrueType Collection of OpenType fonts\n");
    break;
  case OpenTypeFontFile::TrueTag:
    printf ("Obsolete Apple TrueType font\n");
    break;
  case OpenTypeFontFile::Typ1Tag:
    printf ("Obsolete Apple Type1 font in SFNT container\n");
    break;
  default:
    printf ("Unknown font format\n");
    break;
  }

  int num_fonts = ot.get_face_count ();
  printf ("%d font(s) found in file\n", num_fonts);
  for (int n_font = 0; n_font < num_fonts; n_font++) {
    const OpenTypeFontFace &font = ot.get_face (n_font);
    printf ("Font %d of %d:\n", n_font, num_fonts);

    int num_tables = font.get_table_count ();
    printf ("  %d table(s) found in font\n", num_tables);
    for (int n_table = 0; n_table < num_tables; n_table++) {
      const OpenTypeTable &table = font.get_table (n_table);
      printf ("  Table %2d of %2d: %.4s (0x%08x+0x%08x)\n", n_table, num_tables,
	      (const char *)table.tag,
	      (unsigned int) table.offset,
	      (unsigned int) table.length);

      switch (table.tag) {

      case GSUBGPOS::GSUBTag:
      case GSUBGPOS::GPOSTag:
	{

	const GSUBGPOS &g = *CastP<GSUBGPOS> (font_data + table.offset);

	int num_scripts = g.get_script_count ();
	printf ("    %d script(s) found in table\n", num_scripts);
	for (int n_script = 0; n_script < num_scripts; n_script++) {
	  const Script &script = g.get_script (n_script);
	  printf ("    Script %2d of %2d: %.4s\n", n_script, num_scripts,
	          (const char *)g.get_script_tag(n_script));

	  if (!script.has_default_lang_sys())
	    printf ("      No default language system\n");
	  int num_langsys = script.get_lang_sys_count ();
	  printf ("      %d language system(s) found in script\n", num_langsys);
	  for (int n_langsys = script.has_default_lang_sys() ? -1 : 0; n_langsys < num_langsys; n_langsys++) {
	    const LangSys &langsys = n_langsys == -1
				   ? script.get_default_lang_sys ()
				   : script.get_lang_sys (n_langsys);
	    if (n_langsys == -1)
	      printf ("      Default Language System\n");
	    else
	      printf ("      Language System %2d of %2d: %.4s\n", n_langsys, num_langsys,
		      (const char *)script.get_lang_sys_tag (n_langsys));
	    if (!langsys.has_required_feature ())
	      printf ("        No required feature\n");
	    else
	      printf ("        Required feature index: %d\n",
		      langsys.get_required_feature_index ());

	    int num_features = langsys.get_feature_count ();
	    printf ("        %d feature(s) found in language system\n", num_features);
	    for (int n_feature = 0; n_feature < num_features; n_feature++) {
	      printf ("        Feature index %2d of %2d: %d\n", n_feature, num_features,
	              langsys.get_feature_index (n_feature));
	    }
	  }
	}

	int num_features = g.get_feature_count ();
	printf ("    %d feature(s) found in table\n", num_features);
	for (int n_feature = 0; n_feature < num_features; n_feature++) {
	  const Feature &feature = g.get_feature (n_feature);
	  int num_lookups = feature.get_lookup_count ();
	  printf ("    Feature %2d of %2d: %c%c%c%c\n", n_feature, num_features,
	          HB_UNTAG(g.get_feature_tag(n_feature)));

	  printf ("        %d lookup(s) found in feature\n", num_lookups);
	  for (int n_lookup = 0; n_lookup < num_lookups; n_lookup++) {
	    printf ("        Lookup index %2d of %2d: %d\n", n_lookup, num_lookups,
	            feature.get_lookup_index (n_lookup));
	  }
	}

	int num_lookups = g.get_lookup_count ();
	printf ("    %d lookup(s) found in table\n", num_lookups);
	for (int n_lookup = 0; n_lookup < num_lookups; n_lookup++) {
	  const Lookup &lookup = g.get_lookup (n_lookup);
	  printf ("    Lookup %2d of %2d: type %d, props 0x%04X\n", n_lookup, num_lookups,
	          lookup.get_type(), lookup.get_props());
	}

	}
	break;

      case GDEF::tableTag:
	{

	const GDEF &gdef = *CastP<GDEF> (font_data + table.offset);

	printf ("    Has %sglyph classes\n",
		  gdef.has_glyph_classes () ? "" : "no ");
	printf ("    Has %smark attachment types\n",
		  gdef.has_mark_attachment_types () ? "" : "no ");
	printf ("    Has %sattach points\n",
		  gdef.has_attach_points () ? "" : "no ");
	printf ("    Has %slig carets\n",
		  gdef.has_lig_carets () ? "" : "no ");
	printf ("    Has %smark sets\n",
		  gdef.has_mark_sets () ? "" : "no ");
	break;
	}
      }
    }
  }

  return 0;
}


