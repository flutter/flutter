// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CONVERTERS_BASIC_TYPES_H_
#define SKY_VIEWER_CONVERTERS_BASIC_TYPES_H_

#include "mojo/public/cpp/bindings/array.h"
#include "mojo/public/cpp/bindings/type_converter.h"
#include "sky/engine/public/platform/WebVector.h"

namespace blink {
class WebString;
}

namespace mojo {
class String;

template<>
struct TypeConverter<String, blink::WebString> {
  static String Convert(const blink::WebString& str);
};
template<>
struct TypeConverter<blink::WebString, String> {
  static blink::WebString Convert(const String& str);
};

template<typename T, typename U>
struct TypeConverter<Array<T>, blink::WebVector<U> > {
  static Array<T> Convert(const blink::WebVector<U>& vector) {
    Array<T> array(vector.size());
    for (size_t i = 0; i < vector.size(); ++i)
      array[i] = TypeConverter<T, U>::Convert(vector[i]);
    return array.Pass();
  }
};

}  // namespace mojo

#endif  // SKY_VIEWER_CONVERTERS_BASIC_TYPES_H_
