// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "inline_ctor.h"

#include <string>
#include <vector>

// We don't warn on classes that are in CPP files.
class InlineInCPPOK {
 public:
  InlineInCPPOK() {}
  ~InlineInCPPOK() {}

 private:
  std::vector<int> one_;
  std::vector<std::string> two_;
};

int main() {
  InlineInCPPOK one;
  InlineCtorsArentOKInHeader two;
  return 0;
}
