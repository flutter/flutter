// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "gtest/gtest.h"

namespace impeller {

class Playground : public ::testing::Test {
 public:
  Playground();

  ~Playground();

  bool OpenPlaygroundHere(std::function<bool()> closure);

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(Playground);
};

}  // namespace impeller
