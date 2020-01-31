// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_TASK_OBSERVERS_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_TASK_OBSERVERS_H_

#include <lib/fit/function.h>

namespace flutter_runner {

void ExecuteAfterTaskObservers();

void CurrentMessageLoopAddAfterTaskObserver(intptr_t key,
                                            fit::closure observer);

void CurrentMessageLoopRemoveAfterTaskObserver(intptr_t key);

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_TASK_OBSERVERS_H_
