// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_UI_ENGINE_H_
#define SKY_SHELL_UI_ENGINE_H_

#include "base/macros.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/weak_ptr.h"
#include "sky/engine/public/web/WebFrameClient.h"
#include "sky/engine/public/web/WebViewClient.h"
#include "sky/shell/ui_delegate.h"
#include "ui/gfx/geometry/size.h"

namespace sky {
namespace shell {
class PlatformImpl;

class Engine : public UIDelegate,
               public blink::WebFrameClient,
               public blink::WebViewClient {
 public:
  Engine();
  ~Engine() override;

  base::WeakPtr<Engine> GetWeakPtr();

  void Init();

  void OnViewportMetricsChanged(const gfx::Size& size,
                                float device_pixel_ratio) override;

 private:
  scoped_ptr<PlatformImpl> platform_impl_;
  blink::WebView* web_view_;

  base::WeakPtrFactory<Engine> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(Engine);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_UI_ENGINE_H_
