/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#ifndef WebScopedUserGesture_h
#define WebScopedUserGesture_h

#include "../platform/WebPrivateOwnPtr.h"

namespace blink {

class UserGestureIndicator;
class WebUserGestureToken;

// An instance of this class, while kept alive, will indicate that we are in
// the context of a known user gesture. To use, create one, perform whatever
// actions were done under color of a known user gesture, and then delete it.
// Usually this will be done on the stack.
//
// SECURITY WARNING: Do not create several instances of this class for the same
// user gesture. Doing so might enable malicious code to work around certain
// restrictions such as opening multiple windows.
// Instead, obtain the current WebUserGestureToken from the
// WebUserGestureIndicator, and use this token to create a
// WebScopedUserGesture. If the token was alrady consumed, the new
// WebScopedUserGesture will not indicate that we are in the context of a user
// gesture.
class WebScopedUserGesture {
public:
    explicit WebScopedUserGesture(const WebUserGestureToken& token) { initializeWithToken(token); }
    WebScopedUserGesture() { initialize(); }
    ~WebScopedUserGesture() { reset(); }

private:
    BLINK_EXPORT void initialize();
    BLINK_EXPORT void initializeWithToken(const WebUserGestureToken&);
    BLINK_EXPORT void reset();

    WebPrivateOwnPtr<UserGestureIndicator> m_indicator;
};

} // namespace blink

#endif // WebScopedUserGesture_h
