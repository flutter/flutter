// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_PLATFORM_PLATFORM_HANDLE_WATCHER_H_
#define MOJO_EDK_PLATFORM_PLATFORM_HANDLE_WATCHER_H_

#include <functional>
#include <memory>

#include "mojo/edk/platform/platform_handle.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace platform {

// Interface for things that can watch |PlatformHandle|s to be readable/writable
// without blocking. Typically, these are tied to a (particular) |MessageLoop|:
// handles will only be watched while the loop is running and the lifetime of
// the object is typically tied to the |MessageLoop|'s lifetime.
//
// Implementations are typically not thread-safe, and should be used on only the
// watching thread (i.e., the one that the |MessageLoop| belongs to).
class PlatformHandleWatcher {
 public:
  // Abstract "token" class returned by the |Watch()| (below). This object
  // should be destroyed to cancel watching.
  //
  // Note: In theory, libevent (e.g.) can be used without a heap allocation on
  // each "watch". However, in practice, including libevent's event.h pollutes
  // the global namespace with |struct event|, which is very undesirable, so
  // this is hidden via an indirection anyway. However, when using Chromium's
  // |base::MessagePumpLibevent|, this leads to an extra indirection and yet
  // another heap allocation.
  class WatchToken {
   public:
    virtual ~WatchToken() {}

   protected:
    WatchToken() {}

   private:
    MOJO_DISALLOW_COPY_AND_ASSIGN(WatchToken);
  };

  virtual ~PlatformHandleWatcher() {}

  // Watches |platform_handle| to be readable and/or writable (without blocking)
  // as indicated by the presence of |read_callback| and/or |write_callback| (at
  // least one of which must have a valid target), respectively, at which point
  // the respective callback will be called by the message loop. If |persistent|
  // is true, the message loop will continue watching and calling the
  // callback(s) as appropriate.
  virtual std::unique_ptr<WatchToken> Watch(
      PlatformHandle platform_handle,
      bool persistent,
      std::function<void()>&& read_callback,
      std::function<void()>&& write_callback) = 0;

 protected:
  PlatformHandleWatcher() {}

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(PlatformHandleWatcher);
};

}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_PLATFORM_HANDLE_WATCHER_H_
