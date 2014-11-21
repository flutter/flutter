// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS_CORE_V8_SCRIPTPROMISEPROPERTIES_H_
#define SKY_ENGINE_BINDINGS_CORE_V8_SCRIPTPROMISEPROPERTIES_H_

// See ScriptPromiseProperty.h
#define SCRIPT_PROMISE_PROPERTIES(P, ...) \
    P(Ready ## __VA_ARGS__) \
    P(Closed ## __VA_ARGS__) \
    P(Loaded ## __VA_ARGS__)

#endif  // SKY_ENGINE_BINDINGS_CORE_V8_SCRIPTPROMISEPROPERTIES_H_
