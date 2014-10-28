// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef ScriptForbiddenScope_h
#define ScriptForbiddenScope_h

#include "platform/PlatformExport.h"
#include "wtf/Assertions.h"
#include "wtf/TemporaryChange.h"

namespace blink {

class PLATFORM_EXPORT ScriptForbiddenScope {
public:
    ScriptForbiddenScope();
    ~ScriptForbiddenScope();

    class PLATFORM_EXPORT AllowUserAgentScript {
    public:
        AllowUserAgentScript();
        ~AllowUserAgentScript();
    private:
        TemporaryChange<unsigned> m_change;
    };

    static void enter();
    static void exit();
    static bool isScriptForbidden();
};

} // namespace blink

#endif // ScriptForbiddenScope_h
