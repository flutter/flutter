// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/json/json_string_value_serializer.h"

#include "base/json/json_reader.h"
#include "base/json/json_writer.h"
#include "base/logging.h"

using base::Value;

JSONStringValueSerializer::JSONStringValueSerializer(std::string* json_string)
    : json_string_(json_string),
      pretty_print_(false) {
}

JSONStringValueSerializer::~JSONStringValueSerializer() {}

bool JSONStringValueSerializer::Serialize(const Value& root) {
  return SerializeInternal(root, false);
}

bool JSONStringValueSerializer::SerializeAndOmitBinaryValues(
    const Value& root) {
  return SerializeInternal(root, true);
}

bool JSONStringValueSerializer::SerializeInternal(const Value& root,
                                                  bool omit_binary_values) {
  if (!json_string_)
    return false;

  int options = 0;
  if (omit_binary_values)
    options |= base::JSONWriter::OPTIONS_OMIT_BINARY_VALUES;
  if (pretty_print_)
    options |= base::JSONWriter::OPTIONS_PRETTY_PRINT;

  return base::JSONWriter::WriteWithOptions(root, options, json_string_);
}

JSONStringValueDeserializer::JSONStringValueDeserializer(
    const base::StringPiece& json_string)
    : json_string_(json_string),
      allow_trailing_comma_(false) {
}

JSONStringValueDeserializer::~JSONStringValueDeserializer() {}

Value* JSONStringValueDeserializer::Deserialize(int* error_code,
                                                std::string* error_str) {
  return base::JSONReader::DeprecatedReadAndReturnError(
      json_string_, allow_trailing_comma_ ? base::JSON_ALLOW_TRAILING_COMMAS
                                          : base::JSON_PARSE_RFC,
      error_code, error_str);
}
