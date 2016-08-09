// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CLASS_REQUIRES_TRACE_METHOD_H_
#define CLASS_REQUIRES_TRACE_METHOD_H_

#include "heap/stubs.h"

namespace blink {

class HeapObject;

class PartObject {
    DISALLOW_ALLOCATION();
private:
    Member<HeapObject> m_obj;
};

class HeapObject : public GarbageCollected<HeapObject> {
private:
    PartObject m_part;
};

class Mixin : public GarbageCollectedMixin {
public:
  virtual void trace(Visitor*) override;
  Member<Mixin> m_self;
};

class HeapObjectMixin : public GarbageCollected<HeapObjectMixin>, public Mixin {
  USING_GARBAGE_COLLECTED_MIXIN(HeapObjectMixin);
};

class Mixin2 : public Mixin {
public:
  virtual void trace(Visitor*) override;
};

class HeapObjectMixin2
    : public GarbageCollected<HeapObjectMixin2>, public Mixin2 {
  USING_GARBAGE_COLLECTED_MIXIN(HeapObjectMixin2);
};

class Mixin3 : public Mixin {
public:
  virtual void trace(Visitor*) override;
};

class HeapObjectMixin3
    : public GarbageCollected<HeapObjectMixin3>, public Mixin {
  USING_GARBAGE_COLLECTED_MIXIN(HeapObjectMixin2);
public:
  virtual void trace(Visitor*) override;
};

}

#endif
