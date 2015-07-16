// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_CONTEXT_H_
#define UI_GL_GL_CONTEXT_H_

#include <string>
#include <vector>

#include "base/basictypes.h"
#include "base/cancelable_callback.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/synchronization/cancellation_flag.h"
#include "ui/gl/gl_share_group.h"
#include "ui/gl/gl_state_restorer.h"
#include "ui/gl/gpu_preference.h"

namespace gpu {
class GLContextVirtual;
}  // namespace gpu

namespace gfx {

class GLSurface;
class GPUTiming;
class GPUTimingClient;
class VirtualGLApi;
struct GLVersionInfo;


// Encapsulates an OpenGL context, hiding platform specific management.
class GL_EXPORT GLContext : public base::RefCounted<GLContext> {
 public:
  explicit GLContext(GLShareGroup* share_group);

  // Initializes the GL context to be compatible with the given surface. The GL
  // context can be made with other surface's of the same type. The compatible
  // surface is only needed for certain platforms like WGL, OSMesa and GLX. It
  // should be specific for all platforms though.
  virtual bool Initialize(
      GLSurface* compatible_surface, GpuPreference gpu_preference) = 0;

  // Destroys the GL context.
  virtual void Destroy() = 0;

  // Makes the GL context and a surface current on the current thread.
  virtual bool MakeCurrent(GLSurface* surface) = 0;

  // Releases this GL context and surface as current on the current thread.
  virtual void ReleaseCurrent(GLSurface* surface) = 0;

  // Returns true if this context and surface is current. Pass a null surface
  // if the current surface is not important.
  virtual bool IsCurrent(GLSurface* surface) = 0;

  // Get the underlying platform specific GL context "handle".
  virtual void* GetHandle() = 0;

  // Creates a GPUTimingClient class which abstracts various GPU Timing exts.
  virtual scoped_refptr<gfx::GPUTimingClient> CreateGPUTimingClient() = 0;

  // Gets the GLStateRestorer for the context.
  GLStateRestorer* GetGLStateRestorer();

  // Sets the GLStateRestorer for the context (takes ownership).
  void SetGLStateRestorer(GLStateRestorer* state_restorer);

  // Set swap interval. This context must be current.
  void SetSwapInterval(int interval);

  // Forces the swap interval to zero (no vsync) regardless of any future values
  // passed to SetSwapInterval.
  void ForceSwapIntervalZero(bool force);

  // Returns space separated list of extensions. The context must be current.
  virtual std::string GetExtensions();

  // Returns in bytes the total amount of GPU memory for the GPU which this
  // context is currently rendering on. Returns false if no extension exists
  // to get the exact amount of GPU memory.
  virtual bool GetTotalGpuMemory(size_t* bytes);

  // Indicate that it is safe to force this context to switch GPUs, since
  // transitioning can cause corruption and hangs (OS X only).
  virtual void SetSafeToForceGpuSwitch();

  // Attempt to force the context to move to the GPU of its sharegroup. Return
  // false only in the event of an unexpected error on the context.
  virtual bool ForceGpuSwitchIfNeeded();

  // Indicate that the real context switches should unbind the FBO first
  // (For an Android work-around only).
  virtual void SetUnbindFboOnMakeCurrent();

  // Returns whether the current context supports the named extension. The
  // context must be current.
  bool HasExtension(const char* name);

  // Returns version info of the underlying GL context. The context must be
  // current.
  const GLVersionInfo* GetVersionInfo();

  GLShareGroup* share_group();

  // Create a GL context that is compatible with the given surface.
  // |share_group|, if non-NULL, is a group of contexts which the
  // internally created OpenGL context shares textures and other resources.
  static scoped_refptr<GLContext> CreateGLContext(
      GLShareGroup* share_group,
      GLSurface* compatible_surface,
      GpuPreference gpu_preference);

  static bool LosesAllContextsOnContextLost();

  // Returns the last GLContext made current, virtual or real.
  static GLContext* GetCurrent();

  virtual bool WasAllocatedUsingRobustnessExtension();

  // Use this context for virtualization.
  void SetupForVirtualization();

  // Make this context current when used for context virtualization.
  bool MakeVirtuallyCurrent(GLContext* virtual_context, GLSurface* surface);

  // Notify this context that |virtual_context|, that was using us, is
  // being released or destroyed.
  void OnReleaseVirtuallyCurrent(GLContext* virtual_context);

  // Returns the GL version string. The context must be current.
  virtual std::string GetGLVersion();

  // Returns the GL renderer string. The context must be current.
  virtual std::string GetGLRenderer();

  // Return a callback that, when called, indicates that the state the
  // underlying context has been changed by code outside of the command buffer,
  // and will need to be restored.
  virtual base::Closure GetStateWasDirtiedExternallyCallback();

  // Restore the context's state if it was dirtied by an external caller.
  virtual void RestoreStateIfDirtiedExternally();

 protected:
  virtual ~GLContext();

  // Will release the current context when going out of scope, unless canceled.
  class ScopedReleaseCurrent {
   public:
    ScopedReleaseCurrent();
    ~ScopedReleaseCurrent();

    void Cancel();

   private:
    bool canceled_;
  };

  // Sets the GL api to the real hardware API (vs the VirtualAPI)
  static void SetRealGLApi();
  virtual void SetCurrent(GLSurface* surface);

  // Initialize function pointers to functions where the bound version depends
  // on GL version or supported extensions. Should be called immediately after
  // this context is made current.
  bool InitializeDynamicBindings();

  // Returns the last real (non-virtual) GLContext made current.
  static GLContext* GetRealCurrent();

  virtual void OnSetSwapInterval(int interval) = 0;

  bool GetStateWasDirtiedExternally() const;
  void SetStateWasDirtiedExternally(bool dirtied_externally);

 private:
  friend class base::RefCounted<GLContext>;

  // For GetRealCurrent.
  friend class VirtualGLApi;
  friend class gpu::GLContextVirtual;

  scoped_refptr<GLShareGroup> share_group_;
  scoped_ptr<VirtualGLApi> virtual_gl_api_;
  bool state_dirtied_externally_;
  scoped_ptr<GLStateRestorer> state_restorer_;
  scoped_ptr<GLVersionInfo> version_info_;

  int swap_interval_;
  bool force_swap_interval_zero_;

  base::CancelableCallback<void()> state_dirtied_callback_;

  DISALLOW_COPY_AND_ASSIGN(GLContext);
};

class GL_EXPORT GLContextReal : public GLContext {
 public:
  explicit GLContextReal(GLShareGroup* share_group);
  scoped_refptr<gfx::GPUTimingClient> CreateGPUTimingClient() override;

 protected:
  ~GLContextReal() override;

  void SetCurrent(GLSurface* surface) override;

 private:
  scoped_ptr<gfx::GPUTiming> gpu_timing_;
  DISALLOW_COPY_AND_ASSIGN(GLContextReal);
};

}  // namespace gfx

#endif  // UI_GL_GL_CONTEXT_H_
