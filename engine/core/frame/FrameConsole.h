/*
 * Copyright (C) 2013 Apple Inc. All rights reserved.
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

#ifndef FrameConsole_h
#define FrameConsole_h

#include "bindings/core/v8/ScriptState.h"
#include "core/frame/ConsoleTypes.h"
#include "platform/heap/Handle.h"
#include "wtf/Forward.h"
#include "wtf/PassOwnPtr.h"

namespace blink {

class ConsoleMessage;
class ConsoleMessageStorage;
class Document;
class FrameHost;
class ResourceResponse;
class ScriptCallStack;

// FrameConsole takes per-frame console messages and routes them up through the FrameHost to the ChromeClient and Inspector.
// It's meant as an abstraction around ChromeClient calls and the way that Blink core/ can add messages to the console.
class FrameConsole final {
    DECLARE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(FrameConsole);
public:
    static PassOwnPtr<FrameConsole> create(LocalFrame& frame)
    {
        return adoptPtr(new FrameConsole(frame));
    }

    void addMessage(PassRefPtr<ConsoleMessage>);

    void reportResourceResponseReceived(Document*, unsigned long requestIdentifier, const ResourceResponse&);

    static String formatStackTraceString(const String& originalMessage, PassRefPtr<ScriptCallStack>);

    static void mute();
    static void unmute();

    ConsoleMessageStorage* messageStorage();
    void clearMessages();

    void trace(Visitor*);

private:
    explicit FrameConsole(LocalFrame&);

    LocalFrame& m_frame;

    OwnPtr<ConsoleMessageStorage> m_consoleMessageStorage;
};

} // namespace blink

#endif // FrameConsole_h
