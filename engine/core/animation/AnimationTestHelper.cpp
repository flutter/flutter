// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/animation/AnimationTestHelper.h"

#include "bindings/core/v8/V8Binding.h"

namespace blink {

v8::Handle<v8::Value> stringToV8Value(String string)
{
    return v8::Handle<v8::Value>::Cast(v8String(v8::Isolate::GetCurrent(), string));
}

v8::Handle<v8::Value> doubleToV8Value(double number)
{
    return v8::Handle<v8::Value>::Cast(v8::Number::New(v8::Isolate::GetCurrent(), number));
}

void setV8ObjectPropertyAsString(v8::Handle<v8::Object> object, String name, String value)
{
    object->Set(stringToV8Value(name), stringToV8Value(value));
}

void setV8ObjectPropertyAsNumber(v8::Handle<v8::Object> object, String name, double value)
{
    object->Set(stringToV8Value(name), doubleToV8Value(value));
}

} // namespace blink
