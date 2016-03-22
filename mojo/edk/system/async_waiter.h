// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_ASYNC_WAITER_H_
#define MOJO_EDK_SYSTEM_ASYNC_WAITER_H_

#include <functional>

#include "mojo/edk/system/awakable.h"
#include "mojo/public/c/system/types.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

// An |Awakable| implementation that just calls a given callback object.
class AsyncWaiter final : public Awakable {
 public:
  using AwakeCallback = std::function<void(MojoResult)>;

  // |callback| must satisfy the same contract as |Awakable::Awake()|.
  explicit AsyncWaiter(const AwakeCallback& callback);
  ~AsyncWaiter() override;

 private:
  // |Awakable| implementation:
  bool Awake(MojoResult result, uintptr_t context) override;

  AwakeCallback callback_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(AsyncWaiter);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_ASYNC_WAITER_H_
