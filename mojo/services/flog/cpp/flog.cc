// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/services/flog/cpp/flog.h"

namespace mojo {
namespace flog {

// static
std::atomic_ulong Flog::last_allocated_channel_id_;

// static
FlogLoggerPtr Flog::logger_;

FlogChannel::FlogChannel(const char* channel_type_name)
    : id_(Flog::AllocateChannelId()) {
  Flog::LogChannelCreation(id_, channel_type_name);
}

FlogChannel::~FlogChannel() {
  Flog::LogChannelDeletion(id_);
}

bool FlogChannel::Accept(Message* message) {
  Flog::LogChannelMessage(id_, message);
  return true;
}

bool FlogChannel::AcceptWithResponder(Message* message,
                                      MessageReceiver* responder) {
  MOJO_DCHECK(false) << "Flog doesn't support messages with responses";
  abort();
}

}  // namespace flog
}  // namespace mojo
