// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/converters/array_string/array_string_type_converters.h"

#include <string>

#include "base/strings/utf_string_conversions.h"

namespace mojo {

std::string TypeConverter<std::string, Array<uint8_t>>::Convert(
    const Array<uint8_t>& input) {
  if (input.is_null())
    return std::string();

  return std::string(reinterpret_cast<const char*>(&input.front()),
                     input.size());
}

Array<uint8_t> TypeConverter<Array<uint8_t>, std::string>::Convert(
    const std::string& input) {
  Array<uint8_t> result(input.size());
  memcpy(&result.front(), input.c_str(), input.size());
  return result.Pass();
}

}  // namespace mojo
