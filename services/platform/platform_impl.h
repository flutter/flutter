// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_PLATFORM_PLATFORM_IMPL_H_
#define SKY_VIEWER_PLATFORM_PLATFORM_IMPL_H_

#include "base/message_loop/message_loop.h"
#include "sky/engine/public/platform/Platform.h"

namespace mojo {
class ApplicationImpl;
}

namespace sky {

class PlatformImpl : public blink::Platform {
 public:
  explicit PlatformImpl();
  ~PlatformImpl() override;

  // blink::Platform methods:
  blink::WebString defaultLocale() override;
  base::SingleThreadTaskRunner* mainThreadTaskRunner() override;

 private:
  scoped_refptr<base::SingleThreadTaskRunner> main_thread_task_runner_;

  DISALLOW_COPY_AND_ASSIGN(PlatformImpl);
};

}  // namespace sky

#endif  // SKY_VIEWER_PLATFORM_PLATFORM_IMPL_H_
