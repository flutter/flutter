// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef PlatformEventDispatcher_h
#define PlatformEventDispatcher_h

#include "wtf/Vector.h"

namespace blink {
class PlatformEventController;

class PlatformEventDispatcher {
public:
    void addController(PlatformEventController*);
    void removeController(PlatformEventController*);

protected:
    PlatformEventDispatcher();
    virtual ~PlatformEventDispatcher();

    void notifyControllers();

    virtual void startListening() = 0;
    virtual void stopListening() = 0;

private:
    void purgeControllers();

    Vector<PlatformEventController*> m_controllers;
    bool m_needsPurge;
    bool m_isDispatching;
};

} // namespace blink

#endif // PlatformEventDispatcher_h
