// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "traceimpl.h"

namespace blink {

void TraceImplExtern::trace(Visitor* visitor) {
  traceImpl(visitor);
}

template <typename VisitorDispatcher>
inline void TraceImplExtern::traceImpl(VisitorDispatcher visitor) {
  visitor->trace(x_);
}

void TraceImplBaseExtern::trace(Visitor* visitor) {
  traceImpl(visitor);
}

template <typename VisitorDispatcher>
inline void TraceImplBaseExtern::traceImpl(VisitorDispatcher visitor) {
  visitor->trace(x_);
  Base::trace(visitor);
}

}
