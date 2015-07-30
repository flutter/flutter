// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SERVICES_SKY_RUNTIME_FLAGS_H_
#define SERVICES_SKY_RUNTIME_FLAGS_H_

namespace mojo {
class ApplicationImpl;
}

namespace sky {

class RuntimeFlags {
 public:
  static void Initialize(mojo::ApplicationImpl* app);
  static const RuntimeFlags& Get();

  bool testing() const { return testing_; }
  bool enable_checked_mode() const { return enable_checked_mode_; }

 private:
  bool testing_ = false;
  bool enable_checked_mode_ = false;
};

}  // namespace sky

#endif  // SERVICES_SKY_RUNTIME_FLAGS_H_
