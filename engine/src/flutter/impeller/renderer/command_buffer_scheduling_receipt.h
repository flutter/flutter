// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_COMMAND_BUFFER_SCHEDULING_RECEIPT_H_
#define FLUTTER_IMPELLER_RENDERER_COMMAND_BUFFER_SCHEDULING_RECEIPT_H_

#include <vector>

#include "flutter/fml/closure.h"
#include "impeller/base/thread.h"

namespace impeller {

/// A thread-safe receipt for the scheduling state of a submitted command
/// buffer.
///
/// A terminal command buffer has completed or failed and therefore cannot
/// begin executing GPU work later. Waiting is safe from multiple threads and
/// returns once either the scheduled or terminal state is reached.
class CommandBufferSchedulingReceipt {
 public:
  virtual ~CommandBufferSchedulingReceipt();

  virtual void WaitUntilScheduled() const = 0;

  virtual bool IsScheduledOrTerminal() const = 0;

  /// Registers a callback that is invoked once the receipt is scheduled or
  /// terminal. If it is already satisfied, the callback is invoked before this
  /// method returns.
  virtual void AddScheduledOrTerminalCallback(fml::closure callback) = 0;
};

/// The shared scheduling state used by renderer backends to produce a receipt.
class CommandBufferSchedulingReceiptState final
    : public CommandBufferSchedulingReceipt {
 public:
  CommandBufferSchedulingReceiptState();

  ~CommandBufferSchedulingReceiptState() override;

  // |CommandBufferSchedulingReceipt|
  void WaitUntilScheduled() const override;

  // |CommandBufferSchedulingReceipt|
  bool IsScheduledOrTerminal() const override;

  // |CommandBufferSchedulingReceipt|
  void AddScheduledOrTerminalCallback(fml::closure callback) override;

  /// Called by a backend when the submitted command buffer is scheduled.
  void MarkScheduled();

  /// Called by a backend when the submitted command buffer completes or fails.
  void MarkTerminal();

 private:
  enum class State {
    kPending,
    kScheduled,
    kTerminal,
  };

  void MarkSatisfied(State state);

  mutable Mutex mutex_;
  mutable ConditionVariable condition_;
  State state_ IPLR_GUARDED_BY(mutex_) = State::kPending;
  std::vector<fml::closure> callbacks_ IPLR_GUARDED_BY(mutex_);

  CommandBufferSchedulingReceiptState(
      const CommandBufferSchedulingReceiptState&) = delete;

  CommandBufferSchedulingReceiptState& operator=(
      const CommandBufferSchedulingReceiptState&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_COMMAND_BUFFER_SCHEDULING_RECEIPT_H_
