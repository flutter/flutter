// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Testing

struct DummyTest {
  @Test func `This test exists to prevent "Trying to load an unsigned library error"`() async {
    #expect(true == true)
  }
}
