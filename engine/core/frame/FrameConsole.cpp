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

#include "sky/engine/config.h"
#include "sky/engine/core/frame/FrameConsole.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/frame/FrameHost.h"
#include "sky/engine/core/inspector/ConsoleAPITypes.h"
#include "sky/engine/core/inspector/ConsoleMessage.h"
#include "sky/engine/core/page/ChromeClient.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/platform/network/ResourceResponse.h"
#include "sky/engine/wtf/text/StringBuilder.h"

namespace blink {

FrameConsole::FrameConsole(LocalFrame& frame)
    : m_frame(frame)
{
}

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(FrameConsole);

void FrameConsole::addMessage(PassRefPtr<ConsoleMessage> prpConsoleMessage)
{
    RefPtr<ConsoleMessage> consoleMessage = prpConsoleMessage;

    // FIXME: This should not need to reach for the main-frame.
    // Inspector code should just take the current frame and know how to walk itself.
    ExecutionContext* context = m_frame.document();
    if (!context)
        return;

    String messageURL = consoleMessage->url();
    unsigned lineNumber = consoleMessage->lineNumber();
    m_frame.page()->addMessageToConsole(&m_frame, consoleMessage->source(), consoleMessage->level(), consoleMessage->message(), lineNumber, messageURL, String());
}

void FrameConsole::reportResourceResponseReceived(Document* document, unsigned long requestIdentifier, const ResourceResponse& response)
{
    if (!document)
        return;
    if (response.httpStatusCode() < 400)
        return;
    String message = "Failed to load resource: the server responded with a status of " + String::number(response.httpStatusCode()) + " (" + response.httpStatusText() + ')';
    RefPtr<ConsoleMessage> consoleMessage = ConsoleMessage::create(NetworkMessageSource, ErrorMessageLevel, message, response.url().string());
    consoleMessage->setRequestIdentifier(requestIdentifier);
    addMessage(consoleMessage.release());
}

} // namespace blink
