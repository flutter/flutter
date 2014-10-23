// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MediaQueryListEvent_h
#define MediaQueryListEvent_h

#include "core/css/MediaQueryList.h"
#include "core/events/Event.h"

namespace blink {

struct MediaQueryListEventInit : public EventInit {
    MediaQueryListEventInit() : matches(false) { }

    String media;
    bool matches;
};

class MediaQueryListEvent FINAL : public Event {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtrWillBeRawPtr<MediaQueryListEvent> create()
    {
        return adoptRefWillBeNoop(new MediaQueryListEvent);
    }

    static PassRefPtrWillBeRawPtr<MediaQueryListEvent> create(MediaQueryList* list)
    {
        return adoptRefWillBeNoop(new MediaQueryListEvent(list));
    }

    static PassRefPtrWillBeRawPtr<MediaQueryListEvent> create(const String& media, bool matches)
    {
        return adoptRefWillBeNoop(new MediaQueryListEvent(media, matches));
    }

    static PassRefPtrWillBeRawPtr<MediaQueryListEvent> create(const AtomicString& eventType, const MediaQueryListEventInit& initializer)
    {
        return adoptRefWillBeNoop(new MediaQueryListEvent(eventType, initializer));
    }

    String media() const { return m_mediaQueryList ? m_mediaQueryList->media() : m_media; }
    bool matches() const { return m_mediaQueryList ? m_mediaQueryList->matches() : m_matches; }

    virtual const AtomicString& interfaceName() const OVERRIDE { return EventNames::MediaQueryListEvent; }

    virtual void trace(Visitor* visitor) OVERRIDE
    {
        Event::trace(visitor);
        visitor->trace(m_mediaQueryList);
    }

private:
    MediaQueryListEvent()
        : m_matches(false)
    {
        ScriptWrappable::init(this);
    }

    MediaQueryListEvent(const String& media, bool matches)
        : Event(EventTypeNames::change, false, false)
        , m_media(media)
        , m_matches(matches)
    {
        ScriptWrappable::init(this);
    }

    explicit MediaQueryListEvent(MediaQueryList* list)
        : Event(EventTypeNames::change, false, false)
        , m_mediaQueryList(list)
        , m_matches(false)
    {
        ScriptWrappable::init(this);
    }

    MediaQueryListEvent(const AtomicString& eventType, const MediaQueryListEventInit& initializer)
        : Event(eventType, initializer)
        , m_media(initializer.media)
        , m_matches(initializer.matches)
    {
        ScriptWrappable::init(this);
    }

    // We have m_media/m_matches for JS-created events; we use m_mediaQueryList
    // for events that blink generates.
    RefPtrWillBeMember<MediaQueryList> m_mediaQueryList;
    String m_media;
    bool m_matches;
};

} // namespace blink

#endif // MediaQueryListEvent_h
