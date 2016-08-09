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

#ifndef HB_MUTEX_PRIVATE_HH
#define HB_MUTEX_PRIVATE_HH

#include "hb-private.hh"


/* mutex */

/* We need external help for these */

#if 0


#elif !defined(HB_NO_MT) && (defined(_WIN32) || defined(__CYGWIN__))

#include <windows.h>
typedef CRITICAL_SECTION hb_mutex_impl_t;
#define HB_MUTEX_IMPL_INIT	{0}
#if defined(WINAPI_FAMILY) && (WINAPI_FAMILY==WINAPI_FAMILY_PC_APP || WINAPI_FAMILY==WINAPI_FAMILY_PHONE_APP)
#define hb_mutex_impl_init(M)	InitializeCriticalSectionEx (M, 0, 0)
#else
#define hb_mutex_impl_init(M)	InitializeCriticalSection (M)
#endif
#define hb_mutex_impl_lock(M)	EnterCriticalSection (M)
#define hb_mutex_impl_unlock(M)	LeaveCriticalSection (M)
#define hb_mutex_impl_finish(M)	DeleteCriticalSection (M)


#elif !defined(HB_NO_MT) && (defined(HAVE_PTHREAD) || defined(__APPLE__))

#include <pthread.h>
typedef pthread_mutex_t hb_mutex_impl_t;
#define HB_MUTEX_IMPL_INIT	PTHREAD_MUTEX_INITIALIZER
#define hb_mutex_impl_init(M)	pthread_mutex_init (M, NULL)
#define hb_mutex_impl_lock(M)	pthread_mutex_lock (M)
#define hb_mutex_impl_unlock(M)	pthread_mutex_unlock (M)
#define hb_mutex_impl_finish(M)	pthread_mutex_destroy (M)


#elif !defined(HB_NO_MT) && defined(HAVE_INTEL_ATOMIC_PRIMITIVES)

#if defined(HAVE_SCHED_H) && defined(HAVE_SCHED_YIELD)
# include <sched.h>
# define HB_SCHED_YIELD() sched_yield ()
#else
# define HB_SCHED_YIELD() HB_STMT_START {} HB_STMT_END
#endif

/* This actually is not a totally awful implementation. */
typedef volatile int hb_mutex_impl_t;
#define HB_MUTEX_IMPL_INIT	0
#define hb_mutex_impl_init(M)	*(M) = 0
#define hb_mutex_impl_lock(M)	HB_STMT_START { while (__sync_lock_test_and_set((M), 1)) HB_SCHED_YIELD (); } HB_STMT_END
#define hb_mutex_impl_unlock(M)	__sync_lock_release (M)
#define hb_mutex_impl_finish(M)	HB_STMT_START {} HB_STMT_END


#elif !defined(HB_NO_MT)

#if defined(HAVE_SCHED_H) && defined(HAVE_SCHED_YIELD)
# include <sched.h>
# define HB_SCHED_YIELD() sched_yield ()
#else
# define HB_SCHED_YIELD() HB_STMT_START {} HB_STMT_END
#endif

#define HB_MUTEX_INT_NIL 1 /* Warn that fallback implementation is in use. */
typedef volatile int hb_mutex_impl_t;
#define HB_MUTEX_IMPL_INIT	0
#define hb_mutex_impl_init(M)	*(M) = 0
#define hb_mutex_impl_lock(M)	HB_STMT_START { while (*(M)) HB_SCHED_YIELD (); (*(M))++; } HB_STMT_END
#define hb_mutex_impl_unlock(M)	(*(M))--;
#define hb_mutex_impl_finish(M)	HB_STMT_START {} HB_STMT_END


#else /* HB_NO_MT */

typedef int hb_mutex_impl_t;
#define HB_MUTEX_IMPL_INIT	0
#define hb_mutex_impl_init(M)	HB_STMT_START {} HB_STMT_END
#define hb_mutex_impl_lock(M)	HB_STMT_START {} HB_STMT_END
#define hb_mutex_impl_unlock(M)	HB_STMT_START {} HB_STMT_END
#define hb_mutex_impl_finish(M)	HB_STMT_START {} HB_STMT_END

#endif


#define HB_MUTEX_INIT		{HB_MUTEX_IMPL_INIT}
struct hb_mutex_t
{
  /* TODO Add tracing. */

  hb_mutex_impl_t m;

  inline void init   (void) { hb_mutex_impl_init   (&m); }
  inline void lock   (void) { hb_mutex_impl_lock   (&m); }
  inline void unlock (void) { hb_mutex_impl_unlock (&m); }
  inline void finish (void) { hb_mutex_impl_finish (&m); }
};


#endif /* HB_MUTEX_PRIVATE_HH */
