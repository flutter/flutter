// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_PLATFORM_VIEW_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_PLATFORM_VIEW_H_

#include <fuchsia/sys/cpp/fidl.h>
#include <fuchsia/ui/input/cpp/fidl.h>
#include <fuchsia/ui/input3/cpp/fidl.h>
#include <fuchsia/ui/scenic/cpp/fidl.h>
#include <lib/fidl/cpp/binding.h>
#include <lib/fit/function.h>
#include <lib/sys/cpp/service_directory.h>
#include <lib/ui/scenic/cpp/id.h>

#include <map>
#include <set>
#include <unordered_map>

#include "flow/embedded_views.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/platform/fuchsia/flutter/fuchsia_external_view_embedder.h"
#include "flutter/shell/platform/fuchsia/flutter/keyboard.h"
#include "flutter/shell/platform/fuchsia/flutter/vsync_waiter.h"
#include "focus_delegate.h"

namespace flutter_runner {

using OnEnableWireframe = fit::function<void(bool)>;
using OnCreateView =
    fit::function<void(int64_t, ViewCallback, ViewIdCallback, bool, bool)>;
using OnUpdateView = fit::function<void(int64_t, SkRect, bool, bool)>;
using OnDestroyView = fit::function<void(int64_t, ViewIdCallback)>;
using OnCreateSurface = fit::function<std::unique_ptr<flutter::Surface>()>;
using OnSemanticsNodeUpdate =
    fit::function<void(flutter::SemanticsNodeUpdates, float)>;
using OnRequestAnnounce = fit::function<void(std::string)>;
// we use an std::function here because the fit::funtion causes problems with
// std:bind since HandleFuchsiaShaderWarmupChannelPlatformMessage takes one of
// these as its first argument.
using OnShaderWarmup = std::function<void(const std::vector<std::string>&,
                                          std::function<void(uint32_t)>,
                                          uint64_t,
                                          uint64_t)>;

// PlatformView is the per-engine component residing on the platform thread that
// is responsible for all platform specific integrations -- particularly
// integration with the platform's accessibility, input, and windowing features.
//
// PlatformView communicates with the Dart code via "platform messages" handled
// in HandlePlatformMessage.  This communication is bidirectional.  Platform
// messages are notably responsible for communication related to input and
// external views / windowing.
//
// The PlatformView implements SessionListener and gets Session events but it
// does *not* actually own the Session itself; that is owned by the
// FuchsiaExternalViewEmbedder on the raster thread.
class PlatformView final : public flutter::PlatformView,
                           private fuchsia::ui::scenic::SessionListener,
                           private fuchsia::ui::input3::KeyboardListener,
                           private fuchsia::ui::input::InputMethodEditorClient {
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
               fidl::InterfaceHandle<fuchsia::ui::views::ViewRefFocused> vrf,
               fidl::InterfaceHandle<fuchsia::ui::views::Focuser> focuser,
               fidl::InterfaceRequest<fuchsia::ui::input3::KeyboardListener>
                   keyboard_listener,
               fit::closure on_session_listener_error_callback,
               OnEnableWireframe wireframe_enabled_callback,
               OnCreateView on_create_view_callback,
               OnUpdateView on_update_view_callback,
               OnDestroyView on_destroy_view_callback,
               OnCreateSurface on_create_surface_callback,
               OnSemanticsNodeUpdate on_semantics_node_update_callback,
               OnRequestAnnounce on_request_announce_callback,
               OnShaderWarmup on_shader_warmup,
               std::shared_ptr<flutter::ExternalViewEmbedder> view_embedder,
               AwaitVsyncCallback await_vsync_callback,
               AwaitVsyncForSecondaryCallbackCallback
                   await_vsync_for_secondary_callback_callback);

  ~PlatformView();

  // |flutter::PlatformView|
  void SetSemanticsEnabled(bool enabled) override;

  // |flutter::PlatformView|
  std::shared_ptr<flutter::ExternalViewEmbedder> CreateExternalViewEmbedder()
      override;

 private:
  void RegisterPlatformMessageHandlers();

  // |fuchsia.ui.input3.KeyboardListener|
  // Called by the embedder every time there is a key event to process.
  void OnKeyEvent(fuchsia::ui::input3::KeyEvent key_event,
                  fuchsia::ui::input3::KeyboardListener::OnKeyEventCallback
                      callback) override;

  // |fuchsia::ui::input::InputMethodEditorClient|
  void DidUpdateState(
      fuchsia::ui::input::TextInputState state,
      std::unique_ptr<fuchsia::ui::input::InputEvent> event) override;

  // |fuchsia::ui::input::InputMethodEditorClient|
  void OnAction(fuchsia::ui::input::InputMethodAction action) override;

  // |fuchsia::ui::scenic::SessionListener|
  void OnScenicError(std::string error) override;
  void OnScenicEvent(std::vector<fuchsia::ui::scenic::Event> events) override;

  // ViewHolder event handlers.  These return false if the ViewHolder
  // corresponding to `view_holder_id` could not be found and the evnt was
  // unhandled.
  bool OnChildViewConnected(scenic::ResourceId view_holder_id);
  bool OnChildViewDisconnected(scenic::ResourceId view_holder_id);
  bool OnChildViewStateChanged(scenic::ResourceId view_holder_id,
                               bool is_rendering);

  bool OnHandlePointerEvent(const fuchsia::ui::input::PointerEvent& pointer);

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
      std::unique_ptr<flutter::PlatformMessage> message) override;

  // |flutter::PlatformView|
  void UpdateSemantics(
      flutter::SemanticsNodeUpdates update,
      flutter::CustomAccessibilityActionUpdates actions) override;

  // Channel handler for kAccessibilityChannel. This is currently not
  // being used, but it is necessary to handle accessibility messages
  // that are sent by Flutter when semantics is enabled.
  bool HandleAccessibilityChannelPlatformMessage(
      std::unique_ptr<flutter::PlatformMessage> message);

  // Channel handler for kFlutterPlatformChannel
  bool HandleFlutterPlatformChannelPlatformMessage(
      std::unique_ptr<flutter::PlatformMessage> message);

  // Channel handler for kTextInputChannel
  bool HandleFlutterTextInputChannelPlatformMessage(
      std::unique_ptr<flutter::PlatformMessage> message);

  // Channel handler for kPlatformViewsChannel.
  bool HandleFlutterPlatformViewsChannelPlatformMessage(
      std::unique_ptr<flutter::PlatformMessage> message);

  // Channel handler for kFuchsiaShaderWarmupChannel.
  static bool HandleFuchsiaShaderWarmupChannelPlatformMessage(
      OnShaderWarmup on_shader_warmup,
      std::unique_ptr<flutter::PlatformMessage> message);

  const std::string debug_label_;
  // TODO(MI4-2490): remove once ViewRefControl is passed to Scenic and kept
  // alive there
  const fuchsia::ui::views::ViewRef view_ref_;
  std::shared_ptr<FocusDelegate> focus_delegate_;

  // Logical size and logical->physical ratio.  These are optional to provide
  // an "unset" state during program startup, before Scenic has sent any
  // metrics-related events to provide initial values for these.
  //
  // The engine internally uses a default size of (0.f 0.f) with a default 1.f
  // ratio, so there is no need to emit events until Scenic has actually sent a
  // valid size and ratio.
  std::optional<std::pair<float, float>> view_logical_size_;
  std::optional<float> view_pixel_ratio_;

  fidl::Binding<fuchsia::ui::scenic::SessionListener> session_listener_binding_;
  fit::closure session_listener_error_callback_;
  OnEnableWireframe wireframe_enabled_callback_;
  OnCreateView on_create_view_callback_;
  OnUpdateView on_update_view_callback_;
  OnDestroyView on_destroy_view_callback_;
  OnCreateSurface on_create_surface_callback_;

  // Accessibility handlers:
  OnSemanticsNodeUpdate on_semantics_node_update_callback_;
  OnRequestAnnounce on_request_announce_callback_;

  OnShaderWarmup on_shader_warmup_;
  std::shared_ptr<flutter::ExternalViewEmbedder> external_view_embedder_;

  int current_text_input_client_ = 0;
  fidl::Binding<fuchsia::ui::input::InputMethodEditorClient> ime_client_;
  fuchsia::ui::input::InputMethodEditorPtr ime_;
  fuchsia::ui::input::ImeServicePtr text_sync_service_;

  fuchsia::sys::ServiceProviderPtr parent_environment_service_provider_;

  // child_view_ids_ maintains a persistent mapping from Scenic ResourceId's to
  // flutter view ids, which are really zx_handle_t of ViewHolderToken.
  std::unordered_map<scenic::ResourceId, zx_handle_t> child_view_ids_;

  // last_text_state_ is the last state of the text input as reported by the IME
  // or initialized by Flutter. We set it to null if Flutter doesn't want any
  // input, since then there is no text input state at all.
  std::unique_ptr<fuchsia::ui::input::TextInputState> last_text_state_;

  std::set<int> down_pointers_;
  std::map<std::string /* channel */,
           std::function<bool /* response_handled */ (
               std::unique_ptr<
                   flutter::PlatformMessage> /* message */)> /* handler */>
      platform_message_handlers_;
  // These are the channels that aren't registered and have been notified as
  // such. Notifying via logs multiple times results in log-spam. See:
  // https://github.com/flutter/flutter/issues/55966
  std::set<std::string /* channel */> unregistered_channels_;

  // The registered binding for serving the keyboard listener server endpoint.
  fidl::Binding<fuchsia::ui::input3::KeyboardListener>
      keyboard_listener_binding_;

  // The keyboard translation for fuchsia.ui.input3.KeyEvent.
  Keyboard keyboard_;

  AwaitVsyncCallback await_vsync_callback_;
  AwaitVsyncForSecondaryCallbackCallback
      await_vsync_for_secondary_callback_callback_;

  fml::WeakPtrFactory<PlatformView> weak_factory_;  // Must be the last member.

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformView);
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_PLATFORM_VIEW_H_
