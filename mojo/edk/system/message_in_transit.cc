// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/message_in_transit.h"

#include <string.h>

#include <utility>

#include "base/logging.h"
#include "mojo/edk/system/configuration.h"
#include "mojo/edk/system/transport_data.h"

using mojo::platform::AlignedAlloc;

namespace mojo {
namespace system {

const size_t MessageInTransit::kMessageAlignment;

struct MessageInTransit::PrivateStructForCompileAsserts {
  // The size of |Header| must be a multiple of the alignment.
  static_assert(sizeof(Header) % kMessageAlignment == 0,
                "sizeof(MessageInTransit::Header) invalid");
};

MessageInTransit::View::View(size_t message_size, const void* buffer)
    : buffer_(buffer) {
  size_t next_message_size = 0;
  DCHECK(MessageInTransit::GetNextMessageSize(buffer_, message_size,
                                              &next_message_size));
  DCHECK_EQ(message_size, next_message_size);
  // This should be equivalent.
  DCHECK_EQ(message_size, total_size());
}

bool MessageInTransit::View::IsValid(size_t serialized_platform_handle_size,
                                     const char** error_message) const {
  size_t max_message_num_bytes = GetConfiguration().max_message_num_bytes;
  // Avoid dangerous situations, but making sure that the size of the "header" +
  // the size of the data fits into a 31-bit number.
  DCHECK_LE(static_cast<uint64_t>(sizeof(Header)) + max_message_num_bytes,
            0x7fffffffULL)
      << "GetConfiguration().max_message_num_bytes too big";

  // We assume (to avoid extra rounding code) that the maximum message (data)
  // size is a multiple of the alignment.
  DCHECK_EQ(max_message_num_bytes % kMessageAlignment, 0U)
      << "GetConfiguration().max_message_num_bytes not a multiple of alignment";

  // Note: This also implies a check on the |main_buffer_size()|, which is just
  // |RoundUpMessageAlignment(sizeof(Header) + num_bytes())|.
  if (num_bytes() > max_message_num_bytes) {
    *error_message = "Message data payload too large";
    return false;
  }

  if (transport_data_buffer_size() > 0) {
    const char* e = TransportData::ValidateBuffer(
        serialized_platform_handle_size, transport_data_buffer(),
        transport_data_buffer_size());
    if (e) {
      *error_message = e;
      return false;
    }
  }

  return true;
}

MessageInTransit::MessageInTransit(Type type,
                                   Subtype subtype,
                                   uint32_t num_bytes,
                                   const void* bytes)
    : main_buffer_size_(RoundUpMessageAlignment(sizeof(Header) + num_bytes)),
      main_buffer_(AlignedAlloc<char>(kMessageAlignment, main_buffer_size_)) {
  ConstructorHelper(type, subtype, num_bytes);
  if (bytes) {
    memcpy(MessageInTransit::bytes(), bytes, num_bytes);
    memset(static_cast<char*>(MessageInTransit::bytes()) + num_bytes, 0,
           main_buffer_size_ - sizeof(Header) - num_bytes);
  } else {
    memset(MessageInTransit::bytes(), 0, main_buffer_size_ - sizeof(Header));
  }
}

MessageInTransit::MessageInTransit(Type type,
                                   Subtype subtype,
                                   uint32_t num_bytes,
                                   UserPointer<const void> bytes)
    : main_buffer_size_(RoundUpMessageAlignment(sizeof(Header) + num_bytes)),
      main_buffer_(AlignedAlloc<char>(kMessageAlignment, main_buffer_size_)) {
  ConstructorHelper(type, subtype, num_bytes);
  bytes.GetArray(MessageInTransit::bytes(), num_bytes);
  memset(static_cast<char*>(MessageInTransit::bytes()) + num_bytes, 0,
         main_buffer_size_ - sizeof(Header) - num_bytes);
}

MessageInTransit::MessageInTransit(const View& message_view)
    : main_buffer_size_(message_view.main_buffer_size()),
      main_buffer_(AlignedAlloc<char>(kMessageAlignment, main_buffer_size_)) {
  DCHECK_GE(main_buffer_size_, sizeof(Header));
  DCHECK_EQ(main_buffer_size_ % kMessageAlignment, 0u);

  memcpy(main_buffer_.get(), message_view.main_buffer(), main_buffer_size_);
  DCHECK_EQ(main_buffer_size_,
            RoundUpMessageAlignment(sizeof(Header) + num_bytes()));
}

MessageInTransit::~MessageInTransit() {
  if (dispatchers_) {
    for (size_t i = 0; i < dispatchers_->size(); i++) {
      if (!(*dispatchers_)[i])
        continue;

      (*dispatchers_)[i]->AssertHasOneRef();
      (*dispatchers_)[i]->Close();
    }
  }
}

// static
bool MessageInTransit::GetNextMessageSize(const void* buffer,
                                          size_t buffer_size,
                                          size_t* next_message_size) {
  DCHECK(next_message_size);
  if (!buffer_size)
    return false;
  DCHECK(buffer);
  DCHECK_EQ(
      reinterpret_cast<uintptr_t>(buffer) % MessageInTransit::kMessageAlignment,
      0u);

  if (buffer_size < sizeof(Header))
    return false;

  const Header* header = static_cast<const Header*>(buffer);
  *next_message_size = header->total_size;
  DCHECK_EQ(*next_message_size % kMessageAlignment, 0u);
  return true;
}

void MessageInTransit::SetDispatchers(
    std::unique_ptr<DispatcherVector> dispatchers) {
  DCHECK(dispatchers);
  DCHECK(!dispatchers_);
  DCHECK(!transport_data_);

  dispatchers_ = std::move(dispatchers);
#ifndef NDEBUG
  for (size_t i = 0; i < dispatchers_->size(); i++) {
    if ((*dispatchers_)[i])
      (*dispatchers_)[i]->AssertHasOneRef();
  }
#endif
}

void MessageInTransit::SetTransportData(
    std::unique_ptr<TransportData> transport_data) {
  DCHECK(transport_data);
  DCHECK(!transport_data_);
  DCHECK(!dispatchers_);

  transport_data_ = std::move(transport_data);
  UpdateTotalSize();
}

void MessageInTransit::SerializeAndCloseDispatchers(Channel* channel) {
  DCHECK(channel);
  DCHECK(!transport_data_);

  if (!dispatchers_ || !dispatchers_->size())
    return;

  transport_data_.reset(new TransportData(std::move(dispatchers_), channel));

  // Update the sizes in the message header.
  UpdateTotalSize();
}

void MessageInTransit::ConstructorHelper(Type type,
                                         Subtype subtype,
                                         uint32_t num_bytes) {
  DCHECK_LE(num_bytes, GetConfiguration().max_message_num_bytes);

  // |total_size| is updated below, from the other values.
  header()->type = type;
  header()->subtype = subtype;
  header()->source_id = ChannelEndpointId();
  header()->destination_id = ChannelEndpointId();
  header()->num_bytes = num_bytes;
  header()->unused = 0;
  // Note: If dispatchers are subsequently attached, then |total_size| will have
  // to be adjusted.
  UpdateTotalSize();
}

void MessageInTransit::UpdateTotalSize() {
  DCHECK_EQ(main_buffer_size_ % kMessageAlignment, 0u);
  header()->total_size = static_cast<uint32_t>(main_buffer_size_);
  if (transport_data_) {
    header()->total_size +=
        static_cast<uint32_t>(transport_data_->buffer_size());
  }
}

}  // namespace system
}  // namespace mojo
