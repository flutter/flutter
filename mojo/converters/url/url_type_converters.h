// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_CONVERTERS_URL_URL_TYPE_CONVERTERS_H_
#define MOJO_CONVERTERS_URL_URL_TYPE_CONVERTERS_H_

#include "mojo/public/cpp/bindings/type_converter.h"
#include "mojo/public/cpp/bindings/string.h"

class GURL;

namespace mojo {
template <>
struct TypeConverter<String, GURL> {
  static String Convert(const GURL& input);
};

template <>
struct TypeConverter<GURL, String> {
  static GURL Convert(const String& input);
};

}  // namespace mojo

#endif  // MOJO_CONVERTERS_URL_URL_TYPE_CONVERTERS_H_
