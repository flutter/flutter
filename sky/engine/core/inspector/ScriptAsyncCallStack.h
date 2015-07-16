// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_INSPECTOR_SCRIPTASYNCCALLSTACK_H_
#define SKY_ENGINE_CORE_INSPECTOR_SCRIPTASYNCCALLSTACK_H_

#include "sky/engine/core/inspector/ScriptCallStack.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class ScriptAsyncCallStack : public RefCounted<ScriptAsyncCallStack> {
    DECLARE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(ScriptAsyncCallStack);
public:
    static PassRefPtr<ScriptAsyncCallStack> create(const String&, PassRefPtr<ScriptCallStack>, PassRefPtr<ScriptAsyncCallStack>);

private:
    ScriptAsyncCallStack(const String&, PassRefPtr<ScriptCallStack>, PassRefPtr<ScriptAsyncCallStack>);

    String m_description;
    RefPtr<ScriptCallStack> m_callStack;
    RefPtr<ScriptAsyncCallStack> m_asyncStackTrace;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_INSPECTOR_SCRIPTASYNCCALLSTACK_H_
