// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOOLS_BLINK_GC_PLUGIN_TRACING_STATUS_H_
#define TOOLS_BLINK_GC_PLUGIN_TRACING_STATUS_H_

// TracingStatus is a three-point value ordered by unneeded < unknown < needed.
class TracingStatus {
 public:
  static TracingStatus Unneeded() { return kUnneeded; }
  static TracingStatus Unknown() { return kUnknown; }
  static TracingStatus Needed() { return kNeeded; }
  bool IsUnneeded() const { return status_ == kUnneeded; }
  bool IsUnknown() const { return status_ == kUnknown; }
  bool IsNeeded() const { return status_ == kNeeded; }
  TracingStatus LUB(const TracingStatus& other) const {
    return status_ > other.status_ ? status_ : other.status_;
  }
  bool operator==(const TracingStatus& other) const {
    return status_ == other.status_;
  }
 private:
  enum Status { kUnneeded, kUnknown, kNeeded };
  TracingStatus(Status status) : status_(status) {}
  Status status_;
};

#endif // TOOLS_BLINK_GC_PLUGIN_TRACING_STATUS_H_
