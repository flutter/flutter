// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_RUNTIME_CONTROLLER_H_
#define FLUTTER_RUNTIME_RUNTIME_CONTROLLER_H_

#include <memory>
#include <vector>

#include "flutter/common/task_runners.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/fml/macros.h"
#include "flutter/lib/ui/text/font_collection.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/pointer_data_packet.h"
#include "flutter/lib/ui/window/window.h"
#include "flutter/runtime/dart_vm.h"
#include "rapidjson/document.h"
#include "rapidjson/stringbuffer.h"

namespace blink {
class Scene;
class RuntimeDelegate;
class View;
class Window;

class RuntimeController final : public WindowClient {
 public:
  RuntimeController(RuntimeDelegate& client,
                    DartVM* vm,
                    fml::RefPtr<DartSnapshot> isolate_snapshot,
                    fml::RefPtr<DartSnapshot> shared_snapshot,
                    TaskRunners task_runners,
                    fml::WeakPtr<GrContext> resource_context,
                    fml::RefPtr<flow::SkiaUnrefQueue> unref_queue,
                    std::string advisory_script_uri,
                    std::string advisory_script_entrypoint);

  ~RuntimeController();

  std::unique_ptr<RuntimeController> Clone() const;

  bool SetViewportMetrics(const ViewportMetrics& metrics);

  bool SetLocales(const std::vector<std::string>& locale_data);

  bool SetUserSettingsData(const std::string& data);

  bool SetSemanticsEnabled(bool enabled);

  bool SetAccessibilityFeatures(int32_t flags);

  bool BeginFrame(fml::TimePoint frame_time);

  bool NotifyIdle(int64_t deadline);

  bool IsRootIsolateRunning() const;

  bool DispatchPlatformMessage(fml::RefPtr<PlatformMessage> message);

  bool DispatchPointerDataPacket(const PointerDataPacket& packet);

  bool DispatchSemanticsAction(int32_t id,
                               SemanticsAction action,
                               std::vector<uint8_t> args);

  Dart_Port GetMainPort();

  std::string GetIsolateName();

  bool HasLivePorts();

  tonic::DartErrorHandleType GetLastError();

  std::weak_ptr<DartIsolate> GetRootIsolate();

  std::pair<bool, uint32_t> GetRootIsolateReturnCode();

 private:
  struct Locale {
    Locale(std::string language_code_,
           std::string country_code_,
           std::string script_code_,
           std::string variant_code_)
        : language_code(language_code_),
          country_code(country_code_),
          script_code(script_code_),
          variant_code(variant_code_) {}

    std::string language_code;
    std::string country_code;
    std::string script_code;
    std::string variant_code;
  };

  struct WindowData {
    ViewportMetrics viewport_metrics;
    std::string language_code;
    std::string country_code;
    std::string script_code;
    std::string variant_code;
    std::vector<std::string> locale_data;
    std::string user_settings_data = "{}";
    bool semantics_enabled = false;
    bool assistive_technology_enabled = false;
    int32_t accessibility_feature_flags_ = 0;
  };

  RuntimeDelegate& client_;
  DartVM* const vm_;
  fml::RefPtr<DartSnapshot> isolate_snapshot_;
  fml::RefPtr<DartSnapshot> shared_snapshot_;
  TaskRunners task_runners_;
  fml::WeakPtr<GrContext> resource_context_;
  fml::RefPtr<flow::SkiaUnrefQueue> unref_queue_;
  std::string advisory_script_uri_;
  std::string advisory_script_entrypoint_;
  WindowData window_data_;
  std::weak_ptr<DartIsolate> root_isolate_;
  std::pair<bool, uint32_t> root_isolate_return_code_ = {false, 0};

  RuntimeController(RuntimeDelegate& client,
                    DartVM* vm,
                    fml::RefPtr<DartSnapshot> isolate_snapshot,
                    fml::RefPtr<DartSnapshot> shared_snapshot,
                    TaskRunners task_runners,
                    fml::WeakPtr<GrContext> resource_context,
                    fml::RefPtr<flow::SkiaUnrefQueue> unref_queue,
                    std::string advisory_script_uri,
                    std::string advisory_script_entrypoint,
                    WindowData data);

  Window* GetWindowIfAvailable();

  bool FlushRuntimeStateToIsolate();

  // |blink::WindowClient|
  std::string DefaultRouteName() override;

  // |blink::WindowClient|
  void ScheduleFrame() override;

  // |blink::WindowClient|
  void Render(Scene* scene) override;

  // |blink::WindowClient|
  void UpdateSemantics(SemanticsUpdate* update) override;

  // |blink::WindowClient|
  void HandlePlatformMessage(fml::RefPtr<PlatformMessage> message) override;

  // |blink::WindowClient|
  void SetIsolateDebugName(const std::string name) override;

  // |blink::WindowClient|
  FontCollection& GetFontCollection() override;

  FML_DISALLOW_COPY_AND_ASSIGN(RuntimeController);
};

}  // namespace blink

#endif  // FLUTTER_RUNTIME_RUNTIME_CONTROLLER_H_
