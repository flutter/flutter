// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/message_pump/message_pump_mojo.h"

#include "base/message_loop/message_loop_test.h"
#include "base/run_loop.h"
#include "mojo/message_pump/message_pump_mojo_handler.h"
#include "mojo/public/cpp/system/core.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace common {
namespace test {

scoped_ptr<base::MessagePump> CreateMojoMessagePump() {
  return scoped_ptr<base::MessagePump>(new MessagePumpMojo());
}

RUN_MESSAGE_LOOP_TESTS(Mojo, &CreateMojoMessagePump);

class CountingMojoHandler : public MessagePumpMojoHandler {
 public:
  CountingMojoHandler() : success_count_(0), error_count_(0) {}

  void OnHandleReady(const Handle& handle) override {
    ReadMessageRaw(static_cast<const MessagePipeHandle&>(handle),
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   MOJO_READ_MESSAGE_FLAG_NONE);
    ++success_count_;
  }
  void OnHandleError(const Handle& handle, MojoResult result) override {
    ++error_count_;
  }

  int success_count() { return success_count_; }
  int error_count() { return error_count_; }

 private:
  int success_count_;
  int error_count_;

  DISALLOW_COPY_AND_ASSIGN(CountingMojoHandler);
};

class CountingObserver : public MessagePumpMojo::Observer {
 public:
  void WillSignalHandler() override { will_signal_handler_count++; }
  void DidSignalHandler() override { did_signal_handler_count++; }

  int will_signal_handler_count = 0;
  int did_signal_handler_count = 0;
};

TEST(MessagePumpMojo, RunUntilIdle) {
  base::MessageLoop message_loop(MessagePumpMojo::Create());
  CountingMojoHandler handler;
  MessagePipe handles;
  MessagePumpMojo::current()->AddHandler(&handler,
                                         handles.handle0.get(),
                                         MOJO_HANDLE_SIGNAL_READABLE,
                                         base::TimeTicks());
  WriteMessageRaw(
      handles.handle1.get(), NULL, 0, NULL, 0, MOJO_WRITE_MESSAGE_FLAG_NONE);
  WriteMessageRaw(
      handles.handle1.get(), NULL, 0, NULL, 0, MOJO_WRITE_MESSAGE_FLAG_NONE);
  base::RunLoop run_loop;
  run_loop.RunUntilIdle();
  EXPECT_EQ(2, handler.success_count());
}

TEST(MessagePumpMojo, Observer) {
  base::MessageLoop message_loop(MessagePumpMojo::Create());

  CountingObserver observer;
  MessagePumpMojo::current()->AddObserver(&observer);

  CountingMojoHandler handler;
  MessagePipe handles;
  MessagePumpMojo::current()->AddHandler(&handler,
                                         handles.handle0.get(),
                                         MOJO_HANDLE_SIGNAL_READABLE,
                                         base::TimeTicks());
  WriteMessageRaw(
      handles.handle1.get(), NULL, 0, NULL, 0, MOJO_WRITE_MESSAGE_FLAG_NONE);
  base::RunLoop run_loop;
  run_loop.RunUntilIdle();
  EXPECT_EQ(1, handler.success_count());
  EXPECT_EQ(1, observer.will_signal_handler_count);
  EXPECT_EQ(1, observer.did_signal_handler_count);
  MessagePumpMojo::current()->RemoveObserver(&observer);

  WriteMessageRaw(
      handles.handle1.get(), NULL, 0, NULL, 0, MOJO_WRITE_MESSAGE_FLAG_NONE);
  base::RunLoop run_loop2;
  run_loop2.RunUntilIdle();
  EXPECT_EQ(2, handler.success_count());
  EXPECT_EQ(1, observer.will_signal_handler_count);
  EXPECT_EQ(1, observer.did_signal_handler_count);
}

TEST(MessagePumpMojo, UnregisterAfterDeadline) {
  base::MessageLoop message_loop(MessagePumpMojo::Create());
  CountingMojoHandler handler;
  MessagePipe handles;
  MessagePumpMojo::current()->AddHandler(
      &handler,
      handles.handle0.get(),
      MOJO_HANDLE_SIGNAL_READABLE,
      base::TimeTicks::Now() - base::TimeDelta::FromSeconds(1));
  for (int i = 0; i < 2; ++i) {
    base::RunLoop run_loop;
    run_loop.RunUntilIdle();
  }
  EXPECT_EQ(1, handler.error_count());
}

}  // namespace test
}  // namespace common
}  // namespace mojo
