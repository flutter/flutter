// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/frame/Tracing.h"

#include "base/trace_event/trace_event.h"
#include "sky/engine/wtf/text/StringUTF8Adaptor.h"

namespace blink {

Tracing::Tracing()
{
}

Tracing::~Tracing()
{
}

void Tracing::begin(const String& name)
{
    StringUTF8Adaptor utf8(name);
    // TRACE_EVENT_COPY_BEGIN0 needs a c-style null-terminated string.
    CString cstring(utf8.data(), utf8.length());
    TRACE_EVENT_COPY_BEGIN0("script", cstring.data());
}

void Tracing::end(const String& name)
{
    StringUTF8Adaptor utf8(name);
    // TRACE_EVENT_COPY_END0 needs a c-style null-terminated string.
    CString cstring(utf8.data(), utf8.length());
    TRACE_EVENT_COPY_END0("script", cstring.data());
}

} // namespace blink
