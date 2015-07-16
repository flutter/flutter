// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// http://code.google.com/p/protobuf/
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

// Author: kenton@google.com (Kenton Varda)
//
// Deals with the fact that hash_map is not defined everywhere.

#ifndef GOOGLE_PROTOBUF_STUBS_HASH_H__
#define GOOGLE_PROTOBUF_STUBS_HASH_H__

#include <string.h>
#include <google/protobuf/stubs/common.h>
#include "config.h"

#if defined(HAVE_HASH_MAP) && defined(HAVE_HASH_SET)
#include HASH_MAP_H
#include HASH_SET_H
#else
#define MISSING_HASH
#include <map>
#include <set>
#endif

namespace google {
namespace protobuf {

#ifdef MISSING_HASH

// This system doesn't have hash_map or hash_set.  Emulate them using map and
// set.

// Make hash<T> be the same as less<T>.  Note that everywhere where custom
// hash functions are defined in the protobuf code, they are also defined such
// that they can be used as "less" functions, which is required by MSVC anyway.
template <typename Key>
struct hash {
  // Dummy, just to make derivative hash functions compile.
  int operator()(const Key& key) {
    GOOGLE_LOG(FATAL) << "Should never be called.";
    return 0;
  }

  inline bool operator()(const Key& a, const Key& b) const {
    return a < b;
  }
};

// Make sure char* is compared by value.
template <>
struct hash<const char*> {
  // Dummy, just to make derivative hash functions compile.
  int operator()(const char* key) {
    GOOGLE_LOG(FATAL) << "Should never be called.";
    return 0;
  }

  inline bool operator()(const char* a, const char* b) const {
    return strcmp(a, b) < 0;
  }
};

template <typename Key, typename Data,
          typename HashFcn = hash<Key>,
          typename EqualKey = int >
class hash_map : public std::map<Key, Data, HashFcn> {
 public:
  hash_map(int = 0) {}
};

template <typename Key,
          typename HashFcn = hash<Key>,
          typename EqualKey = int >
class hash_set : public std::set<Key, HashFcn> {
 public:
  hash_set(int = 0) {}
};

#elif defined(_MSC_VER) && !defined(_STLPORT_VERSION)

template <typename Key>
struct hash : public HASH_NAMESPACE::hash_compare<Key> {
};

// MSVC's hash_compare<const char*> hashes based on the string contents but
// compares based on the string pointer.  WTF?
class CstringLess {
 public:
  inline bool operator()(const char* a, const char* b) const {
    return strcmp(a, b) < 0;
  }
};

template <>
struct hash<const char*>
  : public HASH_NAMESPACE::hash_compare<const char*, CstringLess> {
};

template <typename Key, typename Data,
          typename HashFcn = hash<Key>,
          typename EqualKey = int >
class hash_map : public HASH_NAMESPACE::hash_map<
    Key, Data, HashFcn> {
 public:
  hash_map(int = 0) {}
};

template <typename Key,
          typename HashFcn = hash<Key>,
          typename EqualKey = int >
class hash_set : public HASH_NAMESPACE::hash_set<
    Key, HashFcn> {
 public:
  hash_set(int = 0) {}
};

#else

template <typename Key>
struct hash : public HASH_NAMESPACE::hash<Key> {
};

template <typename Key>
struct hash<const Key*> {
  inline size_t operator()(const Key* key) const {
    return reinterpret_cast<size_t>(key);
  }
};

// Unlike the old SGI version, the TR1 "hash" does not special-case char*.  So,
// we go ahead and provide our own implementation.
template <>
struct hash<const char*> {
  inline size_t operator()(const char* str) const {
    size_t result = 0;
    for (; *str != '\0'; str++) {
      result = 5 * result + *str;
    }
    return result;
  }
};

template <typename Key, typename Data,
          typename HashFcn = hash<Key>,
          typename EqualKey = std::equal_to<Key> >
class hash_map : public HASH_NAMESPACE::HASH_MAP_CLASS<
    Key, Data, HashFcn, EqualKey> {
 public:
  hash_map(int = 0) {}
};

template <typename Key,
          typename HashFcn = hash<Key>,
          typename EqualKey = std::equal_to<Key> >
class hash_set : public HASH_NAMESPACE::HASH_SET_CLASS<
    Key, HashFcn, EqualKey> {
 public:
  hash_set(int = 0) {}
};

#endif

template <>
struct hash<string> {
  inline size_t operator()(const string& key) const {
    return hash<const char*>()(key.c_str());
  }

  static const size_t bucket_size = 4;
  static const size_t min_buckets = 8;
  inline size_t operator()(const string& a, const string& b) const {
    return a < b;
  }
};

template <typename First, typename Second>
struct hash<pair<First, Second> > {
  inline size_t operator()(const pair<First, Second>& key) const {
    size_t first_hash = hash<First>()(key.first);
    size_t second_hash = hash<Second>()(key.second);

    // FIXME(kenton):  What is the best way to compute this hash?  I have
    // no idea!  This seems a bit better than an XOR.
    return first_hash * ((1 << 16) - 1) + second_hash;
  }

  static const size_t bucket_size = 4;
  static const size_t min_buckets = 8;
  inline size_t operator()(const pair<First, Second>& a,
                           const pair<First, Second>& b) const {
    return a < b;
  }
};

// Used by GCC/SGI STL only.  (Why isn't this provided by the standard
// library?  :( )
struct streq {
  inline bool operator()(const char* a, const char* b) const {
    return strcmp(a, b) == 0;
  }
};

}  // namespace protobuf
}  // namespace google

#endif  // GOOGLE_PROTOBUF_STUBS_HASH_H__
