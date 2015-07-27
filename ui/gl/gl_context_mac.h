// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef __UI_GL_GL_CONTEXT_MAC_H__
#define __UI_GL_GL_CONTEXT_MAC_H__

#include "base/compiler_specific.h"
#include "ui/gl/gl_context.h"

namespace gfx {

class GLSurface;

class GLContextMac : public GLContextReal {
 public:
  explicit GLContextMac(GLShareGroup* share_group);

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
  ~GLContextMac() override;

 private:
  uintptr_t context_;

  DISALLOW_COPY_AND_ASSIGN(GLContextMac);
};

}  // namespace gfx

#endif /* defined(__UI_GL_GL_CONTEXT_MAC_H__) */
