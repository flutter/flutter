/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_BINDINGS_CORE_V8_V8PERSISTENTVALUEMAP_H_
#define SKY_ENGINE_BINDINGS_CORE_V8_V8PERSISTENTVALUEMAP_H_

#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/text/StringHash.h"
#include "v8/include/v8-util.h"
#include "v8/include/v8.h"

namespace blink {

/**
 * A Traits class for v8::PersistentValueMap that uses wtf/HashMap as a
 * backing store.
 *
 * The parameter is_weak will determine whether the references are 'weak'.
 * If so, entries will be removed from the map as the weak references are
 * collected.
 */
template<class KeyType, class ValueType, bool is_weak>
class V8PersistentValueMapTraits {
public:
    // Map traits:
    typedef HashMap<KeyType, v8::PersistentContainerValue> Impl;
    typedef typename Impl::iterator Iterator;
    static size_t Size(const Impl* impl) { return impl->size(); }
    static bool Empty(Impl* impl) { return impl->isEmpty(); }
    static void Swap(Impl& impl, Impl& other) { impl.swap(other); }
    static Iterator Begin(Impl* impl) { return impl->begin(); }
    static Iterator End(Impl* impl) { return impl->end(); }
    static v8::PersistentContainerValue Value(Iterator& iter)
    {
        return iter->value;
    }
    static KeyType Key(Iterator& iter) { return iter->key; }
    static v8::PersistentContainerValue Set(
        Impl* impl, KeyType key, v8::PersistentContainerValue value)
    {
        v8::PersistentContainerValue oldValue = Get(impl, key);
        impl->set(key, value);
        return oldValue;
    }
    static v8::PersistentContainerValue Get(const Impl* impl, KeyType key)
    {
        return impl->get(key);
    }

    static v8::PersistentContainerValue Remove(Impl* impl, KeyType key)
    {
        return impl->take(key);
    }

    // Weak traits:
    static const v8::PersistentContainerCallbackType kCallbackType = is_weak ? v8::kWeak : v8::kNotWeak;
    typedef v8::PersistentValueMap<KeyType, ValueType, V8PersistentValueMapTraits<KeyType, ValueType, is_weak> > MapType;

    typedef void WeakCallbackDataType;

    static WeakCallbackDataType* WeakCallbackParameter(MapType* map, KeyType key, const v8::Local<ValueType>& value)
    {
        return 0;
    }

    static void DisposeCallbackData(WeakCallbackDataType* callbackData)
    {
    }

    static MapType* MapFromWeakCallbackData(
        const v8::WeakCallbackData<ValueType, WeakCallbackDataType>& data)
    {
        return 0;
    }

    static KeyType KeyFromWeakCallbackData(
        const v8::WeakCallbackData<ValueType, WeakCallbackDataType>& data)
    {
        return KeyType();
    }

    // Dispose traits:
    static void Dispose(v8::Isolate* isolate, v8::UniquePersistent<ValueType> value, KeyType key) { }
};

/**
 * A map for safely storing persistent V8 values, based on
 * v8::PersistentValueMap.
 *
 * If is_weak is set, values will be held weakly and map entries will be
 * removed as their values are being collected.
 */
template<class KeyType, class ValueType, bool is_weak = true>
class V8PersistentValueMap : public v8::PersistentValueMap<KeyType, ValueType, V8PersistentValueMapTraits<KeyType, ValueType, is_weak> > {
public:
    typedef V8PersistentValueMapTraits<KeyType, ValueType, is_weak> Traits;
    explicit V8PersistentValueMap(v8::Isolate* isolate) : v8::PersistentValueMap<KeyType, ValueType, Traits>(isolate) { }
};

} // namespace blink

#endif  // SKY_ENGINE_BINDINGS_CORE_V8_V8PERSISTENTVALUEMAP_H_
