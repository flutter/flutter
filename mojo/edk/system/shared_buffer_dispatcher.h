// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_SHARED_BUFFER_DISPATCHER_H_
#define MOJO_EDK_SYSTEM_SHARED_BUFFER_DISPATCHER_H_

#include <utility>

#include "mojo/edk/system/memory.h"
#include "mojo/edk/system/simple_dispatcher.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/thread_annotations.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {

namespace embedder {
class PlatformSupport;
}

namespace platform {
class PlatformSharedBuffer;
class PlatformSharedBufferMapping;
}

namespace system {

// TODO(vtl): We derive from SimpleDispatcher, even though we don't currently
// have anything that's waitable. I want to add a "transferrable" wait flag
// (which would entail overriding |GetHandleSignalsStateImplNoLock()|, etc.).
class SharedBufferDispatcher final : public SimpleDispatcher {
 public:
  // The default options to use for |MojoCreateSharedBuffer()|. (Real uses
  // should obtain this via |ValidateCreateOptions()| with a null |in_options|;
  // this is exposed directly for testing convenience.)
  static const MojoCreateSharedBufferOptions kDefaultCreateOptions;

  // Validates and/or sets default options for |MojoCreateSharedBufferOptions|.
  // If non-null, |in_options| must point to a struct of at least
  // |in_options->struct_size| bytes. |out_options| must point to a (current)
  // |MojoCreateSharedBufferOptions| and will be entirely overwritten on success
  // (it may be partly overwritten on failure).
  static MojoResult ValidateCreateOptions(
      UserPointer<const MojoCreateSharedBufferOptions> in_options,
      MojoCreateSharedBufferOptions* out_options);

  // Static factory method: |validated_options| must be validated (obviously).
  // Returns null on error; |*result| will be set to an appropriate result
  // code).
  static util::RefPtr<SharedBufferDispatcher> Create(
      embedder::PlatformSupport* platform_support,
      const MojoCreateSharedBufferOptions& validated_options,
      uint64_t num_bytes,
      MojoResult* result);

  // |Dispatcher| public methods:
  Type GetType() const override;

  // The "opposite" of |SerializeAndClose()|. (Typically this is called by
  // |Dispatcher::Deserialize()|.)
  static util::RefPtr<SharedBufferDispatcher> Deserialize(
      Channel* channel,
      const void* source,
      size_t size,
      std::vector<platform::ScopedPlatformHandle>* platform_handles);

 private:
  static util::RefPtr<SharedBufferDispatcher> CreateInternal(
      util::RefPtr<platform::PlatformSharedBuffer>&& shared_buffer) {
    return AdoptRef(new SharedBufferDispatcher(std::move(shared_buffer)));
  }

  explicit SharedBufferDispatcher(
      util::RefPtr<platform::PlatformSharedBuffer>&& shared_buffer);
  ~SharedBufferDispatcher() override;

  // Validates and/or sets default options for
  // |MojoDuplicateBufferHandleOptions|. If non-null, |in_options| must point to
  // a struct of at least |in_options->struct_size| bytes. |out_options| must
  // point to a (current) |MojoDuplicateBufferHandleOptions| and will be
  // entirely overwritten on success (it may be partly overwritten on failure).
  static MojoResult ValidateDuplicateOptions(
      UserPointer<const MojoDuplicateBufferHandleOptions> in_options,
      MojoDuplicateBufferHandleOptions* out_options);

  // |Dispatcher| protected methods:
  void CloseImplNoLock() override;
  util::RefPtr<Dispatcher> CreateEquivalentDispatcherAndCloseImplNoLock()
      override;
  MojoResult DuplicateBufferHandleImplNoLock(
      UserPointer<const MojoDuplicateBufferHandleOptions> options,
      util::RefPtr<Dispatcher>* new_dispatcher) override;
  MojoResult GetBufferInformationImplNoLock(
      UserPointer<MojoBufferInformation> info,
      uint32_t info_num_bytes) override;
  MojoResult MapBufferImplNoLock(
      uint64_t offset,
      uint64_t num_bytes,
      MojoMapBufferFlags flags,
      std::unique_ptr<platform::PlatformSharedBufferMapping>* mapping) override;
  void StartSerializeImplNoLock(Channel* channel,
                                size_t* max_size,
                                size_t* max_platform_handles) override
      MOJO_NOT_THREAD_SAFE;
  bool EndSerializeAndCloseImplNoLock(
      Channel* channel,
      void* destination,
      size_t* actual_size,
      std::vector<platform::ScopedPlatformHandle>* platform_handles) override
      MOJO_NOT_THREAD_SAFE;

  util::RefPtr<platform::PlatformSharedBuffer> shared_buffer_
      MOJO_GUARDED_BY(mutex());

  MOJO_DISALLOW_COPY_AND_ASSIGN(SharedBufferDispatcher);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_SHARED_BUFFER_DISPATCHER_H_
