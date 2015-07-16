// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains the mock ErrorState class.

#ifndef GPU_COMMAND_BUFFER_SERVICE_ERROR_STATE_MOCK_H_
#define GPU_COMMAND_BUFFER_SERVICE_ERROR_STATE_MOCK_H_

#include "gpu/command_buffer/service/error_state.h"
#include "testing/gmock/include/gmock/gmock.h"

namespace gpu {
namespace gles2 {

class MockErrorState : public ErrorState {
 public:
  MockErrorState();
  virtual ~MockErrorState();

  MOCK_METHOD0(GetGLError, uint32_t());
  MOCK_METHOD5(SetGLError, void(
      const char* filename, int line,
      unsigned error, const char* function_name, const char* msg));
  MOCK_METHOD5(SetGLErrorInvalidEnum, void(
      const char* filename, int line,
      const char* function_name, unsigned value, const char* label));
  MOCK_METHOD6(SetGLErrorInvalidParami, void(
      const char* filename,
      int line,
      unsigned error,
      const char* function_name,
      unsigned pname,
      int param));
  MOCK_METHOD6(SetGLErrorInvalidParamf, void(
      const char* filename,
      int line,
      unsigned error,
      const char* function_name,
      unsigned pname,
      float param));
  MOCK_METHOD3(PeekGLError, unsigned(
      const char* file, int line, const char* filename));
  MOCK_METHOD3(CopyRealGLErrorsToWrapper, void(
      const char* file, int line, const char* filename));
  MOCK_METHOD3(ClearRealGLErrors, void(
      const char* file, int line, const char* filename));

  DISALLOW_COPY_AND_ASSIGN(MockErrorState);
};
}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_ERROR_STATE_MOCK_H_

