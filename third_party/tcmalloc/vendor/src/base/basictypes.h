// Copyright (c) 2005, Google Inc.
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
// 
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#ifndef _BASICTYPES_H_
#define _BASICTYPES_H_

#include <config.h>
#include <string.h>       // for memcpy()
#ifdef HAVE_INTTYPES_H
#include <inttypes.h>     // gets us PRId64, etc
#endif

// To use this in an autoconf setting, make sure you run the following
// autoconf macros:
//    AC_HEADER_STDC              /* for stdint_h and inttypes_h */
//    AC_CHECK_TYPES([__int64])   /* defined in some windows platforms */

#ifdef HAVE_INTTYPES_H
#include <inttypes.h>           // uint16_t might be here; PRId64 too.
#endif
#ifdef HAVE_STDINT_H
#include <stdint.h>             // to get uint16_t (ISO naming madness)
#endif
#include <sys/types.h>          // our last best hope for uint16_t

// Standard typedefs
// All Google code is compiled with -funsigned-char to make "char"
// unsigned.  Google code therefore doesn't need a "uchar" type.
// TODO(csilvers): how do we make sure unsigned-char works on non-gcc systems?
typedef signed char         schar;
typedef int8_t              int8;
typedef int16_t             int16;
typedef int32_t             int32;
typedef int64_t             int64;

// NOTE: unsigned types are DANGEROUS in loops and other arithmetical
// places.  Use the signed types unless your variable represents a bit
// pattern (eg a hash value) or you really need the extra bit.  Do NOT
// use 'unsigned' to express "this value should always be positive";
// use assertions for this.

typedef uint8_t            uint8;
typedef uint16_t           uint16;
typedef uint32_t           uint32;
typedef uint64_t           uint64;

const uint16 kuint16max = (   (uint16) 0xFFFF);
const uint32 kuint32max = (   (uint32) 0xFFFFFFFF);
const uint64 kuint64max = ( (((uint64) kuint32max) << 32) | kuint32max );

const  int8  kint8max   = (   (  int8) 0x7F);
const  int16 kint16max  = (   ( int16) 0x7FFF);
const  int32 kint32max  = (   ( int32) 0x7FFFFFFF);
const  int64 kint64max =  ( ((( int64) kint32max) << 32) | kuint32max );

const  int8  kint8min   = (   (  int8) 0x80);
const  int16 kint16min  = (   ( int16) 0x8000);
const  int32 kint32min  = (   ( int32) 0x80000000);
const  int64 kint64min =  ( ((( int64) kint32min) << 32) | 0 );

// Define the "portable" printf and scanf macros, if they're not
// already there (via the inttypes.h we #included above, hopefully).
// Mostly it's old systems that don't support inttypes.h, so we assume
// they're 32 bit.
#ifndef PRIx64
#define PRIx64 "llx"
#endif
#ifndef SCNx64
#define SCNx64 "llx"
#endif
#ifndef PRId64
#define PRId64 "lld"
#endif
#ifndef SCNd64
#define SCNd64 "lld"
#endif
#ifndef PRIu64
#define PRIu64 "llu"
#endif
#ifndef PRIxPTR
#define PRIxPTR "lx"
#endif

// Also allow for printing of a pthread_t.
#define GPRIuPTHREAD "lu"
#define GPRIxPTHREAD "lx"
#if defined(__CYGWIN__) || defined(__CYGWIN32__) || defined(__APPLE__) || defined(__FreeBSD__)
#define PRINTABLE_PTHREAD(pthreadt) reinterpret_cast<uintptr_t>(pthreadt)
#else
#define PRINTABLE_PTHREAD(pthreadt) pthreadt
#endif

// A macro to disallow the evil copy constructor and operator= functions
// This should be used in the private: declarations for a class
#define DISALLOW_EVIL_CONSTRUCTORS(TypeName)    \
  TypeName(const TypeName&);                    \
  void operator=(const TypeName&)

// An alternate name that leaves out the moral judgment... :-)
#define DISALLOW_COPY_AND_ASSIGN(TypeName) DISALLOW_EVIL_CONSTRUCTORS(TypeName)

// The COMPILE_ASSERT macro can be used to verify that a compile time
// expression is true. For example, you could use it to verify the
// size of a static array:
//
//   COMPILE_ASSERT(sizeof(num_content_type_names) == sizeof(int),
//                  content_type_names_incorrect_size);
//
// or to make sure a struct is smaller than a certain size:
//
//   COMPILE_ASSERT(sizeof(foo) < 128, foo_too_large);
//
// The second argument to the macro is the name of the variable. If
// the expression is false, most compilers will issue a warning/error
// containing the name of the variable.
//
// Implementation details of COMPILE_ASSERT:
//
// - COMPILE_ASSERT works by defining an array type that has -1
//   elements (and thus is invalid) when the expression is false.
//
// - The simpler definition
//
//     #define COMPILE_ASSERT(expr, msg) typedef char msg[(expr) ? 1 : -1]
//
//   does not work, as gcc supports variable-length arrays whose sizes
//   are determined at run-time (this is gcc's extension and not part
//   of the C++ standard).  As a result, gcc fails to reject the
//   following code with the simple definition:
//
//     int foo;
//     COMPILE_ASSERT(foo, msg); // not supposed to compile as foo is
//                               // not a compile-time constant.
//
// - By using the type CompileAssert<(bool(expr))>, we ensures that
//   expr is a compile-time constant.  (Template arguments must be
//   determined at compile-time.)
//
// - The outter parentheses in CompileAssert<(bool(expr))> are necessary
//   to work around a bug in gcc 3.4.4 and 4.0.1.  If we had written
//
//     CompileAssert<bool(expr)>
//
//   instead, these compilers will refuse to compile
//
//     COMPILE_ASSERT(5 > 0, some_message);
//
//   (They seem to think the ">" in "5 > 0" marks the end of the
//   template argument list.)
//
// - The array size is (bool(expr) ? 1 : -1), instead of simply
//
//     ((expr) ? 1 : -1).
//
//   This is to avoid running into a bug in MS VC 7.1, which
//   causes ((0.0) ? 1 : -1) to incorrectly evaluate to 1.

template <bool>
struct CompileAssert {
};

#define COMPILE_ASSERT(expr, msg)                               \
  typedef CompileAssert<(bool(expr))> msg[bool(expr) ? 1 : -1]

#define arraysize(a)  (sizeof(a) / sizeof(*(a)))

#define OFFSETOF_MEMBER(strct, field)                                   \
   (reinterpret_cast<char*>(&reinterpret_cast<strct*>(16)->field) -     \
    reinterpret_cast<char*>(16))

// bit_cast<Dest,Source> implements the equivalent of
// "*reinterpret_cast<Dest*>(&source)".
//
// The reinterpret_cast method would produce undefined behavior
// according to ISO C++ specification section 3.10 -15 -.
// bit_cast<> calls memcpy() which is blessed by the standard,
// especially by the example in section 3.9.
//
// Fortunately memcpy() is very fast.  In optimized mode, with a
// constant size, gcc 2.95.3, gcc 4.0.1, and msvc 7.1 produce inline
// code with the minimal amount of data movement.  On a 32-bit system,
// memcpy(d,s,4) compiles to one load and one store, and memcpy(d,s,8)
// compiles to two loads and two stores.

template <class Dest, class Source>
inline Dest bit_cast(const Source& source) {
  COMPILE_ASSERT(sizeof(Dest) == sizeof(Source), bitcasting_unequal_sizes);
  Dest dest;
  memcpy(&dest, &source, sizeof(dest));
  return dest;
}

#ifdef HAVE___ATTRIBUTE__
# define ATTRIBUTE_WEAK      __attribute__((weak))
# define ATTRIBUTE_NOINLINE  __attribute__((noinline))
#else
# define ATTRIBUTE_WEAK
# define ATTRIBUTE_NOINLINE
#endif

// Section attributes are supported for both ELF and Mach-O, but in
// very different ways.  Here's the API we provide:
// 1) ATTRIBUTE_SECTION: put this with the declaration of all functions
//    you want to be in the same linker section
// 2) DEFINE_ATTRIBUTE_SECTION_VARS: must be called once per unique
//    name.  You want to make sure this is executed before any
//    DECLARE_ATTRIBUTE_SECTION_VARS; the easiest way is to put them
//    in the same .cc file.  Put this call at the global level.
// 3) INIT_ATTRIBUTE_SECTION_VARS: you can scatter calls to this in
//    multiple places to help ensure execution before any
//    DECLARE_ATTRIBUTE_SECTION_VARS.  You must have at least one
//    DEFINE, but you can have many INITs.  Put each in its own scope.
// 4) DECLARE_ATTRIBUTE_SECTION_VARS: must be called before using
//    ATTRIBUTE_SECTION_START or ATTRIBUTE_SECTION_STOP on a name.
//    Put this call at the global level.
// 5) ATTRIBUTE_SECTION_START/ATTRIBUTE_SECTION_STOP: call this to say
//    where in memory a given section is.  All functions declared with
//    ATTRIBUTE_SECTION are guaranteed to be between START and STOP.

#if defined(HAVE___ATTRIBUTE__) && defined(__ELF__)
# define ATTRIBUTE_SECTION(name) __attribute__ ((section (#name)))

  // Weak section declaration to be used as a global declaration
  // for ATTRIBUTE_SECTION_START|STOP(name) to compile and link
  // even without functions with ATTRIBUTE_SECTION(name).
# define DECLARE_ATTRIBUTE_SECTION_VARS(name) \
    extern char __start_##name[] ATTRIBUTE_WEAK; \
    extern char __stop_##name[] ATTRIBUTE_WEAK
# define INIT_ATTRIBUTE_SECTION_VARS(name)     // no-op for ELF
# define DEFINE_ATTRIBUTE_SECTION_VARS(name)   // no-op for ELF

  // Return void* pointers to start/end of a section of code with functions
  // having ATTRIBUTE_SECTION(name), or 0 if no such function exists.
  // One must DECLARE_ATTRIBUTE_SECTION(name) for this to compile and link.
# define ATTRIBUTE_SECTION_START(name) (reinterpret_cast<void*>(__start_##name))
# define ATTRIBUTE_SECTION_STOP(name) (reinterpret_cast<void*>(__stop_##name))
# define HAVE_ATTRIBUTE_SECTION_START 1

#elif defined(HAVE___ATTRIBUTE__) && defined(__MACH__)
# define ATTRIBUTE_SECTION(name) __attribute__ ((section ("__TEXT, " #name)))

#include <mach-o/getsect.h>
#include <mach-o/dyld.h>
class AssignAttributeStartEnd {
 public:
  AssignAttributeStartEnd(const char* name, char** pstart, char** pend) {
    // Find out what dynamic library name is defined in
    if (_dyld_present()) {
      for (int i = _dyld_image_count() - 1; i >= 0; --i) {
        const mach_header* hdr = _dyld_get_image_header(i);
#ifdef MH_MAGIC_64
        if (hdr->magic == MH_MAGIC_64) {
          uint64_t len;
          *pstart = getsectdatafromheader_64((mach_header_64*)hdr,
                                             "__TEXT", name, &len);
          if (*pstart) {   // NULL if not defined in this dynamic library
            *pstart += _dyld_get_image_vmaddr_slide(i);   // correct for reloc
            *pend = *pstart + len;
            return;
          }
        }
#endif
        if (hdr->magic == MH_MAGIC) {
          uint32_t len;
          *pstart = getsectdatafromheader(hdr, "__TEXT", name, &len);
          if (*pstart) {   // NULL if not defined in this dynamic library
            *pstart += _dyld_get_image_vmaddr_slide(i);   // correct for reloc
            *pend = *pstart + len;
            return;
          }
        }
      }
    }
    // If we get here, not defined in a dll at all.  See if defined statically.
    unsigned long len;    // don't ask me why this type isn't uint32_t too...
    *pstart = getsectdata("__TEXT", name, &len);
    *pend = *pstart + len;
  }
};

#define DECLARE_ATTRIBUTE_SECTION_VARS(name)    \
  extern char* __start_##name;                  \
  extern char* __stop_##name

#define INIT_ATTRIBUTE_SECTION_VARS(name)               \
  DECLARE_ATTRIBUTE_SECTION_VARS(name);                 \
  static const AssignAttributeStartEnd __assign_##name( \
    #name, &__start_##name, &__stop_##name)

#define DEFINE_ATTRIBUTE_SECTION_VARS(name)     \
  char* __start_##name, *__stop_##name;         \
  INIT_ATTRIBUTE_SECTION_VARS(name)

# define ATTRIBUTE_SECTION_START(name) (reinterpret_cast<void*>(__start_##name))
# define ATTRIBUTE_SECTION_STOP(name) (reinterpret_cast<void*>(__stop_##name))
# define HAVE_ATTRIBUTE_SECTION_START 1

#else  // not HAVE___ATTRIBUTE__ && __ELF__, nor HAVE___ATTRIBUTE__ && __MACH__
# define ATTRIBUTE_SECTION(name)
# define DECLARE_ATTRIBUTE_SECTION_VARS(name)
# define INIT_ATTRIBUTE_SECTION_VARS(name)
# define DEFINE_ATTRIBUTE_SECTION_VARS(name)
# define ATTRIBUTE_SECTION_START(name) (reinterpret_cast<void*>(0))
# define ATTRIBUTE_SECTION_STOP(name) (reinterpret_cast<void*>(0))

#endif  // HAVE___ATTRIBUTE__ and __ELF__ or __MACH__

#if defined(HAVE___ATTRIBUTE__) && (defined(__i386__) || defined(__x86_64__))
# define CACHELINE_ALIGNED __attribute__((aligned(64)))
#else
# define CACHELINE_ALIGNED
#endif  // defined(HAVE___ATTRIBUTE__) && (__i386__ || __x86_64__)


// The following enum should be used only as a constructor argument to indicate
// that the variable has static storage class, and that the constructor should
// do nothing to its state.  It indicates to the reader that it is legal to
// declare a static nistance of the class, provided the constructor is given
// the base::LINKER_INITIALIZED argument.  Normally, it is unsafe to declare a
// static variable that has a constructor or a destructor because invocation
// order is undefined.  However, IF the type can be initialized by filling with
// zeroes (which the loader does for static variables), AND the destructor also
// does nothing to the storage, then a constructor declared as
//       explicit MyClass(base::LinkerInitialized x) {}
// and invoked as
//       static MyClass my_variable_name(base::LINKER_INITIALIZED);
namespace base {
enum LinkerInitialized { LINKER_INITIALIZED };
}

#endif  // _BASICTYPES_H_
