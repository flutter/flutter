// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef InstrumentingAgents_h
#define InstrumentingAgents_h

#include "wtf/Noncopyable.h"

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

#endif // InstrumentingAgents_h
