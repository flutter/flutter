// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Pseudorandom number generation for tests.

#ifndef MOJO_EDK_SYSTEM_TEST_RANDOM_H_
#define MOJO_EDK_SYSTEM_TEST_RANDOM_H_

namespace mojo {
namespace system {
namespace test {

// Returns a (uniformly) (pseudo)random integer in the interval [min, max].
// Currently, |max - min| must be at most |RAND_MAX| and must also be (strictly)
// less than |INT_MAX|.
int RandomInt(int min, int max);

}  // namespace test
}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_TEST_RANDOM_H_
