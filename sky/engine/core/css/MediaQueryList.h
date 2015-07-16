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

#ifndef SKY_ENGINE_CORE_CSS_MEDIAQUERYLIST_H_
#define SKY_ENGINE_CORE_CSS_MEDIAQUERYLIST_H_

#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/core/dom/ActiveDOMObject.h"
#include "sky/engine/core/events/EventTarget.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/LinkedHashSet.h"
#include "sky/engine/wtf/ListHashSet.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/RefPtr.h"

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

class MediaQueryList final : public RefCounted<MediaQueryList>, public EventTargetWithInlineData, public ActiveDOMObject {
    DEFINE_EVENT_TARGET_REFCOUNTING_WILL_BE_REMOVED(RefCounted<MediaQueryList>);
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<MediaQueryList> create(ExecutionContext*, PassRefPtr<MediaQueryMatcher>, PassRefPtr<MediaQuerySet>);
    virtual ~MediaQueryList();

    String media() const;
    bool matches();

    // These two functions are provided for compatibility with JS code
    // written before the change listener became a DOM event.
    void addDeprecatedListener(PassRefPtr<EventListener>);
    void removeDeprecatedListener(PassRefPtr<EventListener>);

    // C++ code can use these functions to listen to changes instead of having to use DOM event listeners.
    void addListener(PassRefPtr<MediaQueryListListener>);
    void removeListener(PassRefPtr<MediaQueryListListener>);

    // Will return true if a DOM event should be scheduled.
    bool mediaFeaturesChanged(Vector<RefPtr<MediaQueryListListener> >* listenersToNotify);

    // From ActiveDOMObject
    virtual bool hasPendingActivity() const override;
    virtual void stop() override;

    virtual const AtomicString& interfaceName() const override;
    virtual ExecutionContext* executionContext() const override;

private:
    MediaQueryList(ExecutionContext*, PassRefPtr<MediaQueryMatcher>, PassRefPtr<MediaQuerySet>);

    bool updateMatches();

    RefPtr<MediaQueryMatcher> m_matcher;
    RefPtr<MediaQuerySet> m_media;
    typedef ListHashSet<RefPtr<MediaQueryListListener> > ListenerList;
    ListenerList m_listeners;
    bool m_matchesDirty;
    bool m_matches;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_MEDIAQUERYLIST_H_
