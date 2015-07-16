// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_JSON_JSON_WRITER_H_
#define BASE_JSON_JSON_WRITER_H_

#include <string>

#include "base/base_export.h"
#include "base/basictypes.h"

namespace base {

class Value;

class BASE_EXPORT JSONWriter {
 public:
  enum Options {
    // This option instructs the writer that if a Binary value is encountered,
    // the value (and key if within a dictionary) will be omitted from the
    // output, and success will be returned. Otherwise, if a binary value is
    // encountered, failure will be returned.
    OPTIONS_OMIT_BINARY_VALUES = 1 << 0,

    // This option instructs the writer to write doubles that have no fractional
    // part as a normal integer (i.e., without using exponential notation
    // or appending a '.0') as long as the value is within the range of a
    // 64-bit int.
    OPTIONS_OMIT_DOUBLE_TYPE_PRESERVATION = 1 << 1,

    // Return a slightly nicer formatted json string (pads with whitespace to
    // help with readability).
    OPTIONS_PRETTY_PRINT = 1 << 2,
  };

  // Given a root node, generates a JSON string and puts it into |json|.
  // TODO(tc): Should we generate json if it would be invalid json (e.g.,
  // |node| is not a DictionaryValue/ListValue or if there are inf/-inf float
  // values)? Return true on success and false on failure.
  static bool Write(const Value& node, std::string* json);

  // Same as above but with |options| which is a bunch of JSONWriter::Options
  // bitwise ORed together. Return true on success and false on failure.
  static bool WriteWithOptions(const Value& node,
                               int options,
                               std::string* json);

 private:
  JSONWriter(int options, std::string* json);

  // Called recursively to build the JSON string. When completed,
  // |json_string_| will contain the JSON.
  bool BuildJSONString(const Value& node, size_t depth);

  // Adds space to json_string_ for the indent level.
  void IndentLine(size_t depth);

  bool omit_binary_values_;
  bool omit_double_type_preservation_;
  bool pretty_print_;

  // Where we write JSON data as we generate it.
  std::string* json_string_;

  DISALLOW_COPY_AND_ASSIGN(JSONWriter);
};

}  // namespace base

#endif  // BASE_JSON_JSON_WRITER_H_
