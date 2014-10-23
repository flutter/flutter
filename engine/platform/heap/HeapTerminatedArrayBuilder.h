// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef HeapTerminatedArrayBuilder_h
#define HeapTerminatedArrayBuilder_h

#include "platform/heap/Heap.h"
#include "platform/heap/HeapTerminatedArray.h"
#include "wtf/TerminatedArrayBuilder.h"

namespace blink {

template<typename T>
class HeapTerminatedArrayBuilder : public TerminatedArrayBuilder<T, HeapTerminatedArray> {
public:
    explicit HeapTerminatedArrayBuilder(HeapTerminatedArray<T>* array) : TerminatedArrayBuilder<T, HeapTerminatedArray>(array) { }
};

} // namespace blink

#endif // HeapTerminatedArrayBuilder_h
