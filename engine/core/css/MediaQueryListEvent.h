// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MediaQueryListEvent_h
#define MediaQueryListEvent_h

#include "sky/engine/core/css/MediaQueryList.h"
#include "sky/engine/core/events/Event.h"

namespace blink {

struct MediaQueryListEventInit : public EventInit {
    MediaQueryListEventInit() : matches(false) { }

    String media;
    bool matches;
};

class MediaQueryListEvent final : public Event {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<MediaQueryListEvent> create()
    {
        return adoptRef(new MediaQueryListEvent);
    }

    static PassRefPtr<MediaQueryListEvent> create(MediaQueryList* list)
    {
        return adoptRef(new MediaQueryListEvent(list));
    }

    static PassRefPtr<MediaQueryListEvent> create(const String& media, bool matches)
    {
        return adoptRef(new MediaQueryListEvent(media, matches));
    }

    static PassRefPtr<MediaQueryListEvent> create(const AtomicString& eventType, const MediaQueryListEventInit& initializer)
    {
        return adoptRef(new MediaQueryListEvent(eventType, initializer));
    }

    String media() const { return m_mediaQueryList ? m_mediaQueryList->media() : m_media; }
    bool matches() const { return m_mediaQueryList ? m_mediaQueryList->matches() : m_matches; }

    virtual const AtomicString& interfaceName() const override { return EventNames::MediaQueryListEvent; }

private:
    MediaQueryListEvent()
        : m_matches(false)
    {
    }

    MediaQueryListEvent(const String& media, bool matches)
        : Event(EventTypeNames::change, false, false)
        , m_media(media)
        , m_matches(matches)
    {
    }

    explicit MediaQueryListEvent(MediaQueryList* list)
        : Event(EventTypeNames::change, false, false)
        , m_mediaQueryList(list)
        , m_matches(false)
    {
    }

    MediaQueryListEvent(const AtomicString& eventType, const MediaQueryListEventInit& initializer)
        : Event(eventType, initializer)
        , m_media(initializer.media)
        , m_matches(initializer.matches)
    {
    }

    // We have m_media/m_matches for JS-created events; we use m_mediaQueryList
    // for events that blink generates.
    RefPtr<MediaQueryList> m_mediaQueryList;
    String m_media;
    bool m_matches;
};

} // namespace blink

#endif // MediaQueryListEvent_h
