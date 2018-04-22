// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_PLATFORM_WIN_MESSAGE_LOOP_WIN_H_
#define FLUTTER_FML_PLATFORM_WIN_MESSAGE_LOOP_WIN_H_

#include <atomic>

#include <windows.h>

#include "flutter/fml/macros.h"
#include "flutter/fml/message_loop_impl.h"
#include "lib/fxl/memory/unique_object.h"

namespace fml {

class MessageLoopWin : public MessageLoopImpl {
 private:
  struct UniqueHandleTraits {
    static HANDLE InvalidValue() { return NULL; }
    static bool IsValid(HANDLE value) { return value != NULL; }
    static void Free(HANDLE value) { CloseHandle(value); }
  };

  bool running_;
  fxl::UniqueObject<HANDLE, UniqueHandleTraits> timer_;

  MessageLoopWin();

  ~MessageLoopWin() override;

  void Run() override;

  void Terminate() override;

  void WakeUp(fxl::TimePoint time_point) override;

  FRIEND_MAKE_REF_COUNTED(MessageLoopWin);
  FRIEND_REF_COUNTED_THREAD_SAFE(MessageLoopWin);
  FML_DISALLOW_COPY_AND_ASSIGN(MessageLoopWin);
};

}  // namespace fml

#endif  // FLUTTER_FML_PLATFORM_GENERIC_MESSAGE_LOOP_GENERIC_H_
