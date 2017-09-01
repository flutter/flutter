// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_RUNTIME_CONTROLLER_H_
#define FLUTTER_RUNTIME_RUNTIME_CONTROLLER_H_

#include <memory>

#include "flutter/flow/layers/layer_tree.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/pointer_data_packet.h"
#include "flutter/lib/ui/window/window.h"
#include "lib/ftl/macros.h"

namespace blink {
class DartController;
class DartLibraryProvider;
class Scene;
class RuntimeDelegate;
class View;
class Window;

class RuntimeController : public WindowClient, public IsolateClient {
 public:
  static std::unique_ptr<RuntimeController> Create(RuntimeDelegate* client);
  ~RuntimeController();

  void CreateDartController(const std::string& script_uri,
                            const uint8_t* isolate_snapshot_data,
                            const uint8_t* isolate_snapshot_instr,
                            const std::vector<uint8_t>& kernel_platform);
  DartController* dart_controller() const { return dart_controller_.get(); }

  void SetViewportMetrics(const ViewportMetrics& metrics);
  void SetLocale(const std::string& language_code,
                 const std::string& country_code);
  void SetSemanticsEnabled(bool enabled);

  void BeginFrame(ftl::TimePoint frame_time);
  void NotifyIdle(int64_t deadline);

  void DispatchPlatformMessage(ftl::RefPtr<PlatformMessage> message);
  void DispatchPointerDataPacket(const PointerDataPacket& packet);
  void DispatchSemanticsAction(int32_t id, SemanticsAction action);

  Dart_Port GetMainPort();
  std::string GetIsolateName();
  bool HasLivePorts();
  tonic::DartErrorHandleType GetLastError();

 private:
  explicit RuntimeController(RuntimeDelegate* client);

  Window* GetWindow();

  std::string DefaultRouteName() override;
  void ScheduleFrame() override;
  void Render(Scene* scene) override;
  void UpdateSemantics(SemanticsUpdate* update) override;
  void HandlePlatformMessage(ftl::RefPtr<PlatformMessage> message) override;

  void DidCreateSecondaryIsolate(Dart_Isolate isolate) override;

  RuntimeDelegate* client_;
  std::string language_code_;
  std::string country_code_;
  bool semantics_enabled_ = false;
  std::unique_ptr<DartController> dart_controller_;

  FTL_DISALLOW_COPY_AND_ASSIGN(RuntimeController);
};

}  // namespace blink

#endif  // FLUTTER_RUNTIME_RUNTIME_CONTROLLER_H_
