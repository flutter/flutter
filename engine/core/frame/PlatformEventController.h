// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef PlatformEventController_h
#define PlatformEventController_h

#include "core/page/PageLifecycleObserver.h"
#include "platform/Timer.h"
#include "platform/heap/Handle.h"

namespace blink {

// Base controller class for registering controllers with a dispatcher.
// It watches page visibility and calls stopUpdating when page is not visible.
// It provides a didUpdateData() callback method which is called when new data
// it available.
class PlatformEventController : public PageLifecycleObserver {
public:
    void startUpdating();
    void stopUpdating();

    // This is called when new data becomes available.
    virtual void didUpdateData() = 0;

protected:
    explicit PlatformEventController(Page*);
    virtual ~PlatformEventController();

    virtual void registerWithDispatcher() = 0;
    virtual void unregisterWithDispatcher() = 0;

    // When true initiates a one-shot didUpdateData() when startUpdating() is called.
    virtual bool hasLastData() = 0;

    bool m_hasEventListener;

private:
    // Inherited from PageLifecycleObserver.
    virtual void pageVisibilityChanged() OVERRIDE;

    void oneShotCallback(Timer<PlatformEventController>*);

    bool m_isActive;
    Timer<PlatformEventController> m_timer;
};

} // namespace blink

#endif // PlatformEventController_h
