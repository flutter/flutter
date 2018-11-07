// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_START_UP_H_
#define FLUTTER_RUNTIME_START_UP_H_

#include <stdint.h>

namespace blink {

// The earliest available timestamp in the application's lifecycle. The
// difference between this timestamp and the time we render the very first
// frame gives us a good idea about Flutter's startup time.
//
// This timestamp only covers Flutter's own startup. In an upside-down model
// it is possible that the first Flutter view is not initialized until some
// time later. In this case the timestamp may not cover the time spent in the
// user code prior to initializing Flutter.
extern int64_t engine_main_enter_ts;

}  // namespace blink

#endif  // FLUTTER_RUNTIME_START_UP_H_
