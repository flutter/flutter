// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "platform/ScriptForbiddenScope.h"

#include "wtf/Assertions.h"
#include "wtf/MainThread.h"

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
