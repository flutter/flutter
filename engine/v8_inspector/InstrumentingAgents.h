// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_V8_INSPECTOR_INSTRUMENTINGAGENTS_H_
#define SKY_ENGINE_V8_INSPECTOR_INSTRUMENTINGAGENTS_H_

#include "sky/engine/wtf/Noncopyable.h"

namespace blink {

// This is a stub.
// This allows one agent to talk to another.

class InspectorDebuggerAgent;

class InstrumentingAgents {
  WTF_MAKE_NONCOPYABLE(InstrumentingAgents);
public:
  InstrumentingAgents(InspectorDebuggerAgent* agent) : debug_agent_(agent) {}

  InspectorDebuggerAgent* inspectorDebuggerAgent() {
      return debug_agent_;
  }

private:

  InspectorDebuggerAgent* debug_agent_;
};

} // namespace blink

#endif  // SKY_ENGINE_V8_INSPECTOR_INSTRUMENTINGAGENTS_H_
