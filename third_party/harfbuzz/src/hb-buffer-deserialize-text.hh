
#line 1 "hb-buffer-deserialize-text.rl"
/*
 * Copyright © 2013  Google, Inc.
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

#ifndef HB_BUFFER_DESERIALIZE_TEXT_HH
#define HB_BUFFER_DESERIALIZE_TEXT_HH

#include "hb-private.hh"


#line 36 "hb-buffer-deserialize-text.hh"
static const unsigned char _deserialize_text_trans_keys[] = {
	0u, 0u, 9u, 122u, 45u, 57u, 48u, 57u, 45u, 57u, 48u, 57u, 48u, 57u, 45u, 57u, 
	48u, 57u, 44u, 44u, 45u, 57u, 48u, 57u, 44u, 57u, 9u, 124u, 9u, 124u, 0u, 0u, 
	9u, 122u, 9u, 124u, 9u, 124u, 9u, 124u, 9u, 124u, 9u, 124u, 9u, 124u, 9u, 124u, 
	9u, 124u, 9u, 124u, 9u, 124u, 0
};

static const char _deserialize_text_key_spans[] = {
	0, 114, 13, 10, 13, 10, 10, 13, 
	10, 1, 13, 10, 14, 116, 116, 0, 
	114, 116, 116, 116, 116, 116, 116, 116, 
	116, 116, 116
};

static const short _deserialize_text_index_offsets[] = {
	0, 0, 115, 129, 140, 154, 165, 176, 
	190, 201, 203, 217, 228, 243, 360, 477, 
	478, 593, 710, 827, 944, 1061, 1178, 1295, 
	1412, 1529, 1646
};

static const char _deserialize_text_indicies[] = {
	0, 0, 0, 0, 0, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	0, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	2, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 1, 1, 1, 1, 1, 1, 
	1, 4, 4, 4, 4, 4, 4, 4, 
	4, 4, 4, 4, 4, 4, 4, 4, 
	4, 4, 4, 4, 4, 4, 4, 4, 
	4, 4, 4, 1, 1, 1, 1, 1, 
	1, 4, 4, 4, 4, 4, 4, 4, 
	4, 4, 4, 4, 4, 4, 4, 4, 
	4, 4, 4, 4, 4, 4, 4, 4, 
	4, 4, 4, 1, 5, 1, 1, 6, 
	7, 7, 7, 7, 7, 7, 7, 7, 
	7, 1, 8, 9, 9, 9, 9, 9, 
	9, 9, 9, 9, 1, 10, 1, 1, 
	11, 12, 12, 12, 12, 12, 12, 12, 
	12, 12, 1, 13, 14, 14, 14, 14, 
	14, 14, 14, 14, 14, 1, 15, 16, 
	16, 16, 16, 16, 16, 16, 16, 16, 
	1, 17, 1, 1, 18, 19, 19, 19, 
	19, 19, 19, 19, 19, 19, 1, 20, 
	21, 21, 21, 21, 21, 21, 21, 21, 
	21, 1, 22, 1, 23, 1, 1, 24, 
	25, 25, 25, 25, 25, 25, 25, 25, 
	25, 1, 26, 27, 27, 27, 27, 27, 
	27, 27, 27, 27, 1, 22, 1, 1, 
	1, 21, 21, 21, 21, 21, 21, 21, 
	21, 21, 21, 1, 28, 28, 28, 28, 
	28, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 28, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 29, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	30, 1, 1, 31, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	32, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 33, 
	1, 34, 34, 34, 34, 34, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	34, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 35, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 36, 1, 1, 0, 
	0, 0, 0, 0, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 0, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 2, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	1, 1, 1, 1, 1, 1, 1, 4, 
	4, 4, 4, 4, 4, 4, 4, 4, 
	4, 4, 4, 4, 4, 4, 4, 4, 
	4, 4, 4, 4, 4, 4, 4, 4, 
	4, 1, 1, 1, 1, 1, 1, 4, 
	4, 4, 4, 4, 4, 4, 4, 4, 
	4, 4, 4, 4, 4, 4, 4, 4, 
	4, 4, 4, 4, 4, 4, 4, 4, 
	4, 1, 28, 28, 28, 28, 28, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 28, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 29, 1, 1, 1, 
	1, 37, 37, 37, 37, 37, 37, 37, 
	37, 37, 37, 1, 1, 1, 30, 1, 
	1, 31, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 32, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 33, 1, 38, 
	38, 38, 38, 38, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 38, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 39, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 40, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 41, 1, 42, 42, 42, 42, 
	42, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 42, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	43, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 44, 
	1, 42, 42, 42, 42, 42, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	42, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	14, 14, 14, 14, 14, 14, 14, 14, 
	14, 14, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 43, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 44, 1, 38, 38, 
	38, 38, 38, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 38, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 39, 1, 1, 1, 9, 9, 9, 
	9, 9, 9, 9, 9, 9, 9, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 40, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 41, 1, 45, 45, 45, 45, 45, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 45, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 46, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 47, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 48, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 49, 1, 
	50, 50, 50, 50, 50, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 50, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 51, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 52, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 53, 1, 50, 50, 50, 
	50, 50, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 50, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 51, 
	1, 1, 1, 1, 27, 27, 27, 27, 
	27, 27, 27, 27, 27, 27, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 52, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	53, 1, 45, 45, 45, 45, 45, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 45, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 46, 1, 1, 1, 
	1, 54, 54, 54, 54, 54, 54, 54, 
	54, 54, 54, 1, 1, 1, 1, 1, 
	1, 47, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 48, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 49, 1, 28, 
	28, 28, 28, 28, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 28, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 29, 1, 55, 55, 1, 55, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	1, 1, 1, 30, 1, 1, 31, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	55, 1, 1, 32, 1, 55, 1, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	55, 55, 55, 55, 55, 55, 55, 55, 
	55, 1, 33, 1, 0
};

static const char _deserialize_text_trans_targs[] = {
	1, 0, 13, 17, 26, 3, 18, 21, 
	18, 21, 5, 19, 20, 19, 20, 22, 
	25, 8, 9, 12, 9, 12, 10, 11, 
	23, 24, 23, 24, 14, 2, 6, 7, 
	15, 16, 14, 15, 16, 17, 14, 4, 
	15, 16, 14, 15, 16, 14, 2, 7, 
	15, 16, 14, 2, 15, 16, 25, 26
};

static const char _deserialize_text_trans_actions[] = {
	0, 0, 1, 1, 1, 2, 2, 2, 
	0, 0, 2, 2, 2, 0, 0, 2, 
	2, 2, 2, 2, 0, 0, 3, 2, 
	2, 2, 0, 0, 4, 5, 5, 5, 
	4, 4, 0, 0, 0, 0, 6, 7, 
	6, 6, 8, 8, 8, 9, 10, 10, 
	9, 9, 11, 12, 11, 11, 0, 0
};

static const char _deserialize_text_eof_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 4, 0, 0, 
	0, 4, 6, 8, 8, 6, 9, 11, 
	11, 9, 4
};

static const int deserialize_text_start = 1;
static const int deserialize_text_first_final = 13;
static const int deserialize_text_error = 0;

static const int deserialize_text_en_main = 1;


#line 91 "hb-buffer-deserialize-text.rl"


static hb_bool_t
_hb_buffer_deserialize_glyphs_text (hb_buffer_t *buffer,
				    const char *buf,
				    unsigned int buf_len,
				    const char **end_ptr,
				    hb_font_t *font)
{
  const char *p = buf, *pe = buf + buf_len;

  /* Ensure we have positions. */
  (void) hb_buffer_get_glyph_positions (buffer, NULL);

  while (p < pe && ISSPACE (*p))
    p++;
  if (p < pe && *p == (buffer->len ? '|' : '['))
  {
    *end_ptr = ++p;
  }

  const char *eof = pe, *tok = NULL;
  int cs;
  hb_glyph_info_t info;
  hb_glyph_position_t pos;
  
#line 343 "hb-buffer-deserialize-text.hh"
	{
	cs = deserialize_text_start;
	}

#line 348 "hb-buffer-deserialize-text.hh"
	{
	int _slen;
	int _trans;
	const unsigned char *_keys;
	const char *_inds;
	if ( p == pe )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _deserialize_text_trans_keys + (cs<<1);
	_inds = _deserialize_text_indicies + _deserialize_text_index_offsets[cs];

	_slen = _deserialize_text_key_spans[cs];
	_trans = _inds[ _slen > 0 && _keys[0] <=(*p) &&
		(*p) <= _keys[1] ?
		(*p) - _keys[0] : _slen ];

	cs = _deserialize_text_trans_targs[_trans];

	if ( _deserialize_text_trans_actions[_trans] == 0 )
		goto _again;

	switch ( _deserialize_text_trans_actions[_trans] ) {
	case 2:
#line 51 "hb-buffer-deserialize-text.rl"
	{
	tok = p;
}
	break;
	case 5:
#line 55 "hb-buffer-deserialize-text.rl"
	{
	if (!hb_font_glyph_from_string (font,
					tok, p - tok,
					&info.codepoint))
	  return false;
}
	break;
	case 10:
#line 62 "hb-buffer-deserialize-text.rl"
	{ if (!parse_uint (tok, p, &info.cluster )) return false; }
	break;
	case 3:
#line 63 "hb-buffer-deserialize-text.rl"
	{ if (!parse_int  (tok, p, &pos.x_offset )) return false; }
	break;
	case 12:
#line 64 "hb-buffer-deserialize-text.rl"
	{ if (!parse_int  (tok, p, &pos.y_offset )) return false; }
	break;
	case 7:
#line 65 "hb-buffer-deserialize-text.rl"
	{ if (!parse_int  (tok, p, &pos.x_advance)) return false; }
	break;
	case 1:
#line 38 "hb-buffer-deserialize-text.rl"
	{
	memset (&info, 0, sizeof (info));
	memset (&pos , 0, sizeof (pos ));
}
#line 51 "hb-buffer-deserialize-text.rl"
	{
	tok = p;
}
	break;
	case 4:
#line 55 "hb-buffer-deserialize-text.rl"
	{
	if (!hb_font_glyph_from_string (font,
					tok, p - tok,
					&info.codepoint))
	  return false;
}
#line 43 "hb-buffer-deserialize-text.rl"
	{
	buffer->add_info (info);
	if (buffer->in_error)
	  return false;
	buffer->pos[buffer->len - 1] = pos;
	*end_ptr = p;
}
	break;
	case 9:
#line 62 "hb-buffer-deserialize-text.rl"
	{ if (!parse_uint (tok, p, &info.cluster )) return false; }
#line 43 "hb-buffer-deserialize-text.rl"
	{
	buffer->add_info (info);
	if (buffer->in_error)
	  return false;
	buffer->pos[buffer->len - 1] = pos;
	*end_ptr = p;
}
	break;
	case 11:
#line 64 "hb-buffer-deserialize-text.rl"
	{ if (!parse_int  (tok, p, &pos.y_offset )) return false; }
#line 43 "hb-buffer-deserialize-text.rl"
	{
	buffer->add_info (info);
	if (buffer->in_error)
	  return false;
	buffer->pos[buffer->len - 1] = pos;
	*end_ptr = p;
}
	break;
	case 6:
#line 65 "hb-buffer-deserialize-text.rl"
	{ if (!parse_int  (tok, p, &pos.x_advance)) return false; }
#line 43 "hb-buffer-deserialize-text.rl"
	{
	buffer->add_info (info);
	if (buffer->in_error)
	  return false;
	buffer->pos[buffer->len - 1] = pos;
	*end_ptr = p;
}
	break;
	case 8:
#line 66 "hb-buffer-deserialize-text.rl"
	{ if (!parse_int  (tok, p, &pos.y_advance)) return false; }
#line 43 "hb-buffer-deserialize-text.rl"
	{
	buffer->add_info (info);
	if (buffer->in_error)
	  return false;
	buffer->pos[buffer->len - 1] = pos;
	*end_ptr = p;
}
	break;
#line 480 "hb-buffer-deserialize-text.hh"
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	if ( p == eof )
	{
	switch ( _deserialize_text_eof_actions[cs] ) {
	case 4:
#line 55 "hb-buffer-deserialize-text.rl"
	{
	if (!hb_font_glyph_from_string (font,
					tok, p - tok,
					&info.codepoint))
	  return false;
}
#line 43 "hb-buffer-deserialize-text.rl"
	{
	buffer->add_info (info);
	if (buffer->in_error)
	  return false;
	buffer->pos[buffer->len - 1] = pos;
	*end_ptr = p;
}
	break;
	case 9:
#line 62 "hb-buffer-deserialize-text.rl"
	{ if (!parse_uint (tok, p, &info.cluster )) return false; }
#line 43 "hb-buffer-deserialize-text.rl"
	{
	buffer->add_info (info);
	if (buffer->in_error)
	  return false;
	buffer->pos[buffer->len - 1] = pos;
	*end_ptr = p;
}
	break;
	case 11:
#line 64 "hb-buffer-deserialize-text.rl"
	{ if (!parse_int  (tok, p, &pos.y_offset )) return false; }
#line 43 "hb-buffer-deserialize-text.rl"
	{
	buffer->add_info (info);
	if (buffer->in_error)
	  return false;
	buffer->pos[buffer->len - 1] = pos;
	*end_ptr = p;
}
	break;
	case 6:
#line 65 "hb-buffer-deserialize-text.rl"
	{ if (!parse_int  (tok, p, &pos.x_advance)) return false; }
#line 43 "hb-buffer-deserialize-text.rl"
	{
	buffer->add_info (info);
	if (buffer->in_error)
	  return false;
	buffer->pos[buffer->len - 1] = pos;
	*end_ptr = p;
}
	break;
	case 8:
#line 66 "hb-buffer-deserialize-text.rl"
	{ if (!parse_int  (tok, p, &pos.y_advance)) return false; }
#line 43 "hb-buffer-deserialize-text.rl"
	{
	buffer->add_info (info);
	if (buffer->in_error)
	  return false;
	buffer->pos[buffer->len - 1] = pos;
	*end_ptr = p;
}
	break;
#line 557 "hb-buffer-deserialize-text.hh"
	}
	}

	_out: {}
	}

#line 119 "hb-buffer-deserialize-text.rl"


  *end_ptr = p;

  return p == pe && *(p-1) != ']';
}

#endif /* HB_BUFFER_DESERIALIZE_TEXT_HH */
