// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/testing/platform/platform_impl.h"

namespace sky {

PlatformImpl::PlatformImpl() {
}

PlatformImpl::~PlatformImpl() {
}

blink::WebString PlatformImpl::defaultLocale() {
  return blink::WebString::fromUTF8("en-US");
}

blink::WebUnitTestSupport* PlatformImpl::unitTestSupport() {
  return &unit_test_support_;
}

}  // namespace sky
