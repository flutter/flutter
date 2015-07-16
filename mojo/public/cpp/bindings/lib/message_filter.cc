// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/bindings/message_filter.h"

namespace mojo {

MessageFilter::MessageFilter(MessageReceiver* sink) : sink_(sink) {
}

MessageFilter::~MessageFilter() {
}

PassThroughFilter::PassThroughFilter(MessageReceiver* sink)
    : MessageFilter(sink) {
}

bool PassThroughFilter::Accept(Message* message) {
  return sink_->Accept(message);
}

}  // namespace mojo
