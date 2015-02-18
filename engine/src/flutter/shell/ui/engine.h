// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_UI_ENGINE_H_
#define SKY_SHELL_UI_ENGINE_H_

#include "base/macros.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/weak_ptr.h"
#include "base/single_thread_task_runner.h"
#include "mojo/public/cpp/system/core.h"
#include "skia/ext/refptr.h"
#include "sky/engine/public/web/WebFrameClient.h"
#include "sky/engine/public/web/WebViewClient.h"
#include "sky/shell/gpu_delegate.h"
#include "sky/shell/ui_delegate.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "ui/gfx/geometry/size.h"

namespace sky {
namespace shell {
class Animator;
class PlatformImpl;

class Engine : public UIDelegate,
               public blink::WebFrameClient,
               public blink::WebViewClient {
 public:
  struct Config {
    base::WeakPtr<GPUDelegate> gpu_delegate;
    scoped_refptr<base::SingleThreadTaskRunner> gpu_task_runner;
  };

  explicit Engine(const Config& config);
  ~Engine() override;

  base::WeakPtr<Engine> GetWeakPtr();

  void Init(mojo::ScopedMessagePipeHandle service_provider);

  void BeginFrame(base::TimeTicks frame_time);
  skia::RefPtr<SkPicture> Paint();

 private:
  // UIDelegate methods:
  void OnViewportMetricsChanged(const gfx::Size& physical_size,
                                float device_pixel_ratio) override;

  // WebViewClient methods:
  void initializeLayerTreeView() override;
  void scheduleVisualUpdate() override;

  scoped_ptr<PlatformImpl> platform_impl_;
  scoped_ptr<Animator> animator_;
  blink::WebView* web_view_;
  gfx::Size physical_size_;

  base::WeakPtrFactory<Engine> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(Engine);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_UI_ENGINE_H_
