// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/gles2_cmd_decoder_mock.h"

namespace gpu {
namespace gles2 {

MockGLES2Decoder::MockGLES2Decoder()
    : GLES2Decoder() {
  ON_CALL(*this, GetCommandName(testing::_))
      .WillByDefault(testing::Return(""));
  ON_CALL(*this, MakeCurrent())
      .WillByDefault(testing::Return(true));
}

MockGLES2Decoder::~MockGLES2Decoder() {}

error::Error MockGLES2Decoder::FakeDoCommands(unsigned int num_commands,
                                              const void* buffer,
                                              int num_entries,
                                              int* entries_processed) {
  return AsyncAPIInterface::DoCommands(
      num_commands, buffer, num_entries, entries_processed);
}

}  // namespace gles2
}  // namespace gpu
