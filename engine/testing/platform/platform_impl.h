// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TESTING_PLATFORM_PLATFORM_IMPL_H_
#define SKY_ENGINE_TESTING_PLATFORM_PLATFORM_IMPL_H_

#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop.h"
#include "base/threading/thread_local_storage.h"
#include "base/timer/timer.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/testing/platform/webunittestsupport_impl.h"

namespace sky {

class PlatformImpl : public blink::Platform {
 public:
  explicit PlatformImpl();
  virtual ~PlatformImpl();

  // blink::Platform methods:
  virtual blink::WebUnitTestSupport* unitTestSupport();
  virtual blink::WebString defaultLocale();

 private:
  WebUnitTestSupportImpl unit_test_support_;

  DISALLOW_COPY_AND_ASSIGN(PlatformImpl);
};

}  // namespace sky

#endif  // SKY_ENGINE_TESTING_PLATFORM_PLATFORM_IMPL_H_
