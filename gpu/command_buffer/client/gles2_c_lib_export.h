// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_CLIENT_GLES2_C_LIB_EXPORT_H_
#define GPU_COMMAND_BUFFER_CLIENT_GLES2_C_LIB_EXPORT_H_

#if defined(COMPONENT_BUILD)
#if defined(WIN32)

#if defined(GLES2_C_LIB_IMPLEMENTATION)
#define GLES2_C_LIB_EXPORT __declspec(dllexport)
#else
#define GLES2_C_LIB_EXPORT __declspec(dllimport)
#endif  // defined(GLES2_C_LIB_IMPLEMENTATION)

#else // defined(WIN32)
#if defined(GLES2_C_LIB_IMPLEMENTATION)
#define GLES2_C_LIB_EXPORT __attribute__((visibility("default")))
#else
#define GLES2_C_LIB_EXPORT
#endif
#endif

#else // defined(COMPONENT_BUILD)
#define GLES2_C_LIB_EXPORT
#endif

#endif  // GPU_COMMAND_BUFFER_CLIENT_GLES2_C_LIB_EXPORT_H_
