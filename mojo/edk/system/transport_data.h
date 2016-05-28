// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_TRANSPORT_DATA_H_
#define MOJO_EDK_SYSTEM_TRANSPORT_DATA_H_

#include <stdint.h>

#include <memory>
#include <vector>

#include "mojo/edk/platform/aligned_alloc.h"
#include "mojo/edk/platform/scoped_platform_handle.h"
#include "mojo/edk/system/dispatcher.h"
#include "mojo/edk/system/handle.h"
#include "mojo/public/c/system/handle.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

class Channel;

// This class is used by |MessageInTransit| to represent handles (|Dispatcher|s)
// in various stages of serialization.
//
// The stages are:
//   - Before reaching |TransportData|: Turn |HandleTransport|s into
//     |Dispatcher|s that are "owned" by (and attached to) a |MessageInTransit|.
//     This invalidates the handles in the space of the sending application
//     (and, e.g., if another thread is waiting on such a handle, it'll be
//     notified of this invalidation).
//   - Serialize these dispatchers into the |TransportData|: First, for each
//     attached dispatcher, there's an entry in the |TransportData|'s "handle
//     table", which points to a segment of (dispatcher-type-dependent) data.
//   - During the serialization of the dispatchers, |PlatformHandle|s may be
//     detached from the dispatchers and attached to the |TransportData|.
//   - Before sending the |MessageInTransit|, including its main buffer and the
//     |TransportData|'s buffer, the |Channel| sends any |PlatformHandle|s (in a
//     platform-, and possibly sandbox-situation-, specific way) first. In doing
//     so, it appends a "platform handle table" to the |TransportData|
//     containing information about how to deserialize these |PlatformHandle|s.
//   - Finally, at this point, to send the |MessageInTransit|, there only
//     remains "inert" data: the |MessageInTransit|'s main buffer and data from
//     the |TransportData|, consisting of the "handle table" (one entry for each
//     attached dispatcher), dispatcher-type-specific data (one segment for each
//     entry in the "handle table"), and the "platform handle table" (one entry
//     for each attached |PlatformHandle|).
//
// To receive a message (|MessageInTransit|), the "reverse" happens:
//   - On POSIX, receive and buffer |PlatformHandle|s (i.e., FDs), which were
//     sent before the "inert" data.
//   - Receive the "inert" data from the |MessageInTransit|. Examine its
//     "platform handle table". On POSIX, match its entries with the buffered
//     |PlatformHandle|s, which were previously received. On Windows, do what's
//     necessary to obtain |PlatformHandle|s (e.g.: i. if the sender is fully
//     trusted and able to duplicate handle into the receiver, then just pick
//     out the |HANDLE| value; ii. if the receiver is fully trusted and able to
//     duplicate handles from the receiver, do the |DuplicateHandle()|; iii.
//     otherwise, talk to a broker to get handles). Reattach all the
//     |PlatformHandle|s to the |MessageInTransit|.
//   - For each entry in the "handle table", use serialized dispatcher data to
//     reconstitute a dispatcher, taking ownership of associated
//     |PlatformHandle|s (and detaching them). Attach these dispatchers to the
//     |MessageInTransit|.
//   - At this point, the |MessageInTransit| consists of its main buffer
//     (primarily the data payload) and the attached dispatchers; the
//     |TransportData| can be discarded.
//   - When |MojoReadMessage()| is to give data to the application, attach the
//     dispatchers to the (global, "core") handle table, getting handles; give
//     the application the data payload and these handles.
//
// TODO(vtl): Everything above involving |PlatformHandle|s.
class TransportData {
 public:
  // The maximum size of a single serialized dispatcher. This must be a multiple
  // of |kMessageAlignment|.
  static const size_t kMaxSerializedDispatcherSize = 10000;

  // The maximum number of platform handles to attach for a single serialized
  // dispatcher.
  static const size_t kMaxSerializedDispatcherPlatformHandles = 2;

  // The maximum possible size of a valid transport data buffer.
  static size_t GetMaxBufferSize();

  // The maximum total number of platform handles that may be attached.
  static size_t GetMaxPlatformHandles();

  TransportData(std::unique_ptr<HandleVector> handles, Channel* channel);

  // This is used for users of |MessageInTransit|/|TransportData|/|RawChannel|
  // that want to simply transport data and platform handles, and not
  // |Dispatcher|s. (|Header| will be present, and zero except for
  // |num_platform_handles|, and |platform_handle_table_offset| if necessary.)
  explicit TransportData(
      std::unique_ptr<std::vector<platform::ScopedPlatformHandle>>
          platform_handles,
      size_t serialized_platform_handle_size);

  ~TransportData();

  const void* buffer() const { return buffer_.get(); }
  void* buffer() { return buffer_.get(); }
  size_t buffer_size() const { return buffer_size_; }

  uint32_t platform_handle_table_offset() const {
    return header()->platform_handle_table_offset;
  }

  // Gets attached platform-specific handles; this may return null if there are
  // none. Note that the caller may mutate the set of platform-specific handles.
  const std::vector<platform::ScopedPlatformHandle>* platform_handles() const {
    return platform_handles_.get();
  }
  std::vector<platform::ScopedPlatformHandle>* platform_handles() {
    return platform_handles_.get();
  }

  // Receive-side functions:

  // Checks if the given buffer (from the "wire") looks like a valid
  // |TransportData| buffer. (Should only be called if |buffer_size| is
  // nonzero.) Returns null if valid, and a pointer to a human-readable error
  // message (for debug/logging purposes) on error. Note: This checks the
  // validity of the handle table entries (i.e., does range checking), but does
  // not check that the validity of the actual serialized dispatcher
  // information.
  static const char* ValidateBuffer(size_t serialized_platform_handle_size,
                                    const void* buffer,
                                    size_t buffer_size);

  // Gets the platform handle table from a (valid) |TransportData| buffer (which
  // should have been validated using |ValidateBuffer()| first).
  static void GetPlatformHandleTable(const void* transport_data_buffer,
                                     size_t* num_platform_handles,
                                     const void** platform_handle_table);

  // Deserializes handles from the given (serialized) transport data buffer
  // (typically from a |MessageInTransit::View|) and vector of platform handles.
  // |buffer| should be non-null and |buffer_size| should be nonzero.
  static std::unique_ptr<HandleVector> DeserializeHandles(
      const void* buffer,
      size_t buffer_size,
      std::unique_ptr<std::vector<platform::ScopedPlatformHandle>>
          platform_handles,
      Channel* channel);

 private:
  // To allow us to make compile-assertions about |Header|, etc. in the .cc
  // file.
  struct PrivateStructForCompileAsserts;

  // Header for the "secondary buffer"/"transport data". Must be a multiple of
  // |MessageInTransit::kMessageAlignment| in size. Must be POD.
  struct Header {
    uint32_t num_handles;
    // TODO(vtl): Not used yet:
    uint32_t platform_handle_table_offset;
    uint32_t num_platform_handles;
    uint32_t unused;
  };

  struct HandleTableEntry {
    // TODO(vtl): Should I make |Dispatcher::Type| an |int32_t| enum class?
    int32_t type;     // From |Dispatcher::Type| (|UNKNOWN| for "invalid").
    uint32_t offset;  // Relative to the start of the "secondary buffer".
    uint32_t size;    // (Not including any padding.)
    MojoHandleRights rights;
  };

  const Header* header() const {
    return reinterpret_cast<const Header*>(buffer_.get());
  }

  size_t buffer_size_;
  platform::AlignedUniquePtr<char> buffer_;  // Never null.

  // Any platform-specific handles attached to this message (for inter-process
  // transport). The vector (if any) owns the handles that it contains (and is
  // responsible for closing them).
  // TODO(vtl): With C++11, change it to a vector of |ScopedPlatformHandle|s.
  std::unique_ptr<std::vector<platform::ScopedPlatformHandle>>
      platform_handles_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TransportData);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_TRANSPORT_DATA_H_
