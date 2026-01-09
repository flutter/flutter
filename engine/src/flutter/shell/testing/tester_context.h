// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_TESTING_TESTER_CONTEXT_H_
#define FLUTTER_SHELL_TESTING_TESTER_CONTEXT_H_

#include <memory>

#include "flutter/flow/surface.h"
#include "flutter/impeller/renderer/context.h"

namespace flutter {

class TesterContext {
 public:
  virtual ~TesterContext() = default;

  virtual std::shared_ptr<impeller::Context> GetImpellerContext() const = 0;

  virtual std::unique_ptr<Surface> CreateRenderingSurface() = 0;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_TESTING_TESTER_CONTEXT_H_
