// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_EMBEDDER_PLATFORM_CHANNEL_UTILS_POSIX_H_
#define MOJO_EDK_EMBEDDER_PLATFORM_CHANNEL_UTILS_POSIX_H_

#include <stddef.h>
#include <sys/types.h>  // For |ssize_t|.

#include <deque>

#include "base/memory/scoped_ptr.h"
#include "mojo/edk/embedder/platform_handle.h"
#include "mojo/edk/system/system_impl_export.h"

struct iovec;  // Declared in <sys/uio.h>.

namespace mojo {
namespace embedder {

// The maximum number of handles that can be sent "at once" using
// |PlatformChannelSendmsgWithHandles()|.
// TODO(vtl): This number is taken from ipc/ipc_message_attachment_set.h:
// |IPC::MessageAttachmentSet::kMaxDescriptorsPerMessage|.
const size_t kPlatformChannelMaxNumHandles = 128;

// Use these to write to a socket created using |PlatformChannelPair| (or
// equivalent). These are like |write()| and |writev()|, but handle |EINTR| and
// never raise |SIGPIPE|. (Note: On Mac, the suppression of |SIGPIPE| is set up
// by |PlatformChannelPair|.)
MOJO_SYSTEM_IMPL_EXPORT ssize_t
PlatformChannelWrite(PlatformHandle h, const void* bytes, size_t num_bytes);
MOJO_SYSTEM_IMPL_EXPORT ssize_t
PlatformChannelWritev(PlatformHandle h, struct iovec* iov, size_t num_iov);

// Writes data, and the given set of |PlatformHandle|s (i.e., file descriptors)
// over the Unix domain socket given by |h| (e.g., created using
// |PlatformChannelPair()|). All the handles must be valid, and there must be at
// least one and at most |kPlatformChannelMaxNumHandles| handles. The return
// value is as for |sendmsg()|, namely -1 on failure and otherwise the number of
// bytes of data sent on success (note that this may not be all the data
// specified by |iov|). (The handles are not closed, regardless of success or
// failure.)
MOJO_SYSTEM_IMPL_EXPORT ssize_t
PlatformChannelSendmsgWithHandles(PlatformHandle h,
                                  struct iovec* iov,
                                  size_t num_iov,
                                  PlatformHandle* platform_handles,
                                  size_t num_platform_handles);

// TODO(vtl): Remove this once I've switched things over to
// |PlatformChannelSendmsgWithHandles()|.
// Sends |PlatformHandle|s (i.e., file descriptors) over the Unix domain socket
// (e.g., created using PlatformChannelPair|). (These will be sent in a single
// message having one null byte of data and one control message header with all
// the file descriptors.) All of the handles must be valid, and there must be at
// most |kPlatformChannelMaxNumHandles| (and at least one handle). Returns true
// on success, in which case it closes all the handles.
MOJO_SYSTEM_IMPL_EXPORT bool PlatformChannelSendHandles(PlatformHandle h,
                                                        PlatformHandle* handles,
                                                        size_t num_handles);

// Wrapper around |recvmsg()|, which will extract any attached file descriptors
// (in the control message) to |PlatformHandle|s (and append them to
// |platform_handles|). (This also handles |EINTR|.)
MOJO_SYSTEM_IMPL_EXPORT ssize_t
PlatformChannelRecvmsg(PlatformHandle h,
                       void* buf,
                       size_t num_bytes,
                       std::deque<PlatformHandle>* platform_handles);

}  // namespace embedder
}  // namespace mojo

#endif  // MOJO_EDK_EMBEDDER_PLATFORM_CHANNEL_UTILS_POSIX_H_
