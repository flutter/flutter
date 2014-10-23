/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef DictionaryHelperForBindings_h
#define DictionaryHelperForBindings_h

#include "bindings/core/v8/Dictionary.h"

namespace blink {

template <typename T>
struct DictionaryHelperTraits {
};

template <template <typename> class PointerType, typename T>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, PointerType<T>& value)
{
    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value))
        return false;

    value = DictionaryHelperTraits<T>::type::toNativeWithTypeCheck(dictionary.isolate(), v8Value);
    return true;
}

template <template <typename> class PointerType, typename T>
bool DictionaryHelper::convert(const Dictionary& dictionary, Dictionary::ConversionContext& context, const String& key, PointerType<T>& value)
{
    Dictionary::ConversionContextScope scope(context);

    if (!DictionaryHelper::get(dictionary, key, value))
        return true;

    if (value)
        return true;

    v8::Local<v8::Value> v8Value;
    dictionary.get(key, v8Value);
    if (context.isNullable() && blink::isUndefinedOrNull(v8Value))
        return true;

    context.throwTypeError(ExceptionMessages::incorrectPropertyType(key, "does not have a " + context.typeName() + " type."));
    return false;
}

} // namespace blink

#endif // DictionaryHelperForBindings_h
