/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#ifndef V8Converter_h
#define V8Converter_h

#include <dart_api.h>
#include <v8.h>

namespace blink {

class DartDOMData;
class DartToV8Map;
class V8ToDartMap;

class V8Converter {
public:
    static v8::Handle<v8::Value> toV8(Dart_Handle value, Dart_Handle& exception);
    static Dart_Handle toDart(v8::Handle<v8::Value> value, Dart_Handle& exception);

    static v8::Handle<v8::Value> toV8IfPrimitive(DartDOMData*, Dart_Handle value, Dart_Handle& exception);
    static Dart_Handle toDartIfPrimitive(v8::Handle<v8::Value>);

    static v8::Handle<v8::Value> toV8IfBrowserNative(DartDOMData*, Dart_Handle value, Dart_Handle& exception);
    static Dart_Handle toDartIfBrowserNative(v8::Handle<v8::Object>, v8::Isolate*, Dart_Handle& exception);

    static v8::Handle<v8::String> stringToV8(Dart_Handle);
    static Dart_Handle stringToDart(v8::Handle<v8::Value>);

    static v8::Handle<v8::Value> booleanToV8(Dart_Handle);

    static v8::Handle<v8::Value> numberToV8(Dart_Handle);

    static v8::Handle<v8::Value> listToV8(Dart_Handle);

    static v8::Handle<v8::Value> dateToV8(Dart_Handle);
    static Dart_Handle dateToDart(v8::Handle<v8::Value>);

    static v8::Handle<v8::Value> nodeToV8(Dart_Handle, Dart_Handle& exception);
    static Dart_Handle nodeToDart(v8::Handle<v8::Value>);

    static v8::Handle<v8::Value> eventToV8(Dart_Handle, Dart_Handle& exception);
    static Dart_Handle eventToDart(v8::Handle<v8::Value>);

    static v8::Handle<v8::Value> windowToV8(Dart_Handle, Dart_Handle& exception);
    static Dart_Handle windowToDart(v8::Handle<v8::Value>);

private:
    static v8::Handle<v8::Value> toV8(Dart_Handle value, DartToV8Map&, Dart_Handle& exception);
    static Dart_Handle toDart(v8::Handle<v8::Value>, V8ToDartMap&, Dart_Handle& exception);
    static v8::Handle<v8::Value> numberToV8(Dart_Handle, Dart_Handle& exception);
    static v8::Handle<v8::Value> listToV8(Dart_Handle, DartToV8Map&, Dart_Handle& exception);
    static Dart_Handle listToDart(v8::Handle<v8::Array>, V8ToDartMap&, Dart_Handle& exception);
    static v8::Handle<v8::Value> mapToV8(Dart_Handle, DartToV8Map&, Dart_Handle& exception);
    static Dart_Handle mapToDart(v8::Handle<v8::Object>, V8ToDartMap&, Dart_Handle& exception);
    static v8::Handle<v8::Value> arrayBufferToV8(Dart_Handle, Dart_Handle& exception);
    static Dart_Handle arrayBufferToDart(v8::Handle<v8::Object>, Dart_Handle& exception);
    static v8::Handle<v8::Value> arrayBufferViewToV8(Dart_Handle, Dart_Handle& exception);
    static Dart_Handle arrayBufferViewToDart(v8::Handle<v8::Object>, Dart_Handle& exception);
    static v8::Handle<v8::Value> dateToV8(Dart_Handle, Dart_Handle& exception);
    static Dart_Handle blobToDart(v8::Handle<v8::Object>, Dart_Handle& exception);
    static v8::Handle<v8::Value> blobToV8(Dart_Handle, Dart_Handle& exception);
    static Dart_Handle imageDataToDart(v8::Handle<v8::Object>, Dart_Handle& exception);
    static v8::Handle<v8::Value> imageDataToV8(Dart_Handle, Dart_Handle& exception);
    static Dart_Handle idbKeyRangeToDart(v8::Handle<v8::Object>, Dart_Handle& exception);
    static v8::Handle<v8::Value> idbKeyRangeToV8(Dart_Handle, Dart_Handle& exception);
    static Dart_Handle idbDatabaseToDart(v8::Handle<v8::Object>, Dart_Handle& exception);
    static Dart_Handle idbCursorToDart(v8::Handle<v8::Object>, Dart_Handle& exception);
    static Dart_Handle idbCursorWithValueToDart(v8::Handle<v8::Object>, Dart_Handle& exception);
    static Dart_Handle idbFactoryToDart(v8::Handle<v8::Object>, Dart_Handle& exception);
    static Dart_Handle domStringListToDart(v8::Handle<v8::Object>, Dart_Handle& exception);
    static v8::Handle<v8::Value> domStringListToV8(Dart_Handle, Dart_Handle& exception);
};

}

#endif // V8Converter_h
