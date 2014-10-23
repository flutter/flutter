// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TESTING_PLATFORM_WEBUNITTESTSUPPORT_IMPL_H_
#define SKY_ENGINE_TESTING_PLATFORM_WEBUNITTESTSUPPORT_IMPL_H_

#include "sky/engine/public/platform/WebUnitTestSupport.h"

namespace sky {

class WebUnitTestSupportImpl : public blink::WebUnitTestSupport {
public:
    // Returns the root directory of the WebKit code.
    virtual blink::WebString webKitRootDir();

    virtual blink::WebData readFromFile(const blink::WebString& path);
};

}  // namespace sky

#endif  // SKY_ENGINE_TESTING_PLATFORM_WEBUNITTESTSUPPORT_IMPL_H_
