// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_DART_MESSAGE_HANDLER_H_
#define SKY_ENGINE_TONIC_DART_MESSAGE_HANDLER_H_

#include "base/callback.h"
#include "base/message_loop/message_loop.h"
#include "dart/runtime/include/dart_api.h"

namespace blink {
class DartState;

class DartMessageHandler {
 public:
  DartMessageHandler();
  ~DartMessageHandler();

  // Messages for the current isolate will be scheduled on |runner|.
  void Initialize(const scoped_refptr<base::SingleThreadTaskRunner>& runner);

  // Request the message loop to quit when isolate exits? Default is true.
  void set_quit_message_loop_when_isolate_exits(
      bool quit_message_loop_when_isolate_exits) {
    quit_message_loop_when_isolate_exits_ =
        quit_message_loop_when_isolate_exits;
  }

  bool quit_message_loop_when_isolate_exits() const {
    return quit_message_loop_when_isolate_exits_;
  }

  // Did the isolate exit?
  bool isolate_exited() const {
    return isolate_exited_;
  }

  // Did the isolate have an uncaught exception error?
  bool isolate_had_uncaught_exception_error() const {
    return isolate_had_uncaught_exception_error_;
  }

 protected:
  // Called from an unknown thread for each message.
  void OnMessage(DartState* dart_state);
  // By default, called on the task runner's thread for each message.
  void OnHandleMessage(DartState* dart_state);

  scoped_refptr<base::SingleThreadTaskRunner> task_runner() const {
    return task_runner_;
  }

  bool handled_first_message() const {
    return handled_first_message_;
  }

  void set_handled_first_message(bool handled_first_message) {
    handled_first_message_ = handled_first_message;
  }

  bool handled_first_message_;
  bool quit_message_loop_when_isolate_exits_;
  bool isolate_exited_;
  bool isolate_had_uncaught_exception_error_;
  scoped_refptr<base::SingleThreadTaskRunner> task_runner_;

 private:
  static void HandleMessage(base::WeakPtr<DartState> dart_state);
  static void MessageNotifyCallback(Dart_Isolate dest_isolate);
};

}  // namespace blink

#endif  // SKY_ENGINE_TONIC_DART_MESSAGE_HANDLER_H_
