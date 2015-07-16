// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/threading/thread.h"
#include "base/time/time.h"
#include "gpu/command_buffer/service/gpu_scheduler.h"
#include "gpu/command_buffer/service/mocks.h"

using testing::Invoke;
using testing::_;

namespace gpu {

AsyncAPIMock::AsyncAPIMock(bool default_do_commands) {
  testing::DefaultValue<error::Error>::Set(
      error::kNoError);

  if (default_do_commands) {
    ON_CALL(*this, DoCommands(_, _, _, _))
        .WillByDefault(Invoke(this, &AsyncAPIMock::FakeDoCommands));
  }
}

AsyncAPIMock::~AsyncAPIMock() {}

error::Error AsyncAPIMock::FakeDoCommands(unsigned int num_commands,
                                          const void* buffer,
                                          int num_entries,
                                          int* entries_processed) {
  return AsyncAPIInterface::DoCommands(
      num_commands, buffer, num_entries, entries_processed);
}

void AsyncAPIMock::SetToken(unsigned int command,
                            unsigned int arg_count,
                            const void* _args) {
  DCHECK(engine_);
  DCHECK_EQ(1u, command);
  DCHECK_EQ(1u, arg_count);
  const cmd::SetToken* args =
      static_cast<const cmd::SetToken*>(_args);
  engine_->set_token(args->token);
}

namespace gles2 {

MockShaderTranslator::MockShaderTranslator() {}

MockShaderTranslator::~MockShaderTranslator() {}

MockProgramCache::MockProgramCache() {}
MockProgramCache::~MockProgramCache() {}

MockMemoryTracker::MockMemoryTracker() {}
MockMemoryTracker::~MockMemoryTracker() {}

}  // namespace gles2
}  // namespace gpu


