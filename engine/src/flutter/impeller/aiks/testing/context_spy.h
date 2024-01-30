// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_AIKS_TESTING_CONTEXT_SPY_H_
#define FLUTTER_IMPELLER_AIKS_TESTING_CONTEXT_SPY_H_

#include <memory>

#include "impeller/aiks/testing/context_mock.h"
#include "impeller/entity/contents/test/recording_render_pass.h"
#include "impeller/renderer/command_queue.h"

namespace impeller {
namespace testing {

class NoopCommandQueue : public CommandQueue {
 public:
  fml::Status Submit(
      const std::vector<std::shared_ptr<CommandBuffer>>& buffers,
      const CompletionCallback& completion_callback = {}) override;
};

/// Forwards calls to a real Context but can store information about how
/// the Context was used.
class ContextSpy : public std::enable_shared_from_this<ContextSpy> {
 public:
  static std::shared_ptr<ContextSpy> Make();

  std::shared_ptr<ContextMock> MakeContext(
      const std::shared_ptr<Context>& real_context);

  std::vector<std::shared_ptr<RecordingRenderPass>> render_passes_;
  std::shared_ptr<CommandQueue> command_queue_ =
      std::make_shared<NoopCommandQueue>();

 private:
  ContextSpy() = default;
};

}  // namespace testing

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_AIKS_TESTING_CONTEXT_SPY_H_
