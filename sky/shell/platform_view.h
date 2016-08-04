// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_VIEW_H_
#define SKY_SHELL_PLATFORM_VIEW_H_

#include <memory>

#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "base/synchronization/waitable_event.h"
#include "base/threading/thread_local_storage.h"
#include "sky/shell/shell.h"
#include "sky/shell/ui/engine.h"
#include "sky/shell/ui_delegate.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace sky {
namespace shell {

class Rasterizer;

class PlatformView {
 public:
  struct Config {
    Config();

    ~Config();

    base::WeakPtr<UIDelegate> ui_delegate;
    Rasterizer* rasterizer;
    scoped_refptr<base::SingleThreadTaskRunner> ui_task_runner;
  };

  struct SurfaceConfig {
    uint8_t red_bits = 8;
    uint8_t green_bits = 8;
    uint8_t blue_bits = 8;
    uint8_t alpha_bits = 8;
    uint8_t depth_bits = 0;
    uint8_t stencil_bits = 8;
  };

  void SetupResourceContextOnIOThread();

  static base::ThreadLocalStorage::StaticSlot ResourceContext;

  virtual ~PlatformView();

  void ConnectToEngine(mojo::InterfaceRequest<SkyEngine> request);

  void NotifyCreated();

  void NotifyCreated(base::Closure continuation);

  void NotifyDestroyed();

  virtual base::WeakPtr<sky::shell::PlatformView> GetWeakViewPtr() = 0;

  virtual uint64_t DefaultFramebuffer() const = 0;

  virtual bool ContextMakeCurrent() = 0;

  virtual bool ResourceContextMakeCurrent() = 0;

  virtual bool SwapBuffers() = 0;

  virtual SkISize GetSize();

  virtual void Resize(const SkISize& size);

  Engine& engine() {
    return *engine_;
  }

 protected:
  Config config_;
  SurfaceConfig surface_config_;

  std::unique_ptr<Rasterizer> rasterizer_;
  std::unique_ptr<Engine> engine_;

  SkISize size_;

  explicit PlatformView();

  void SetupResourceContextOnIOThreadPerform(base::WaitableEvent* event);

 private:
  DISALLOW_COPY_AND_ASSIGN(PlatformView);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_VIEW_H_
