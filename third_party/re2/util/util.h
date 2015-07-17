// Copyright 2009 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#ifndef RE2_UTIL_UTIL_H__
#define RE2_UTIL_UTIL_H__

// C
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stddef.h>         // For size_t
#include <assert.h>
#include <stdarg.h>
#ifndef WIN32
#include <sys/time.h>
#endif
#include <time.h>
#include <ctype.h>	// For isdigit, isalpha.

// C++
#include <vector>
#include <string>
#include <algorithm>
#include <iosfwd>
#include <map>
#include <stack>
#include <ostream>
#include <utility>
#include <set>

#include "build/build_config.h"
#include "base/third_party/dynamic_annotations/dynamic_annotations.h"

// Use std names.
using std::set;
using std::pair;
using std::vector;
using std::string;
using std::min;
using std::max;
using std::ostream;
using std::map;
using std::stack;
using std::sort;
using std::swap;
using std::make_pair;

#if defined(__GNUC__) && !defined(USE_CXX0X) && !defined(_LIBCPP_ABI_VERSION) && !defined(OS_ANDROID)

#include <tr1/unordered_set>
using std::tr1::unordered_set;

#else

#include <unordered_set>
#if defined(WIN32) || (defined(OS_ANDROID) && !defined(_LIBCPP_ABI_VERSION))
using std::tr1::unordered_set;
#else
using std::unordered_set;
#endif

#endif

namespace re2 {

typedef int8_t int8;
typedef uint8_t uint8;
typedef int16_t int16;
typedef uint16_t uint16;
typedef int32_t int32;
typedef uint32_t uint32;
typedef int64_t int64;
typedef uint64_t uint64;

typedef unsigned long ulong;
typedef unsigned int uint;
typedef unsigned short ushort;

// COMPILE_ASSERT causes a compile error about msg if expr is not true.
#if __cplusplus >= 201103L
#define COMPILE_ASSERT(expr, msg) static_assert(expr, #msg)
#else
template<bool> struct CompileAssert {};
#define COMPILE_ASSERT(expr, msg) \
  typedef CompileAssert<(bool(expr))> msg[bool(expr) ? 1 : -1]
#endif

// DISALLOW_EVIL_CONSTRUCTORS disallows the copy and operator= functions.
// It goes in the private: declarations in a class.
#define DISALLOW_EVIL_CONSTRUCTORS(TypeName) \
  TypeName(const TypeName&);                 \
  void operator=(const TypeName&)

#define arraysize(array) (sizeof(array)/sizeof((array)[0]))

// Fake lock annotations.  For real ones, see
// http://code.google.com/p/data-race-test/
#ifndef ANNOTATE_PUBLISH_MEMORY_RANGE
#define ANNOTATE_PUBLISH_MEMORY_RANGE(a, b)
#define ANNOTATE_IGNORE_WRITES_BEGIN()
#define ANNOTATE_IGNORE_WRITES_END()
#define ANNOTATE_BENIGN_RACE(a, b)
#define NO_THREAD_SAFETY_ANALYSIS
#define ANNOTATE_HAPPENS_BEFORE(x)
#define ANNOTATE_HAPPENS_AFTER(x)
#define ANNOTATE_UNPROTECTED_READ(x) (x)
#endif

class StringPiece;

string CEscape(const StringPiece& src);
int CEscapeString(const char* src, int src_len, char* dest, int dest_len);

extern string StringPrintf(const char* format, ...);
extern void SStringPrintf(string* dst, const char* format, ...);
extern void StringAppendF(string* dst, const char* format, ...);
extern string PrefixSuccessor(const StringPiece& prefix);

uint32 hashword(const uint32*, size_t, uint32);
void hashword2(const uint32*, size_t, uint32*, uint32*);

static inline uint32 Hash32StringWithSeed(const char* s, int len, uint32 seed) {
  return hashword((uint32*)s, len/4, seed);
}

static inline uint64 Hash64StringWithSeed(const char* s, int len, uint32 seed) {
  uint32 x, y;
  x = seed;
  y = 0;
  hashword2((uint32*)s, len/4, &x, &y);
  return ((uint64)x << 32) | y;
}

inline bool RunningOnValgrindOrMemorySanitizer() {
#if defined(MEMORY_SANITIZER)
  return true;
#else
  return RunningOnValgrind();
#endif
}

}  // namespace re2

#include "util/arena.h"
#include "util/logging.h"
#include "util/mutex.h"
#include "util/utf.h"

#endif // RE2_UTIL_UTIL_H__
