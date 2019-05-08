// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_LOOP_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_LOOP_H_

#include <lib/async-loop/cpp/loop.h>

namespace flutter_runner {

// Creates a loop which allows task observers to be attached to it.
async::Loop* MakeObservableLoop(bool attachToThread);

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_LOOP_H_
