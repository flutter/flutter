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

#ifndef MediaQueryList_h
#define MediaQueryList_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "core/dom/ActiveDOMObject.h"
#include "core/events/EventTarget.h"
#include "platform/heap/Handle.h"
#include "wtf/Forward.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"

namespace blink {

class Document;
class ExecutionContext;
class MediaQueryListListener;
class MediaQueryEvaluator;
class MediaQueryMatcher;
class MediaQuerySet;

// MediaQueryList interface is specified at http://dev.w3.org/csswg/cssom-view/#the-mediaquerylist-interface
// The objects of this class are returned by window.matchMedia. They may be used to
// retrieve the current value of the given media query and to add/remove listeners that
// will be called whenever the value of the query changes.

class MediaQueryList FINAL : public RefCountedWillBeGarbageCollectedFinalized<MediaQueryList>, public EventTargetWithInlineData, public ActiveDOMObject {
    DEFINE_EVENT_TARGET_REFCOUNTING_WILL_BE_REMOVED(RefCounted<MediaQueryList>);
    DEFINE_WRAPPERTYPEINFO();
    WILL_BE_USING_GARBAGE_COLLECTED_MIXIN(MediaQueryList);
public:
    static PassRefPtrWillBeRawPtr<MediaQueryList> create(ExecutionContext*, PassRefPtrWillBeRawPtr<MediaQueryMatcher>, PassRefPtrWillBeRawPtr<MediaQuerySet>);
    virtual ~MediaQueryList();

    String media() const;
    bool matches();

    DEFINE_ATTRIBUTE_EVENT_LISTENER(change);

    // These two functions are provided for compatibility with JS code
    // written before the change listener became a DOM event.
    void addDeprecatedListener(PassRefPtr<EventListener>);
    void removeDeprecatedListener(PassRefPtr<EventListener>);

    // C++ code can use these functions to listen to changes instead of having to use DOM event listeners.
    void addListener(PassRefPtrWillBeRawPtr<MediaQueryListListener>);
    void removeListener(PassRefPtrWillBeRawPtr<MediaQueryListListener>);

    // Will return true if a DOM event should be scheduled.
    bool mediaFeaturesChanged(WillBeHeapVector<RefPtrWillBeMember<MediaQueryListListener> >* listenersToNotify);

    void trace(Visitor*);

    // From ActiveDOMObject
    virtual bool hasPendingActivity() const OVERRIDE;
    virtual void stop() OVERRIDE;

    virtual const AtomicString& interfaceName() const OVERRIDE;
    virtual ExecutionContext* executionContext() const OVERRIDE;

private:
    MediaQueryList(ExecutionContext*, PassRefPtrWillBeRawPtr<MediaQueryMatcher>, PassRefPtrWillBeRawPtr<MediaQuerySet>);

    bool updateMatches();

    RefPtrWillBeMember<MediaQueryMatcher> m_matcher;
    RefPtrWillBeMember<MediaQuerySet> m_media;
    typedef WillBeHeapListHashSet<RefPtrWillBeMember<MediaQueryListListener> > ListenerList;
    ListenerList m_listeners;
    bool m_matchesDirty;
    bool m_matches;
};

} // namespace blink

#endif // MediaQueryList_h
