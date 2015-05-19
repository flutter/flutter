// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_VIEW_EVENTCALLBACK_H_
#define SKY_ENGINE_CORE_VIEW_EVENTCALLBACK_H_

namespace blink {
class Event;

class EventCallback {
public:
    virtual ~EventCallback() { }
    virtual bool handleEvent(Event* event) = 0;
};

}

#endif  // SKY_ENGINE_CORE_VIEW_EVENTCALLBACK_H_
