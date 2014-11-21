// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/platform/ScriptForbiddenScope.h"

#include "sky/engine/wtf/Assertions.h"
#include "sky/engine/wtf/MainThread.h"

namespace blink {

static unsigned s_scriptForbiddenCount = 0;

ScriptForbiddenScope::ScriptForbiddenScope()
{
    ASSERT(isMainThread());
    ++s_scriptForbiddenCount;
}

ScriptForbiddenScope::~ScriptForbiddenScope()
{
    ASSERT(isMainThread());
    ASSERT(s_scriptForbiddenCount);
    --s_scriptForbiddenCount;
}

void ScriptForbiddenScope::enter()
{
    ASSERT(isMainThread());
    ++s_scriptForbiddenCount;
}

void ScriptForbiddenScope::exit()
{
    ASSERT(isMainThread());
    ASSERT(s_scriptForbiddenCount);
    --s_scriptForbiddenCount;
}

bool ScriptForbiddenScope::isScriptForbidden()
{
    return isMainThread() && s_scriptForbiddenCount;
}

ScriptForbiddenScope::AllowUserAgentScript::AllowUserAgentScript()
    : m_change(s_scriptForbiddenCount, 0)
{
}

ScriptForbiddenScope::AllowUserAgentScript::~AllowUserAgentScript()
{
    ASSERT(!s_scriptForbiddenCount);
}

} // namespace blink
