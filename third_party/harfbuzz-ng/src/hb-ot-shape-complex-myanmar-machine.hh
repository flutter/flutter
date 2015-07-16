
#line 1 "hb-ot-shape-complex-myanmar-machine.rl"
/*
 * Copyright © 2011,2012  Google, Inc.
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

#ifndef HB_OT_SHAPE_COMPLEX_MYANMAR_MACHINE_HH
#define HB_OT_SHAPE_COMPLEX_MYANMAR_MACHINE_HH

#include "hb-private.hh"


#line 36 "hb-ot-shape-complex-myanmar-machine.hh"
static const unsigned char _myanmar_syllable_machine_trans_keys[] = {
	1u, 31u, 3u, 30u, 5u, 29u, 5u, 8u, 5u, 29u, 3u, 25u, 5u, 25u, 5u, 25u, 
	3u, 29u, 3u, 29u, 3u, 29u, 3u, 29u, 1u, 16u, 3u, 29u, 3u, 29u, 3u, 29u, 
	3u, 29u, 3u, 29u, 3u, 29u, 3u, 29u, 3u, 29u, 3u, 29u, 5u, 29u, 5u, 8u, 
	5u, 29u, 3u, 25u, 5u, 25u, 5u, 25u, 3u, 29u, 3u, 29u, 3u, 29u, 3u, 29u, 
	3u, 30u, 3u, 29u, 1u, 30u, 3u, 29u, 3u, 29u, 3u, 29u, 3u, 29u, 3u, 29u, 
	3u, 29u, 3u, 29u, 3u, 29u, 3u, 29u, 8u, 8u, 0
};

static const char _myanmar_syllable_machine_key_spans[] = {
	31, 28, 25, 4, 25, 23, 21, 21, 
	27, 27, 27, 27, 16, 27, 27, 27, 
	27, 27, 27, 27, 27, 27, 25, 4, 
	25, 23, 21, 21, 27, 27, 27, 27, 
	28, 27, 30, 27, 27, 27, 27, 27, 
	27, 27, 27, 27, 1
};

static const short _myanmar_syllable_machine_index_offsets[] = {
	0, 32, 61, 87, 92, 118, 142, 164, 
	186, 214, 242, 270, 298, 315, 343, 371, 
	399, 427, 455, 483, 511, 539, 567, 593, 
	598, 624, 648, 670, 692, 720, 748, 776, 
	804, 833, 861, 892, 920, 948, 976, 1004, 
	1032, 1060, 1088, 1116, 1144
};

static const char _myanmar_syllable_machine_indicies[] = {
	1, 1, 2, 3, 4, 4, 0, 5, 
	0, 6, 1, 0, 0, 0, 0, 7, 
	0, 8, 1, 0, 9, 10, 11, 12, 
	13, 14, 15, 16, 17, 18, 19, 0, 
	21, 22, 23, 23, 20, 24, 20, 25, 
	20, 20, 20, 20, 20, 20, 20, 26, 
	20, 20, 27, 28, 29, 30, 31, 32, 
	33, 34, 35, 36, 20, 23, 23, 20, 
	24, 20, 20, 20, 20, 20, 20, 20, 
	20, 20, 37, 20, 20, 20, 20, 20, 
	20, 31, 20, 20, 20, 35, 20, 23, 
	23, 20, 24, 20, 23, 23, 20, 24, 
	20, 20, 20, 20, 20, 20, 20, 20, 
	20, 20, 20, 20, 20, 20, 20, 20, 
	31, 20, 20, 20, 35, 20, 38, 20, 
	23, 23, 20, 24, 20, 31, 20, 20, 
	20, 20, 20, 20, 20, 39, 20, 20, 
	20, 20, 20, 20, 31, 20, 23, 23, 
	20, 24, 20, 20, 20, 20, 20, 20, 
	20, 20, 20, 39, 20, 20, 20, 20, 
	20, 20, 31, 20, 23, 23, 20, 24, 
	20, 20, 20, 20, 20, 20, 20, 20, 
	20, 20, 20, 20, 20, 20, 20, 20, 
	31, 20, 21, 20, 23, 23, 20, 24, 
	20, 25, 20, 20, 20, 20, 20, 20, 
	20, 40, 20, 20, 40, 20, 20, 20, 
	31, 41, 20, 20, 35, 20, 21, 20, 
	23, 23, 20, 24, 20, 25, 20, 20, 
	20, 20, 20, 20, 20, 20, 20, 20, 
	20, 20, 20, 20, 31, 20, 20, 20, 
	35, 20, 21, 20, 23, 23, 20, 24, 
	20, 25, 20, 20, 20, 20, 20, 20, 
	20, 40, 20, 20, 20, 20, 20, 20, 
	31, 41, 20, 20, 35, 20, 21, 20, 
	23, 23, 20, 24, 20, 25, 20, 20, 
	20, 20, 20, 20, 20, 20, 20, 20, 
	20, 20, 20, 20, 31, 41, 20, 20, 
	35, 20, 1, 1, 20, 20, 20, 20, 
	20, 20, 20, 20, 20, 20, 20, 20, 
	20, 1, 20, 21, 20, 23, 23, 20, 
	24, 20, 25, 20, 20, 20, 20, 20, 
	20, 20, 26, 20, 20, 27, 28, 29, 
	30, 31, 32, 33, 34, 35, 20, 21, 
	20, 23, 23, 20, 24, 20, 25, 20, 
	20, 20, 20, 20, 20, 20, 34, 20, 
	20, 20, 20, 20, 20, 31, 32, 33, 
	34, 35, 20, 21, 20, 23, 23, 20, 
	24, 20, 25, 20, 20, 20, 20, 20, 
	20, 20, 20, 20, 20, 20, 20, 20, 
	20, 31, 32, 33, 34, 35, 20, 21, 
	20, 23, 23, 20, 24, 20, 25, 20, 
	20, 20, 20, 20, 20, 20, 20, 20, 
	20, 20, 20, 20, 20, 31, 32, 33, 
	20, 35, 20, 21, 20, 23, 23, 20, 
	24, 20, 25, 20, 20, 20, 20, 20, 
	20, 20, 20, 20, 20, 20, 20, 20, 
	20, 31, 20, 33, 20, 35, 20, 21, 
	20, 23, 23, 20, 24, 20, 25, 20, 
	20, 20, 20, 20, 20, 20, 34, 20, 
	20, 27, 20, 29, 20, 31, 32, 33, 
	34, 35, 20, 21, 20, 23, 23, 20, 
	24, 20, 25, 20, 20, 20, 20, 20, 
	20, 20, 34, 20, 20, 27, 20, 20, 
	20, 31, 32, 33, 34, 35, 20, 21, 
	20, 23, 23, 20, 24, 20, 25, 20, 
	20, 20, 20, 20, 20, 20, 34, 20, 
	20, 27, 28, 29, 20, 31, 32, 33, 
	34, 35, 20, 21, 22, 23, 23, 20, 
	24, 20, 25, 20, 20, 20, 20, 20, 
	20, 20, 26, 20, 20, 27, 28, 29, 
	30, 31, 32, 33, 34, 35, 20, 3, 
	3, 42, 5, 42, 42, 42, 42, 42, 
	42, 42, 42, 42, 43, 42, 42, 42, 
	42, 42, 42, 13, 42, 42, 42, 17, 
	42, 3, 3, 42, 5, 42, 3, 3, 
	42, 5, 42, 42, 42, 42, 42, 42, 
	42, 42, 42, 42, 42, 42, 42, 42, 
	42, 42, 13, 42, 42, 42, 17, 42, 
	44, 42, 3, 3, 42, 5, 42, 13, 
	42, 42, 42, 42, 42, 42, 42, 45, 
	42, 42, 42, 42, 42, 42, 13, 42, 
	3, 3, 42, 5, 42, 42, 42, 42, 
	42, 42, 42, 42, 42, 45, 42, 42, 
	42, 42, 42, 42, 13, 42, 3, 3, 
	42, 5, 42, 42, 42, 42, 42, 42, 
	42, 42, 42, 42, 42, 42, 42, 42, 
	42, 42, 13, 42, 2, 42, 3, 3, 
	42, 5, 42, 6, 42, 42, 42, 42, 
	42, 42, 42, 46, 42, 42, 46, 42, 
	42, 42, 13, 47, 42, 42, 17, 42, 
	2, 42, 3, 3, 42, 5, 42, 6, 
	42, 42, 42, 42, 42, 42, 42, 42, 
	42, 42, 42, 42, 42, 42, 13, 42, 
	42, 42, 17, 42, 2, 42, 3, 3, 
	42, 5, 42, 6, 42, 42, 42, 42, 
	42, 42, 42, 46, 42, 42, 42, 42, 
	42, 42, 13, 47, 42, 42, 17, 42, 
	2, 42, 3, 3, 42, 5, 42, 6, 
	42, 42, 42, 42, 42, 42, 42, 42, 
	42, 42, 42, 42, 42, 42, 13, 47, 
	42, 42, 17, 42, 21, 22, 23, 23, 
	20, 24, 20, 25, 20, 20, 20, 20, 
	20, 20, 20, 48, 20, 20, 27, 28, 
	29, 30, 31, 32, 33, 34, 35, 36, 
	20, 21, 49, 23, 23, 20, 24, 20, 
	25, 20, 20, 20, 20, 20, 20, 20, 
	26, 20, 20, 27, 28, 29, 30, 31, 
	32, 33, 34, 35, 20, 1, 1, 2, 
	3, 3, 3, 42, 5, 42, 6, 1, 
	42, 42, 42, 42, 1, 42, 8, 1, 
	42, 9, 10, 11, 12, 13, 14, 15, 
	16, 17, 18, 42, 2, 42, 3, 3, 
	42, 5, 42, 6, 42, 42, 42, 42, 
	42, 42, 42, 8, 42, 42, 9, 10, 
	11, 12, 13, 14, 15, 16, 17, 42, 
	2, 42, 3, 3, 42, 5, 42, 6, 
	42, 42, 42, 42, 42, 42, 42, 16, 
	42, 42, 42, 42, 42, 42, 13, 14, 
	15, 16, 17, 42, 2, 42, 3, 3, 
	42, 5, 42, 6, 42, 42, 42, 42, 
	42, 42, 42, 42, 42, 42, 42, 42, 
	42, 42, 13, 14, 15, 16, 17, 42, 
	2, 42, 3, 3, 42, 5, 42, 6, 
	42, 42, 42, 42, 42, 42, 42, 42, 
	42, 42, 42, 42, 42, 42, 13, 14, 
	15, 42, 17, 42, 2, 42, 3, 3, 
	42, 5, 42, 6, 42, 42, 42, 42, 
	42, 42, 42, 42, 42, 42, 42, 42, 
	42, 42, 13, 42, 15, 42, 17, 42, 
	2, 42, 3, 3, 42, 5, 42, 6, 
	42, 42, 42, 42, 42, 42, 42, 16, 
	42, 42, 9, 42, 11, 42, 13, 14, 
	15, 16, 17, 42, 2, 42, 3, 3, 
	42, 5, 42, 6, 42, 42, 42, 42, 
	42, 42, 42, 16, 42, 42, 9, 42, 
	42, 42, 13, 14, 15, 16, 17, 42, 
	2, 42, 3, 3, 42, 5, 42, 6, 
	42, 42, 42, 42, 42, 42, 42, 16, 
	42, 42, 9, 10, 11, 42, 13, 14, 
	15, 16, 17, 42, 2, 3, 3, 3, 
	42, 5, 42, 6, 42, 42, 42, 42, 
	42, 42, 42, 8, 42, 42, 9, 10, 
	11, 12, 13, 14, 15, 16, 17, 42, 
	51, 50, 0
};

static const char _myanmar_syllable_machine_trans_targs[] = {
	0, 1, 22, 0, 0, 23, 29, 32, 
	35, 36, 40, 41, 42, 25, 38, 39, 
	37, 28, 43, 44, 0, 2, 12, 0, 
	3, 9, 13, 14, 18, 19, 20, 5, 
	16, 17, 15, 8, 21, 4, 6, 7, 
	10, 11, 0, 24, 26, 27, 30, 31, 
	33, 34, 0, 0
};

static const char _myanmar_syllable_machine_trans_actions[] = {
	3, 0, 0, 4, 5, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 6, 0, 0, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 8, 0, 0, 0, 0, 0, 
	0, 0, 9, 10
};

static const char _myanmar_syllable_machine_to_state_actions[] = {
	1, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0
};

static const char _myanmar_syllable_machine_from_state_actions[] = {
	2, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0
};

static const short _myanmar_syllable_machine_eof_trans[] = {
	0, 21, 21, 21, 21, 21, 21, 21, 
	21, 21, 21, 21, 21, 21, 21, 21, 
	21, 21, 21, 21, 21, 21, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	21, 21, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 51
};

static const int myanmar_syllable_machine_start = 0;
static const int myanmar_syllable_machine_first_final = 0;
static const int myanmar_syllable_machine_error = -1;

static const int myanmar_syllable_machine_en_main = 0;


#line 36 "hb-ot-shape-complex-myanmar-machine.rl"



#line 93 "hb-ot-shape-complex-myanmar-machine.rl"


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
  
#line 289 "hb-ot-shape-complex-myanmar-machine.hh"
	{
	cs = myanmar_syllable_machine_start;
	ts = 0;
	te = 0;
	act = 0;
	}

#line 114 "hb-ot-shape-complex-myanmar-machine.rl"


  p = 0;
  pe = eof = buffer->len;

  unsigned int last = 0;
  unsigned int syllable_serial = 1;
  
#line 306 "hb-ot-shape-complex-myanmar-machine.hh"
	{
	int _slen;
	int _trans;
	const unsigned char *_keys;
	const char *_inds;
	if ( p == pe )
		goto _test_eof;
_resume:
	switch ( _myanmar_syllable_machine_from_state_actions[cs] ) {
	case 2:
#line 1 "NONE"
	{ts = p;}
	break;
#line 320 "hb-ot-shape-complex-myanmar-machine.hh"
	}

	_keys = _myanmar_syllable_machine_trans_keys + (cs<<1);
	_inds = _myanmar_syllable_machine_indicies + _myanmar_syllable_machine_index_offsets[cs];

	_slen = _myanmar_syllable_machine_key_spans[cs];
	_trans = _inds[ _slen > 0 && _keys[0] <=( info[p].myanmar_category()) &&
		( info[p].myanmar_category()) <= _keys[1] ?
		( info[p].myanmar_category()) - _keys[0] : _slen ];

_eof_trans:
	cs = _myanmar_syllable_machine_trans_targs[_trans];

	if ( _myanmar_syllable_machine_trans_actions[_trans] == 0 )
		goto _again;

	switch ( _myanmar_syllable_machine_trans_actions[_trans] ) {
	case 7:
#line 85 "hb-ot-shape-complex-myanmar-machine.rl"
	{te = p+1;{ found_syllable (consonant_syllable); }}
	break;
	case 5:
#line 86 "hb-ot-shape-complex-myanmar-machine.rl"
	{te = p+1;{ found_syllable (non_myanmar_cluster); }}
	break;
	case 10:
#line 87 "hb-ot-shape-complex-myanmar-machine.rl"
	{te = p+1;{ found_syllable (punctuation_cluster); }}
	break;
	case 4:
#line 88 "hb-ot-shape-complex-myanmar-machine.rl"
	{te = p+1;{ found_syllable (broken_cluster); }}
	break;
	case 3:
#line 89 "hb-ot-shape-complex-myanmar-machine.rl"
	{te = p+1;{ found_syllable (non_myanmar_cluster); }}
	break;
	case 6:
#line 85 "hb-ot-shape-complex-myanmar-machine.rl"
	{te = p;p--;{ found_syllable (consonant_syllable); }}
	break;
	case 8:
#line 88 "hb-ot-shape-complex-myanmar-machine.rl"
	{te = p;p--;{ found_syllable (broken_cluster); }}
	break;
	case 9:
#line 89 "hb-ot-shape-complex-myanmar-machine.rl"
	{te = p;p--;{ found_syllable (non_myanmar_cluster); }}
	break;
#line 370 "hb-ot-shape-complex-myanmar-machine.hh"
	}

_again:
	switch ( _myanmar_syllable_machine_to_state_actions[cs] ) {
	case 1:
#line 1 "NONE"
	{ts = 0;}
	break;
#line 379 "hb-ot-shape-complex-myanmar-machine.hh"
	}

	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	if ( p == eof )
	{
	if ( _myanmar_syllable_machine_eof_trans[cs] > 0 ) {
		_trans = _myanmar_syllable_machine_eof_trans[cs] - 1;
		goto _eof_trans;
	}
	}

	}

#line 123 "hb-ot-shape-complex-myanmar-machine.rl"

}

#undef found_syllable

#endif /* HB_OT_SHAPE_COMPLEX_MYANMAR_MACHINE_HH */
