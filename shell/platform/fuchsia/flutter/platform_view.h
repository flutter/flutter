// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_PLATFORM_VIEW_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_PLATFORM_VIEW_H_

#include <fuchsia/sys/cpp/fidl.h>
#include <fuchsia/ui/input/cpp/fidl.h>
#include <fuchsia/ui/input3/cpp/fidl.h>
#include <fuchsia/ui/pointer/cpp/fidl.h>
#include <fuchsia/ui/scenic/cpp/fidl.h>
#include <fuchsia/ui/test/input/cpp/fidl.h>
#include <lib/fidl/cpp/binding.h>
#include <lib/fit/function.h>
#include <lib/sys/cpp/service_directory.h>
#include <lib/ui/scenic/cpp/id.h>

#include <array>
#include <functional>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <unordered_map>
#include <vector>

#include "flow/embedded_views.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/platform/fuchsia/flutter/keyboard.h"
#include "flutter/shell/platform/fuchsia/flutter/vsync_waiter.h"
#include "focus_delegate.h"
#include "pointer_delegate.h"
#include "pointer_injector_delegate.h"
#include "text_delegate.h"

namespace flutter_runner {

using OnEnableWireframe = fit::function<void(bool)>;
using ViewCallback = std::function<void()>;
using OnUpdateView = fit::function<void(int64_t, SkRect, bool, bool)>;
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
class PlatformView : public flutter::PlatformView {
 public:
  PlatformView(
      bool is_flatland,
      flutter::PlatformView::Delegate& delegate,
      flutter::TaskRunners task_runners,
      fuchsia::ui::views::ViewRef view_ref,
      std::shared_ptr<flutter::ExternalViewEmbedder> external_view_embedder,
      fuchsia::ui::input::ImeServiceHandle ime_service,
      fuchsia::ui::input3::KeyboardHandle keyboard,
      fuchsia::ui::pointer::TouchSourceHandle touch_source,
      fuchsia::ui::pointer::MouseSourceHandle mouse_source,
      fuchsia::ui::views::FocuserHandle focuser,
      fuchsia::ui::views::ViewRefFocusedHandle view_ref_focused,
      fuchsia::ui::pointerinjector::RegistryHandle pointerinjector_registry,
      OnEnableWireframe wireframe_enabled_callback,
      OnUpdateView on_update_view_callback,
      OnCreateSurface on_create_surface_callback,
      OnSemanticsNodeUpdate on_semantics_node_update_callback,
      OnRequestAnnounce on_request_announce_callback,
      OnShaderWarmup on_shader_warmup,
      AwaitVsyncCallback await_vsync_callback,
      AwaitVsyncForSecondaryCallbackCallback
          await_vsync_for_secondary_callback_callback,
      std::shared_ptr<sys::ServiceDirectory> dart_application_svc);

  ~PlatformView() override;

  // |flutter::PlatformView|
  void SetSemanticsEnabled(bool enabled) override;

  // |flutter::PlatformView|
  std::shared_ptr<flutter::ExternalViewEmbedder> CreateExternalViewEmbedder()
      override;

 protected:
  void RegisterPlatformMessageHandlers();

  bool OnHandlePointerEvent(const fuchsia::ui::input::PointerEvent& pointer);

  bool OnHandleFocusEvent(const fuchsia::ui::input::FocusEvent& focus);

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

  // Channel handler for kPlatformViewsChannel.
  bool HandleFlutterPlatformViewsChannelPlatformMessage(
      std::unique_ptr<flutter::PlatformMessage> message);

  // Channel handler for kFuchsiaShaderWarmupChannel.
  static bool HandleFuchsiaShaderWarmupChannelPlatformMessage(
      OnShaderWarmup on_shader_warmup,
      std::unique_ptr<flutter::PlatformMessage> message);

  // Channel handler for kFuchsiaInputTestChannel.
  bool HandleFuchsiaInputTestChannelPlatformMessage(
      std::unique_ptr<flutter::PlatformMessage> message);

  // Channel handler for kFuchsiaChildViewChannel.
  bool HandleFuchsiaChildViewChannelPlatformMessage(
      std::unique_ptr<flutter::PlatformMessage> message);

  virtual void OnCreateView(ViewCallback on_view_created,
                            int64_t view_id_raw,
                            bool hit_testable,
                            bool focusable) = 0;
  virtual void OnDisposeView(int64_t view_id_raw) = 0;

  // Utility function for coordinate massaging.
  std::array<float, 2> ClampToViewSpace(const float x, const float y) const;

  // Logical size and origin, and logical->physical ratio.  These are optional
  // to provide an "unset" state during program startup, before Scenic has sent
  // any metrics-related events to provide initial values for these.
  //
  // The engine internally uses a default size of (0.f 0.f) with a default 1.f
  // ratio, so there is no need to emit events until Scenic has actually sent a
  // valid size and ratio.
  std::optional<std::array<float, 2>> view_logical_size_;
  std::optional<std::array<float, 2>> view_logical_origin_;
  std::optional<float> view_pixel_ratio_;

  std::shared_ptr<flutter::ExternalViewEmbedder> external_view_embedder_;

  std::shared_ptr<FocusDelegate> focus_delegate_;
  std::shared_ptr<PointerDelegate> pointer_delegate_;
  std::unique_ptr<PointerInjectorDelegate> pointer_injector_delegate_;

  // Text delegate is responsible for handling keyboard input and text editing.
  std::unique_ptr<TextDelegate> text_delegate_;

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

  OnEnableWireframe wireframe_enabled_callback_;
  OnUpdateView on_update_view_callback_;
  OnCreateSurface on_create_surface_callback_;
  OnSemanticsNodeUpdate on_semantics_node_update_callback_;
  OnRequestAnnounce on_request_announce_callback_;
  OnShaderWarmup on_shader_warmup_;
  AwaitVsyncCallback await_vsync_callback_;
  AwaitVsyncForSecondaryCallbackCallback
      await_vsync_for_secondary_callback_callback_;

  // Proxies for input tests.
  fuchsia::ui::test::input::TouchInputListenerPtr touch_input_listener_;
  fuchsia::ui::test::input::KeyboardInputListenerPtr keyboard_input_listener_;
  fuchsia::ui::test::input::MouseInputListenerPtr mouse_input_listener_;

  // Component's service directory.
  std::shared_ptr<sys::ServiceDirectory> dart_application_svc_;

  fml::WeakPtrFactory<PlatformView> weak_factory_;  // Must be the last member.

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformView);
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_PLATFORM_VIEW_H_
