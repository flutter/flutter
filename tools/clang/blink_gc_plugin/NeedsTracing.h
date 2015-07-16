// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// NeedsTracing is a three-point value ordered by unneeded < unknown < needed.
// Unneeded means that the point definitively does not need to be traced.

#ifndef TOOLS_BLINK_GC_PLUGIN_NEEDS_TRACING_H_
#define TOOLS_BLINK_GC_PLUGIN_NEEDS_TRACING_H_

class NeedsTracing {
 public:
  static NeedsTracing Unneeded() { return kUnneeded; }
  static NeedsTracing Unknown() { return kUnknown; }
  static NeedsTracing Needed() { return kNeeded; }
  bool IsUnneeded() { return value_ == kUnneeded; }
  bool IsUnknown() { return value_ == kUnknown; }
  bool IsNeeded() { return value_ == kNeeded; }
  NeedsTracing LUB(const NeedsTracing& other) {
    return value_ > other.value_ ? value_ : other.value_;
  }
  bool operator==(const NeedsTracing& other) {
    return value_ == other.value_;
  }
 private:
  enum Value { kUnneeded, kUnknown, kNeeded };
  NeedsTracing(Value value) : value_(value) {}
  Value value_;
};

#endif // TOOLS_BLINK_GC_PLUGIN_NEEDS_TRACING_H_
