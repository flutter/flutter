/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#ifndef SKY_ENGINE_CORE_FRAME_DOMTIMER_H_
#define SKY_ENGINE_CORE_FRAME_DOMTIMER_H_

#include "sky/engine/bindings2/scheduled_action.h"
#include "sky/engine/core/frame/SuspendableTimer.h"
#include "sky/engine/wtf/Compiler.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/PassOwnPtr.h"

namespace blink {

class ExecutionContext;

class DOMTimer final : public SuspendableTimer {
public:
    // Creates a new timer owned by the ExecutionContext, starts it and returns its ID.
    static int install(ExecutionContext*, PassOwnPtr<ScheduledAction>, int timeout, bool singleShot);
    static void removeByID(ExecutionContext*, int timeoutID);

    virtual ~DOMTimer();

    int timeoutID() const;

    // ActiveDOMObject
    virtual void contextDestroyed() override;
    virtual void stop() override;

    // The following are essentially constants. All intervals are in seconds.
    static double hiddenPageAlignmentInterval();
    static double visiblePageAlignmentInterval();

private:
    friend class ExecutionContext; // For create().

    // Should only be used by ExecutionContext.
    static PassOwnPtr<DOMTimer> create(ExecutionContext* context, PassOwnPtr<ScheduledAction> action, int timeout, bool singleShot, int timeoutID)
    {
        return adoptPtr(new DOMTimer(context, action, timeout, singleShot, timeoutID));
    }

    DOMTimer(ExecutionContext*, PassOwnPtr<ScheduledAction>, int interval, bool singleShot, int timeoutID);
    virtual void fired() override;

    // Retuns timer fire time rounded to the next multiple of timer alignment interval.
    virtual double alignedFireTime(double) const override;

    int m_timeoutID;
    int m_nestingLevel;
    OwnPtr<ScheduledAction> m_action;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_FRAME_DOMTIMER_H_
