/*
 * Copyright © 2007  Chris Wilson
 * Copyright © 2009,2010  Red Hat, Inc.
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
 * Contributor(s):
 *	Chris Wilson <chris@chris-wilson.co.uk>
 * Red Hat Author(s): Behdad Esfahbod
 * Google Author(s): Behdad Esfahbod
 */

#ifndef HB_OBJECT_PRIVATE_HH
#define HB_OBJECT_PRIVATE_HH

#include "hb-private.hh"

#include "hb-atomic-private.hh"
#include "hb-mutex-private.hh"


/* Debug */

#ifndef HB_DEBUG_OBJECT
#define HB_DEBUG_OBJECT (HB_DEBUG+0)
#endif


/* reference_count */

#define HB_REFERENCE_COUNT_INVALID_VALUE ((hb_atomic_int_t) -1)
#define HB_REFERENCE_COUNT_INVALID {HB_REFERENCE_COUNT_INVALID_VALUE}
struct hb_reference_count_t
{
  hb_atomic_int_t ref_count;

  inline void init (int v) { ref_count = v; }
  inline int inc (void) { return hb_atomic_int_add (const_cast<hb_atomic_int_t &> (ref_count),  1); }
  inline int dec (void) { return hb_atomic_int_add (const_cast<hb_atomic_int_t &> (ref_count), -1); }
  inline void finish (void) { ref_count = HB_REFERENCE_COUNT_INVALID_VALUE; }

  inline bool is_invalid (void) const { return ref_count == HB_REFERENCE_COUNT_INVALID_VALUE; }

};


/* user_data */

#define HB_USER_DATA_ARRAY_INIT {HB_MUTEX_INIT, HB_LOCKABLE_SET_INIT}
struct hb_user_data_array_t
{
  struct hb_user_data_item_t {
    hb_user_data_key_t *key;
    void *data;
    hb_destroy_func_t destroy;

    inline bool operator == (hb_user_data_key_t *other_key) const { return key == other_key; }
    inline bool operator == (hb_user_data_item_t &other) const { return key == other.key; }

    void finish (void) { if (destroy) destroy (data); }
  };

  hb_mutex_t lock;
  hb_lockable_set_t<hb_user_data_item_t, hb_mutex_t> items;

  inline void init (void) { lock.init (); items.init (); }

  HB_INTERNAL bool set (hb_user_data_key_t *key,
			void *              data,
			hb_destroy_func_t   destroy,
			hb_bool_t           replace);

  HB_INTERNAL void *get (hb_user_data_key_t *key);

  inline void finish (void) { items.finish (lock); lock.finish (); }
};


/* object_header */

struct hb_object_header_t
{
  hb_reference_count_t ref_count;
  hb_user_data_array_t user_data;

#define HB_OBJECT_HEADER_STATIC {HB_REFERENCE_COUNT_INVALID, HB_USER_DATA_ARRAY_INIT}

  private:
  ASSERT_POD ();
};


/* object */

template <typename Type>
static inline void hb_object_trace (const Type *obj, const char *function)
{
  DEBUG_MSG (OBJECT, (void *) obj,
	     "%s refcount=%d",
	     function,
	     obj ? obj->header.ref_count.ref_count : 0);
}

template <typename Type>
static inline Type *hb_object_create (void)
{
  Type *obj = (Type *) calloc (1, sizeof (Type));

  if (unlikely (!obj))
    return obj;

  hb_object_init (obj);
  hb_object_trace (obj, HB_FUNC);
  return obj;
}
template <typename Type>
static inline void hb_object_init (Type *obj)
{
  obj->header.ref_count.init (1);
  obj->header.user_data.init ();
}
template <typename Type>
static inline bool hb_object_is_inert (const Type *obj)
{
  return unlikely (obj->header.ref_count.is_invalid ());
}
template <typename Type>
static inline Type *hb_object_reference (Type *obj)
{
  hb_object_trace (obj, HB_FUNC);
  if (unlikely (!obj || hb_object_is_inert (obj)))
    return obj;
  obj->header.ref_count.inc ();
  return obj;
}
template <typename Type>
static inline bool hb_object_destroy (Type *obj)
{
  hb_object_trace (obj, HB_FUNC);
  if (unlikely (!obj || hb_object_is_inert (obj)))
    return false;
  if (obj->header.ref_count.dec () != 1)
    return false;

  obj->header.ref_count.finish (); /* Do this before user_data */
  obj->header.user_data.finish ();
  return true;
}
template <typename Type>
static inline bool hb_object_set_user_data (Type               *obj,
					    hb_user_data_key_t *key,
					    void *              data,
					    hb_destroy_func_t   destroy,
					    hb_bool_t           replace)
{
  if (unlikely (!obj || hb_object_is_inert (obj)))
    return false;
  return obj->header.user_data.set (key, data, destroy, replace);
}

template <typename Type>
static inline void *hb_object_get_user_data (Type               *obj,
					     hb_user_data_key_t *key)
{
  if (unlikely (!obj || hb_object_is_inert (obj)))
    return NULL;
  return obj->header.user_data.get (key);
}


#endif /* HB_OBJECT_PRIVATE_HH */
