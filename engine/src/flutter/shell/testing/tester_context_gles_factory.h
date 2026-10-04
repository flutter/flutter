// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_TESTING_TESTER_CONTEXT_GLES_FACTORY_H_
#define FLUTTER_SHELL_TESTING_TESTER_CONTEXT_GLES_FACTORY_H_

#include <memory>
#include "flutter/shell/testing/tester_context.h"

// Impeller should only be enabled if the OpenGLES backend is enabled.
#define TESTER_ENABLE_OPENGLES \
  (IMPELLER_SUPPORTS_RENDERING && IMPELLER_ENABLE_OPENGLES && SHELL_ENABLE_GL)

namespace flutter {

class TesterContextGLESFactory {
 public:
  static std::unique_ptr<TesterContext> Create();
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_TESTING_TESTER_CONTEXT_GLES_FACTORY_H_
