// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef AnimationTestHelper_h
#define AnimationTestHelper_h

#include "wtf/text/WTFString.h"
#include <v8.h>

namespace blink {

v8::Handle<v8::Value> stringToV8Value(String);

v8::Handle<v8::Value> doubleToV8Value(double);

void setV8ObjectPropertyAsString(v8::Handle<v8::Object>, String, String);

void setV8ObjectPropertyAsNumber(v8::Handle<v8::Object>, String, double);

} // namespace blink

#endif // AnimationTestHelper_h
