// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Regression test for http://crbug.com/421958

#ifndef CRASH_ON_INVALID_H_
#define CRASH_ON_INVALID_H_

namespace blink {

class Visitor;
class GamepadCommon {};
class ScriptWrappable {};

class Gamepad final : public GarbageCollectedFinalized<Gamepad>,
                      public GamepadCommon,
                      public ScriptWrappable {
public:
    virtual const WrapperTypeInfo *wrapperTypeInfo() const {}
    void trace(Visitor *);
};

}

#endif
