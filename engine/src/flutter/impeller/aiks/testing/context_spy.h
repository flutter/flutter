// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include "impeller/aiks/testing/context_mock.h"

namespace impeller {
namespace testing {

/// Forwards calls to a real Context but can store information about how
/// the Context was used.
class ContextSpy : public std::enable_shared_from_this<ContextSpy> {
 public:
  static std::shared_ptr<ContextSpy> Make();

  std::shared_ptr<ContextMock> MakeContext(
      const std::shared_ptr<Context>& real_context);

  std::vector<std::shared_ptr<RenderPass>> render_passes_;

 private:
  ContextSpy() = default;
};

}  // namespace testing

}  // namespace impeller
