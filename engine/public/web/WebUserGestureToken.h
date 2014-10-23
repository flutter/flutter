/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef WebUserGestureToken_h
#define WebUserGestureToken_h

#include "../platform/WebPrivatePtr.h"

namespace blink {

class UserGestureToken;

// A WebUserGestureToken allows for storing the user gesture state of the
// currently active context and reinstantiating it later on to continue
// processing the user gesture in case it was not consumed meanwhile.
class WebUserGestureToken {
public:
    WebUserGestureToken() { }
    WebUserGestureToken(const WebUserGestureToken& other) { assign(other); }
    WebUserGestureToken& operator=(const WebUserGestureToken& other)
    {
        assign(other);
        return *this;
    }
    ~WebUserGestureToken() { reset(); }

    BLINK_EXPORT bool hasGestures() const;
    BLINK_EXPORT void setOutOfProcess();
    BLINK_EXPORT void setJavascriptPrompt();
    bool isNull() const { return m_token.isNull(); }

#if BLINK_IMPLEMENTATION
    explicit WebUserGestureToken(PassRefPtr<UserGestureToken>);
    operator PassRefPtr<UserGestureToken>() const;
#endif

private:
    BLINK_EXPORT void assign(const WebUserGestureToken&);
    BLINK_EXPORT void reset();

    WebPrivatePtr<UserGestureToken> m_token;
};

} // namespace blink

#endif // WebUserGestureToken_h
