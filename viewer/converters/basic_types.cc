// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/converters/basic_types.h"

#include "mojo/public/cpp/bindings/string.h"
#include "sky/engine/public/platform/WebString.h"

using blink::WebString;

namespace mojo {

// static
String TypeConverter<String, WebString>::Convert(const WebString& str) {
  return String(str.utf8());
}

// static
WebString TypeConverter<WebString, String>::Convert(const String& str) {
  return WebString::fromUTF8(str.get());
}

}  // namespace mojo
