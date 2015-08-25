// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_CONVERTERS_BASE_BASE_TYPE_CONVERTERS_H_
#define MOJO_CONVERTERS_BASE_BASE_TYPE_CONVERTERS_H_

#include "base/strings/string16.h"
#include "base/strings/string_piece.h"
#include "mojo/public/cpp/bindings/array.h"
#include "mojo/public/cpp/bindings/string.h"
#include "mojo/public/cpp/bindings/type_converter.h"

namespace mojo {

template <>
struct TypeConverter<String, base::StringPiece> {
  static String Convert(const base::StringPiece& input);
};

template <>
struct TypeConverter<base::StringPiece, String> {
  static base::StringPiece Convert(const String& input);
};

template <>
struct TypeConverter<String, base::string16> {
  static String Convert(const base::string16& input);
};

template <>
struct TypeConverter<base::string16, String> {
  static base::string16 Convert(const String& input);
};

}  // namespace mojo

#endif  // MOJO_CONVERTERS_BASE_BASE_TYPE_CONVERTERS_H_
