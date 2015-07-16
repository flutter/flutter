// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/ui/platform_impl.h"

namespace sky {
namespace shell {

PlatformImpl::PlatformImpl()
    : main_thread_task_runner_(base::MessageLoop::current()->task_runner()) {
}

PlatformImpl::~PlatformImpl() {
}

blink::WebString PlatformImpl::defaultLocale() {
  return blink::WebString::fromUTF8("en-US");
}

base::SingleThreadTaskRunner* PlatformImpl::mainThreadTaskRunner() {
  return main_thread_task_runner_.get();
}

}  // namespace shell
}  // namespace sky
