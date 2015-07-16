// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "trace_if_needed.h"

namespace blink {

template<typename T>
void TemplatedObject<T>::trace(Visitor* visitor)
{
    TraceIfNeeded<T>::trace(visitor, &m_one);
    // Missing trace of m_two
}

}
