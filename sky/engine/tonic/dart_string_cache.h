// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_DART_STRING_CACHE_H_
#define SKY_ENGINE_TONIC_DART_STRING_CACHE_H_

#include "base/logging.h"
#include "dart/runtime/include/dart_api.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/text/StringHash.h"
#include "sky/engine/wtf/text/StringImpl.h"

namespace blink {

// DartStringCache maintains a mapping between WTF Strings and Dart strings.
// When you create a Dart string from a WTF String, the underlying character
// data is shared between the two systems.
class DartStringCache {
 public:
  DartStringCache();
  ~DartStringCache();

  Dart_WeakPersistentHandle Get(StringImpl* string_impl,
                                bool auto_scope = true) {
    DCHECK(string_impl);
    if (last_string_impl_.get() == string_impl)
      return last_dart_string_;
    return GetSlow(string_impl, auto_scope);
  }

 private:
  Dart_WeakPersistentHandle GetSlow(StringImpl* string_impl, bool auto_scope);
  static void FinalizeCacheEntry(void*, Dart_WeakPersistentHandle, void* peer);

  typedef HashMap<StringImpl*, Dart_WeakPersistentHandle> StringCache;

  StringCache cache_;
  Dart_WeakPersistentHandle last_dart_string_;
  RefPtr<StringImpl> last_string_impl_;

  DISALLOW_COPY_AND_ASSIGN(DartStringCache);
};

}  // namespace blink

#endif  // SKY_ENGINE_TONIC_DART_STRING_CACHE_H_
