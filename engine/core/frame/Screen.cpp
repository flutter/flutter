/*
 * Copyright (C) 2007 Apple Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#include "config.h"
#include "core/frame/Screen.h"

#include "core/frame/FrameHost.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "platform/PlatformScreen.h"
#include "platform/geometry/FloatRect.h"

namespace blink {

Screen::Screen(LocalFrame* frame)
    : DOMWindowProperty(frame)
{
}

unsigned Screen::height() const
{
    if (!m_frame)
        return 0;
    return static_cast<unsigned>(screenRect(m_frame->view()).height());
}

unsigned Screen::width() const
{
    if (!m_frame)
        return 0;
    return static_cast<unsigned>(screenRect(m_frame->view()).width());
}

unsigned Screen::colorDepth() const
{
    if (!m_frame)
        return 0;
    return static_cast<unsigned>(screenDepth(m_frame->view()));
}

unsigned Screen::pixelDepth() const
{
    if (!m_frame)
        return 0;
    return static_cast<unsigned>(screenDepth(m_frame->view()));
}

int Screen::availLeft() const
{
    if (!m_frame)
        return 0;
    return static_cast<int>(screenAvailableRect(m_frame->view()).x());
}

int Screen::availTop() const
{
    if (!m_frame)
        return 0;
    return static_cast<int>(screenAvailableRect(m_frame->view()).y());
}

unsigned Screen::availHeight() const
{
    if (!m_frame)
        return 0;
    return static_cast<unsigned>(screenAvailableRect(m_frame->view()).height());
}

unsigned Screen::availWidth() const
{
    if (!m_frame)
        return 0;
    return static_cast<unsigned>(screenAvailableRect(m_frame->view()).width());
}

} // namespace blink
