// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_WAIT_SET_DISPATCHER_H_
#define MOJO_EDK_SYSTEM_WAIT_SET_DISPATCHER_H_

#include "mojo/edk/system/dispatcher.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

// This is the |Dispatcher| implementation for wait sets (created by the Mojo
// primitive |MojoCreateWaitSet()|). This class is thread-safe.
class WaitSetDispatcher final : public Dispatcher {
 public:
  // The default/standard rights for a wait set handle. Note that they are not
  // transferrable.
  // TODO(vtl): Figure out if these are the correct rights. (E.g., we currently
  // don't have get/set options functions ... but maybe we should?)
  static constexpr MojoHandleRights kDefaultHandleRights =
      MOJO_HANDLE_RIGHT_READ | MOJO_HANDLE_RIGHT_WRITE |
      MOJO_HANDLE_RIGHT_GET_OPTIONS | MOJO_HANDLE_RIGHT_SET_OPTIONS;

  // The default options to use for |MojoCreateWaitSet()|. (Real uses should
  // obtain this via |ValidateCreateOptions()| with a null |in_options|; this is
  // exposed directly for testing convenience.)
  static const MojoCreateWaitSetOptions kDefaultCreateOptions;

  // Validates and/or sets default options for |MojoCreateWaitSetOptions|. If
  // non-null, |in_options| must point to a struct of at least
  // |in_options->struct_size| bytes. |out_options| must point to a (current)
  // |MojoCreateWaitSetOptions| and will be entirely overwritten on success (it
  // may be partly overwritten on failure).
  static MojoResult ValidateCreateOptions(
      UserPointer<const MojoCreateWaitSetOptions> in_options,
      MojoCreateWaitSetOptions* out_options);

  static util::RefPtr<WaitSetDispatcher> Create(
      const MojoCreateWaitSetOptions& /*validated_options*/) {
    return AdoptRef(new WaitSetDispatcher());
  }

  // |Dispatcher| public methods:
  Type GetType() const override;
  bool SupportsEntrypointClass(EntrypointClass entrypoint_class) const override;

 private:
  WaitSetDispatcher();
  ~WaitSetDispatcher() override;

  // |Dispatcher| protected methods:
  util::RefPtr<Dispatcher> CreateEquivalentDispatcherAndCloseImplNoLock(
      MessagePipe* message_pipe,
      unsigned port) override;
  MojoResult WaitSetAddImpl(UserPointer<const MojoWaitSetAddOptions> options,
                            Handle&& handle,
                            MojoHandleSignals signals,
                            uint64_t cookie) override;
  MojoResult WaitSetRemoveImpl(uint64_t cookie) override;
  MojoResult WaitSetWaitImpl(MojoDeadline deadline,
                             UserPointer<uint32_t> num_results,
                             UserPointer<MojoWaitSetResult> results,
                             UserPointer<uint32_t> max_results) override;

  MOJO_DISALLOW_COPY_AND_ASSIGN(WaitSetDispatcher);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_WAIT_SET_DISPATCHER_H_
