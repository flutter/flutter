// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/common/cpp/client_wrapper/testing/encodable_value_utils.h"

#include <cmath>

namespace flutter {
namespace testing {

bool EncodableValuesAreEqual(const EncodableValue& a, const EncodableValue& b) {
  if (a.type() != b.type()) {
    return false;
  }

  switch (a.type()) {
    case EncodableValue::Type::kNull:
      return true;
    case EncodableValue::Type::kBool:
      return a.BoolValue() == b.BoolValue();
    case EncodableValue::Type::kInt:
      return a.IntValue() == b.IntValue();
    case EncodableValue::Type::kLong:
      return a.LongValue() == b.LongValue();
    case EncodableValue::Type::kDouble:
      // This is a crude epsilon, but fine for the values in the unit tests.
      return std::abs(a.DoubleValue() - b.DoubleValue()) < 0.0001l;
    case EncodableValue::Type::kString:
      return a.StringValue() == b.StringValue();
    case EncodableValue::Type::kByteList:
      return a.ByteListValue() == b.ByteListValue();
    case EncodableValue::Type::kIntList:
      return a.IntListValue() == b.IntListValue();
    case EncodableValue::Type::kLongList:
      return a.LongListValue() == b.LongListValue();
    case EncodableValue::Type::kDoubleList:
      return a.DoubleListValue() == b.DoubleListValue();
    case EncodableValue::Type::kList: {
      const auto& a_list = a.ListValue();
      const auto& b_list = b.ListValue();
      if (a_list.size() != b_list.size()) {
        return false;
      }
      for (size_t i = 0; i < a_list.size(); ++i) {
        if (!EncodableValuesAreEqual(a_list[0], b_list[0])) {
          return false;
        }
      }
      return true;
    }
    case EncodableValue::Type::kMap: {
      const auto& a_map = a.MapValue();
      const auto& b_map = b.MapValue();
      if (a_map.size() != b_map.size()) {
        return false;
      }
      // Store references to all the keys in |b|.
      std::vector<const EncodableValue*> unmatched_b_keys;
      for (auto& pair : b_map) {
        unmatched_b_keys.push_back(&pair.first);
      }
      // For each key,value in |a|, see if any of the not-yet-matched key,value
      // pairs in |b| match by value; if so, remove that match and continue.
      for (const auto& pair : a_map) {
        bool found_match = false;
        for (size_t i = 0; i < unmatched_b_keys.size(); ++i) {
          const EncodableValue& b_key = *unmatched_b_keys[i];
          if (EncodableValuesAreEqual(pair.first, b_key) &&
              EncodableValuesAreEqual(pair.second, b_map.at(b_key))) {
            found_match = true;
            unmatched_b_keys.erase(unmatched_b_keys.begin() + i);
            break;
          }
        }
        if (!found_match) {
          return false;
        }
      }
      // If all entries had matches, consider the maps equal.
      return true;
    }
  }
  assert(false);
  return false;
}

}  // namespace testing
}  // namespace flutter
