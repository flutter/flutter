// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_TESTING_ENCODABLE_VALUE_UTILS_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_TESTING_ENCODABLE_VALUE_UTILS_H_

#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/encodable_value.h"

namespace flutter {
namespace testing {

// Returns true if |a| and |b| have equivalent values, recursively comparing
// the contents of collections (unlike the < operator defined on EncodableValue,
// which doesn't consider different collections with the same contents to be
// the same).
bool EncodableValuesAreEqual(const EncodableValue& a, const EncodableValue& b);

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_TESTING_ENCODABLE_VALUE_UTILS_H_
