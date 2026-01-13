// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_TESTING_TESTER_CONTEXT_MTL_FACTORY_H_
#define FLUTTER_SHELL_TESTING_TESTER_CONTEXT_MTL_FACTORY_H_

#include <memory>
#include "flutter/shell/testing/tester_context.h"

// Impeller should only be enabled if the Metal backend is enabled.
#define TESTER_ENABLE_METAL \
  (IMPELLER_SUPPORTS_RENDERING && IMPELLER_ENABLE_METAL)

namespace flutter {

class TesterContextMTLFactory {
 public:
  static std::unique_ptr<TesterContext> Create();
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_TESTING_TESTER_CONTEXT_MTL_FACTORY_H_
