// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/tonic/dart_string_cache.h"

#include "sky/engine/tonic/dart_state.h"
#include "sky/engine/tonic/dart_string.h"

namespace blink {

DartStringCache::DartStringCache() : last_dart_string_(nullptr) {
}

DartStringCache::~DartStringCache() {
}

Dart_WeakPersistentHandle DartStringCache::GetSlow(StringImpl* string_impl,
                                                   bool auto_scope) {
  if (Dart_WeakPersistentHandle string = cache_.get(string_impl)) {
    last_dart_string_ = string;
    last_string_impl_ = string_impl;
    return string;
  }

  if (!auto_scope)
    Dart_EnterScope();

  Dart_Handle string = CreateDartString(string_impl);
  DCHECK(!Dart_IsError(string));

  intptr_t size_in_bytes = string_impl->sizeInBytes();
  Dart_WeakPersistentHandle wrapper = Dart_NewWeakPersistentHandle(
      string, string_impl, size_in_bytes, FinalizeCacheEntry);

  string_impl->ref();  // Balanced in FinalizeCacheEntry.
  cache_.set(string_impl, wrapper);

  last_dart_string_ = wrapper;
  last_string_impl_ = string_impl;

  if (!auto_scope)
    Dart_ExitScope();

  return wrapper;
}

void DartStringCache::FinalizeCacheEntry(void* isolate_callback_data,
                                         Dart_WeakPersistentHandle handle,
                                         void* peer) {
  DartState* state = reinterpret_cast<DartState*>(isolate_callback_data);
  StringImpl* string_impl = reinterpret_cast<StringImpl*>(peer);
  DartStringCache& cache = state->string_cache();

  Dart_WeakPersistentHandle cached_handle = cache.cache_.take(string_impl);
  ASSERT_UNUSED(cached_handle, handle == cached_handle);

  if (cache.last_dart_string_ == handle) {
    cache.last_dart_string_ = nullptr;
    cache.last_string_impl_ = nullptr;
  }

  string_impl->deref();
}

}  // namespace blink
