// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_PLATFORM_VIEW_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_PLATFORM_VIEW_H_

#include <fuchsia/ui/input/cpp/fidl.h>
#include <fuchsia/ui/scenic/cpp/fidl.h>
#include <lib/fidl/cpp/binding.h>
#include <lib/fit/function.h>

#include <map>
#include <set>

#include "flutter/fml/macros.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/shell/common/platform_view.h"

#include "accessibility_bridge.h"

#if defined(LEGACY_FUCHSIA_EMBEDDER)
#include <lib/ui/scenic/cpp/id.h>  // nogncheck
#endif

namespace flutter_runner {

using OnEnableWireframe = fit::function<void(bool)>;
using OnCreateView = fit::function<void(int64_t, bool, bool)>;
using OnUpdateView = fit::function<void(int64_t, bool, bool)>;
using OnDestroyView = fit::function<void(int64_t)>;
using OnCreateSurface = fit::function<std::unique_ptr<flutter::Surface>()>;

// The per engine component residing on the platform thread is responsible for
// all platform specific integrations.
//
// The PlatformView implements SessionListener and gets Session events but it
// does *not* actually own the Session itself; that is owned by the Compositor
// thread.
class PlatformView final : public flutter::PlatformView,
                           private fuchsia::ui::scenic::SessionListener,
                           public fuchsia::ui::input::InputMethodEditorClient,
                           public AccessibilityBridge::Delegate {
 public:
  PlatformView(flutter::PlatformView::Delegate& delegate,
               std::string debug_label,
               fuchsia::ui::views::ViewRef view_ref,
               flutter::TaskRunners task_runners,
               std::shared_ptr<sys::ServiceDirectory> runner_services,
               fidl::InterfaceHandle<fuchsia::sys::ServiceProvider>
                   parent_environment_service_provider,
               fidl::InterfaceRequest<fuchsia::ui::scenic::SessionListener>
                   session_listener_request,
               fidl::InterfaceHandle<fuchsia::ui::views::Focuser> focuser,
               fit::closure on_session_listener_error_callback,
               OnEnableWireframe wireframe_enabled_callback,
               OnCreateView on_create_view_callback,
               OnUpdateView on_update_view_callback,
               OnDestroyView on_destroy_view_callback,
               OnCreateSurface on_create_surface_callback,
               fml::TimeDelta vsync_offset,
               zx_handle_t vsync_event_handle);

  ~PlatformView();

  // |flutter::PlatformView|
  // |flutter_runner::AccessibilityBridge::Delegate|
  void SetSemanticsEnabled(bool enabled) override;

  // |flutter_runner::AccessibilityBridge::Delegate|
  void DispatchSemanticsAction(int32_t node_id,
                               flutter::SemanticsAction action) override;

  // |PlatformView|
  flutter::PointerDataDispatcherMaker GetDispatcherMaker() override;

 private:
  const std::string debug_label_;
  // TODO(MI4-2490): remove once ViewRefControl is passed to Scenic and kept
  // alive there
  const fuchsia::ui::views::ViewRef view_ref_;
  fuchsia::ui::views::FocuserPtr focuser_;
  std::unique_ptr<AccessibilityBridge> accessibility_bridge_;

  fidl::Binding<fuchsia::ui::scenic::SessionListener> session_listener_binding_;
  fit::closure session_listener_error_callback_;
  OnEnableWireframe wireframe_enabled_callback_;
  OnCreateView on_create_view_callback_;
  OnUpdateView on_update_view_callback_;
  OnDestroyView on_destroy_view_callback_;
  OnCreateSurface on_create_surface_callback_;

  int current_text_input_client_ = 0;
  fidl::Binding<fuchsia::ui::input::InputMethodEditorClient> ime_client_;
  fuchsia::ui::input::InputMethodEditorPtr ime_;
  fuchsia::ui::input::ImeServicePtr text_sync_service_;

  fuchsia::sys::ServiceProviderPtr parent_environment_service_provider_;

  // last_text_state_ is the last state of the text input as reported by the IME
  // or initialized by Flutter. We set it to null if Flutter doesn't want any
  // input, since then there is no text input state at all.
  std::unique_ptr<fuchsia::ui::input::TextInputState> last_text_state_;

  std::set<int> down_pointers_;
  std::map<
      std::string /* channel */,
      fit::function<void(
          fml::RefPtr<flutter::PlatformMessage> /* message */)> /* handler */>
      platform_message_handlers_;
  // These are the channels that aren't registered and have been notified as
  // such. Notifying via logs multiple times results in log-spam. See:
  // https://github.com/flutter/flutter/issues/55966
  std::set<std::string /* channel */> unregistered_channels_;

  fml::TimeDelta vsync_offset_;
  zx_handle_t vsync_event_handle_ = 0;

  float view_width_ = 0.0f;        // Width in logical pixels.
  float view_height_ = 0.0f;       // Height in logical pixels.
  float view_pixel_ratio_ = 0.0f;  // Logical / physical pixel ratio.

  void RegisterPlatformMessageHandlers();

  // |fuchsia::ui::input::InputMethodEditorClient|
  void DidUpdateState(
      fuchsia::ui::input::TextInputState state,
      std::unique_ptr<fuchsia::ui::input::InputEvent> event) override;

  // |fuchsia::ui::input::InputMethodEditorClient|
  void OnAction(fuchsia::ui::input::InputMethodAction action) override;

  // |fuchsia::ui::scenic::SessionListener|
  void OnScenicError(std::string error) override;
  void OnScenicEvent(std::vector<fuchsia::ui::scenic::Event> events) override;

#if defined(LEGACY_FUCHSIA_EMBEDDER)
  void OnChildViewConnected(scenic::ResourceId view_holder_id);
  void OnChildViewDisconnected(scenic::ResourceId view_holder_id);
  void OnChildViewStateChanged(scenic::ResourceId view_holder_id, bool state);
#endif

  bool OnHandlePointerEvent(const fuchsia::ui::input::PointerEvent& pointer);

  bool OnHandleKeyboardEvent(const fuchsia::ui::input::KeyboardEvent& keyboard);

  bool OnHandleFocusEvent(const fuchsia::ui::input::FocusEvent& focus);

  // Gets a new input method editor from the input connection. Run when both
  // Scenic has focus and Flutter has requested input with setClient.
  void ActivateIme();

  // Detaches the input method editor connection, ending the edit session and
  // closing the onscreen keyboard. Call when input is no longer desired, either
  // because Scenic says we lost focus or when Flutter no longer has a text
  // field focused.
  void DeactivateIme();

  // |flutter::PlatformView|
  std::unique_ptr<flutter::VsyncWaiter> CreateVSyncWaiter() override;

  // |flutter::PlatformView|
  std::unique_ptr<flutter::Surface> CreateRenderingSurface() override;

  // |flutter::PlatformView|
  void HandlePlatformMessage(
      fml::RefPtr<flutter::PlatformMessage> message) override;

  // |flutter::PlatformView|
  void UpdateSemantics(
      flutter::SemanticsNodeUpdates update,
      flutter::CustomAccessibilityActionUpdates actions) override;

  // Channel handler for kAccessibilityChannel. This is currently not
  // being used, but it is necessary to handle accessibility messages
  // that are sent by Flutter when semantics is enabled.
  void HandleAccessibilityChannelPlatformMessage(
      fml::RefPtr<flutter::PlatformMessage> message);

  // Channel handler for kFlutterPlatformChannel
  void HandleFlutterPlatformChannelPlatformMessage(
      fml::RefPtr<flutter::PlatformMessage> message);

  // Channel handler for kTextInputChannel
  void HandleFlutterTextInputChannelPlatformMessage(
      fml::RefPtr<flutter::PlatformMessage> message);

  // Channel handler for kPlatformViewsChannel.
  void HandleFlutterPlatformViewsChannelPlatformMessage(
      fml::RefPtr<flutter::PlatformMessage> message);

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformView);
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_PLATFORM_VIEW_H_
