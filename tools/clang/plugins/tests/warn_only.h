// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef WARN_ONLY_H_
#define WARN_ONLY_H_

#include <string>
#include <vector>

class InlineCtors {
 public:
  InlineCtors() {}
  ~InlineCtors() {}

 private:
  std::vector<int> one_;
  std::vector<std::string> two_;
};

#endif  // WARN_ONLY_H_
