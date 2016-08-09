/*
 * Summary: macros for marking symbols as exportable/importable.
 * Description: macros for marking symbols as exportable/importable.
 *
 * Copy: See Copyright for the status of this software.
 *
 * Author: Igor Zlatovic <igor@zlatkovic.com>
 */

#ifndef __XML_EXPORTS_H__
#define __XML_EXPORTS_H__

/**
 * XMLPUBFUN, XMLPUBVAR, XMLCALL
 *
 * Macros which declare an exportable function, an exportable variable and
 * the calling convention used for functions.
 *
 * Please use an extra block for every platform/compiler combination when
 * modifying this, rather than overlong #ifdef lines. This helps
 * readability as well as the fact that different compilers on the same
 * platform might need different definitions.
 */

/**
 * XMLPUBFUN:
 *
 * Macros which declare an exportable function
 */
#define XMLPUBFUN
/**
 * XMLPUBVAR:
 *
 * Macros which declare an exportable variable
 */
#define XMLPUBVAR extern
/**
 * XMLCALL:
 *
 * Macros which declare the called convention for exported functions
 */
#define XMLCALL
/**
 * XMLCDECL:
 *
 * Macro which declares the calling convention for exported functions that 
 * use '...'.
 */
#define XMLCDECL

/** DOC_DISABLE */

/* Windows platform with MS compiler */
#if defined(_WIN32) && defined(_MSC_VER)
  #undef XMLPUBFUN
  #undef XMLPUBVAR
  #undef XMLCALL
  #undef XMLCDECL
  #if defined(IN_LIBXML) && !defined(LIBXML_STATIC)
    #define XMLPUBFUN __declspec(dllexport)
    #define XMLPUBVAR __declspec(dllexport)
  #else
    #define XMLPUBFUN
    #if !defined(LIBXML_STATIC)
      #define XMLPUBVAR __declspec(dllimport) extern
    #else
      #define XMLPUBVAR extern
    #endif
  #endif
  #if defined(LIBXML_FASTCALL)
    #define XMLCALL __fastcall
  #else
    #define XMLCALL __cdecl
  #endif
  #define XMLCDECL __cdecl
  #if !defined _REENTRANT
    #define _REENTRANT
  #endif
#endif

/* Windows platform with Borland compiler */
#if defined(_WIN32) && defined(__BORLANDC__)
  #undef XMLPUBFUN
  #undef XMLPUBVAR
  #undef XMLCALL
  #undef XMLCDECL
  #if defined(IN_LIBXML) && !defined(LIBXML_STATIC)
    #define XMLPUBFUN __declspec(dllexport)
    #define XMLPUBVAR __declspec(dllexport) extern
  #else
    #define XMLPUBFUN
    #if !defined(LIBXML_STATIC)
      #define XMLPUBVAR __declspec(dllimport) extern
    #else
      #define XMLPUBVAR extern
    #endif
  #endif
  #define XMLCALL __cdecl
  #define XMLCDECL __cdecl
  #if !defined _REENTRANT
    #define _REENTRANT
  #endif
#endif

/* Windows platform with GNU compiler (Mingw) */
#if defined(_WIN32) && defined(__MINGW32__)
  #undef XMLPUBFUN
  #undef XMLPUBVAR
  #undef XMLCALL
  #undef XMLCDECL
  /*
   * if defined(IN_LIBXML) this raises problems on mingw with msys
   * _imp__xmlFree listed as missing. Try to workaround the problem
   * by also making that declaration when compiling client code.
   */
  #if defined(IN_LIBXML) && !defined(LIBXML_STATIC)
    #define XMLPUBFUN __declspec(dllexport)
    #define XMLPUBVAR __declspec(dllexport)
  #else
    #define XMLPUBFUN
    #if !defined(LIBXML_STATIC)
      #define XMLPUBVAR __declspec(dllimport) extern
    #else
      #define XMLPUBVAR extern
    #endif
  #endif
  #define XMLCALL __cdecl
  #define XMLCDECL __cdecl
  #if !defined _REENTRANT
    #define _REENTRANT
  #endif
#endif

/* Cygwin platform, GNU compiler */
#if defined(_WIN32) && defined(__CYGWIN__)
  #undef XMLPUBFUN
  #undef XMLPUBVAR
  #undef XMLCALL
  #undef XMLCDECL
  #if defined(IN_LIBXML) && !defined(LIBXML_STATIC)
    #define XMLPUBFUN __declspec(dllexport)
    #define XMLPUBVAR __declspec(dllexport)
  #else
    #define XMLPUBFUN
    #if !defined(LIBXML_STATIC)
      #define XMLPUBVAR __declspec(dllimport) extern
    #else
      #define XMLPUBVAR
    #endif
  #endif
  #define XMLCALL __cdecl
  #define XMLCDECL __cdecl
#endif

/* Compatibility */
#if !defined(LIBXML_DLL_IMPORT)
#define LIBXML_DLL_IMPORT XMLPUBVAR
#endif

#endif /* __XML_EXPORTS_H__ */


