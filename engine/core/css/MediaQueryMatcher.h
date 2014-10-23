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

#ifndef MediaQueryMatcher_h
#define MediaQueryMatcher_h

#include "platform/heap/Handle.h"
#include "wtf/Forward.h"
#include "wtf/RefCounted.h"

namespace blink {

class Document;
class MediaQueryList;
class MediaQueryListListener;
class MediaQueryEvaluator;
class MediaQuerySet;

// MediaQueryMatcher class is responsible for keeping a vector of pairs
// MediaQueryList x MediaQueryListListener. It is responsible for evaluating the queries
// whenever it is needed and to call the listeners if the corresponding query has changed.
// The listeners must be called in the very same order in which they have been added.

class MediaQueryMatcher FINAL : public RefCountedWillBeGarbageCollectedFinalized<MediaQueryMatcher> {
    DECLARE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(MediaQueryMatcher)
public:
    static PassRefPtrWillBeRawPtr<MediaQueryMatcher> create(Document&);
    void documentDetached();

    void addMediaQueryList(MediaQueryList*);
    void removeMediaQueryList(MediaQueryList*);

    void addViewportListener(MediaQueryListListener*);
    void removeViewportListener(MediaQueryListListener*);

    PassRefPtrWillBeRawPtr<MediaQueryList> matchMedia(const String&);

    void mediaFeaturesChanged();
    void viewportChanged();
    bool evaluate(const MediaQuerySet*);

    void trace(Visitor*);

private:
    explicit MediaQueryMatcher(Document&);

    PassOwnPtr<MediaQueryEvaluator> createEvaluator() const;

    RawPtrWillBeMember<Document> m_document;
    OwnPtr<MediaQueryEvaluator> m_evaluator;

    typedef WillBeHeapLinkedHashSet<RawPtrWillBeWeakMember<MediaQueryList> > MediaQueryListSet;
    MediaQueryListSet m_mediaLists;

    typedef WillBeHeapLinkedHashSet<RawPtrWillBeWeakMember<MediaQueryListListener> > ViewportListenerSet;
    ViewportListenerSet m_viewportListeners;
};

}

#endif // MediaQueryMatcher_h
