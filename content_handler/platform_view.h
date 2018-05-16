// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <map>
#include <set>

#include <input/cpp/fidl.h>
#include <modular/cpp/fidl.h>
#include <views_v1/cpp/fidl.h>
#include <views_v1_token/cpp/fidl.h>

#include "accessibility_bridge.h"
#include "flutter/lib/ui/window/viewport_metrics.h"
#include "flutter/shell/common/platform_view.h"
#include "lib/fidl/cpp/binding.h"
#include "lib/fxl/macros.h"
#include "surface.h"

namespace flutter {

// The per engine component residing on the platform thread is responsible for
// all platform specific integrations.
class PlatformView final : public shell::PlatformView,
                           public views_v1::ViewListener,
                           public input::InputMethodEditorClient,
                           public input::InputListener {
 public:
  PlatformView(PlatformView::Delegate& delegate,
               std::string debug_label,
               blink::TaskRunners task_runners,
               fidl::InterfaceHandle<component::ServiceProvider>
                   parent_environment_service_provider,
               fidl::InterfaceHandle<views_v1::ViewManager> view_manager,
               fidl::InterfaceRequest<views_v1_token::ViewOwner> view_owner,
               zx::eventpair export_token,
               fidl::InterfaceHandle<modular::ContextWriter>
                   accessibility_context_writer,
               zx_handle_t vsync_event_handle);

  ~PlatformView();

  void UpdateViewportMetrics(double pixel_ratio);

  fidl::InterfaceHandle<views_v1::ViewContainer> TakeViewContainer();

  void OfferServiceProvider(
      fidl::InterfaceHandle<component::ServiceProvider> service_provider,
      fidl::VectorPtr<fidl::StringPtr> services);

 private:
  const std::string debug_label_;
  views_v1::ViewManagerPtr view_manager_;
  views_v1::ViewPtr view_;
  fidl::InterfaceHandle<views_v1::ViewContainer> view_container_;
  component::ServiceProviderPtr service_provider_;
  fidl::Binding<views_v1::ViewListener> view_listener_;
  input::InputConnectionPtr input_connection_;
  fidl::Binding<input::InputListener> input_listener_;
  int current_text_input_client_ = 0;
  fidl::Binding<input::InputMethodEditorClient> ime_client_;
  input::InputMethodEditorPtr ime_;
  component::ServiceProviderPtr parent_environment_service_provider_;
  modular::ClipboardPtr clipboard_;
  AccessibilityBridge accessibility_bridge_;
  std::unique_ptr<Surface> surface_;
  blink::LogicalMetrics metrics_;
  std::set<int> down_pointers_;
  std::map<
      std::string /* channel */,
      std::function<void(
          fxl::RefPtr<blink::PlatformMessage> /* message */)> /* handler */>
      platform_message_handlers_;
  zx_handle_t vsync_event_handle_ = 0;

  void RegisterPlatformMessageHandlers();

  void UpdateViewportMetrics(const views_v1::ViewLayout& layout);

  void FlushViewportMetrics();

  // |views_v1::ViewListener|
  void OnPropertiesChanged(views_v1::ViewProperties properties,
                           OnPropertiesChangedCallback callback) override;

  // |input::InputMethodEditorClient|
  void DidUpdateState(input::TextInputState state,
                      std::unique_ptr<input::InputEvent> event) override;

  // |input::InputMethodEditorClient|
  void OnAction(input::InputMethodAction action) override;

  // |input::InputListener|
  void OnEvent(input::InputEvent event, OnEventCallback callback) override;

  bool OnHandlePointerEvent(const input::PointerEvent& pointer);

  bool OnHandleKeyboardEvent(const input::KeyboardEvent& keyboard);

  bool OnHandleFocusEvent(const input::FocusEvent& focus);

  // |shell::PlatformView|
  std::unique_ptr<shell::VsyncWaiter> CreateVSyncWaiter() override;

  // |shell::PlatformView|
  std::unique_ptr<shell::Surface> CreateRenderingSurface() override;

  // |shell::PlatformView|
  void HandlePlatformMessage(
      fxl::RefPtr<blink::PlatformMessage> message) override;

  // |shell::PlatformView|
  void UpdateSemantics(blink::SemanticsNodeUpdates update) override;

  // Channel handler for kFlutterPlatformChannel
  void HandleFlutterPlatformChannelPlatformMessage(
      fxl::RefPtr<blink::PlatformMessage> message);

  // Channel handler for kTextInputChannel
  void HandleFlutterTextInputChannelPlatformMessage(
      fxl::RefPtr<blink::PlatformMessage> message);

  FXL_DISALLOW_COPY_AND_ASSIGN(PlatformView);
};

}  // namespace flutter
