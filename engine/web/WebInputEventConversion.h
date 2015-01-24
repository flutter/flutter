/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_WEB_WEBINPUTEVENTCONVERSION_H_
#define SKY_ENGINE_WEB_WEBINPUTEVENTCONVERSION_H_

#include "sky/engine/platform/PlatformKeyboardEvent.h"
#include "sky/engine/public/platform/WebInputEvent.h"

namespace blink {

class KeyboardEvent;
class RenderObject;
class WebKeyboardEvent;
class Widget;

// These classes are used to convert from WebInputEvent subclasses to
// corresponding WebCore events.

class PlatformKeyboardEventBuilder : public PlatformKeyboardEvent {
public:
    PlatformKeyboardEventBuilder(const WebKeyboardEvent&);
    void setKeyType(Type);
    bool isCharacterKey() const;
};

// Converts a KeyboardEvent or PlatformKeyboardEvent to a
// corresponding WebKeyboardEvent.
// NOTE: For KeyboardEvent, this is only implemented for keydown,
// keyup, and keypress. If the event mapping fails, the event type will be set
// to Undefined.
class WebKeyboardEventBuilder : public WebKeyboardEvent {
public:
    WebKeyboardEventBuilder(const KeyboardEvent&);
    WebKeyboardEventBuilder(const PlatformKeyboardEvent&);
};

} // namespace blink

#endif  // SKY_ENGINE_WEB_WEBINPUTEVENTCONVERSION_H_
