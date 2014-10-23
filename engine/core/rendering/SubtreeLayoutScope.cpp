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

#include "config.h"
#include "core/rendering/SubtreeLayoutScope.h"

#include "core/frame/FrameView.h"
#include "core/rendering/RenderObject.h"

namespace blink {

SubtreeLayoutScope::SubtreeLayoutScope(RenderObject& root)
    : m_root(root)
{
    RELEASE_ASSERT(m_root.document().view()->isInPerformLayout());
}

SubtreeLayoutScope::~SubtreeLayoutScope()
{
    RELEASE_ASSERT(!m_root.needsLayout());

#if ENABLE(ASSERT)
    for (HashSet<RenderObject*>::iterator it = m_renderersToLayout.begin(); it != m_renderersToLayout.end(); ++it)
        (*it)->assertRendererLaidOut();
#endif
}

void SubtreeLayoutScope::setNeedsLayout(RenderObject* descendant)
{
    ASSERT(descendant->isDescendantOf(&m_root));
    descendant->setNeedsLayoutAndFullPaintInvalidation(MarkContainingBlockChain, this);
}

void SubtreeLayoutScope::setChildNeedsLayout(RenderObject* descendant)
{
    ASSERT(descendant->isDescendantOf(&m_root));
    descendant->setChildNeedsLayout(MarkContainingBlockChain, this);
}

void SubtreeLayoutScope::addRendererToLayout(RenderObject* renderer)
{
#if ENABLE(ASSERT)
    m_renderersToLayout.add(renderer);
#endif
}

}
