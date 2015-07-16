/* internal.h

   Internal definitions used by Expat.  This is not needed to compile
   client code.

   The following calling convention macros are defined for frequently
   called functions:

   FASTCALL    - Used for those internal functions that have a simple
                 body and a low number of arguments and local variables.

   PTRCALL     - Used for functions called though function pointers.

   PTRFASTCALL - Like PTRCALL, but for low number of arguments.

   inline      - Used for selected internal functions for which inlining
                 may improve performance on some platforms.

   Note: Use of these macros is based on judgement, not hard rules,
         and therefore subject to change.
*/

#if defined(__GNUC__) && defined(__i386__) && !defined(__MINGW32__)
/* We'll use this version by default only where we know it helps.

   regparm() generates warnings on Solaris boxes.   See SF bug #692878.

   Instability reported with egcs on a RedHat Linux 7.3.
   Let's comment out:
   #define FASTCALL __attribute__((stdcall, regparm(3)))
   and let's try this:
*/
#define FASTCALL __attribute__((regparm(3)))
#define PTRFASTCALL __attribute__((regparm(3)))
#endif

/* Using __fastcall seems to have an unexpected negative effect under
   MS VC++, especially for function pointers, so we won't use it for
   now on that platform. It may be reconsidered for a future release
   if it can be made more effective.
   Likely reason: __fastcall on Windows is like stdcall, therefore
   the compiler cannot perform stack optimizations for call clusters.
*/

/* Make sure all of these are defined if they aren't already. */

#ifndef FASTCALL
#define FASTCALL
#endif

#ifndef PTRCALL
#define PTRCALL
#endif

#ifndef PTRFASTCALL
#define PTRFASTCALL
#endif

#ifndef XML_MIN_SIZE
#if !defined(__cplusplus) && !defined(inline)
#ifdef __GNUC__
#define inline __inline
#endif /* __GNUC__ */
#endif
#endif /* XML_MIN_SIZE */

#ifdef __cplusplus
#define inline inline
#else
#ifndef inline
#define inline
#endif
#endif
