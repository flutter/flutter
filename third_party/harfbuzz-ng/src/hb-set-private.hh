/*
 * Copyright © 2012  Google, Inc.
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

#ifndef HB_SET_PRIVATE_HH
#define HB_SET_PRIVATE_HH

#include "hb-private.hh"
#include "hb-object-private.hh"


/*
 * The set digests here implement various "filters" that support
 * "approximate member query".  Conceptually these are like Bloom
 * Filter and Quotient Filter, however, much smaller, faster, and
 * designed to fit the requirements of our uses for glyph coverage
 * queries.  As a result, our filters have much higher.
 */

template <typename mask_t, unsigned int shift>
struct hb_set_digest_lowest_bits_t
{
  ASSERT_POD ();

  static const unsigned int mask_bytes = sizeof (mask_t);
  static const unsigned int mask_bits = sizeof (mask_t) * 8;
  static const unsigned int num_bits = 0
				     + (mask_bytes >= 1 ? 3 : 0)
				     + (mask_bytes >= 2 ? 1 : 0)
				     + (mask_bytes >= 4 ? 1 : 0)
				     + (mask_bytes >= 8 ? 1 : 0)
				     + (mask_bytes >= 16? 1 : 0)
				     + 0;

  ASSERT_STATIC (shift < sizeof (hb_codepoint_t) * 8);
  ASSERT_STATIC (shift + num_bits <= sizeof (hb_codepoint_t) * 8);

  inline void init (void) {
    mask = 0;
  }

  inline void add (hb_codepoint_t g) {
    mask |= mask_for (g);
  }

  inline void add_range (hb_codepoint_t a, hb_codepoint_t b) {
    if ((b >> shift) - (a >> shift) >= mask_bits - 1)
      mask = (mask_t) -1;
    else {
      mask_t ma = mask_for (a);
      mask_t mb = mask_for (b);
      mask |= mb + (mb - ma) - (mb < ma);
    }
  }

  inline bool may_have (hb_codepoint_t g) const {
    return !!(mask & mask_for (g));
  }

  private:

  static inline mask_t mask_for (hb_codepoint_t g) {
    return ((mask_t) 1) << ((g >> shift) & (mask_bits - 1));
  }
  mask_t mask;
};

template <typename head_t, typename tail_t>
struct hb_set_digest_combiner_t
{
  ASSERT_POD ();

  inline void init (void) {
    head.init ();
    tail.init ();
  }

  inline void add (hb_codepoint_t g) {
    head.add (g);
    tail.add (g);
  }

  inline void add_range (hb_codepoint_t a, hb_codepoint_t b) {
    head.add_range (a, b);
    tail.add_range (a, b);
  }

  inline bool may_have (hb_codepoint_t g) const {
    return head.may_have (g) && tail.may_have (g);
  }

  private:
  head_t head;
  tail_t tail;
};


/*
 * hb_set_digest_t
 *
 * This is a combination of digests that performs "best".
 * There is not much science to this: it's a result of intuition
 * and testing.
 */
typedef hb_set_digest_combiner_t
<
  hb_set_digest_lowest_bits_t<unsigned long, 4>,
  hb_set_digest_combiner_t
  <
    hb_set_digest_lowest_bits_t<unsigned long, 0>,
    hb_set_digest_lowest_bits_t<unsigned long, 9>
  >
> hb_set_digest_t;



/*
 * hb_set_t
 */


/* TODO Make this faster and memmory efficient. */

struct hb_set_t
{
  friend struct hb_frozen_set_t;

  hb_object_header_t header;
  ASSERT_POD ();
  bool in_error;

  inline void init (void) {
    hb_object_init (this);
    clear ();
  }
  inline void fini (void) {
  }
  inline void clear (void) {
    if (unlikely (hb_object_is_inert (this)))
      return;
    in_error = false;
    memset (elts, 0, sizeof elts);
  }
  inline bool is_empty (void) const {
    for (unsigned int i = 0; i < ARRAY_LENGTH (elts); i++)
      if (elts[i])
        return false;
    return true;
  }
  inline void add (hb_codepoint_t g)
  {
    if (unlikely (in_error)) return;
    if (unlikely (g == INVALID)) return;
    if (unlikely (g > MAX_G)) return;
    elt (g) |= mask (g);
  }
  inline void add_range (hb_codepoint_t a, hb_codepoint_t b)
  {
    if (unlikely (in_error)) return;
    /* TODO Speedup */
    for (unsigned int i = a; i < b + 1; i++)
      add (i);
  }
  inline void del (hb_codepoint_t g)
  {
    if (unlikely (in_error)) return;
    if (unlikely (g > MAX_G)) return;
    elt (g) &= ~mask (g);
  }
  inline void del_range (hb_codepoint_t a, hb_codepoint_t b)
  {
    if (unlikely (in_error)) return;
    /* TODO Speedup */
    for (unsigned int i = a; i < b + 1; i++)
      del (i);
  }
  inline bool has (hb_codepoint_t g) const
  {
    if (unlikely (g > MAX_G)) return false;
    return !!(elt (g) & mask (g));
  }
  inline bool intersects (hb_codepoint_t first,
			  hb_codepoint_t last) const
  {
    if (unlikely (first > MAX_G)) return false;
    if (unlikely (last  > MAX_G)) last = MAX_G;
    unsigned int end = last + 1;
    for (hb_codepoint_t i = first; i < end; i++)
      if (has (i))
        return true;
    return false;
  }
  inline bool is_equal (const hb_set_t *other) const
  {
    for (unsigned int i = 0; i < ELTS; i++)
      if (elts[i] != other->elts[i])
        return false;
    return true;
  }
  inline void set (const hb_set_t *other)
  {
    if (unlikely (in_error)) return;
    for (unsigned int i = 0; i < ELTS; i++)
      elts[i] = other->elts[i];
  }
  inline void union_ (const hb_set_t *other)
  {
    if (unlikely (in_error)) return;
    for (unsigned int i = 0; i < ELTS; i++)
      elts[i] |= other->elts[i];
  }
  inline void intersect (const hb_set_t *other)
  {
    if (unlikely (in_error)) return;
    for (unsigned int i = 0; i < ELTS; i++)
      elts[i] &= other->elts[i];
  }
  inline void subtract (const hb_set_t *other)
  {
    if (unlikely (in_error)) return;
    for (unsigned int i = 0; i < ELTS; i++)
      elts[i] &= ~other->elts[i];
  }
  inline void symmetric_difference (const hb_set_t *other)
  {
    if (unlikely (in_error)) return;
    for (unsigned int i = 0; i < ELTS; i++)
      elts[i] ^= other->elts[i];
  }
  inline void invert (void)
  {
    if (unlikely (in_error)) return;
    for (unsigned int i = 0; i < ELTS; i++)
      elts[i] = ~elts[i];
  }
  inline bool next (hb_codepoint_t *codepoint) const
  {
    if (unlikely (*codepoint == INVALID)) {
      hb_codepoint_t i = get_min ();
      if (i != INVALID) {
        *codepoint = i;
	return true;
      } else {
	*codepoint = INVALID;
        return false;
      }
    }
    for (hb_codepoint_t i = *codepoint + 1; i < MAX_G + 1; i++)
      if (has (i)) {
        *codepoint = i;
	return true;
      }
    *codepoint = INVALID;
    return false;
  }
  inline bool next_range (hb_codepoint_t *first, hb_codepoint_t *last) const
  {
    hb_codepoint_t i;

    i = *last;
    if (!next (&i))
    {
      *last = *first = INVALID;
      return false;
    }

    *last = *first = i;
    while (next (&i) && i == *last + 1)
      (*last)++;

    return true;
  }

  inline unsigned int get_population (void) const
  {
    unsigned int count = 0;
    for (unsigned int i = 0; i < ELTS; i++)
      count += _hb_popcount32 (elts[i]);
    return count;
  }
  inline hb_codepoint_t get_min (void) const
  {
    for (unsigned int i = 0; i < ELTS; i++)
      if (elts[i])
	for (unsigned int j = 0; j < BITS; j++)
	  if (elts[i] & (1 << j))
	    return i * BITS + j;
    return INVALID;
  }
  inline hb_codepoint_t get_max (void) const
  {
    for (unsigned int i = ELTS; i; i--)
      if (elts[i - 1])
	for (unsigned int j = BITS; j; j--)
	  if (elts[i - 1] & (1 << (j - 1)))
	    return (i - 1) * BITS + (j - 1);
    return INVALID;
  }

  typedef uint32_t elt_t;
  static const unsigned int MAX_G = 65536 - 1; /* XXX Fix this... */
  static const unsigned int SHIFT = 5;
  static const unsigned int BITS = (1 << SHIFT);
  static const unsigned int MASK = BITS - 1;
  static const unsigned int ELTS = (MAX_G + 1 + (BITS - 1)) / BITS;
  static  const hb_codepoint_t INVALID = HB_SET_VALUE_INVALID;

  elt_t &elt (hb_codepoint_t g) { return elts[g >> SHIFT]; }
  elt_t const &elt (hb_codepoint_t g) const { return elts[g >> SHIFT]; }
  elt_t mask (hb_codepoint_t g) const { return elt_t (1) << (g & MASK); }

  elt_t elts[ELTS]; /* XXX 8kb */

  ASSERT_STATIC (sizeof (elt_t) * 8 == BITS);
  ASSERT_STATIC (sizeof (elt_t) * 8 * ELTS > MAX_G);
};

struct hb_frozen_set_t
{
  static const unsigned int SHIFT = hb_set_t::SHIFT;
  static const unsigned int BITS = hb_set_t::BITS;
  static const unsigned int MASK = hb_set_t::MASK;
  typedef hb_set_t::elt_t elt_t;

  inline void init (const hb_set_t &set)
  {
    start = count = 0;
    elts = NULL;

    unsigned int max = set.get_max ();
    if (max == set.INVALID)
      return;
    unsigned int min = set.get_min ();
    const elt_t &min_elt = set.elt (min);
    const elt_t &max_elt = set.elt (max);

    start = min & ~MASK;
    count = max - start + 1;
    unsigned int num_elts = (count + BITS - 1) / BITS;
    unsigned int elts_size = num_elts * sizeof (elt_t);
    elts = (elt_t *) malloc (elts_size);
    if (unlikely (!elts))
    {
      start = count = 0;
      return;
    }
    memcpy (elts, &min_elt, elts_size);
  }

  inline void fini (void)
  {
    if (elts)
      free (elts);
  }

  inline bool has (hb_codepoint_t g) const
  {
    /* hb_codepoint_t is unsigned. */
    g -= start;
    if (unlikely (g > count)) return false;
    return !!(elt (g) & mask (g));
  }

  elt_t const &elt (hb_codepoint_t g) const { return elts[g >> SHIFT]; }
  elt_t mask (hb_codepoint_t g) const { return elt_t (1) << (g & MASK); }

  private:
  hb_codepoint_t start, count;
  elt_t *elts;
};


#endif /* HB_SET_PRIVATE_HH */
