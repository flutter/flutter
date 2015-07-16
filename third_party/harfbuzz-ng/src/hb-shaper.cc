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

#include "hb-private.hh"
#include "hb-shaper-private.hh"
#include "hb-atomic-private.hh"


static const hb_shaper_pair_t all_shapers[] = {
#define HB_SHAPER_IMPLEMENT(name) {#name, _hb_##name##_shape},
#include "hb-shaper-list.hh"
#undef HB_SHAPER_IMPLEMENT
};


/* Thread-safe, lock-free, shapers */

static const hb_shaper_pair_t *static_shapers;

#ifdef HB_USE_ATEXIT
static
void free_static_shapers (void)
{
  if (unlikely (static_shapers != all_shapers))
    free ((void *) static_shapers);
}
#endif

const hb_shaper_pair_t *
_hb_shapers_get (void)
{
retry:
  hb_shaper_pair_t *shapers = (hb_shaper_pair_t *) hb_atomic_ptr_get (&static_shapers);

  if (unlikely (!shapers))
  {
    char *env = getenv ("HB_SHAPER_LIST");
    if (!env || !*env) {
      (void) hb_atomic_ptr_cmpexch (&static_shapers, NULL, &all_shapers[0]);
      return (const hb_shaper_pair_t *) all_shapers;
    }

    /* Not found; allocate one. */
    shapers = (hb_shaper_pair_t *) malloc (sizeof (all_shapers));
    if (unlikely (!shapers)) {
      (void) hb_atomic_ptr_cmpexch (&static_shapers, NULL, &all_shapers[0]);
      return (const hb_shaper_pair_t *) all_shapers;
    }

    memcpy (shapers, all_shapers, sizeof (all_shapers));

     /* Reorder shaper list to prefer requested shapers. */
    unsigned int i = 0;
    char *end, *p = env;
    for (;;) {
      end = strchr (p, ',');
      if (!end)
	end = p + strlen (p);

      for (unsigned int j = i; j < ARRAY_LENGTH (all_shapers); j++)
	if (end - p == (int) strlen (shapers[j].name) &&
	    0 == strncmp (shapers[j].name, p, end - p))
	{
	  /* Reorder this shaper to position i */
	 struct hb_shaper_pair_t t = shapers[j];
	 memmove (&shapers[i + 1], &shapers[i], sizeof (shapers[i]) * (j - i));
	 shapers[i] = t;
	 i++;
	}

      if (!*end)
	break;
      else
	p = end + 1;
    }

    if (!hb_atomic_ptr_cmpexch (&static_shapers, NULL, shapers)) {
      free (shapers);
      goto retry;
    }

#ifdef HB_USE_ATEXIT
    atexit (free_static_shapers); /* First person registers atexit() callback. */
#endif
  }

  return shapers;
}
