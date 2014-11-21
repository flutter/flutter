// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_INSPECTOR_PROMISETRACKER_H_
#define SKY_ENGINE_CORE_INSPECTOR_PROMISETRACKER_H_

#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/Noncopyable.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/Vector.h"
#include "v8/include/v8.h"

namespace blink {

class ScriptState;

class PromiseTracker {
    WTF_MAKE_NONCOPYABLE(PromiseTracker);
public:
    PromiseTracker();
    ~PromiseTracker();

    bool isEnabled() const { return m_isEnabled; }
    void enable();
    void disable();

    void clear();

    void didReceiveV8PromiseEvent(ScriptState*, v8::Handle<v8::Object> promise, v8::Handle<v8::Value> parentPromise, int status);

    class PromiseData;

    typedef Vector<RefPtr<PromiseData> > PromiseDataVector;
    typedef HashMap<int, PromiseDataVector> PromiseDataMap;

private:
    bool m_isEnabled;
    PromiseDataMap m_promiseDataMap;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_INSPECTOR_PROMISETRACKER_H_
