// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <map>
#include <set>

#include "accessibility_bridge.h"
#include "flutter/lib/ui/window/viewport_metrics.h"
#include "flutter/shell/common/platform_view.h"
#include "lib/clipboard/fidl/clipboard.fidl.h"
#include "lib/fidl/cpp/bindings/binding.h"
#include "lib/fxl/macros.h"
#include "lib/ui/input/fidl/input_connection.fidl.h"
#include "lib/ui/views/fidl/view_manager.fidl.h"
#include "lib/ui/views/fidl/views.fidl.h"
#include "surface.h"

namespace flutter {

// The per engine component residing on the platform thread is responsible for
// all platform specific integrations.
class PlatformView final : public shell::PlatformView,
                           public mozart::ViewListener,
                           public mozart::InputMethodEditorClient,
                           public mozart::InputListener {
 public:
  PlatformView(
      PlatformView::Delegate& delegate,
      std::string debug_label,
      blink::TaskRunners task_runners,
      component::ServiceProviderPtr parent_environment_service_provider,
      mozart::ViewManagerPtr& view_manager,
      f1dl::InterfaceRequest<mozart::ViewOwner> view_owner,
      ui::ScenicPtr scenic,
      zx::eventpair export_token,
      zx::eventpair import_token,
      maxwell::ContextWriterPtr accessibility_context_writer,
      OnMetricsUpdate on_session_metrics_did_change,
      fxl::Closure session_error_callback);

  ~PlatformView();

  void UpdateViewportMetrics(double pixel_ratio);

  mozart::ViewPtr& GetMozartView();

 private:
  const std::string debug_label_;
  mozart::ViewPtr view_;
  f1dl::Binding<mozart::ViewListener> view_listener_;
  mozart::InputConnectionPtr input_connection_;
  f1dl::Binding<mozart::InputListener> input_listener_;
  int current_text_input_client_ = 0;
  f1dl::Binding<mozart::InputMethodEditorClient> ime_client_;
  mozart::InputMethodEditorPtr ime_;
  modular::ClipboardPtr clipboard_;
  ui::ScenicPtr scenic_;
  AccessibilityBridge accessibility_bridge_;
  std::unique_ptr<Surface> surface_;
  blink::LogicalMetrics metrics_;
  std::set<int> down_pointers_;
  std::map<
      std::string /* channel */,
      std::function<void(
          fxl::RefPtr<blink::PlatformMessage> /* message */)> /* handler */>
      platform_message_handlers_;

  void RegisterPlatformMessageHandlers();

  void UpdateViewportMetrics(const mozart::ViewLayoutPtr& layout);

  void FlushViewportMetrics();

  // |mozart::ViewListener|
  void OnPropertiesChanged(
      mozart::ViewPropertiesPtr properties,
      const OnPropertiesChangedCallback& callback) override;

  // |mozart::InputMethodEditorClient|
  void DidUpdateState(mozart::TextInputStatePtr state,
                      mozart::InputEventPtr event) override;

  // |mozart::InputMethodEditorClient|
  void OnAction(mozart::InputMethodAction action) override;

  // |mozart::InputListener|
  void OnEvent(mozart::InputEventPtr event,
               const OnEventCallback& callback) override;

  bool OnHandlePointerEvent(const mozart::PointerEventPtr& pointer);

  bool OnHandleKeyboardEvent(const mozart::KeyboardEventPtr& keyboard);

  bool OnHandleFocusEvent(const mozart::FocusEventPtr& focus);

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
