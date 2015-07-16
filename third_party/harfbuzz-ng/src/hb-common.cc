/*
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
 * Red Hat Author(s): Behdad Esfahbod
 * Google Author(s): Behdad Esfahbod
 */

#include "hb-private.hh"

#include "hb-mutex-private.hh"
#include "hb-object-private.hh"

#include <locale.h>


/* hb_options_t */

hb_options_union_t _hb_options;

void
_hb_options_init (void)
{
  hb_options_union_t u;
  u.i = 0;
  u.opts.initialized = 1;

  char *c = getenv ("HB_OPTIONS");
  u.opts.uniscribe_bug_compatible = c && strstr (c, "uniscribe-bug-compatible");

  /* This is idempotent and threadsafe. */
  _hb_options = u;
}


/* hb_tag_t */

/**
 * hb_tag_from_string:
 * @str: (array length=len): 
 * @len: 
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_tag_t
hb_tag_from_string (const char *str, int len)
{
  char tag[4];
  unsigned int i;

  if (!str || !len || !*str)
    return HB_TAG_NONE;

  if (len < 0 || len > 4)
    len = 4;
  for (i = 0; i < (unsigned) len && str[i]; i++)
    tag[i] = str[i];
  for (; i < 4; i++)
    tag[i] = ' ';

  return HB_TAG_CHAR4 (tag);
}

/**
 * hb_tag_to_string:
 * @tag: 
 * @buf: (array fixed-size=4): 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_tag_to_string (hb_tag_t tag, char *buf)
{
  buf[0] = (char) (uint8_t) (tag >> 24);
  buf[1] = (char) (uint8_t) (tag >> 16);
  buf[2] = (char) (uint8_t) (tag >>  8);
  buf[3] = (char) (uint8_t) (tag >>  0);
}


/* hb_direction_t */

const char direction_strings[][4] = {
  "ltr",
  "rtl",
  "ttb",
  "btt"
};

/**
 * hb_direction_from_string:
 * @str: (array length=len): 
 * @len: 
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_direction_t
hb_direction_from_string (const char *str, int len)
{
  if (unlikely (!str || !len || !*str))
    return HB_DIRECTION_INVALID;

  /* Lets match loosely: just match the first letter, such that
   * all of "ltr", "left-to-right", etc work!
   */
  char c = TOLOWER (str[0]);
  for (unsigned int i = 0; i < ARRAY_LENGTH (direction_strings); i++)
    if (c == direction_strings[i][0])
      return (hb_direction_t) (HB_DIRECTION_LTR + i);

  return HB_DIRECTION_INVALID;
}

/**
 * hb_direction_to_string:
 * @direction: 
 *
 * 
 *
 * Return value: (transfer none): 
 *
 * Since: 1.0
 **/
const char *
hb_direction_to_string (hb_direction_t direction)
{
  if (likely ((unsigned int) (direction - HB_DIRECTION_LTR)
	      < ARRAY_LENGTH (direction_strings)))
    return direction_strings[direction - HB_DIRECTION_LTR];

  return "invalid";
}


/* hb_language_t */

struct hb_language_impl_t {
  const char s[1];
};

static const char canon_map[256] = {
   0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,   0,   0,   0,   0,   0,
   0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,   0,   0,   0,   0,   0,
   0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,   0,   0,  '-',  0,   0,
  '0', '1', '2', '3', '4', '5', '6', '7',  '8', '9',  0,   0,   0,   0,   0,   0,
  '-', 'a', 'b', 'c', 'd', 'e', 'f', 'g',  'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o',
  'p', 'q', 'r', 's', 't', 'u', 'v', 'w',  'x', 'y', 'z',  0,   0,   0,   0,  '-',
   0,  'a', 'b', 'c', 'd', 'e', 'f', 'g',  'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o',
  'p', 'q', 'r', 's', 't', 'u', 'v', 'w',  'x', 'y', 'z',  0,   0,   0,   0,   0
};

static hb_bool_t
lang_equal (hb_language_t  v1,
	    const void    *v2)
{
  const unsigned char *p1 = (const unsigned char *) v1;
  const unsigned char *p2 = (const unsigned char *) v2;

  while (*p1 && *p1 == canon_map[*p2])
    p1++, p2++;

  return *p1 == canon_map[*p2];
}

#if 0
static unsigned int
lang_hash (const void *key)
{
  const unsigned char *p = key;
  unsigned int h = 0;
  while (canon_map[*p])
    {
      h = (h << 5) - h + canon_map[*p];
      p++;
    }

  return h;
}
#endif


struct hb_language_item_t {

  struct hb_language_item_t *next;
  hb_language_t lang;

  inline bool operator == (const char *s) const {
    return lang_equal (lang, s);
  }

  inline hb_language_item_t & operator = (const char *s) {
    lang = (hb_language_t) strdup (s);
    for (unsigned char *p = (unsigned char *) lang; *p; p++)
      *p = canon_map[*p];

    return *this;
  }

  void finish (void) { free ((void *) lang); }
};


/* Thread-safe lock-free language list */

static hb_language_item_t *langs;

#ifdef HB_USE_ATEXIT
static
void free_langs (void)
{
  while (langs) {
    hb_language_item_t *next = langs->next;
    langs->finish ();
    free (langs);
    langs = next;
  }
}
#endif

static hb_language_item_t *
lang_find_or_insert (const char *key)
{
retry:
  hb_language_item_t *first_lang = (hb_language_item_t *) hb_atomic_ptr_get (&langs);

  for (hb_language_item_t *lang = first_lang; lang; lang = lang->next)
    if (*lang == key)
      return lang;

  /* Not found; allocate one. */
  hb_language_item_t *lang = (hb_language_item_t *) calloc (1, sizeof (hb_language_item_t));
  if (unlikely (!lang))
    return NULL;
  lang->next = first_lang;
  *lang = key;

  if (!hb_atomic_ptr_cmpexch (&langs, first_lang, lang)) {
    lang->finish ();
    free (lang);
    goto retry;
  }

#ifdef HB_USE_ATEXIT
  if (!first_lang)
    atexit (free_langs); /* First person registers atexit() callback. */
#endif

  return lang;
}


/**
 * hb_language_from_string:
 * @str: (array length=len): 
 * @len: 
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_language_t
hb_language_from_string (const char *str, int len)
{
  char strbuf[64];

  if (!str || !len || !*str)
    return HB_LANGUAGE_INVALID;

  if (len >= 0)
  {
    /* NUL-terminate it. */
    len = MIN (len, (int) sizeof (strbuf) - 1);
    memcpy (strbuf, str, len);
    strbuf[len] = '\0';
    str = strbuf;
  }

  hb_language_item_t *item = lang_find_or_insert (str);

  return likely (item) ? item->lang : HB_LANGUAGE_INVALID;
}

/**
 * hb_language_to_string:
 * @language: 
 *
 * 
 *
 * Return value: (transfer none): 
 *
 * Since: 1.0
 **/
const char *
hb_language_to_string (hb_language_t language)
{
  /* This is actually NULL-safe! */
  return language->s;
}

/**
 * hb_language_get_default:
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_language_t
hb_language_get_default (void)
{
  static hb_language_t default_language = HB_LANGUAGE_INVALID;

  hb_language_t language = (hb_language_t) hb_atomic_ptr_get (&default_language);
  if (unlikely (language == HB_LANGUAGE_INVALID)) {
    language = hb_language_from_string (setlocale (LC_CTYPE, NULL), -1);
    (void) hb_atomic_ptr_cmpexch (&default_language, HB_LANGUAGE_INVALID, language);
  }

  return default_language;
}


/* hb_script_t */

/**
 * hb_script_from_iso15924_tag:
 * @tag: 
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_script_t
hb_script_from_iso15924_tag (hb_tag_t tag)
{
  if (unlikely (tag == HB_TAG_NONE))
    return HB_SCRIPT_INVALID;

  /* Be lenient, adjust case (one capital letter followed by three small letters) */
  tag = (tag & 0xDFDFDFDFu) | 0x00202020u;

  switch (tag) {

    /* These graduated from the 'Q' private-area codes, but
     * the old code is still aliased by Unicode, and the Qaai
     * one in use by ICU. */
    case HB_TAG('Q','a','a','i'): return HB_SCRIPT_INHERITED;
    case HB_TAG('Q','a','a','c'): return HB_SCRIPT_COPTIC;

    /* Script variants from http://unicode.org/iso15924/ */
    case HB_TAG('C','y','r','s'): return HB_SCRIPT_CYRILLIC;
    case HB_TAG('L','a','t','f'): return HB_SCRIPT_LATIN;
    case HB_TAG('L','a','t','g'): return HB_SCRIPT_LATIN;
    case HB_TAG('S','y','r','e'): return HB_SCRIPT_SYRIAC;
    case HB_TAG('S','y','r','j'): return HB_SCRIPT_SYRIAC;
    case HB_TAG('S','y','r','n'): return HB_SCRIPT_SYRIAC;
  }

  /* If it looks right, just use the tag as a script */
  if (((uint32_t) tag & 0xE0E0E0E0u) == 0x40606060u)
    return (hb_script_t) tag;

  /* Otherwise, return unknown */
  return HB_SCRIPT_UNKNOWN;
}

/**
 * hb_script_from_string:
 * @s: (array length=len): 
 * @len: 
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_script_t
hb_script_from_string (const char *s, int len)
{
  return hb_script_from_iso15924_tag (hb_tag_from_string (s, len));
}

/**
 * hb_script_to_iso15924_tag:
 * @script: 
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_tag_t
hb_script_to_iso15924_tag (hb_script_t script)
{
  return (hb_tag_t) script;
}

/**
 * hb_script_get_horizontal_direction:
 * @script: 
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_direction_t
hb_script_get_horizontal_direction (hb_script_t script)
{
  /* http://goo.gl/x9ilM */
  switch ((hb_tag_t) script)
  {
    /* Unicode-1.1 additions */
    case HB_SCRIPT_ARABIC:
    case HB_SCRIPT_HEBREW:

    /* Unicode-3.0 additions */
    case HB_SCRIPT_SYRIAC:
    case HB_SCRIPT_THAANA:

    /* Unicode-4.0 additions */
    case HB_SCRIPT_CYPRIOT:

    /* Unicode-4.1 additions */
    case HB_SCRIPT_KHAROSHTHI:

    /* Unicode-5.0 additions */
    case HB_SCRIPT_PHOENICIAN:
    case HB_SCRIPT_NKO:

    /* Unicode-5.1 additions */
    case HB_SCRIPT_LYDIAN:

    /* Unicode-5.2 additions */
    case HB_SCRIPT_AVESTAN:
    case HB_SCRIPT_IMPERIAL_ARAMAIC:
    case HB_SCRIPT_INSCRIPTIONAL_PAHLAVI:
    case HB_SCRIPT_INSCRIPTIONAL_PARTHIAN:
    case HB_SCRIPT_OLD_SOUTH_ARABIAN:
    case HB_SCRIPT_OLD_TURKIC:
    case HB_SCRIPT_SAMARITAN:

    /* Unicode-6.0 additions */
    case HB_SCRIPT_MANDAIC:

    /* Unicode-6.1 additions */
    case HB_SCRIPT_MEROITIC_CURSIVE:
    case HB_SCRIPT_MEROITIC_HIEROGLYPHS:

    /* Unicode-7.0 additions */
    case HB_SCRIPT_MANICHAEAN:
    case HB_SCRIPT_MENDE_KIKAKUI:
    case HB_SCRIPT_NABATAEAN:
    case HB_SCRIPT_OLD_NORTH_ARABIAN:
    case HB_SCRIPT_PALMYRENE:
    case HB_SCRIPT_PSALTER_PAHLAVI:

      return HB_DIRECTION_RTL;
  }

  return HB_DIRECTION_LTR;
}


/* hb_user_data_array_t */

bool
hb_user_data_array_t::set (hb_user_data_key_t *key,
			   void *              data,
			   hb_destroy_func_t   destroy,
			   hb_bool_t           replace)
{
  if (!key)
    return false;

  if (replace) {
    if (!data && !destroy) {
      items.remove (key, lock);
      return true;
    }
  }
  hb_user_data_item_t item = {key, data, destroy};
  bool ret = !!items.replace_or_insert (item, lock, replace);

  return ret;
}

void *
hb_user_data_array_t::get (hb_user_data_key_t *key)
{
  hb_user_data_item_t item = {NULL };

  return items.find (key, &item, lock) ? item.data : NULL;
}


/* hb_version */

/**
 * hb_version:
 * @major: (out): Library major version component.
 * @minor: (out): Library minor version component.
 * @micro: (out): Library micro version component.
 *
 * Returns library version as three integer components.
 *
 * Since: 1.0
 **/
void
hb_version (unsigned int *major,
	    unsigned int *minor,
	    unsigned int *micro)
{
  *major = HB_VERSION_MAJOR;
  *minor = HB_VERSION_MINOR;
  *micro = HB_VERSION_MICRO;
}

/**
 * hb_version_string:
 *
 * Returns library version as a string with three components.
 *
 * Return value: library version string.
 *
 * Since: 1.0
 **/
const char *
hb_version_string (void)
{
  return HB_VERSION_STRING;
}

/**
 * hb_version_atleast:
 * @major: 
 * @minor: 
 * @micro: 
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_bool_t
hb_version_atleast (unsigned int major,
		    unsigned int minor,
		    unsigned int micro)
{
  return HB_VERSION_ATLEAST (major, minor, micro);
}
