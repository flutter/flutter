// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_CONNECTION_MANAGER_H_
#define MOJO_EDK_SYSTEM_CONNECTION_MANAGER_H_

#include <ostream>

#include "mojo/edk/system/connection_identifier.h"
#include "mojo/edk/system/process_identifier.h"
#include "mojo/edk/system/system_impl_export.h"
#include "mojo/edk/system/thread_annotations.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {

namespace embedder {
class PlatformSupport;
class ScopedPlatformHandle;
}  // namespace embedder

namespace system {

// |ConnectionManager| is an interface for the system that allows "connections"
// (i.e., native "pipes") to be established between different processes.
//
// The starting point for establishing such a connection is that the two
// processes (not necessarily distinct) are provided with a common
// |ConnectionIdentifier|, and also some (probably indirect, temporary) way of
// communicating.
//
// (The usual case for this are processes A, B, C, with connections A <-> B <->
// C, with the goal being to establish a direct connection A <-> C. Process B
// generates a |ConnectionIdentifier| that it transmits to A and C, and serves
// as an intermediary until A and C are directly connected.)
//
// To establish such a connection, each process calls |AllowConnect()| with the
// common |ConnectionIdentifier|. Each process then informs the other process
// that it has done so. Once a process knows that both processes have called
// |AllowConnect()|, it proceeds to call |Connect()|.
//
// On success, if the two processes are in fact distinct, |Connect()| provides a
// native (platform) handle for a "pipe" that connects/will connect the two
// processes. (If they are in fact the same process, success will simply yield
// no valid handle, to indicate this case.)
//
// Additionally, on success |Connect()| also provides a unique identifier for
// the peer process. In this way, processes may recognize when they already have
// a direct connection and reuse that, disposing of the new one provided by
// |Connect()|. (TODO(vtl): This is somewhat wasteful, but removes the need to
// handle various race conditions, and for the "master" process -- see below --
// to track connection teardowns.)
//
// Implementation notes: We implement this using a "star topology", with a
// single trusted "master" (broker) process and an arbitrary number of untrusted
// "slave" (client) processes. The former is implemented by
// |MasterConnectionManager| (master_connection_manager.*) and the latter by
// |SlaveConnectionManager| (slave_connection_manager.*). Each slave is
// connected to the master by a special dedicated |RawChannel|, on which it does
// synchronous IPC (note, however, that the master should never block on any
// slave).
class MOJO_SYSTEM_IMPL_EXPORT ConnectionManager {
 public:
  enum class Result {
    FAILURE = 0,
    SUCCESS,
    // These results are used for |Connect()| (which also uses |FAILURE|, but
    // not |SUCCESS|).
    SUCCESS_CONNECT_SAME_PROCESS,
    SUCCESS_CONNECT_NEW_CONNECTION,
    SUCCESS_CONNECT_REUSE_CONNECTION
  };

  virtual ~ConnectionManager() {}

  ConnectionIdentifier GenerateConnectionIdentifier();

  // Shuts down this connection manager. No other methods may be called after
  // this is (or while it is being) called.
  virtual void Shutdown() MOJO_NOT_THREAD_SAFE = 0;

  // TODO(vtl): Add a "get my own process identifier" method?

  // All of the methods below return true on success or false on failure.
  // Failure is obviously fatal for the establishment of a particular
  // connection, but should not be treated as fatal to the process. Failure may,
  // e.g., be caused by a misbehaving (malicious) untrusted peer process.

  // Allows a process who makes the identical call (with equal |connection_id|)
  // to connect to the calling process. (On success, there will be a "pending
  // connection" for the given |connection_id| for the calling process.)
  virtual bool AllowConnect(const ConnectionIdentifier& connection_id) = 0;

  // Cancels a pending connection for the calling process. (Note that this may
  // fail even if |AllowConnect()| succeeded; regardless, |Connect()| should not
  // be called.)
  virtual bool CancelConnect(const ConnectionIdentifier& connection_id) = 0;

  // Connects a pending connection; to be called only after both parties have
  // called |AllowConnect()|. On success, |Result::SUCCESS_CONNECT_...| is
  // returned and |peer_process_identifier| is set to an unique identifier for
  // the peer process. In the case of |SUCCESS_CONNECT_SAME_PROCESS|,
  // |*platform_handle| is set to a suitable native handle connecting the two
  // parties.
  virtual Result Connect(const ConnectionIdentifier& connection_id,
                         ProcessIdentifier* peer_process_identifier,
                         embedder::ScopedPlatformHandle* platform_handle) = 0;

 protected:
  // |platform_support| must be valid and remain alive until after |Shutdown()|
  // has completed.
  explicit ConnectionManager(embedder::PlatformSupport* platform_support)
      : platform_support_(platform_support) {}

 private:
  embedder::PlatformSupport* const platform_support_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ConnectionManager);
};

// So logging macros and |DCHECK_EQ()|, etc. work.
MOJO_SYSTEM_IMPL_EXPORT inline std::ostream& operator<<(
    std::ostream& out,
    ConnectionManager::Result result) {
  return out << static_cast<int>(result);
}

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_CONNECTION_MANAGER_H_
