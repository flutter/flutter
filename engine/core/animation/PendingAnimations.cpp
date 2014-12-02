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

#include "sky/engine/config.h"
#include "sky/engine/core/animation/PendingAnimations.h"

#include "sky/engine/core/animation/Animation.h"
#include "sky/engine/core/animation/AnimationTimeline.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/RenderLayer.h"

namespace blink {

void PendingAnimations::add(AnimationPlayer* player)
{
    ASSERT(player);
    ASSERT(m_pending.find(player) == kNotFound);
    m_pending.append(player);

    Document* document = player->timeline()->document();
    if (document->view())
        document->view()->scheduleAnimation();

    bool visible = document->page() && document->page()->visibilityState() == PageVisibilityStateVisible;
    if (!visible && !m_timer.isActive()) {
        m_timer.startOneShot(0, FROM_HERE);
    }
}

bool PendingAnimations::update()
{
    Vector<AnimationPlayer*> waitingForStartTime;
    Vector<RefPtr<AnimationPlayer> > players;
    players.swap(m_pending);

    for (size_t i = 0; i < players.size(); ++i) {
        AnimationPlayer& player = *players[i].get();
        player.preCommit();
        if (player.playing() && !player.hasStartTime()) {
            waitingForStartTime.append(&player);
        }
    }

    for (size_t i = 0; i < waitingForStartTime.size(); ++i) {
        if (!waitingForStartTime[i]->hasStartTime()) {
            waitingForStartTime[i]->notifyCompositorStartTime(waitingForStartTime[i]->timeline()->currentTimeInternal());
        }
    }

    // FIXME: The postCommit should happen *after* the commit, not before.
    for (size_t i = 0; i < players.size(); ++i) {
        AnimationPlayer& player = *players[i].get();
        player.postCommit(player.timeline()->currentTimeInternal());
    }

    ASSERT(m_pending.isEmpty());
    return false;
}

} // namespace
