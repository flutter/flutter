// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_HANDLE_TRANSPORT_H_
#define MOJO_EDK_SYSTEM_HANDLE_TRANSPORT_H_

#include "mojo/edk/system/dispatcher.h"
#include "mojo/edk/system/handle.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/thread_annotations.h"
#include "mojo/public/c/system/handle.h"

namespace mojo {
namespace system {

class MessagePipe;

// Like |Handle|, but non-owning, for use while a handle is being processed to
// be replaced or to be passed in a message pipe (note this is only *during* the
// "write message" call). (I.e., this is a wrapper around a |Dispatcher*| and a
// |MojoHandleRights|.) See the comment about |Dispatcher::HandleTableAccess|
// for more details.
//
// Note: This class is deliberately "thin" -- no more expensive than a struct
// containing a |Dispatcher*| and a |MojoHandleRights|.
class HandleTransport final {
 public:
  // Constructs a "null"/invalid |HandleTransport|. No methods other than
  // |is_valid()| may be called on the resulting instance.
  HandleTransport() : dispatcher_(nullptr), rights_(MOJO_HANDLE_RIGHT_NONE) {}

  // Ends transport. This must be called exactly once (on the result, or one of
  // the copies thereof) if |Dispatcher::HandleTableAccess::TryStartTransport()|
  // succeeds.
  void End() MOJO_NOT_THREAD_SAFE;

  Dispatcher::Type GetType() const { return dispatcher_->GetType(); }
  void Close() MOJO_NOT_THREAD_SAFE { dispatcher_->CloseNoLock(); }
  // Creates an equivalent handle and closes the original one. If this is done
  // while being sent on a message pipe (i.e., under a |MessagePipe| mutex),
  // then |message_pipe|/|port| should be set appropriately. Otherwise,
  // |message_pipe| should be null (and |port| will be ignored).
  Handle CreateEquivalentHandleAndClose(MessagePipe* message_pipe,
                                        unsigned port) MOJO_NOT_THREAD_SAFE {
    return Handle(dispatcher_->CreateEquivalentDispatcherAndCloseNoLock(
                      message_pipe, port),
                  rights_);
  }

  bool is_valid() const { return !!dispatcher_; }

 private:
  friend class Dispatcher::HandleTableAccess;

  explicit HandleTransport(const Handle& handle)
      : dispatcher_(handle.dispatcher.get()), rights_(handle.rights) {}

  Dispatcher* dispatcher_;
  MojoHandleRights rights_;

  // Copy and assign allowed.
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_HANDLE_TRANSPORT_H_
