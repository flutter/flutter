// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains the ErrorState class.

#ifndef GPU_COMMAND_BUFFER_SERVICE_ERROR_STATE_H_
#define GPU_COMMAND_BUFFER_SERVICE_ERROR_STATE_H_

#include <stdint.h>

#include "base/compiler_specific.h"
#include "base/macros.h"
#include "gpu/gpu_export.h"

namespace gpu {
namespace gles2 {

class Logger;

// Use these macro to synthesize GL errors instead of calling the error_state
// functions directly as they will propogate the __FILE__ and __LINE__.

// Use to synthesize a GL error on the error_state.
#define ERRORSTATE_SET_GL_ERROR(error_state, error, function_name, msg) \
    error_state->SetGLError(__FILE__, __LINE__, error, function_name, msg)

// Use to synthesize an INVALID_ENUM GL error on the error_state. Will attempt
// to expand the enum to a string.
#define ERRORSTATE_SET_GL_ERROR_INVALID_ENUM( \
    error_state, function_name, value, label) \
    error_state->SetGLErrorInvalidEnum( \
        __FILE__, __LINE__, function_name, value, label)

// Use to synthesize a GL error on the error_state for an invalid enum based
// integer parameter. Will attempt to expand the parameter to a string.
#define ERRORSTATE_SET_GL_ERROR_INVALID_PARAMI( \
    error_state, error, function_name, pname, param) \
    error_state->SetGLErrorInvalidParami( \
        __FILE__, __LINE__, error, function_name, pname, param)

// Use to synthesize a GL error on the error_state for an invalid enum based
// float parameter. Will attempt to expand the parameter to a string.
#define ERRORSTATE_SET_GL_ERROR_INVALID_PARAMF( \
    error_state, error, function_name, pname, param) \
    error_state->SetGLErrorInvalidParamf( \
        __FILE__, __LINE__, error, function_name, pname, param)

// Use to move all pending error to the wrapper so on your next GL call
// you can see if that call generates an error.
#define ERRORSTATE_COPY_REAL_GL_ERRORS_TO_WRAPPER(error_state, function_name) \
    error_state->CopyRealGLErrorsToWrapper(__FILE__, __LINE__, function_name)
// Use to look at the real GL error and still pass it on to the user.
#define ERRORSTATE_PEEK_GL_ERROR(error_state, function_name) \
    error_state->PeekGLError(__FILE__, __LINE__, function_name)
// Use to clear all current GL errors. FAILS if there are any.
#define ERRORSTATE_CLEAR_REAL_GL_ERRORS(error_state, function_name) \
    error_state->ClearRealGLErrors(__FILE__, __LINE__, function_name)

class GPU_EXPORT ErrorStateClient {
 public:
  virtual void OnContextLostError() = 0;
  // GL_OUT_OF_MEMORY can cause side effects such as losing the context.
  virtual void OnOutOfMemoryError() = 0;
};

class GPU_EXPORT ErrorState {
 public:
  virtual ~ErrorState();

  static ErrorState* Create(ErrorStateClient* client, Logger* logger);

  virtual uint32_t GetGLError() = 0;

  virtual void SetGLError(
      const char* filename,
      int line,
      unsigned int error,
      const char* function_name,
      const char* msg) = 0;
  virtual void SetGLErrorInvalidEnum(
      const char* filename,
      int line,
      const char* function_name,
      unsigned int value,
      const char* label) = 0;
  virtual void SetGLErrorInvalidParami(
      const char* filename,
      int line,
      unsigned int error,
      const char* function_name,
      unsigned int pname,
      int param) = 0;
  virtual void SetGLErrorInvalidParamf(
      const char* filename,
      int line,
      unsigned int error,
      const char* function_name,
      unsigned int pname,
      float param) = 0;

  // Gets the GLError and stores it in our wrapper. Effectively
  // this lets us peek at the error without losing it.
  virtual unsigned int PeekGLError(
      const char* filename, int line, const char* function_name) = 0;

  // Copies the real GL errors to the wrapper. This is so we can
  // make sure there are no native GL errors before calling some GL function
  // so that on return we know any error generated was for that specific
  // command.
  virtual void CopyRealGLErrorsToWrapper(
      const char* filename, int line, const char* function_name) = 0;

  // Clear all real GL errors. This is to prevent the client from seeing any
  // errors caused by GL calls that it was not responsible for issuing.
  virtual void ClearRealGLErrors(
      const char* filename, int line, const char* function_name) = 0;

 protected:
  ErrorState();

  DISALLOW_COPY_AND_ASSIGN(ErrorState);
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_ERROR_STATE_H_

