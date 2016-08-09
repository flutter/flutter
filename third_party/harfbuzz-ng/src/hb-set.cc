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

#include "hb-set-private.hh"


/* Public API */


/**
 * hb_set_create: (Xconstructor)
 *
 * Return value: (transfer full):
 *
 * Since: 1.0
 **/
hb_set_t *
hb_set_create (void)
{
  hb_set_t *set;

  if (!(set = hb_object_create<hb_set_t> ()))
    return hb_set_get_empty ();

  set->clear ();

  return set;
}

/**
 * hb_set_get_empty:
 *
 * Return value: (transfer full):
 *
 * Since: 1.0
 **/
hb_set_t *
hb_set_get_empty (void)
{
  static const hb_set_t _hb_set_nil = {
    HB_OBJECT_HEADER_STATIC,
    true, /* in_error */

    {0} /* elts */
  };

  return const_cast<hb_set_t *> (&_hb_set_nil);
}

/**
 * hb_set_reference: (skip)
 * @set: a set.
 *
 * Return value: (transfer full):
 *
 * Since: 1.0
 **/
hb_set_t *
hb_set_reference (hb_set_t *set)
{
  return hb_object_reference (set);
}

/**
 * hb_set_destroy: (skip)
 * @set: a set.
 *
 * Since: 1.0
 **/
void
hb_set_destroy (hb_set_t *set)
{
  if (!hb_object_destroy (set)) return;

  set->fini ();

  free (set);
}

/**
 * hb_set_set_user_data: (skip)
 * @set: a set.
 * @key:
 * @data:
 * @destroy (closure data):
 * @replace:
 *
 * Return value:
 *
 * Since: 1.0
 **/
hb_bool_t
hb_set_set_user_data (hb_set_t           *set,
		      hb_user_data_key_t *key,
		      void *              data,
		      hb_destroy_func_t   destroy,
		      hb_bool_t           replace)
{
  return hb_object_set_user_data (set, key, data, destroy, replace);
}

/**
 * hb_set_get_user_data: (skip)
 * @set: a set.
 * @key:
 *
 * Return value: (transfer none):
 *
 * Since: 1.0
 **/
void *
hb_set_get_user_data (hb_set_t           *set,
		      hb_user_data_key_t *key)
{
  return hb_object_get_user_data (set, key);
}


/**
 * hb_set_allocation_successful:
 * @set: a set.
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_bool_t
hb_set_allocation_successful (const hb_set_t  *set HB_UNUSED)
{
  return !set->in_error;
}

/**
 * hb_set_clear:
 * @set: a set.
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_set_clear (hb_set_t *set)
{
  set->clear ();
}

/**
 * hb_set_is_empty:
 * @set: a set.
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_bool_t
hb_set_is_empty (const hb_set_t *set)
{
  return set->is_empty ();
}

/**
 * hb_set_has:
 * @set: a set.
 * @codepoint: 
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_bool_t
hb_set_has (const hb_set_t *set,
	    hb_codepoint_t  codepoint)
{
  return set->has (codepoint);
}

/**
 * hb_set_add:
 * @set: a set.
 * @codepoint: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_set_add (hb_set_t       *set,
	    hb_codepoint_t  codepoint)
{
  set->add (codepoint);
}

/**
 * hb_set_add_range:
 * @set: a set.
 * @first: 
 * @last: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_set_add_range (hb_set_t       *set,
		  hb_codepoint_t  first,
		  hb_codepoint_t  last)
{
  set->add_range (first, last);
}

/**
 * hb_set_del:
 * @set: a set.
 * @codepoint: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_set_del (hb_set_t       *set,
	    hb_codepoint_t  codepoint)
{
  set->del (codepoint);
}

/**
 * hb_set_del_range:
 * @set: a set.
 * @first: 
 * @last: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_set_del_range (hb_set_t       *set,
		  hb_codepoint_t  first,
		  hb_codepoint_t  last)
{
  set->del_range (first, last);
}

/**
 * hb_set_is_equal:
 * @set: a set.
 * @other: 
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_bool_t
hb_set_is_equal (const hb_set_t *set,
		 const hb_set_t *other)
{
  return set->is_equal (other);
}

/**
 * hb_set_set:
 * @set: a set.
 * @other: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_set_set (hb_set_t       *set,
	    const hb_set_t *other)
{
  set->set (other);
}

/**
 * hb_set_union:
 * @set: a set.
 * @other: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_set_union (hb_set_t       *set,
	      const hb_set_t *other)
{
  set->union_ (other);
}

/**
 * hb_set_intersect:
 * @set: a set.
 * @other: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_set_intersect (hb_set_t       *set,
		  const hb_set_t *other)
{
  set->intersect (other);
}

/**
 * hb_set_subtract:
 * @set: a set.
 * @other: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_set_subtract (hb_set_t       *set,
		 const hb_set_t *other)
{
  set->subtract (other);
}

/**
 * hb_set_symmetric_difference:
 * @set: a set.
 * @other: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_set_symmetric_difference (hb_set_t       *set,
			     const hb_set_t *other)
{
  set->symmetric_difference (other);
}

/**
 * hb_set_invert:
 * @set: a set.
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_set_invert (hb_set_t *set)
{
  set->invert ();
}

/**
 * hb_set_get_population:
 * @set: a set.
 *
 * Returns the number of numbers in the set.
 *
 * Return value: set population.
 *
 * Since: 1.0
 **/
unsigned int
hb_set_get_population (const hb_set_t *set)
{
  return set->get_population ();
}

/**
 * hb_set_get_min:
 * @set: a set.
 *
 * Finds the minimum number in the set.
 *
 * Return value: minimum of the set, or %HB_SET_VALUE_INVALID if set is empty.
 *
 * Since: 1.0
 **/
hb_codepoint_t
hb_set_get_min (const hb_set_t *set)
{
  return set->get_min ();
}

/**
 * hb_set_get_max:
 * @set: a set.
 *
 * Finds the maximum number in the set.
 *
 * Return value: minimum of the set, or %HB_SET_VALUE_INVALID if set is empty.
 *
 * Since: 1.0
 **/
hb_codepoint_t
hb_set_get_max (const hb_set_t *set)
{
  return set->get_max ();
}

/**
 * hb_set_next:
 * @set: a set.
 * @codepoint: (inout):
 *
 * 
 *
 * Return value: whether there was a next value.
 *
 * Since: 1.0
 **/
hb_bool_t
hb_set_next (const hb_set_t *set,
	     hb_codepoint_t *codepoint)
{
  return set->next (codepoint);
}

/**
 * hb_set_next_range:
 * @set: a set.
 * @first: (out): output first codepoint in the range.
 * @last: (inout): input current last and output last codepoint in the range.
 *
 * Gets the next consecutive range of numbers in @set that
 * are greater than current value of @last.
 *
 * Return value: whether there was a next range.
 *
 * Since: 1.0
 **/
hb_bool_t
hb_set_next_range (const hb_set_t *set,
		   hb_codepoint_t *first,
		   hb_codepoint_t *last)
{
  return set->next_range (first, last);
}
