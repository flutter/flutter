// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_PUBLIC_WEB_WEBLOCALFRAME_H_
#define SKY_ENGINE_PUBLIC_WEB_WEBLOCALFRAME_H_

#include "sky/engine/public/web/WebFrame.h"

namespace blink {

// Interface for interacting with in process frames. This contains methods that
// require interacting with a frame's document.
// FIXME: Move lots of methods from WebFrame in here.
class WebLocalFrame : public WebFrame {
public:
    // Creates a WebFrame. Delete this WebFrame by calling WebFrame::close().
    // It is valid to pass a null client pointer.
    BLINK_EXPORT static WebLocalFrame* create(WebFrameClient*);
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_WEB_WEBLOCALFRAME_H_
