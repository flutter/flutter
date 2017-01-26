// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_DIRECT_INPUT_H_
#define FLUTTER_CONTENT_HANDLER_DIRECT_INPUT_H_

#include <functional>
#include <set>
#include <vector>

#include "flutter/lib/ui/window/pointer_data_packet.h"
#include "lib/fidl/c/waiter/async_waiter.h"
#include "lib/ftl/files/unique_fd.h"
#include "lib/ftl/macros.h"

namespace flutter_runner {

class DirectInput {
 public:
  using DirectInputCallback =
      std::function<void(const blink::PointerDataPacket& packet)>;

  explicit DirectInput(DirectInputCallback callback);

  ~DirectInput();

  bool IsValid() const;

  void WaitForReadAvailability();

  void CancelWaitForReadAvailability();

 private:
  DirectInputCallback callback_;
  bool valid_;
  ftl::UniqueFD touch_fd_;
  ftl::UniqueFD input_event_;
  std::vector<uint8_t> read_buffer_;
  FidlAsyncWaitID last_wait_;
  std::set<int64_t> touch_ids_;

  static ftl::UniqueFD GetTouchFileDescriptor();

  void OnReadAvailable();

  void PerformRead();

  FTL_DISALLOW_COPY_AND_ASSIGN(DirectInput);
};

}  // namespace flutter_runner

#endif  // FLUTTER_CONTENT_HANDLER_DIRECT_INPUT_H_
