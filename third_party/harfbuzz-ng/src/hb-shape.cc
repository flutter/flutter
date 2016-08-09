/*
 * Copyright © 2009  Red Hat, Inc.
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
 * Red Hat Author(s): Behdad Esfahbod
 * Google Author(s): Behdad Esfahbod
 */

#include "hb-private.hh"

#include "hb-shaper-private.hh"
#include "hb-shape-plan-private.hh"
#include "hb-buffer-private.hh"
#include "hb-font-private.hh"


static bool
parse_space (const char **pp, const char *end)
{
  while (*pp < end && ISSPACE (**pp))
    (*pp)++;
  return true;
}

static bool
parse_char (const char **pp, const char *end, char c)
{
  parse_space (pp, end);

  if (*pp == end || **pp != c)
    return false;

  (*pp)++;
  return true;
}

static bool
parse_uint (const char **pp, const char *end, unsigned int *pv)
{
  char buf[32];
  unsigned int len = MIN (ARRAY_LENGTH (buf) - 1, (unsigned int) (end - *pp));
  strncpy (buf, *pp, len);
  buf[len] = '\0';

  char *p = buf;
  char *pend = p;
  unsigned int v;

  /* Intentionally use strtol instead of strtoul, such that
   * -1 turns into "big number"... */
  errno = 0;
  v = strtol (p, &pend, 0);
  if (errno || p == pend)
    return false;

  *pv = v;
  *pp += pend - p;
  return true;
}

static bool
parse_bool (const char **pp, const char *end, unsigned int *pv)
{
  parse_space (pp, end);

  const char *p = *pp;
  while (*pp < end && ISALPHA(**pp))
    (*pp)++;

  /* CSS allows on/off as aliases 1/0. */
  if (*pp - p == 2 || 0 == strncmp (p, "on", 2))
    *pv = 1;
  else if (*pp - p == 3 || 0 == strncmp (p, "off", 2))
    *pv = 0;
  else
    return false;

  return true;
}

static bool
parse_feature_value_prefix (const char **pp, const char *end, hb_feature_t *feature)
{
  if (parse_char (pp, end, '-'))
    feature->value = 0;
  else {
    parse_char (pp, end, '+');
    feature->value = 1;
  }

  return true;
}

static bool
parse_feature_tag (const char **pp, const char *end, hb_feature_t *feature)
{
  parse_space (pp, end);

  char quote = 0;

  if (*pp < end && (**pp == '\'' || **pp == '"'))
  {
    quote = **pp;
    (*pp)++;
  }

  const char *p = *pp;
  while (*pp < end && ISALNUM(**pp))
    (*pp)++;

  if (p == *pp || *pp - p > 4)
    return false;

  feature->tag = hb_tag_from_string (p, *pp - p);

  if (quote)
  {
    /* CSS expects exactly four bytes.  And we only allow quotations for
     * CSS compatibility.  So, enforce the length. */
     if (*pp - p != 4)
       return false;
    if (*pp == end || **pp != quote)
      return false;
    (*pp)++;
  }

  return true;
}

static bool
parse_feature_indices (const char **pp, const char *end, hb_feature_t *feature)
{
  parse_space (pp, end);

  bool has_start;

  feature->start = 0;
  feature->end = (unsigned int) -1;

  if (!parse_char (pp, end, '['))
    return true;

  has_start = parse_uint (pp, end, &feature->start);

  if (parse_char (pp, end, ':')) {
    parse_uint (pp, end, &feature->end);
  } else {
    if (has_start)
      feature->end = feature->start + 1;
  }

  return parse_char (pp, end, ']');
}

static bool
parse_feature_value_postfix (const char **pp, const char *end, hb_feature_t *feature)
{
  bool had_equal = parse_char (pp, end, '=');
  bool had_value = parse_uint (pp, end, &feature->value) ||
                   parse_bool (pp, end, &feature->value);
  /* CSS doesn't use equal-sign between tag and value.
   * If there was an equal-sign, then there *must* be a value.
   * A value without an eqaul-sign is ok, but not required. */
  return !had_equal || had_value;
}


static bool
parse_one_feature (const char **pp, const char *end, hb_feature_t *feature)
{
  return parse_feature_value_prefix (pp, end, feature) &&
	 parse_feature_tag (pp, end, feature) &&
	 parse_feature_indices (pp, end, feature) &&
	 parse_feature_value_postfix (pp, end, feature) &&
	 parse_space (pp, end) &&
	 *pp == end;
}

/**
 * hb_feature_from_string:
 * @str: (array length=len):
 * @len: 
 * @feature: (out) (optional):
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_bool_t
hb_feature_from_string (const char *str, int len,
			hb_feature_t *feature)
{
  hb_feature_t feat;

  if (len < 0)
    len = strlen (str);

  if (likely (parse_one_feature (&str, str + len, &feat)))
  {
    if (feature)
      *feature = feat;
    return true;
  }

  if (feature)
    memset (feature, 0, sizeof (*feature));
  return false;
}

/**
 * hb_feature_to_string:
 * @feature: 
 * @buf: (array length=size):
 * @size: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_feature_to_string (hb_feature_t *feature,
		      char *buf, unsigned int size)
{
  if (unlikely (!size)) return;

  char s[128];
  unsigned int len = 0;
  if (feature->value == 0)
    s[len++] = '-';
  hb_tag_to_string (feature->tag, s + len);
  len += 4;
  while (len && s[len - 1] == ' ')
    len--;
  if (feature->start != 0 || feature->end != (unsigned int) -1)
  {
    s[len++] = '[';
    if (feature->start)
      len += MAX (0, snprintf (s + len, ARRAY_LENGTH (s) - len, "%u", feature->start));
    if (feature->end != feature->start + 1) {
      s[len++] = ':';
      if (feature->end != (unsigned int) -1)
	len += MAX (0, snprintf (s + len, ARRAY_LENGTH (s) - len, "%u", feature->end));
    }
    s[len++] = ']';
  }
  if (feature->value > 1)
  {
    s[len++] = '=';
    len += MAX (0, snprintf (s + len, ARRAY_LENGTH (s) - len, "%u", feature->value));
  }
  assert (len < ARRAY_LENGTH (s));
  len = MIN (len, size - 1);
  memcpy (buf, s, len);
  buf[len] = '\0';
}


static const char **static_shaper_list;

#ifdef HB_USE_ATEXIT
static
void free_static_shaper_list (void)
{
  free (static_shaper_list);
}
#endif

/**
 * hb_shape_list_shapers:
 *
 * 
 *
 * Return value: (transfer none):
 *
 * Since: 1.0
 **/
const char **
hb_shape_list_shapers (void)
{
retry:
  const char **shaper_list = (const char **) hb_atomic_ptr_get (&static_shaper_list);

  if (unlikely (!shaper_list))
  {
    /* Not found; allocate one. */
    shaper_list = (const char **) calloc (1 + HB_SHAPERS_COUNT, sizeof (const char *));
    if (unlikely (!shaper_list)) {
      static const char *nil_shaper_list[] = {NULL};
      return nil_shaper_list;
    }

    const hb_shaper_pair_t *shapers = _hb_shapers_get ();
    unsigned int i;
    for (i = 0; i < HB_SHAPERS_COUNT; i++)
      shaper_list[i] = shapers[i].name;
    shaper_list[i] = NULL;

    if (!hb_atomic_ptr_cmpexch (&static_shaper_list, NULL, shaper_list)) {
      free (shaper_list);
      goto retry;
    }

#ifdef HB_USE_ATEXIT
    atexit (free_static_shaper_list); /* First person registers atexit() callback. */
#endif
  }

  return shaper_list;
}


/**
 * hb_shape_full:
 * @font: a font.
 * @buffer: a buffer.
 * @features: (array length=num_features):
 * @num_features: 
 * @shaper_list: (array zero-terminated=1):
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_bool_t
hb_shape_full (hb_font_t          *font,
	       hb_buffer_t        *buffer,
	       const hb_feature_t *features,
	       unsigned int        num_features,
	       const char * const *shaper_list)
{
  if (unlikely (!buffer->len))
    return true;

  assert (buffer->content_type == HB_BUFFER_CONTENT_TYPE_UNICODE);

  hb_shape_plan_t *shape_plan = hb_shape_plan_create_cached (font->face, &buffer->props, features, num_features, shaper_list);
  hb_bool_t res = hb_shape_plan_execute (shape_plan, font, buffer, features, num_features);
  hb_shape_plan_destroy (shape_plan);

  if (res)
    buffer->content_type = HB_BUFFER_CONTENT_TYPE_GLYPHS;
  return res;
}

/**
 * hb_shape:
 * @font: a font.
 * @buffer: a buffer.
 * @features: (array length=num_features):
 * @num_features: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_shape (hb_font_t           *font,
	  hb_buffer_t         *buffer,
	  const hb_feature_t  *features,
	  unsigned int         num_features)
{
  hb_shape_full (font, buffer, features, num_features, NULL);
}
