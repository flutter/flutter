// Copyright (c) 2007, Google Inc.
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

// ---
// Author: Geoff Pike
//
// This file provides a minimal cache that can hold a <key, value> pair
// with little if any wasted space.  The types of the key and value
// must be unsigned integral types or at least have unsigned semantics
// for >>, casting, and similar operations.
//
// Synchronization is not provided.  However, the cache is implemented
// as an array of cache entries whose type is chosen at compile time.
// If a[i] is atomic on your hardware for the chosen array type then
// raciness will not necessarily lead to bugginess.  The cache entries
// must be large enough to hold a partial key and a value packed
// together.  The partial keys are bit strings of length
// kKeybits - kHashbits, and the values are bit strings of length kValuebits.
//
// In an effort to use minimal space, every cache entry represents
// some <key, value> pair; the class provides no way to mark a cache
// entry as empty or uninitialized.  In practice, you may want to have
// reserved keys or values to get around this limitation.  For example, in
// tcmalloc's PageID-to-sizeclass cache, a value of 0 is used as
// "unknown sizeclass."
//
// Usage Considerations
// --------------------
//
// kHashbits controls the size of the cache.  The best value for
// kHashbits will of course depend on the application.  Perhaps try
// tuning the value of kHashbits by measuring different values on your
// favorite benchmark.  Also remember not to be a pig; other
// programs that need resources may suffer if you are.
//
// The main uses for this class will be when performance is
// critical and there's a convenient type to hold the cache's
// entries.  As described above, the number of bits required
// for a cache entry is (kKeybits - kHashbits) + kValuebits.  Suppose
// kKeybits + kValuebits is 43.  Then it probably makes sense to
// chose kHashbits >= 11 so that cache entries fit in a uint32.
//
// On the other hand, suppose kKeybits = kValuebits = 64.  Then
// using this class may be less worthwhile.  You'll probably
// be using 128 bits for each entry anyway, so maybe just pick
// a hash function, H, and use an array indexed by H(key):
//    void Put(K key, V value) { a_[H(key)] = pair<K, V>(key, value); }
//    V GetOrDefault(K key, V default) { const pair<K, V> &p = a_[H(key)]; ... }
//    etc.
//
// Further Details
// ---------------
//
// For caches used only by one thread, the following is true:
// 1. For a cache c,
//      (c.Put(key, value), c.GetOrDefault(key, 0)) == value
//    and
//      (c.Put(key, value), <...>, c.GetOrDefault(key, 0)) == value
//    if the elided code contains no c.Put calls.
//
// 2. Has(key) will return false if no <key, value> pair with that key
//    has ever been Put.  However, a newly initialized cache will have
//    some <key, value> pairs already present.  When you create a new
//    cache, you must specify an "initial value."  The initialization
//    procedure is equivalent to Clear(initial_value), which is
//    equivalent to Put(k, initial_value) for all keys k from 0 to
//    2^kHashbits - 1.
//
// 3. If key and key' differ then the only way Put(key, value) may
//    cause Has(key') to change is that Has(key') may change from true to
//    false. Furthermore, a Put() call that doesn't change Has(key')
//    doesn't change GetOrDefault(key', ...) either.
//
// Implementation details:
//
// This is a direct-mapped cache with 2^kHashbits entries; the hash
// function simply takes the low bits of the key.  We store whole keys
// if a whole key plus a whole value fits in an entry.  Otherwise, an
// entry is the high bits of a key and a value, packed together.
// E.g., a 20 bit key and a 7 bit value only require a uint16 for each
// entry if kHashbits >= 11.
//
// Alternatives to this scheme will be added as needed.

#ifndef TCMALLOC_PACKED_CACHE_INL_H_
#define TCMALLOC_PACKED_CACHE_INL_H_

#include "config.h"
#include <stddef.h>                     // for size_t
#ifdef HAVE_STDINT_H
#include <stdint.h>                     // for uintptr_t
#endif
#include "base/basictypes.h"
#include "internal_logging.h"

// A safe way of doing "(1 << n) - 1" -- without worrying about overflow
// Note this will all be resolved to a constant expression at compile-time
#define N_ONES_(IntType, N)                                     \
  ( (N) == 0 ? 0 : ((static_cast<IntType>(1) << ((N)-1))-1 +    \
                    (static_cast<IntType>(1) << ((N)-1))) )

// The types K and V provide upper bounds on the number of valid keys
// and values, but we explicitly require the keys to be less than
// 2^kKeybits and the values to be less than 2^kValuebits.  The size of
// the table is controlled by kHashbits, and the type of each entry in
// the cache is T.  See also the big comment at the top of the file.
template <int kKeybits, typename T>
class PackedCache {
 public:
  typedef uintptr_t K;
  typedef size_t V;
#ifdef TCMALLOC_SMALL_BUT_SLOW
  // Decrease the size map cache if running in the small memory mode.
  static const int kHashbits = 12;
#else
  // We don't want the hash map to occupy 512K memory at Chromium, so
  // kHashbits is decreased from 16 to 12.
  static const int kHashbits = 12;
#endif
  static const int kValuebits = 7;
  static const bool kUseWholeKeys = kKeybits + kValuebits <= 8 * sizeof(T);

  explicit PackedCache(V initial_value) {
    COMPILE_ASSERT(kKeybits <= sizeof(K) * 8, key_size);
    COMPILE_ASSERT(kValuebits <= sizeof(V) * 8, value_size);
    COMPILE_ASSERT(kHashbits <= kKeybits, hash_function);
    COMPILE_ASSERT(kKeybits - kHashbits + kValuebits <= kTbits,
                   entry_size_must_be_big_enough);
    Clear(initial_value);
  }

  void Put(K key, V value) {
    ASSERT(key == (key & kKeyMask));
    ASSERT(value == (value & kValueMask));
    array_[Hash(key)] = KeyToUpper(key) | value;
  }

  bool Has(K key) const {
    ASSERT(key == (key & kKeyMask));
    return KeyMatch(array_[Hash(key)], key);
  }

  V GetOrDefault(K key, V default_value) const {
    // As with other code in this class, we touch array_ as few times
    // as we can.  Assuming entries are read atomically (e.g., their
    // type is uintptr_t on most hardware) then certain races are
    // harmless.
    ASSERT(key == (key & kKeyMask));
    T entry = array_[Hash(key)];
    return KeyMatch(entry, key) ? EntryToValue(entry) : default_value;
  }

  void Clear(V value) {
    ASSERT(value == (value & kValueMask));
    for (int i = 0; i < 1 << kHashbits; i++) {
      ASSERT(kUseWholeKeys || KeyToUpper(i) == 0);
      array_[i] = kUseWholeKeys ? (value | KeyToUpper(i)) : value;
    }
  }

 private:
  // We are going to pack a value and the upper part of a key (or a
  // whole key) into an entry of type T.  The UPPER type is for the
  // upper part of a key, after the key has been masked and shifted
  // for inclusion in an entry.
  typedef T UPPER;

  static V EntryToValue(T t) { return t & kValueMask; }

  // If we have space for a whole key, we just shift it left.
  // Otherwise kHashbits determines where in a K to find the upper
  // part of the key, and kValuebits determines where in the entry to
  // put it.
  static UPPER KeyToUpper(K k) {
    if (kUseWholeKeys) {
      return static_cast<T>(k) << kValuebits;
    } else {
      const int shift = kHashbits - kValuebits;
      // Assume kHashbits >= kValuebits.  It'd be easy to lift this assumption.
      return static_cast<T>(k >> shift) & kUpperMask;
    }
  }

  static size_t Hash(K key) {
    return static_cast<size_t>(key) & N_ONES_(size_t, kHashbits);
  }

  // Does the entry match the relevant part of the given key?
  static bool KeyMatch(T entry, K key) {
    return kUseWholeKeys ?
        (entry >> kValuebits == key) :
        ((KeyToUpper(key) ^ entry) & kUpperMask) == 0;
  }

  static const int kTbits = 8 * sizeof(T);
  static const int kUpperbits = kUseWholeKeys ? kKeybits : kKeybits - kHashbits;

  // For masking a K.
  static const K kKeyMask = N_ONES_(K, kKeybits);

  // For masking a T.
  static const T kUpperMask = N_ONES_(T, kUpperbits) << kValuebits;

  // For masking a V or a T.
  static const V kValueMask = N_ONES_(V, kValuebits);

  // array_ is the cache.  Its elements are volatile because any
  // thread can write any array element at any time.
  volatile T array_[1 << kHashbits];
};

#undef N_ONES_

#endif  // TCMALLOC_PACKED_CACHE_INL_H_
