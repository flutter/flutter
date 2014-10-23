/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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
#include "public/web/WebDOMMouseEvent.h"

#include "core/events/MouseEvent.h"

namespace blink {

int WebDOMMouseEvent::screenX() const
{
    return constUnwrap<MouseEvent>()->screenX();
}

int WebDOMMouseEvent::screenY() const
{
    return constUnwrap<MouseEvent>()->screenY();
}

int WebDOMMouseEvent::clientX() const
{
    return constUnwrap<MouseEvent>()->clientX();
}

int WebDOMMouseEvent::clientY() const
{
    return constUnwrap<MouseEvent>()->clientY();
}

int WebDOMMouseEvent::offsetX()
{
    return unwrap<MouseEvent>()->offsetX();
}

int WebDOMMouseEvent::offsetY()
{
    return unwrap<MouseEvent>()->offsetY();
}

int WebDOMMouseEvent::pageX() const
{
    return constUnwrap<MouseEvent>()->pageX();
}

int WebDOMMouseEvent::pageY() const
{
    return constUnwrap<MouseEvent>()->pageY();
}

int WebDOMMouseEvent::x() const
{
    return constUnwrap<MouseEvent>()->x();
}

int WebDOMMouseEvent::y() const
{
    return constUnwrap<MouseEvent>()->y();
}

int WebDOMMouseEvent::button() const
{
    return constUnwrap<MouseEvent>()->button();
}

bool WebDOMMouseEvent::buttonDown() const
{
    return constUnwrap<MouseEvent>()->buttonDown();
}

} // namespace blink
