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

#include "hb-atomic-private.hh"
#include "hb-mutex-private.hh"


#if defined(HB_ATOMIC_INT_NIL)
#ifdef _MSC_VER
#pragma message("Could not find any system to define atomic_int macros, library may NOT be thread-safe")
#else
#warning "Could not find any system to define atomic_int macros, library may NOT be thread-safe"
#endif
#endif

#if defined(HB_MUTEX_IMPL_NIL)
#ifdef _MSC_VER
#pragma message("Could not find any system to define mutex macros, library may NOT be thread-safe")
#else
#warning "Could not find any system to define mutex macros, library may NOT be thread-safe"
#endif
#endif

#if defined(HB_ATOMIC_INT_NIL) || defined(HB_MUTEX_IMPL_NIL)
#ifdef _MSC_VER
#pragma message("To suppress these warnings, define HB_NO_MT")
#else
#warning "To suppress these warnings, define HB_NO_MT"
#endif
#endif


