// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_CONTEXT_IOS_H_
#define UI_GL_GL_CONTEXT_IOS_H_

#include "base/compiler_specific.h"
#include "ui/gl/gl_context.h"

namespace gfx {

class GLSurface;

class GLContextIOS : public GLContextReal {
 public:
  explicit GLContextIOS(GLShareGroup* share_group);

  bool Initialize(GLSurface* compatible_surface,
                  GpuPreference gpu_preference) override;
  void Destroy() override;
  bool MakeCurrent(GLSurface* surface) override;
  void ReleaseCurrent(GLSurface* surface) override;
  bool IsCurrent(GLSurface* surface) override;
  void* GetHandle() override;
  void OnSetSwapInterval(int interval) override;
  std::string GetExtensions() override;
  bool WasAllocatedUsingRobustnessExtension() override;
  bool GetTotalGpuMemory(size_t* bytes) override;
  void SetUnbindFboOnMakeCurrent() override;

 protected:
  ~GLContextIOS() override;

 private:
  uintptr_t context_;

  DISALLOW_COPY_AND_ASSIGN(GLContextIOS);
};

}  // namespace gfx

#endif  // UI_GL_GL_CONTEXT_IOS_H_
