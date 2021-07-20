// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_TESTS_FAKES_SCENIC_FAKE_SESSION_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_TESTS_FAKES_SCENIC_FAKE_SESSION_H_

#include <fuchsia/images/cpp/fidl.h>
#include <fuchsia/scenic/scheduling/cpp/fidl.h>
#include <fuchsia/ui/scenic/cpp/fidl.h>
#include <fuchsia/ui/scenic/cpp/fidl_test_base.h>
#include <lib/async/dispatcher.h>
#include <lib/fidl/cpp/binding.h>
#include <lib/fidl/cpp/interface_handle.h>
#include <lib/fidl/cpp/interface_request.h>

#include <functional>
#include <string>
#include <utility>  // For std::pair
#include <vector>

#include "flutter/fml/macros.h"

namespace flutter_runner::testing {

class FakeSession : public fuchsia::ui::scenic::testing::Session_TestBase {
 public:
  using PresentHandler =
      std::function<fuchsia::images::PresentationInfo(uint64_t,
                                                      std::vector<zx::event>,
                                                      std::vector<zx::event>)>;
  using Present2Handler =
      std::function<fuchsia::scenic::scheduling::FuturePresentationTimes(
          fuchsia::ui::scenic::Present2Args)>;
  using RequestPresentationTimesHandler =
      std::function<fuchsia::scenic::scheduling::FuturePresentationTimes(
          int64_t)>;
  using SessionAndListenerClientPair =
      std::pair<fidl::InterfaceHandle<fuchsia::ui::scenic::Session>,
                fidl::InterfaceRequest<fuchsia::ui::scenic::SessionListener>>;

  FakeSession();
  ~FakeSession() override = default;

  bool is_bound() const { return binding_.is_bound() && listener_.is_bound(); }

  const std::string& debug_name() const { return debug_name_; }

  const std::vector<fuchsia::ui::scenic::Command>& command_queue() {
    return command_queue_;
  }

  // Bind method.  Call to bind this session's FIDL channels to the |dispatcher|
  // and allow processing of incoming FIDL requests.
  SessionAndListenerClientPair Bind(async_dispatcher_t* dispatcher = nullptr);

  // Stub methods.  Call these to set a handler for the specified FIDL calls'
  // return values.
  void SetPresentHandler(PresentHandler present_handler);
  void SetPresent2Handler(Present2Handler present2_handler);
  void SetRequestPresentationTimesHandler(
      RequestPresentationTimesHandler request_presentation_times_handler);

  // Event methods.  Call these to fire the associated FIDL event.
  void FireOnFramePresentedEvent(
      fuchsia::scenic::scheduling::FramePresentedInfo frame_presented_info);

  // Error method.  Call to disconnect the session with an error.
  void DisconnectSession();

 private:
  // |fuchsia::ui::scenic::Session|
  void Enqueue(std::vector<fuchsia::ui::scenic::Command> cmds) override;

  // |fuchsia::ui::scenic::Session|
  void Present(uint64_t presentation_time,
               std::vector<zx::event> acquire_fences,
               std::vector<zx::event> release_fences,
               PresentCallback callback) override;

  // |fuchsia::ui::scenic::Session|
  void Present2(fuchsia::ui::scenic::Present2Args args,
                Present2Callback callback) override;

  // |fuchsia::ui::scenic::Session|
  void RequestPresentationTimes(
      int64_t requested_prediction_span,
      RequestPresentationTimesCallback callback) override;

  // |fuchsia::ui::scenic::Session|
  void RegisterBufferCollection(
      uint32_t buffer_id,
      fidl::InterfaceHandle<fuchsia::sysmem::BufferCollectionToken> token)
      override;

  // |fuchsia::ui::scenic::Session|
  void DeregisterBufferCollection(uint32_t buffer_id) override;

  // |fuchsia::ui::scenic::Session|
  void SetDebugName(std::string debug_name) override;

  // |fuchsia::ui::scenic::testing::Session_TestBase|
  void NotImplemented_(const std::string& name) override;

  fidl::Binding<fuchsia::ui::scenic::Session> binding_;
  fuchsia::ui::scenic::SessionListenerPtr listener_;

  std::string debug_name_;

  std::vector<fuchsia::ui::scenic::Command> command_queue_;

  PresentHandler present_handler_;
  Present2Handler present2_handler_;
  RequestPresentationTimesHandler request_presentation_times_handler_;

  FML_DISALLOW_COPY_AND_ASSIGN(FakeSession);
};

}  // namespace flutter_runner::testing

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_TESTS_FAKES_SCENIC_FAKE_SESSION_H_
