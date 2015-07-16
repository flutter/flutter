// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "base/test/ios/wait_util.h"

#import <Foundation/Foundation.h>

#include "base/logging.h"
#include "base/mac/scoped_nsobject.h"
#include "base/message_loop/message_loop.h"
#include "base/test/test_timeouts.h"
#include "base/timer/elapsed_timer.h"

namespace base {
namespace test {
namespace ios {

TimeDelta TimeUntilCondition(ProceduralBlock action,
                             ConditionBlock condition,
                             MessageLoop* message_loop,
                             TimeDelta timeout) {
  ElapsedTimer timer;
  if (action)
    action();
  if (timeout == TimeDelta())
    timeout = TestTimeouts::action_timeout();
  const TimeDelta spin_delay(TimeDelta::FromMilliseconds(10));
  while (timer.Elapsed() < timeout && (!condition || !condition())) {
    SpinRunLoopWithMaxDelay(spin_delay);
    if (message_loop) {
      message_loop->RunUntilIdle();
    }
  }
  TimeDelta elapsed = timer.Elapsed();
  // If DCHECK is ever hit, check if |action| is doing something that is
  // taking an unreasonably long time, or if |condition| does not come
  // true quickly enough. Increase |timeout| only if necessary.
  DCHECK(!condition || condition());
  return elapsed;
}

void WaitUntilCondition(ConditionBlock condition,
                        MessageLoop* message_loop,
                        TimeDelta timeout) {
  TimeUntilCondition(nil, condition, message_loop, timeout);
}

void WaitUntilCondition(ConditionBlock condition) {
  WaitUntilCondition(condition, nullptr, TimeDelta());
}

void SpinRunLoopWithMaxDelay(TimeDelta max_delay) {
  scoped_nsobject<NSDate> beforeDate(
      [[NSDate alloc] initWithTimeIntervalSinceNow:max_delay.InSecondsF()]);
  [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                           beforeDate:beforeDate];
}

}  // namespace ios
}  // namespace test
}  // namespace base
