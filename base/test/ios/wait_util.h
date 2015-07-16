// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_IOS_WAIT_UTIL_H_
#define BASE_TEST_IOS_WAIT_UTIL_H_

#include "base/ios/block_types.h"
#include "base/time/time.h"

namespace base {

class MessageLoop;

namespace test {
namespace ios {

// Returns the time spent in running |action| plus waiting until |condition| is
// met.
// Performs |action| and then spins run loop and runs the |message_loop| until
// |condition| block returns true.
// |action| may be nil if no action needs to be performed before the wait loop.
// |message_loop| can be null if there is no need to spin the message loop.
// |condition| may be nil if there is no condition to wait for: the run loop
// will spin until timeout is reached.
// |timeout| parameter sets the maximum wait time. If |timeout| is zero,
// a reasonable default will be used.
TimeDelta TimeUntilCondition(ProceduralBlock action,
                             ConditionBlock condition,
                             MessageLoop* message_loop,
                             TimeDelta timeout);

// Waits until |condition| is met. A |message_loop| to spin and a |timeout| can
// be optionally passed; if |timeout| is zero, a reasonable default will be
// used.
void WaitUntilCondition(ConditionBlock condition,
                        MessageLoop* message_loop,
                        TimeDelta timeout);
void WaitUntilCondition(ConditionBlock condition);

// Lets the run loop of the current thread process other messages
// within the given maximum delay.
void SpinRunLoopWithMaxDelay(TimeDelta max_delay);

}  // namespace ios
}  // namespace test
}  // namespace base

#endif  // BASE_TEST_IOS_WAIT_UTIL_H_
