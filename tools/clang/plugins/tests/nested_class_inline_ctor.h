// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NESTED_CLASS_INLINE_CTOR_H_
#define NESTED_CLASS_INLINE_CTOR_H_

#include <string>
#include <vector>

// See crbug.com/136863.

class Foo {
  class Bar {
    Bar() {}
    ~Bar() {}

    std::vector<std::string> a;
  };
};

#endif  // NESTED_CLASS_INLINE_CTOR_H_
