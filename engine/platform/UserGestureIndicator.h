/*
 * Copyright (C) 2010 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef UserGestureIndicator_h
#define UserGestureIndicator_h

#include "platform/PlatformExport.h"
#include "wtf/Noncopyable.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"

namespace blink {

class UserGestureIndicator;

enum ProcessingUserGestureState {
    DefinitelyProcessingNewUserGesture,
    DefinitelyProcessingUserGesture,
    PossiblyProcessingUserGesture,
    DefinitelyNotProcessingUserGesture
};

class PLATFORM_EXPORT UserGestureToken : public RefCounted<UserGestureToken> {
public:
    virtual ~UserGestureToken() { }
    virtual bool hasGestures() const = 0;
    virtual void setOutOfProcess() = 0;
    virtual void setJavascriptPrompt() = 0;
};

class PLATFORM_EXPORT UserGestureIndicatorDisabler {
    WTF_MAKE_NONCOPYABLE(UserGestureIndicatorDisabler);
public:
    UserGestureIndicatorDisabler();
    ~UserGestureIndicatorDisabler();

private:
    ProcessingUserGestureState m_savedState;
    UserGestureIndicator* m_savedIndicator;
};

class PLATFORM_EXPORT UserGestureIndicator {
    WTF_MAKE_NONCOPYABLE(UserGestureIndicator);
    friend class UserGestureIndicatorDisabler;
public:
    static bool processingUserGesture();
    static bool consumeUserGesture();
    static UserGestureToken* currentToken();
    static void clearProcessedUserGestureSinceLoad();
    static bool processedUserGestureSinceLoad();

    explicit UserGestureIndicator(ProcessingUserGestureState);
    explicit UserGestureIndicator(PassRefPtr<UserGestureToken>);
    ~UserGestureIndicator();


private:
    static ProcessingUserGestureState s_state;
    static UserGestureIndicator* s_topmostIndicator;
    static bool s_processedUserGestureSinceLoad;
    ProcessingUserGestureState m_previousState;
    RefPtr<UserGestureToken> m_token;
};

}

#endif
