// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TESTING_PLATFORM_PLATFORM_IMPL_H_
#define SKY_ENGINE_TESTING_PLATFORM_PLATFORM_IMPL_H_

#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/testing/platform/webunittestsupport_impl.h"

namespace sky {

class PlatformImpl : public blink::Platform {
 public:
  PlatformImpl();
  ~PlatformImpl() override;

  // blink::Platform methods:
  blink::WebString defaultLocale() override;
  blink::WebUnitTestSupport* unitTestSupport() override;

 private:
  WebUnitTestSupportImpl unit_test_support_;

  DISALLOW_COPY_AND_ASSIGN(PlatformImpl);
};

}  // namespace sky

#endif  // SKY_ENGINE_TESTING_PLATFORM_PLATFORM_IMPL_H_
