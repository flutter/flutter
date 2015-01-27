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

#include "config.h"
#include "bindings/common/BindingSecurity.h"

#include "bindings/common/ScriptState.h"
#include "core/dom/Document.h"
#include "core/html/HTMLFrameElementBase.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/html/HTMLFrameElementBase.h"
#include "platform/weborigin/SecurityOrigin.h"

namespace blink {

static bool isDocumentAccessibleFromDOMWindow(Document* targetDocument, LocalDOMWindow* callingWindow)
{
    if (!targetDocument)
        return false;

    if (!callingWindow)
        return false;

    if (callingWindow->document()->securityOrigin()->canAccess(targetDocument->securityOrigin()))
        return true;

    return false;
}

static bool canAccessDocument(ScriptState* scriptState, Document* targetDocument, ExceptionState& exceptionState)
{
    LocalDOMWindow* callingWindow = scriptState->callingDOMWindow();
    if (isDocumentAccessibleFromDOMWindow(targetDocument, callingWindow))
        return true;

    if (targetDocument->domWindow())
        exceptionState.throwSecurityError(targetDocument->domWindow()->sanitizedCrossDomainAccessErrorMessage(callingWindow), targetDocument->domWindow()->crossDomainAccessErrorMessage(callingWindow));
    return false;
}

static bool canAccessDocument(ScriptState* scriptState, Document* targetDocument, SecurityReportingOption reportingOption = ReportSecurityError)
{
    LocalDOMWindow* callingWindow = scriptState->callingDOMWindow();
    if (isDocumentAccessibleFromDOMWindow(targetDocument, callingWindow))
        return true;

    if (reportingOption == ReportSecurityError && targetDocument->domWindow()) {
        if (LocalFrame* frame = targetDocument->frame())
            frame->domWindow()->printErrorMessage(targetDocument->domWindow()->crossDomainAccessErrorMessage(callingWindow));
    }

    return false;
}

bool BindingSecurity::shouldAllowAccessToFrame(ScriptState* scriptState, Frame* target, SecurityReportingOption reportingOption)
{
    if (!target || !target->isLocalFrame())
        return false;
    return canAccessDocument(scriptState, toLocalFrame(target)->document(), reportingOption);
}

bool BindingSecurity::shouldAllowAccessToFrame(ScriptState* scriptState, Frame* target, ExceptionState& exceptionState)
{
    if (!target || !target->isLocalFrame())
        return false;
    return canAccessDocument(scriptState, toLocalFrame(target)->document(), exceptionState);
}

bool BindingSecurity::shouldAllowAccessToNode(ScriptState* scriptState, Node* target, ExceptionState& exceptionState)
{
    return target && canAccessDocument(scriptState, &target->document(), exceptionState);
}

}
