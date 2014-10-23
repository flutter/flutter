/*
 * Copyright (c) 2008, 2009, Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/PlatformScreen.h"

#include "platform/HostWindow.h"
#include "platform/Widget.h"
#include "public/platform/Platform.h"
#include "public/platform/WebScreenInfo.h"

namespace blink {

static HostWindow* toHostWindow(Widget* widget)
{
    if (!widget)
        return 0;
    Widget* root = widget->root();
    if (!root)
        return 0;
    return root->hostWindow();
}

int screenDepth(Widget* widget)
{
    HostWindow* hostWindow = toHostWindow(widget);
    if (!hostWindow)
        return 0;
    return hostWindow->screenInfo().depth;
}

int screenDepthPerComponent(Widget* widget)
{
    HostWindow* hostWindow = toHostWindow(widget);
    if (!hostWindow)
        return 0;
    return hostWindow->screenInfo().depthPerComponent;
}

bool screenIsMonochrome(Widget* widget)
{
    HostWindow* hostWindow = toHostWindow(widget);
    if (!hostWindow)
        return false;
    return hostWindow->screenInfo().isMonochrome;
}

FloatRect screenRect(Widget* widget)
{
    HostWindow* hostWindow = toHostWindow(widget);
    if (!hostWindow)
        return FloatRect();
    return IntRect(hostWindow->screenInfo().rect);
}

FloatRect screenAvailableRect(Widget* widget)
{
    HostWindow* hostWindow = toHostWindow(widget);
    if (!hostWindow)
        return FloatRect();
    return IntRect(hostWindow->screenInfo().availableRect);
}

uint16_t screenOrientationAngle(Widget* widget)
{
    HostWindow* hostWindow = toHostWindow(widget);
    if (!hostWindow)
        return 0;
    return hostWindow->screenInfo().orientationAngle;
}

blink::WebScreenOrientationType screenOrientationType(Widget* widget)
{
    HostWindow* hostWindow = toHostWindow(widget);
    if (!hostWindow)
        return blink::WebScreenOrientationUndefined;
    return hostWindow->screenInfo().orientationType;
}

void screenColorProfile(ColorProfile& toProfile)
{
    blink::WebVector<char> profile;
    blink::Platform::current()->screenColorProfile(&profile);
    toProfile.append(profile.data(), profile.size());
}

} // namespace blink
