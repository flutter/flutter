// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/json/json_writer.h"

#include <cmath>

#include "base/json/string_escape.h"
#include "base/logging.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/utf_string_conversions.h"
#include "base/values.h"

namespace base {

#if defined(OS_WIN)
const char kPrettyPrintLineEnding[] = "\r\n";
#else
const char kPrettyPrintLineEnding[] = "\n";
#endif

// static
bool JSONWriter::Write(const Value& node, std::string* json) {
  return WriteWithOptions(node, 0, json);
}

// static
bool JSONWriter::WriteWithOptions(const Value& node,
                                  int options,
                                  std::string* json) {
  json->clear();
  // Is there a better way to estimate the size of the output?
  json->reserve(1024);

  JSONWriter writer(options, json);
  bool result = writer.BuildJSONString(node, 0U);

  if (options & OPTIONS_PRETTY_PRINT)
    json->append(kPrettyPrintLineEnding);

  return result;
}

JSONWriter::JSONWriter(int options, std::string* json)
    : omit_binary_values_((options & OPTIONS_OMIT_BINARY_VALUES) != 0),
      omit_double_type_preservation_(
          (options & OPTIONS_OMIT_DOUBLE_TYPE_PRESERVATION) != 0),
      pretty_print_((options & OPTIONS_PRETTY_PRINT) != 0),
      json_string_(json) {
  DCHECK(json);
}

bool JSONWriter::BuildJSONString(const Value& node, size_t depth) {
  switch (node.GetType()) {
    case Value::TYPE_NULL: {
      json_string_->append("null");
      return true;
    }

    case Value::TYPE_BOOLEAN: {
      bool value;
      bool result = node.GetAsBoolean(&value);
      DCHECK(result);
      json_string_->append(value ? "true" : "false");
      return result;
    }

    case Value::TYPE_INTEGER: {
      int value;
      bool result = node.GetAsInteger(&value);
      DCHECK(result);
      json_string_->append(IntToString(value));
      return result;
    }

    case Value::TYPE_DOUBLE: {
      double value;
      bool result = node.GetAsDouble(&value);
      DCHECK(result);
      if (omit_double_type_preservation_ &&
          value <= kint64max &&
          value >= kint64min &&
          std::floor(value) == value) {
        json_string_->append(Int64ToString(static_cast<int64>(value)));
        return result;
      }
      std::string real = DoubleToString(value);
      // Ensure that the number has a .0 if there's no decimal or 'e'.  This
      // makes sure that when we read the JSON back, it's interpreted as a
      // real rather than an int.
      if (real.find('.') == std::string::npos &&
          real.find('e') == std::string::npos &&
          real.find('E') == std::string::npos) {
        real.append(".0");
      }
      // The JSON spec requires that non-integer values in the range (-1,1)
      // have a zero before the decimal point - ".52" is not valid, "0.52" is.
      if (real[0] == '.') {
        real.insert(static_cast<size_t>(0), static_cast<size_t>(1), '0');
      } else if (real.length() > 1 && real[0] == '-' && real[1] == '.') {
        // "-.1" bad "-0.1" good
        real.insert(static_cast<size_t>(1), static_cast<size_t>(1), '0');
      }
      json_string_->append(real);
      return result;
    }

    case Value::TYPE_STRING: {
      std::string value;
      bool result = node.GetAsString(&value);
      DCHECK(result);
      EscapeJSONString(value, true, json_string_);
      return result;
    }

    case Value::TYPE_LIST: {
      json_string_->push_back('[');
      if (pretty_print_)
        json_string_->push_back(' ');

      const ListValue* list = NULL;
      bool first_value_has_been_output = false;
      bool result = node.GetAsList(&list);
      DCHECK(result);
      for (ListValue::const_iterator it = list->begin(); it != list->end();
           ++it) {
        const Value* value = *it;
        if (omit_binary_values_ && value->GetType() == Value::TYPE_BINARY)
          continue;

        if (first_value_has_been_output) {
          json_string_->push_back(',');
          if (pretty_print_)
            json_string_->push_back(' ');
        }

        if (!BuildJSONString(*value, depth))
          result = false;

        first_value_has_been_output = true;
      }

      if (pretty_print_)
        json_string_->push_back(' ');
      json_string_->push_back(']');
      return result;
    }

    case Value::TYPE_DICTIONARY: {
      json_string_->push_back('{');
      if (pretty_print_)
        json_string_->append(kPrettyPrintLineEnding);

      const DictionaryValue* dict = NULL;
      bool first_value_has_been_output = false;
      bool result = node.GetAsDictionary(&dict);
      DCHECK(result);
      for (DictionaryValue::Iterator itr(*dict); !itr.IsAtEnd();
           itr.Advance()) {
        if (omit_binary_values_ &&
            itr.value().GetType() == Value::TYPE_BINARY) {
          continue;
        }

        if (first_value_has_been_output) {
          json_string_->push_back(',');
          if (pretty_print_)
            json_string_->append(kPrettyPrintLineEnding);
        }

        if (pretty_print_)
          IndentLine(depth + 1U);

        EscapeJSONString(itr.key(), true, json_string_);
        json_string_->push_back(':');
        if (pretty_print_)
          json_string_->push_back(' ');

        if (!BuildJSONString(itr.value(), depth + 1U))
          result = false;

        first_value_has_been_output = true;
      }

      if (pretty_print_) {
        json_string_->append(kPrettyPrintLineEnding);
        IndentLine(depth);
      }

      json_string_->push_back('}');
      return result;
    }

    case Value::TYPE_BINARY:
      // Successful only if we're allowed to omit it.
      DLOG_IF(ERROR, !omit_binary_values_) << "Cannot serialize binary value.";
      return omit_binary_values_;
  }
  NOTREACHED();
  return false;
}

void JSONWriter::IndentLine(size_t depth) {
  json_string_->append(depth * 3U, ' ');
}

}  // namespace base
