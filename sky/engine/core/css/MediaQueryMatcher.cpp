/*
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies)
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Library General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Library General Public License for more details.
 *
 *  You should have received a copy of the GNU Library General Public License
 *  along with this library; see the file COPYING.LIB.  If not, write to
 *  the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301, USA.
 */

#include "sky/engine/core/css/MediaQueryMatcher.h"

#include "sky/engine/core/css/MediaList.h"
#include "sky/engine/core/css/MediaQueryEvaluator.h"
#include "sky/engine/core/css/MediaQueryList.h"
#include "sky/engine/core/css/MediaQueryListEvent.h"
#include "sky/engine/core/css/MediaQueryListListener.h"
#include "sky/engine/core/css/resolver/StyleResolver.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/wtf/Vector.h"

// Note: when removing EventTarget, the MediaQuery logic was
// disconnected from Documents, and as part of that, the
// viewportChanged and mediaFeaturesChanged methods were dropped.

namespace blink {

PassRefPtr<MediaQueryMatcher> MediaQueryMatcher::create(Document& document)
{
    return adoptRef(new MediaQueryMatcher(document));
}

MediaQueryMatcher::MediaQueryMatcher(Document& document)
    : m_document(&document)
{
    ASSERT(m_document);
}

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(MediaQueryMatcher)

void MediaQueryMatcher::documentDetached()
{
    m_document = nullptr;
    m_evaluator = nullptr;
}

PassOwnPtr<MediaQueryEvaluator> MediaQueryMatcher::createEvaluator() const
{
    if (!m_document || !m_document->frame())
        return nullptr;

    return adoptPtr(new MediaQueryEvaluator(m_document->frame()));
}

bool MediaQueryMatcher::evaluate(const MediaQuerySet* media)
{
    ASSERT(!m_document || m_document->frame() || !m_evaluator);

    if (!media)
        return false;

    // Cache the evaluator to avoid allocating one per evaluation.
    if (!m_evaluator)
        m_evaluator = createEvaluator();

    if (m_evaluator)
        return m_evaluator->eval(media);

    return false;
}

PassRefPtr<MediaQueryList> MediaQueryMatcher::matchMedia(const String& query)
{
    if (!m_document)
        return nullptr;

    RefPtr<MediaQuerySet> media = MediaQuerySet::create(query);
    return MediaQueryList::create(this, media);
}

void MediaQueryMatcher::addMediaQueryList(MediaQueryList* query)
{
    if (!m_document)
        return;
    m_mediaLists.add(query);
}

void MediaQueryMatcher::removeMediaQueryList(MediaQueryList* query)
{
    if (!m_document)
        return;
    m_mediaLists.remove(query);
}

void MediaQueryMatcher::addViewportListener(MediaQueryListListener* listener)
{
    if (!m_document)
        return;
    m_viewportListeners.add(listener);
}

void MediaQueryMatcher::removeViewportListener(MediaQueryListListener* listener)
{
    if (!m_document)
        return;
    m_viewportListeners.remove(listener);
}

}
