// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/shared_buffer_dispatcher.h"

#include <limits>

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "mojo/edk/embedder/platform_support.h"
#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/configuration.h"
#include "mojo/edk/system/memory.h"
#include "mojo/edk/system/options_validation.h"
#include "mojo/public/c/system/macros.h"

namespace mojo {
namespace system {

namespace {

struct SerializedSharedBufferDispatcher {
  size_t num_bytes;
  size_t platform_handle_index;
};

}  // namespace

// static
const MojoCreateSharedBufferOptions
    SharedBufferDispatcher::kDefaultCreateOptions = {
        static_cast<uint32_t>(sizeof(MojoCreateSharedBufferOptions)),
        MOJO_CREATE_SHARED_BUFFER_OPTIONS_FLAG_NONE};

// static
MojoResult SharedBufferDispatcher::ValidateCreateOptions(
    UserPointer<const MojoCreateSharedBufferOptions> in_options,
    MojoCreateSharedBufferOptions* out_options) {
  const MojoCreateSharedBufferOptionsFlags kKnownFlags =
      MOJO_CREATE_SHARED_BUFFER_OPTIONS_FLAG_NONE;

  *out_options = kDefaultCreateOptions;
  if (in_options.IsNull())
    return MOJO_RESULT_OK;

  UserOptionsReader<MojoCreateSharedBufferOptions> reader(in_options);
  if (!reader.is_valid())
    return MOJO_RESULT_INVALID_ARGUMENT;

  if (!OPTIONS_STRUCT_HAS_MEMBER(MojoCreateSharedBufferOptions, flags, reader))
    return MOJO_RESULT_OK;
  if ((reader.options().flags & ~kKnownFlags))
    return MOJO_RESULT_UNIMPLEMENTED;
  out_options->flags = reader.options().flags;

  // Checks for fields beyond |flags|:

  // (Nothing here yet.)

  return MOJO_RESULT_OK;
}

// static
MojoResult SharedBufferDispatcher::Create(
    embedder::PlatformSupport* platform_support,
    const MojoCreateSharedBufferOptions& /*validated_options*/,
    uint64_t num_bytes,
    scoped_refptr<SharedBufferDispatcher>* result) {
  if (!num_bytes)
    return MOJO_RESULT_INVALID_ARGUMENT;
  if (num_bytes > GetConfiguration().max_shared_memory_num_bytes)
    return MOJO_RESULT_RESOURCE_EXHAUSTED;

  scoped_refptr<embedder::PlatformSharedBuffer> shared_buffer(
      platform_support->CreateSharedBuffer(static_cast<size_t>(num_bytes)));
  if (!shared_buffer)
    return MOJO_RESULT_RESOURCE_EXHAUSTED;

  *result = CreateInternal(shared_buffer.Pass());
  return MOJO_RESULT_OK;
}

Dispatcher::Type SharedBufferDispatcher::GetType() const {
  return Type::SHARED_BUFFER;
}

// static
scoped_refptr<SharedBufferDispatcher> SharedBufferDispatcher::Deserialize(
    Channel* channel,
    const void* source,
    size_t size,
    embedder::PlatformHandleVector* platform_handles) {
  DCHECK(channel);

  if (size != sizeof(SerializedSharedBufferDispatcher)) {
    LOG(ERROR) << "Invalid serialized shared buffer dispatcher (bad size)";
    return nullptr;
  }

  const SerializedSharedBufferDispatcher* serialization =
      static_cast<const SerializedSharedBufferDispatcher*>(source);
  size_t num_bytes = serialization->num_bytes;
  size_t platform_handle_index = serialization->platform_handle_index;

  if (!num_bytes) {
    LOG(ERROR)
        << "Invalid serialized shared buffer dispatcher (invalid num_bytes)";
    return nullptr;
  }

  if (!platform_handles || platform_handle_index >= platform_handles->size()) {
    LOG(ERROR)
        << "Invalid serialized shared buffer dispatcher (missing handles)";
    return nullptr;
  }

  // Starts off invalid, which is what we want.
  embedder::PlatformHandle platform_handle;
  // We take ownership of the handle, so we have to invalidate the one in
  // |platform_handles|.
  std::swap(platform_handle, (*platform_handles)[platform_handle_index]);

  // Wrapping |platform_handle| in a |ScopedPlatformHandle| means that it'll be
  // closed even if creation fails.
  scoped_refptr<embedder::PlatformSharedBuffer> shared_buffer(
      channel->platform_support()->CreateSharedBufferFromHandle(
          num_bytes, embedder::ScopedPlatformHandle(platform_handle)));
  if (!shared_buffer) {
    LOG(ERROR)
        << "Invalid serialized shared buffer dispatcher (invalid num_bytes?)";
    return nullptr;
  }

  return CreateInternal(shared_buffer.Pass());
}

SharedBufferDispatcher::SharedBufferDispatcher(
    scoped_refptr<embedder::PlatformSharedBuffer> shared_buffer)
    : shared_buffer_(shared_buffer) {
  DCHECK(shared_buffer_);
}

SharedBufferDispatcher::~SharedBufferDispatcher() {
}

// static
MojoResult SharedBufferDispatcher::ValidateDuplicateOptions(
    UserPointer<const MojoDuplicateBufferHandleOptions> in_options,
    MojoDuplicateBufferHandleOptions* out_options) {
  const MojoDuplicateBufferHandleOptionsFlags kKnownFlags =
      MOJO_DUPLICATE_BUFFER_HANDLE_OPTIONS_FLAG_NONE;
  static const MojoDuplicateBufferHandleOptions kDefaultOptions = {
      static_cast<uint32_t>(sizeof(MojoDuplicateBufferHandleOptions)),
      MOJO_DUPLICATE_BUFFER_HANDLE_OPTIONS_FLAG_NONE};

  *out_options = kDefaultOptions;
  if (in_options.IsNull())
    return MOJO_RESULT_OK;

  UserOptionsReader<MojoDuplicateBufferHandleOptions> reader(in_options);
  if (!reader.is_valid())
    return MOJO_RESULT_INVALID_ARGUMENT;

  if (!OPTIONS_STRUCT_HAS_MEMBER(MojoDuplicateBufferHandleOptions, flags,
                                 reader))
    return MOJO_RESULT_OK;
  if ((reader.options().flags & ~kKnownFlags))
    return MOJO_RESULT_UNIMPLEMENTED;
  out_options->flags = reader.options().flags;

  // Checks for fields beyond |flags|:

  // (Nothing here yet.)

  return MOJO_RESULT_OK;
}

void SharedBufferDispatcher::CloseImplNoLock() {
  mutex().AssertHeld();
  DCHECK(shared_buffer_);
  shared_buffer_ = nullptr;
}

scoped_refptr<Dispatcher>
SharedBufferDispatcher::CreateEquivalentDispatcherAndCloseImplNoLock() {
  mutex().AssertHeld();
  DCHECK(shared_buffer_);
  return CreateInternal(shared_buffer_.Pass());
}

MojoResult SharedBufferDispatcher::DuplicateBufferHandleImplNoLock(
    UserPointer<const MojoDuplicateBufferHandleOptions> options,
    scoped_refptr<Dispatcher>* new_dispatcher) {
  mutex().AssertHeld();

  MojoDuplicateBufferHandleOptions validated_options;
  MojoResult result = ValidateDuplicateOptions(options, &validated_options);
  if (result != MOJO_RESULT_OK)
    return result;

  // Note: Since this is "duplicate", we keep our ref to |shared_buffer_|.
  *new_dispatcher = CreateInternal(shared_buffer_);
  return MOJO_RESULT_OK;
}

MojoResult SharedBufferDispatcher::MapBufferImplNoLock(
    uint64_t offset,
    uint64_t num_bytes,
    MojoMapBufferFlags flags,
    scoped_ptr<embedder::PlatformSharedBufferMapping>* mapping) {
  mutex().AssertHeld();
  DCHECK(shared_buffer_);

  if (offset > static_cast<uint64_t>(std::numeric_limits<size_t>::max()))
    return MOJO_RESULT_INVALID_ARGUMENT;
  if (num_bytes > static_cast<uint64_t>(std::numeric_limits<size_t>::max()))
    return MOJO_RESULT_INVALID_ARGUMENT;

  if (!shared_buffer_->IsValidMap(static_cast<size_t>(offset),
                                  static_cast<size_t>(num_bytes)))
    return MOJO_RESULT_INVALID_ARGUMENT;

  DCHECK(mapping);
  *mapping = shared_buffer_->MapNoCheck(static_cast<size_t>(offset),
                                        static_cast<size_t>(num_bytes));
  if (!*mapping)
    return MOJO_RESULT_RESOURCE_EXHAUSTED;

  return MOJO_RESULT_OK;
}

void SharedBufferDispatcher::StartSerializeImplNoLock(
    Channel* /*channel*/,
    size_t* max_size,
    size_t* max_platform_handles) {
  DCHECK(HasOneRef());  // Only one ref => no need to take the lock.
  *max_size = sizeof(SerializedSharedBufferDispatcher);
  *max_platform_handles = 1;
}

bool SharedBufferDispatcher::EndSerializeAndCloseImplNoLock(
    Channel* /*channel*/,
    void* destination,
    size_t* actual_size,
    embedder::PlatformHandleVector* platform_handles) {
  DCHECK(HasOneRef());  // Only one ref => no need to take the lock.
  DCHECK(shared_buffer_);

  SerializedSharedBufferDispatcher* serialization =
      static_cast<SerializedSharedBufferDispatcher*>(destination);
  // If there's only one reference to |shared_buffer_|, then it's ours (and no
  // one else can make any more references to it), so we can just take its
  // handle.
  embedder::ScopedPlatformHandle platform_handle(
      shared_buffer_->HasOneRef() ? shared_buffer_->PassPlatformHandle()
                                  : shared_buffer_->DuplicatePlatformHandle());
  if (!platform_handle.is_valid()) {
    shared_buffer_ = nullptr;
    return false;
  }

  serialization->num_bytes = shared_buffer_->GetNumBytes();
  serialization->platform_handle_index = platform_handles->size();
  platform_handles->push_back(platform_handle.release());
  *actual_size = sizeof(SerializedSharedBufferDispatcher);

  shared_buffer_ = nullptr;

  return true;
}

}  // namespace system
}  // namespace mojo
