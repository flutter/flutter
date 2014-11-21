// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/public/platform/WebConvertableToTraceFormat.h"

#include "sky/engine/platform/EventTracer.h"
#include "sky/engine/public/platform/WebString.h"

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
