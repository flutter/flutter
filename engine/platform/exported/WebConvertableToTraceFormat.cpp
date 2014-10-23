// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "public/platform/WebConvertableToTraceFormat.h"

#include "platform/EventTracer.h"
#include "public/platform/WebString.h"

namespace blink {

WebConvertableToTraceFormat::WebConvertableToTraceFormat(TraceEvent::ConvertableToTraceFormat* convertable)
    : m_private(convertable)
{
}

WebString WebConvertableToTraceFormat::asTraceFormat() const
{
    return m_private->asTraceFormat();
}

void WebConvertableToTraceFormat::assign(const WebConvertableToTraceFormat& r)
{
    m_private = r.m_private;
}

void WebConvertableToTraceFormat::reset()
{
    m_private.reset();
}

} // namespace blink
