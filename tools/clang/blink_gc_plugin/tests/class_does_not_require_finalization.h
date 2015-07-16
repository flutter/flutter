// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CLASS_DOES_NOT_REQUIRE_FINALIZATION_BASE_H_
#define CLASS_DOES_NOT_REQUIRE_FINALIZATION_BASE_H_

#include "heap/stubs.h"

namespace blink {

class DoesNeedFinalizer : public GarbageCollectedFinalized<DoesNeedFinalizer> {
public:
    ~DoesNeedFinalizer() { ; }
    void trace(Visitor*);
};

class DoesNotNeedFinalizer
    : public GarbageCollectedFinalized<DoesNotNeedFinalizer> {
public:
    void trace(Visitor*);
};

class DoesNotNeedFinalizer2
    : public GarbageCollectedFinalized<DoesNotNeedFinalizer2> {
public:
    ~DoesNotNeedFinalizer2();
    void trace(Visitor*);
};

class HasEmptyDtor {
public:
    virtual ~HasEmptyDtor() { }
};

class DoesNotNeedFinalizer3
    : public GarbageCollectedFinalized<DoesNotNeedFinalizer3>,
      public HasEmptyDtor {
public:
    void trace(Visitor*);
};

}

#endif
