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

#ifndef HB_CACHE_PRIVATE_HH
#define HB_CACHE_PRIVATE_HH

#include "hb-private.hh"


/* Implements a lock-free cache for int->int functions. */

template <unsigned int key_bits, unsigned int value_bits, unsigned int cache_bits>
struct hb_cache_t
{
  ASSERT_STATIC (key_bits >= cache_bits);
  ASSERT_STATIC (key_bits + value_bits - cache_bits < 8 * sizeof (unsigned int));

  inline void clear (void)
  {
    memset (values, 255, sizeof (values));
  }

  inline bool get (unsigned int key, unsigned int *value)
  {
    unsigned int k = key & ((1<<cache_bits)-1);
    unsigned int v = values[k];
    if ((v >> value_bits) != (key >> cache_bits))
      return false;
    *value = v & ((1<<value_bits)-1);
    return true;
  }

  inline bool set (unsigned int key, unsigned int value)
  {
    if (unlikely ((key >> key_bits) || (value >> value_bits)))
      return false; /* Overflows */
    unsigned int k = key & ((1<<cache_bits)-1);
    unsigned int v = ((key>>cache_bits)<<value_bits) | value;
    values[k] = v;
    return true;
  }

  private:
  unsigned int values[1<<cache_bits];
};

typedef hb_cache_t<21, 16, 8> hb_cmap_cache_t;
typedef hb_cache_t<16, 24, 8> hb_advance_cache_t;


#endif /* HB_CACHE_PRIVATE_HH */
