// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/testing/platform/platform_impl.h"

#include <cmath>

#include "base/rand_util.h"
#include "base/stl_util.h"
#include "base/synchronization/waitable_event.h"
#include "base/time/time.h"
#include "net/base/data_url.h"
#include "net/base/mime_util.h"
#include "net/base/net_errors.h"

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
