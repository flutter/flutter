// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_MESSAGE_FILTER_H_
#define MOJO_PUBLIC_CPP_BINDINGS_MESSAGE_FILTER_H_

#include "mojo/public/cpp/bindings/message.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {

// This class is the base class for message filters. Subclasses should
// implement the pure virtual method Accept() inherited from MessageReceiver to
// process messages and/or forward them to |sink_|.
class MessageFilter : public MessageReceiver {
 public:
  // Doesn't take ownership of |sink|. Therefore |sink| has to stay alive while
  // this object is alive.
  explicit MessageFilter(MessageReceiver* sink = nullptr);
  ~MessageFilter() override;

  void set_sink(MessageReceiver* sink) { sink_ = sink; }

 protected:
  MessageReceiver* sink_;
};

// A trivial filter that simply forwards every message it receives to |sink_|.
class PassThroughFilter : public MessageFilter {
 public:
  explicit PassThroughFilter(MessageReceiver* sink = nullptr);

  bool Accept(Message* message) override;
};

}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_MESSAGE_FILTER_H_
