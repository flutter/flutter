// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "trace_templated_super.h"

namespace blink {

template<typename T>
void Super<T>::clearWeakMembers(Visitor* visitor)
{
    (void)m_weak;
}

template<typename T>
void Super<T>::trace(Visitor* visitor)
{
    visitor->registerWeakMembers<Super<T>, &Super<T>::clearWeakMembers>(this);
    visitor->trace(m_obj);
    Mixin::trace(visitor);
}

template<typename T>
void Sub<T>::trace(Visitor* visitor)
{
    // Missing trace of m_obj.
    Super<T>::trace(visitor);
}

void HeapObject::trace(Visitor* visitor)
{
    visitor->trace(m_obj);
    Sub<HeapObject>::trace(visitor);
}

}
