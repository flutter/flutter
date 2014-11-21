// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/public/web/WebFrame.h"

#include <algorithm>
#include "sky/engine/platform/UserGestureIndicator.h"
#include "sky/engine/web/WebLocalFrameImpl.h"

namespace blink {

Frame* toCoreFrame(const WebFrame* frame)
{
    if (!frame)
        return 0;

    return static_cast<Frame*>(toWebLocalFrameImpl(frame)->frame());
}

v8::Handle<v8::Value> WebFrame::executeScriptAndReturnValueForTests(const WebScriptSource& source)
{
    // FIXME: This fake UserGestureIndicator is required for a bunch of browser
    // tests to pass. We should update the tests to simulate input and get rid
    // of this.
    // http://code.google.com/p/chromium/issues/detail?id=86397
    UserGestureIndicator gestureIndicator(DefinitelyProcessingNewUserGesture);
    return executeScriptAndReturnValue(source);
}

WebFrame* WebFrame::fromFrame(Frame* frame)
{
    if (!frame)
        return 0;
    return WebLocalFrameImpl::fromFrame(toLocalFrame(*frame));
}

WebFrame::WebFrame()
{
}

WebFrame::~WebFrame()
{
}

} // namespace blink
