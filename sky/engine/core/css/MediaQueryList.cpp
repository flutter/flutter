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

#include "sky/engine/core/css/MediaQueryList.h"
#include "gen/sky/core/EventTargetNames.h"
#include "sky/engine/core/css/MediaList.h"
#include "sky/engine/core/css/MediaQueryEvaluator.h"
#include "sky/engine/core/css/MediaQueryListListener.h"
#include "sky/engine/core/css/MediaQueryMatcher.h"
#include "sky/engine/core/dom/Document.h"

namespace blink {

PassRefPtr<MediaQueryList> MediaQueryList::create(PassRefPtr<MediaQueryMatcher> matcher, PassRefPtr<MediaQuerySet> media)
{
    RefPtr<MediaQueryList> list = adoptRef(new MediaQueryList(matcher, media));
    return list.release();
}

MediaQueryList::MediaQueryList(PassRefPtr<MediaQueryMatcher> matcher, PassRefPtr<MediaQuerySet> media)
    : m_matcher(matcher)
    , m_media(media)
    , m_matchesDirty(true)
    , m_matches(false)
{
    m_matcher->addMediaQueryList(this);
    updateMatches();
}

MediaQueryList::~MediaQueryList()
{
    m_matcher->removeMediaQueryList(this);
}

String MediaQueryList::media() const
{
    return m_media->mediaText();
}

void MediaQueryList::addListener(PassRefPtr<MediaQueryListListener> listener)
{
    if (!listener)
        return;

    m_listeners.add(listener);
}

void MediaQueryList::removeListener(PassRefPtr<MediaQueryListListener> listener)
{
    if (!listener)
        return;

    RefPtr<MediaQueryList> protect(this);
    m_listeners.remove(listener);
}

bool MediaQueryList::mediaFeaturesChanged(Vector<RefPtr<MediaQueryListListener> >* listenersToNotify)
{
    m_matchesDirty = true;
    if (!updateMatches())
        return false;
    for (ListenerList::const_iterator it = m_listeners.begin(), end = m_listeners.end(); it != end; ++it) {
        listenersToNotify->append(*it);
    }
    return false;
}

bool MediaQueryList::updateMatches()
{
    m_matchesDirty = false;
    if (m_matches != m_matcher->evaluate(m_media.get())) {
        m_matches = !m_matches;
        return true;
    }
    return false;
}

bool MediaQueryList::matches()
{
    updateMatches();
    return m_matches;
}

}
