// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/ui/engine.h"

#include "sky/engine/public/web/Sky.h"
#include "sky/engine/public/web/WebLocalFrame.h"
#include "sky/engine/public/web/WebView.h"
#include "sky/shell/ui/platform_impl.h"

namespace sky {
namespace shell {

Engine::Engine() : web_view_(nullptr), weak_factory_(this) {
}

Engine::~Engine() {
  if (web_view_)
    web_view_->close();
}

base::WeakPtr<Engine> Engine::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void Engine::Init() {
  platform_impl_.reset(new PlatformImpl);
  blink::initialize(platform_impl_.get());

  web_view_ = blink::WebView::create(this);
  web_view_->setMainFrame(blink::WebLocalFrame::create(this));
}

}  // namespace shell
}  // namespace sky
