/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WebTransformKeyframe_h
#define WebTransformKeyframe_h

#include "WebNonCopyable.h"
#include "WebPrivateOwnPtr.h"
#include "WebTransformOperations.h"
#if INSIDE_BLINK
namespace WTF { template <typename T> class PassOwnPtr; }
#endif

namespace blink {

class WebTransformKeyframe : public WebNonCopyable {
public:
#if INSIDE_BLINK
    BLINK_PLATFORM_EXPORT WebTransformKeyframe(double time, WTF::PassOwnPtr<WebTransformOperations> value);
#endif

    BLINK_PLATFORM_EXPORT ~WebTransformKeyframe();

    BLINK_PLATFORM_EXPORT double time() const;

    BLINK_PLATFORM_EXPORT const WebTransformOperations& value() const;

private:
    double m_time;
    WebPrivateOwnPtr<WebTransformOperations> m_value;
};

} // namespace blink

#endif // WebTransformKeyframe_h
