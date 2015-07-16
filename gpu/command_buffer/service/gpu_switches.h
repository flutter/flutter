// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Defines all the command-line switches used by gpu/command_buffer/service/.

#ifndef GPU_COMMAND_BUFFER_SERVICE_GPU_SWITCHES_H_
#define GPU_COMMAND_BUFFER_SERVICE_GPU_SWITCHES_H_

#include "gpu/config/gpu_switches.h"
#include "gpu/gpu_export.h"

namespace switches {

GPU_EXPORT extern const char kCompileShaderAlwaysSucceeds[];
GPU_EXPORT extern const char kDisableGLErrorLimit[];
GPU_EXPORT extern const char kDisableGLSLTranslator[];
GPU_EXPORT extern const char kDisableGpuDriverBugWorkarounds[];
GPU_EXPORT extern const char kDisableShaderNameHashing[];
GPU_EXPORT extern const char kEnableGPUCommandLogging[];
GPU_EXPORT extern const char kEnableGPUDebugging[];
GPU_EXPORT extern const char kEnableGPUServiceLoggingGPU[];
GPU_EXPORT extern const char kDisableGpuProgramCache[];
GPU_EXPORT extern const char kEnforceGLMinimums[];
GPU_EXPORT extern const char kForceGpuMemAvailableMb[];
GPU_EXPORT extern const char kGpuProgramCacheSizeKb[];
GPU_EXPORT extern const char kDisableGpuShaderDiskCache[];
GPU_EXPORT extern const char kEnableShareGroupAsyncTextureUpload[];
GPU_EXPORT extern const char kEnableSubscribeUniformExtension[];
GPU_EXPORT extern const char kEnableThreadedTextureMailboxes[];
GPU_EXPORT extern const char kGLShaderIntermOutput[];
GPU_EXPORT extern const char kEmulateShaderPrecision[];

GPU_EXPORT extern const char* kGpuSwitches[];
GPU_EXPORT extern const int kNumGpuSwitches;

}  // namespace switches

#endif  // GPU_COMMAND_BUFFER_SERVICE_GPU_SWITCHES_H_
