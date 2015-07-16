
#line 1 "hb-ot-shape-complex-sea-machine.rl"
/*
 * Copyright © 2011,2012,2013  Google, Inc.
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

#ifndef HB_OT_SHAPE_COMPLEX_SEA_MACHINE_HH
#define HB_OT_SHAPE_COMPLEX_SEA_MACHINE_HH

#include "hb-private.hh"


#line 36 "hb-ot-shape-complex-sea-machine.hh"
static const unsigned char _sea_syllable_machine_trans_keys[] = {
	1u, 1u, 1u, 1u, 1u, 29u, 3u, 29u, 3u, 29u, 1u, 1u, 0
};

static const char _sea_syllable_machine_key_spans[] = {
	1, 1, 29, 27, 27, 1
};

static const char _sea_syllable_machine_index_offsets[] = {
	0, 2, 4, 34, 62, 90
};

static const char _sea_syllable_machine_indicies[] = {
	1, 0, 3, 2, 1, 1, 3, 5, 
	4, 4, 4, 4, 4, 3, 4, 1, 
	4, 4, 4, 4, 3, 4, 4, 4, 
	4, 3, 4, 4, 4, 3, 3, 3, 
	3, 4, 1, 7, 6, 6, 6, 6, 
	6, 1, 6, 6, 6, 6, 6, 6, 
	1, 6, 6, 6, 6, 1, 6, 6, 
	6, 1, 1, 1, 1, 6, 3, 9, 
	8, 8, 8, 8, 8, 3, 8, 8, 
	8, 8, 8, 8, 3, 8, 8, 8, 
	8, 3, 8, 8, 8, 3, 3, 3, 
	3, 8, 3, 10, 0
};

static const char _sea_syllable_machine_trans_targs[] = {
	2, 3, 2, 4, 2, 5, 2, 0, 
	2, 1, 2
};

static const char _sea_syllable_machine_trans_actions[] = {
	1, 2, 3, 2, 6, 0, 7, 0, 
	8, 0, 9
};

static const char _sea_syllable_machine_to_state_actions[] = {
	0, 0, 4, 0, 0, 0
};

static const char _sea_syllable_machine_from_state_actions[] = {
	0, 0, 5, 0, 0, 0
};

static const char _sea_syllable_machine_eof_trans[] = {
	1, 3, 0, 7, 9, 11
};

static const int sea_syllable_machine_start = 2;
static const int sea_syllable_machine_first_final = 2;
static const int sea_syllable_machine_error = -1;

static const int sea_syllable_machine_en_main = 2;


#line 36 "hb-ot-shape-complex-sea-machine.rl"



#line 67 "hb-ot-shape-complex-sea-machine.rl"


#define found_syllable(syllable_type) \
  HB_STMT_START { \
    if (0) fprintf (stderr, "syllable %d..%d %s\n", last, p+1, #syllable_type); \
    for (unsigned int i = last; i < p+1; i++) \
      info[i].syllable() = (syllable_serial << 4) | syllable_type; \
    last = p+1; \
    syllable_serial++; \
    if (unlikely (syllable_serial == 16)) syllable_serial = 1; \
  } HB_STMT_END

static void
find_syllables (hb_buffer_t *buffer)
{
  unsigned int p, pe, eof, ts HB_UNUSED, te HB_UNUSED, act HB_UNUSED;
  int cs;
  hb_glyph_info_t *info = buffer->info;
  
#line 117 "hb-ot-shape-complex-sea-machine.hh"
	{
	cs = sea_syllable_machine_start;
	ts = 0;
	te = 0;
	act = 0;
	}

#line 88 "hb-ot-shape-complex-sea-machine.rl"


  p = 0;
  pe = eof = buffer->len;

  unsigned int last = 0;
  unsigned int syllable_serial = 1;
  
#line 134 "hb-ot-shape-complex-sea-machine.hh"
	{
	int _slen;
	int _trans;
	const unsigned char *_keys;
	const char *_inds;
	if ( p == pe )
		goto _test_eof;
_resume:
	switch ( _sea_syllable_machine_from_state_actions[cs] ) {
	case 5:
#line 1 "NONE"
	{ts = p;}
	break;
#line 148 "hb-ot-shape-complex-sea-machine.hh"
	}

	_keys = _sea_syllable_machine_trans_keys + (cs<<1);
	_inds = _sea_syllable_machine_indicies + _sea_syllable_machine_index_offsets[cs];

	_slen = _sea_syllable_machine_key_spans[cs];
	_trans = _inds[ _slen > 0 && _keys[0] <=( info[p].sea_category()) &&
		( info[p].sea_category()) <= _keys[1] ?
		( info[p].sea_category()) - _keys[0] : _slen ];

_eof_trans:
	cs = _sea_syllable_machine_trans_targs[_trans];

	if ( _sea_syllable_machine_trans_actions[_trans] == 0 )
		goto _again;

	switch ( _sea_syllable_machine_trans_actions[_trans] ) {
	case 2:
#line 1 "NONE"
	{te = p+1;}
	break;
	case 6:
#line 63 "hb-ot-shape-complex-sea-machine.rl"
	{te = p+1;{ found_syllable (non_sea_cluster); }}
	break;
	case 7:
#line 61 "hb-ot-shape-complex-sea-machine.rl"
	{te = p;p--;{ found_syllable (consonant_syllable); }}
	break;
	case 8:
#line 62 "hb-ot-shape-complex-sea-machine.rl"
	{te = p;p--;{ found_syllable (broken_cluster); }}
	break;
	case 9:
#line 63 "hb-ot-shape-complex-sea-machine.rl"
	{te = p;p--;{ found_syllable (non_sea_cluster); }}
	break;
	case 1:
#line 61 "hb-ot-shape-complex-sea-machine.rl"
	{{p = ((te))-1;}{ found_syllable (consonant_syllable); }}
	break;
	case 3:
#line 62 "hb-ot-shape-complex-sea-machine.rl"
	{{p = ((te))-1;}{ found_syllable (broken_cluster); }}
	break;
#line 194 "hb-ot-shape-complex-sea-machine.hh"
	}

_again:
	switch ( _sea_syllable_machine_to_state_actions[cs] ) {
	case 4:
#line 1 "NONE"
	{ts = 0;}
	break;
#line 203 "hb-ot-shape-complex-sea-machine.hh"
	}

	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	if ( p == eof )
	{
	if ( _sea_syllable_machine_eof_trans[cs] > 0 ) {
		_trans = _sea_syllable_machine_eof_trans[cs] - 1;
		goto _eof_trans;
	}
	}

	}

#line 97 "hb-ot-shape-complex-sea-machine.rl"

}

#undef found_syllable

#endif /* HB_OT_SHAPE_COMPLEX_SEA_MACHINE_HH */
