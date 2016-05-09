// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_MESSAGE_IN_TRANSIT_H_
#define MOJO_EDK_SYSTEM_MESSAGE_IN_TRANSIT_H_

#include <stddef.h>
#include <stdint.h>

#include <memory>
#include <ostream>
#include <vector>

#include "mojo/edk/platform/aligned_alloc.h"
#include "mojo/edk/system/channel_endpoint_id.h"
#include "mojo/edk/system/dispatcher.h"
#include "mojo/edk/system/handle.h"
#include "mojo/edk/system/memory.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

class Channel;
class TransportData;

// This class is used to represent data in transit. It is thread-unsafe.
//
// |MessageInTransit| buffers:
//
// A |MessageInTransit| can be serialized by writing the main buffer and then,
// if it has one, the transport data buffer. Both buffers are
// |kMessageAlignment|-byte aligned and a multiple of |kMessageAlignment| bytes
// in size.
//
// The main buffer consists of the header (of type |Header|, which is an
// internal detail of this class) followed immediately by the message data
// (accessed by |bytes()| and of size |num_bytes()|, and also
// |kMessageAlignment|-byte aligned), and then any padding needed to make the
// main buffer a multiple of |kMessageAlignment| bytes in size.
//
// See |TransportData| for a description of the (serialized) transport data
// buffer.
class MessageInTransit {
 public:
  enum class Type : uint16_t {
    // Messages that are forwarded to endpoint clients.
    ENDPOINT_CLIENT = 0,
    // Messages that are consumed by the |ChannelEndpoint|.
    ENDPOINT = 1,
    // Messages that are consumed by the |Channel|.
    CHANNEL = 2,
    // Messages that are consumed by the |RawChannel| (implementation).
    RAW_CHANNEL = 3,
    // |ConnectionManager| implementations also use |RawChannel|s.
    // Messages sent to a |MasterConnectionManager|.
    CONNECTION_MANAGER = 4,
    // Messages sent by a |MasterConnectionManager| (all responses).
    CONNECTION_MANAGER_ACK = 5,
  };

  enum class Subtype : uint16_t {
    // Subtypes for type |Type::ENDPOINT_CLIENT|:
    // Message pipe or data pipe data (etc.).
    ENDPOINT_CLIENT_DATA = 0,
    // Data pipe: consumer -> producer message that data was consumed. Payload
    // is |RemoteDataPipeAck|.
    ENDPOINT_CLIENT_DATA_PIPE_ACK = 1,
    // Subtypes for type |Type::ENDPOINT|:
    // TODO(vtl): Nothing yet.
    // Subtypes for type |Type::CHANNEL|:
    CHANNEL_ATTACH_AND_RUN_ENDPOINT = 0,
    CHANNEL_REMOVE_ENDPOINT = 1,
    CHANNEL_REMOVE_ENDPOINT_ACK = 2,
    // Subtypes for type |Type::RAW_CHANNEL|:
    RAW_CHANNEL_POSIX_EXTRA_PLATFORM_HANDLES = 0,
    // Subtypes for type |Type::CONNECTION_MANAGER| (the message data is always
    // a buffer containing the connection ID):
    CONNECTION_MANAGER_ALLOW_CONNECT = 0,
    CONNECTION_MANAGER_CANCEL_CONNECT = 1,
    CONNECTION_MANAGER_CONNECT = 2,
    // Subtypes for type |Type::CONNECTION_MANAGER_ACK|, corresponding to
    // |ConnectionManager::Result| values (failure and non-"connect" acks never
    // have any message contents; success acks for "connect" always have a
    // |ConnectionManagerAckSuccessConnectData| as data and also a platform
    // handle attached for "new connection"):
    CONNECTION_MANAGER_ACK_FAILURE = 0,
    CONNECTION_MANAGER_ACK_SUCCESS = 1,
    CONNECTION_MANAGER_ACK_SUCCESS_CONNECT_SAME_PROCESS = 2,
    CONNECTION_MANAGER_ACK_SUCCESS_CONNECT_NEW_CONNECTION = 3,
    CONNECTION_MANAGER_ACK_SUCCESS_CONNECT_REUSE_CONNECTION = 4,
  };

  // Messages (the header and data) must always be aligned to a multiple of this
  // quantity (which must be a power of 2).
  static const size_t kMessageAlignment = 8;

  // Forward-declare |Header| so that |View| can use it:
 private:
  struct Header;

 public:
  // This represents a view of serialized message data in a raw buffer.
  class View {
   public:
    // Constructs a view from the given buffer of the given size. (The size must
    // be as provided by |MessageInTransit::GetNextMessageSize()|.) The buffer
    // must remain alive/unmodified through the lifetime of this object.
    // |buffer| should be |kMessageAlignment|-byte aligned.
    View(size_t message_size, const void* buffer);

    // Checks that the given |View| appears to be for a valid message, within
    // predetermined limits (e.g., |num_bytes()| and |main_buffer_size()|, that
    // |transport_data_buffer()|/|transport_data_buffer_size()| is for valid
    // transport data -- see |TransportData::ValidateBuffer()|).
    //
    // It returns true (and leaves |error_message| alone) if this object appears
    // to be a valid message (according to the above) and false, pointing
    // |*error_message| to a suitable error message, if not.
    bool IsValid(size_t serialized_platform_handle_size,
                 const char** error_message) const;

    // API parallel to that for |MessageInTransit| itself (mostly getters for
    // header data).
    const void* main_buffer() const { return buffer_; }
    size_t main_buffer_size() const {
      return RoundUpMessageAlignment(sizeof(Header) + header()->num_bytes);
    }
    const void* transport_data_buffer() const {
      return (total_size() > main_buffer_size())
                 ? static_cast<const char*>(buffer_) + main_buffer_size()
                 : nullptr;
    }
    size_t transport_data_buffer_size() const {
      return total_size() - main_buffer_size();
    }
    size_t total_size() const { return header()->total_size; }
    uint32_t num_bytes() const { return header()->num_bytes; }
    const void* bytes() const {
      return static_cast<const char*>(buffer_) + sizeof(Header);
    }
    Type type() const { return header()->type; }
    Subtype subtype() const { return header()->subtype; }
    ChannelEndpointId source_id() const { return header()->source_id; }
    ChannelEndpointId destination_id() const {
      return header()->destination_id;
    }

   private:
    const Header* header() const { return static_cast<const Header*>(buffer_); }

    const void* const buffer_;

    // Though this struct is trivial, disallow copy and assign, since it doesn't
    // own its data. (If you're copying/assigning this, you're probably doing
    // something wrong.)
    MOJO_DISALLOW_COPY_AND_ASSIGN(View);
  };

  // |bytes| is optional; if null, the message data will be zero-initialized.
  MessageInTransit(Type type,
                   Subtype subtype,
                   uint32_t num_bytes,
                   const void* bytes);
  // |bytes| should be valid (and non-null), unless |num_bytes| is zero.
  MessageInTransit(Type type,
                   Subtype subtype,
                   uint32_t num_bytes,
                   UserPointer<const void> bytes);
  // Constructs a |MessageInTransit| from a |View|.
  explicit MessageInTransit(const View& message_view);

  ~MessageInTransit();

  // Gets the size of the next message from |buffer|, which has |buffer_size|
  // bytes currently available, returning true and setting |*next_message_size|
  // on success. |buffer| should be aligned on a |kMessageAlignment| boundary
  // (and on success, |*next_message_size| will be a multiple of
  // |kMessageAlignment|).
  // TODO(vtl): In |RawChannelPosix|, the alignment requirements are currently
  // satisified on a faith-based basis.
  static bool GetNextMessageSize(const void* buffer,
                                 size_t buffer_size,
                                 size_t* next_message_size);

  // Makes this message "own" the given set of handles. Each handle's dispatcher
  // must not be referenced from anywhere else (in particular, not from any
  // handle in the handle table), i.e., the dispatcher must have a reference
  // count of 1. This message must not already have handles.
  void SetHandles(std::unique_ptr<HandleVector> handles);
  // TODO(vtl): Delete this.
  void SetDispatchers(std::unique_ptr<DispatcherVector> dispatchers);

  // Sets the |TransportData| for this message. This should only be done when
  // there are no handles and no existing |TransportData|.
  void SetTransportData(std::unique_ptr<TransportData> transport_data);

  // Serializes any handles to the secondary buffer. This message must not
  // already have a secondary buffer (so this must only be called once). The
  // caller must ensure (e.g., by holding on to a reference) that |channel|
  // stays alive through the call.
  void SerializeAndCloseHandles(Channel* channel);

  // Gets the main buffer and its size (in number of bytes), respectively.
  const void* main_buffer() const { return main_buffer_.get(); }
  size_t main_buffer_size() const { return main_buffer_size_; }

  // Gets the transport data buffer (if any).
  const TransportData* transport_data() const { return transport_data_.get(); }
  TransportData* transport_data() { return transport_data_.get(); }

  // Gets the total size of the message (see comment in |Header|, below).
  size_t total_size() const { return header()->total_size; }

  // Gets the size of the message data.
  uint32_t num_bytes() const { return header()->num_bytes; }

  // Gets the message data (of size |num_bytes()| bytes).
  const void* bytes() const { return main_buffer_.get() + sizeof(Header); }
  void* bytes() { return main_buffer_.get() + sizeof(Header); }

  Type type() const { return header()->type; }
  Subtype subtype() const { return header()->subtype; }
  ChannelEndpointId source_id() const { return header()->source_id; }
  ChannelEndpointId destination_id() const { return header()->destination_id; }

  void set_source_id(ChannelEndpointId source_id) {
    header()->source_id = source_id;
  }
  void set_destination_id(ChannelEndpointId destination_id) {
    header()->destination_id = destination_id;
  }

  // Gets the handles attached to this message; this may return null if there
  // are none. Note that the caller may mutate the set of handles (e.g., take
  // ownership of all the handles, leaving the vector empty).
  HandleVector* handles() { return handles_.get(); }

  // Returns true if this message has handles attached.
  bool has_handles() const { return handles_ && !handles_->empty(); }

  // Rounds |n| up to a multiple of |kMessageAlignment|.
  static inline size_t RoundUpMessageAlignment(size_t n) {
    return (n + kMessageAlignment - 1) & ~(kMessageAlignment - 1);
  }

 private:
  // To allow us to make compile-assertions about |Header| in the .cc file.
  struct PrivateStructForCompileAsserts;

  // Header for the data (main buffer). Must be a multiple of
  // |kMessageAlignment| bytes in size. Must be POD.
  struct Header {
    // Total size of the message, including the header, the message data
    // ("bytes") including padding (to make it a multiple of |kMessageAlignment|
    // bytes), and serialized handle information. Note that this may not be the
    // correct value if handles are attached but |SerializeAndCloseHandles()|
    // has not been called.
    uint32_t total_size;
    Type type;                         // 2 bytes.
    Subtype subtype;                   // 2 bytes.
    ChannelEndpointId source_id;       // 4 bytes.
    ChannelEndpointId destination_id;  // 4 bytes.
    // Size of actual message data.
    uint32_t num_bytes;
    uint32_t unused;
  };

  const Header* header() const {
    return reinterpret_cast<const Header*>(main_buffer_.get());
  }
  Header* header() { return reinterpret_cast<Header*>(main_buffer_.get()); }

  void ConstructorHelper(Type type, Subtype subtype, uint32_t num_bytes);
  void UpdateTotalSize();

  const size_t main_buffer_size_;
  // Never null.
  const platform::AlignedUniquePtr<char> main_buffer_;

  std::unique_ptr<TransportData> transport_data_;  // May be null.

  // Any handles that may be attached to this message. These handles should be
  // "owned" by this message, i.e., their dispatcher have a ref count of exactly
  // 1. (We allow a handle entry to be "null"/invalid, in case it couldn't be
  // duplicated for some reason.)
  std::unique_ptr<HandleVector> handles_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(MessageInTransit);
};

// So logging macros and |DCHECK_EQ()|, etc. work.
inline std::ostream& operator<<(std::ostream& out,
                                MessageInTransit::Type type) {
  return out << static_cast<uint16_t>(type);
}

// So logging macros and |DCHECK_EQ()|, etc. work.
inline std::ostream& operator<<(std::ostream& out,
                                MessageInTransit::Subtype subtype) {
  return out << static_cast<uint16_t>(subtype);
}

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_MESSAGE_IN_TRANSIT_H_
