// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/window/platform_configuration.h"

#include <cstring>

#include "flutter/lib/ui/compositing/scene.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/platform_message_response_dart.h"
#include "flutter/lib/ui/window/platform_message_response_dart_port.h"
#include "flutter/lib/ui/window/viewport_metrics.h"
#include "flutter/lib/ui/window/window.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_library_natives.h"
#include "third_party/tonic/dart_microtask_queue.h"
#include "third_party/tonic/logging/dart_invoke.h"
#include "third_party/tonic/typed_data/dart_byte_data.h"

namespace flutter {
namespace {

// Keep this in sync with _kImplicitViewId in ../platform_dispatcher.dart.
constexpr int kImplicitViewId = 0;

Dart_Handle ToByteData(const fml::Mapping& buffer) {
  return tonic::DartByteData::Create(buffer.GetMapping(), buffer.GetSize());
}

}  // namespace

PlatformConfigurationClient::~PlatformConfigurationClient() {}

PlatformConfiguration::PlatformConfiguration(
    PlatformConfigurationClient* client)
    : client_(client) {}

PlatformConfiguration::~PlatformConfiguration() {}

void PlatformConfiguration::DidCreateIsolate() {
  Dart_Handle library = Dart_LookupLibrary(tonic::ToDart("dart:ui"));

  on_error_.Set(tonic::DartState::Current(),
                Dart_GetField(library, tonic::ToDart("_onError")));
  update_displays_.Set(
      tonic::DartState::Current(),
      Dart_GetField(library, tonic::ToDart("_updateDisplays")));
  update_locales_.Set(tonic::DartState::Current(),
                      Dart_GetField(library, tonic::ToDart("_updateLocales")));
  update_user_settings_data_.Set(
      tonic::DartState::Current(),
      Dart_GetField(library, tonic::ToDart("_updateUserSettingsData")));
  update_initial_lifecycle_state_.Set(
      tonic::DartState::Current(),
      Dart_GetField(library, tonic::ToDart("_updateInitialLifecycleState")));
  update_semantics_enabled_.Set(
      tonic::DartState::Current(),
      Dart_GetField(library, tonic::ToDart("_updateSemanticsEnabled")));
  update_accessibility_features_.Set(
      tonic::DartState::Current(),
      Dart_GetField(library, tonic::ToDart("_updateAccessibilityFeatures")));
  dispatch_platform_message_.Set(
      tonic::DartState::Current(),
      Dart_GetField(library, tonic::ToDart("_dispatchPlatformMessage")));
  dispatch_pointer_data_packet_.Set(
      tonic::DartState::Current(),
      Dart_GetField(library, tonic::ToDart("_dispatchPointerDataPacket")));
  dispatch_semantics_action_.Set(
      tonic::DartState::Current(),
      Dart_GetField(library, tonic::ToDart("_dispatchSemanticsAction")));
  begin_frame_.Set(tonic::DartState::Current(),
                   Dart_GetField(library, tonic::ToDart("_beginFrame")));
  draw_frame_.Set(tonic::DartState::Current(),
                  Dart_GetField(library, tonic::ToDart("_drawFrame")));
  report_timings_.Set(tonic::DartState::Current(),
                      Dart_GetField(library, tonic::ToDart("_reportTimings")));

  // TODO(loicsharma): This should only be created if the embedder enables the
  // implicit view.
  // See: https://github.com/flutter/flutter/issues/120306
  windows_.emplace(kImplicitViewId,
                   std::make_unique<Window>(
                       kImplicitViewId, ViewportMetrics{1.0, 0.0, 0.0, -1, 0}));
}

void PlatformConfiguration::UpdateDisplays(
    const std::vector<DisplayData>& displays) {
  std::vector<DisplayId> ids;
  std::vector<double> widths;
  std::vector<double> heights;
  std::vector<double> device_pixel_ratios;
  std::vector<double> refresh_rates;
  for (const auto& display : displays) {
    ids.push_back(display.id);
    widths.push_back(display.width);
    heights.push_back(display.height);
    device_pixel_ratios.push_back(display.pixel_ratio);
    refresh_rates.push_back(display.refresh_rate);
  }
  std::shared_ptr<tonic::DartState> dart_state =
      update_displays_.dart_state().lock();
  if (!dart_state) {
    return;
  }
  tonic::DartState::Scope scope(dart_state);
  tonic::CheckAndHandleError(tonic::DartInvoke(
      update_displays_.Get(),
      {
          tonic::ToDart<std::vector<DisplayId>>(ids),
          tonic::ToDart<std::vector<double>>(widths),
          tonic::ToDart<std::vector<double>>(heights),
          tonic::ToDart<std::vector<double>>(device_pixel_ratios),
          tonic::ToDart<std::vector<double>>(refresh_rates),
      }));
}

void PlatformConfiguration::UpdateLocales(
    const std::vector<std::string>& locales) {
  std::shared_ptr<tonic::DartState> dart_state =
      update_locales_.dart_state().lock();
  if (!dart_state) {
    return;
  }

  tonic::DartState::Scope scope(dart_state);
  tonic::CheckAndHandleError(
      tonic::DartInvoke(update_locales_.Get(),
                        {
                            tonic::ToDart<std::vector<std::string>>(locales),
                        }));
}

void PlatformConfiguration::UpdateUserSettingsData(const std::string& data) {
  std::shared_ptr<tonic::DartState> dart_state =
      update_user_settings_data_.dart_state().lock();
  if (!dart_state) {
    return;
  }
  tonic::DartState::Scope scope(dart_state);

  tonic::CheckAndHandleError(tonic::DartInvoke(update_user_settings_data_.Get(),
                                               {
                                                   tonic::StdStringToDart(data),
                                               }));
}

void PlatformConfiguration::UpdateInitialLifecycleState(
    const std::string& data) {
  std::shared_ptr<tonic::DartState> dart_state =
      update_initial_lifecycle_state_.dart_state().lock();
  if (!dart_state) {
    return;
  }
  tonic::DartState::Scope scope(dart_state);
  tonic::CheckAndHandleError(tonic::DartInvoke(
      update_initial_lifecycle_state_.Get(), {
                                                 tonic::StdStringToDart(data),
                                             }));
}

void PlatformConfiguration::UpdateSemanticsEnabled(bool enabled) {
  std::shared_ptr<tonic::DartState> dart_state =
      update_semantics_enabled_.dart_state().lock();
  if (!dart_state) {
    return;
  }
  tonic::DartState::Scope scope(dart_state);
  UIDartState::ThrowIfUIOperationsProhibited();

  tonic::CheckAndHandleError(tonic::DartInvoke(update_semantics_enabled_.Get(),
                                               {tonic::ToDart(enabled)}));
}

void PlatformConfiguration::UpdateAccessibilityFeatures(int32_t values) {
  std::shared_ptr<tonic::DartState> dart_state =
      update_accessibility_features_.dart_state().lock();
  if (!dart_state) {
    return;
  }
  tonic::DartState::Scope scope(dart_state);

  tonic::CheckAndHandleError(tonic::DartInvoke(
      update_accessibility_features_.Get(), {tonic::ToDart(values)}));
}

void PlatformConfiguration::DispatchPlatformMessage(
    std::unique_ptr<PlatformMessage> message) {
  std::shared_ptr<tonic::DartState> dart_state =
      dispatch_platform_message_.dart_state().lock();
  if (!dart_state) {
    FML_DLOG(WARNING)
        << "Dropping platform message for lack of DartState on channel: "
        << message->channel();
    return;
  }
  tonic::DartState::Scope scope(dart_state);
  Dart_Handle data_handle =
      (message->hasData()) ? ToByteData(message->data()) : Dart_Null();
  if (Dart_IsError(data_handle)) {
    FML_DLOG(WARNING)
        << "Dropping platform message because of a Dart error on channel: "
        << message->channel();
    return;
  }

  int response_id = 0;
  if (auto response = message->response()) {
    response_id = next_response_id_++;
    pending_responses_[response_id] = response;
  }

  tonic::CheckAndHandleError(
      tonic::DartInvoke(dispatch_platform_message_.Get(),
                        {tonic::ToDart(message->channel()), data_handle,
                         tonic::ToDart(response_id)}));
}

void PlatformConfiguration::DispatchPointerDataPacket(
    const PointerDataPacket& packet) {
  std::shared_ptr<tonic::DartState> dart_state =
      dispatch_pointer_data_packet_.dart_state().lock();
  if (!dart_state) {
    return;
  }
  tonic::DartState::Scope scope(dart_state);

  const std::vector<uint8_t>& buffer = packet.data();
  Dart_Handle data_handle =
      tonic::DartByteData::Create(buffer.data(), buffer.size());
  if (Dart_IsError(data_handle)) {
    return;
  }

  tonic::CheckAndHandleError(
      tonic::DartInvoke(dispatch_pointer_data_packet_.Get(), {data_handle}));
}

void PlatformConfiguration::DispatchSemanticsAction(int32_t node_id,
                                                    SemanticsAction action,
                                                    fml::MallocMapping args) {
  std::shared_ptr<tonic::DartState> dart_state =
      dispatch_semantics_action_.dart_state().lock();
  if (!dart_state) {
    return;
  }
  tonic::DartState::Scope scope(dart_state);

  Dart_Handle args_handle =
      (args.GetSize() <= 0) ? Dart_Null() : ToByteData(args);

  if (Dart_IsError(args_handle)) {
    return;
  }

  tonic::CheckAndHandleError(tonic::DartInvoke(
      dispatch_semantics_action_.Get(),
      {tonic::ToDart(node_id), tonic::ToDart(static_cast<int32_t>(action)),
       args_handle}));
}

void PlatformConfiguration::BeginFrame(fml::TimePoint frameTime,
                                       uint64_t frame_number) {
  std::shared_ptr<tonic::DartState> dart_state =
      begin_frame_.dart_state().lock();
  if (!dart_state) {
    return;
  }
  tonic::DartState::Scope scope(dart_state);

  int64_t microseconds = (frameTime - fml::TimePoint()).ToMicroseconds();

  tonic::CheckAndHandleError(
      tonic::DartInvoke(begin_frame_.Get(), {
                                                Dart_NewInteger(microseconds),
                                                Dart_NewInteger(frame_number),
                                            }));

  UIDartState::Current()->FlushMicrotasksNow();

  tonic::CheckAndHandleError(tonic::DartInvokeVoid(draw_frame_.Get()));
}

void PlatformConfiguration::ReportTimings(std::vector<int64_t> timings) {
  std::shared_ptr<tonic::DartState> dart_state =
      report_timings_.dart_state().lock();
  if (!dart_state) {
    return;
  }
  tonic::DartState::Scope scope(dart_state);

  Dart_Handle data_handle =
      Dart_NewTypedData(Dart_TypedData_kInt64, timings.size());

  Dart_TypedData_Type type;
  void* data = nullptr;
  intptr_t num_acquired = 0;
  FML_CHECK(!Dart_IsError(
      Dart_TypedDataAcquireData(data_handle, &type, &data, &num_acquired)));
  FML_DCHECK(num_acquired == static_cast<int>(timings.size()));

  memcpy(data, timings.data(), sizeof(int64_t) * timings.size());
  FML_CHECK(Dart_TypedDataReleaseData(data_handle));

  tonic::CheckAndHandleError(
      tonic::DartInvoke(report_timings_.Get(), {
                                                   data_handle,
                                               }));
}

Window* PlatformConfiguration::get_window(int window_id) {
  auto found = windows_.find(window_id);
  if (found != windows_.end()) {
    return found->second.get();
  } else {
    return nullptr;
  }
}

void PlatformConfiguration::CompletePlatformMessageEmptyResponse(
    int response_id) {
  if (!response_id) {
    return;
  }
  auto it = pending_responses_.find(response_id);
  if (it == pending_responses_.end()) {
    return;
  }
  auto response = std::move(it->second);
  pending_responses_.erase(it);
  response->CompleteEmpty();
}

void PlatformConfiguration::CompletePlatformMessageResponse(
    int response_id,
    std::vector<uint8_t> data) {
  if (!response_id) {
    return;
  }
  auto it = pending_responses_.find(response_id);
  if (it == pending_responses_.end()) {
    return;
  }
  auto response = std::move(it->second);
  pending_responses_.erase(it);
  response->Complete(std::make_unique<fml::DataMapping>(std::move(data)));
}

void PlatformConfigurationNativeApi::Render(Scene* scene) {
  UIDartState::ThrowIfUIOperationsProhibited();
  UIDartState::Current()->platform_configuration()->client()->Render(scene);
}

void PlatformConfigurationNativeApi::SetNeedsReportTimings(bool value) {
  UIDartState::ThrowIfUIOperationsProhibited();
  UIDartState::Current()
      ->platform_configuration()
      ->client()
      ->SetNeedsReportTimings(value);
}

namespace {
Dart_Handle HandlePlatformMessage(
    UIDartState* dart_state,
    const std::string& name,
    Dart_Handle data_handle,
    const fml::RefPtr<PlatformMessageResponse>& response) {
  if (Dart_IsNull(data_handle)) {
    return dart_state->HandlePlatformMessage(
        std::make_unique<PlatformMessage>(name, response));
  } else {
    tonic::DartByteData data(data_handle);
    const uint8_t* buffer = static_cast<const uint8_t*>(data.data());
    return dart_state->HandlePlatformMessage(std::make_unique<PlatformMessage>(
        name, fml::MallocMapping::Copy(buffer, data.length_in_bytes()),
        response));
  }
}
}  // namespace

Dart_Handle PlatformConfigurationNativeApi::SendPlatformMessage(
    const std::string& name,
    Dart_Handle callback,
    Dart_Handle data_handle) {
  UIDartState* dart_state = UIDartState::Current();

  if (!dart_state->platform_configuration()) {
    return tonic::ToDart(
        "SendPlatformMessage only works on the root isolate, see "
        "SendPortPlatformMessage.");
  }

  fml::RefPtr<PlatformMessageResponse> response;
  if (!Dart_IsNull(callback)) {
    response = fml::MakeRefCounted<PlatformMessageResponseDart>(
        tonic::DartPersistentValue(dart_state, callback),
        dart_state->GetTaskRunners().GetUITaskRunner(), name);
  }

  return HandlePlatformMessage(dart_state, name, data_handle, response);
}

Dart_Handle PlatformConfigurationNativeApi::SendPortPlatformMessage(
    const std::string& name,
    Dart_Handle identifier,
    Dart_Handle send_port,
    Dart_Handle data_handle) {
  // This can be executed on any isolate.
  UIDartState* dart_state = UIDartState::Current();

  int64_t c_send_port = tonic::DartConverter<int64_t>::FromDart(send_port);
  if (c_send_port == ILLEGAL_PORT) {
    return tonic::ToDart("Invalid port specified");
  }

  fml::RefPtr<PlatformMessageResponse> response =
      fml::MakeRefCounted<PlatformMessageResponseDartPort>(
          c_send_port, tonic::DartConverter<int64_t>::FromDart(identifier),
          name);

  return HandlePlatformMessage(dart_state, name, data_handle, response);
}

void PlatformConfigurationNativeApi::RespondToPlatformMessage(
    int response_id,
    const tonic::DartByteData& data) {
  if (Dart_IsNull(data.dart_handle())) {
    UIDartState::Current()
        ->platform_configuration()
        ->CompletePlatformMessageEmptyResponse(response_id);
  } else {
    // TODO(engine): Avoid this copy.
    const uint8_t* buffer = static_cast<const uint8_t*>(data.data());
    UIDartState::Current()
        ->platform_configuration()
        ->CompletePlatformMessageResponse(
            response_id,
            std::vector<uint8_t>(buffer, buffer + data.length_in_bytes()));
  }
}

void PlatformConfigurationNativeApi::SetIsolateDebugName(
    const std::string& name) {
  UIDartState::ThrowIfUIOperationsProhibited();
  UIDartState::Current()->SetDebugName(name);
}

Dart_PerformanceMode PlatformConfigurationNativeApi::current_performance_mode_ =
    Dart_PerformanceMode_Default;

Dart_PerformanceMode PlatformConfigurationNativeApi::GetDartPerformanceMode() {
  return current_performance_mode_;
}

int PlatformConfigurationNativeApi::RequestDartPerformanceMode(int mode) {
  UIDartState::ThrowIfUIOperationsProhibited();
  current_performance_mode_ = static_cast<Dart_PerformanceMode>(mode);
  return Dart_SetPerformanceMode(current_performance_mode_);
}

Dart_Handle PlatformConfigurationNativeApi::GetPersistentIsolateData() {
  UIDartState::ThrowIfUIOperationsProhibited();

  auto persistent_isolate_data = UIDartState::Current()
                                     ->platform_configuration()
                                     ->client()
                                     ->GetPersistentIsolateData();

  if (!persistent_isolate_data) {
    return Dart_Null();
  }

  return tonic::DartByteData::Create(persistent_isolate_data->GetMapping(),
                                     persistent_isolate_data->GetSize());
}

void PlatformConfigurationNativeApi::ScheduleFrame() {
  UIDartState::ThrowIfUIOperationsProhibited();
  UIDartState::Current()->platform_configuration()->client()->ScheduleFrame();
}

void PlatformConfigurationNativeApi::UpdateSemantics(SemanticsUpdate* update) {
  UIDartState::ThrowIfUIOperationsProhibited();
  UIDartState::Current()->platform_configuration()->client()->UpdateSemantics(
      update);
}

Dart_Handle PlatformConfigurationNativeApi::ComputePlatformResolvedLocale(
    Dart_Handle supportedLocalesHandle) {
  UIDartState::ThrowIfUIOperationsProhibited();
  std::vector<std::string> supportedLocales =
      tonic::DartConverter<std::vector<std::string>>::FromDart(
          supportedLocalesHandle);

  std::vector<std::string> results =
      *UIDartState::Current()
           ->platform_configuration()
           ->client()
           ->ComputePlatformResolvedLocale(supportedLocales);

  return tonic::DartConverter<std::vector<std::string>>::ToDart(results);
}

Dart_Handle PlatformConfigurationNativeApi::ImplicitViewEnabled() {
  UIDartState::ThrowIfUIOperationsProhibited();
  bool enabled = UIDartState::Current()
                     ->platform_configuration()
                     ->client()
                     ->ImplicitViewEnabled();

  return Dart_NewBoolean(enabled);
}

std::string PlatformConfigurationNativeApi::DefaultRouteName() {
  UIDartState::ThrowIfUIOperationsProhibited();
  return UIDartState::Current()
      ->platform_configuration()
      ->client()
      ->DefaultRouteName();
}

int64_t PlatformConfigurationNativeApi::GetRootIsolateToken() {
  UIDartState* dart_state = UIDartState::Current();
  FML_DCHECK(dart_state);
  return dart_state->GetRootIsolateToken();
}

void PlatformConfigurationNativeApi::RegisterBackgroundIsolate(
    int64_t root_isolate_token) {
  UIDartState* dart_state = UIDartState::Current();
  FML_DCHECK(dart_state && !dart_state->IsRootIsolate());
  auto platform_message_handler =
      (*static_cast<std::shared_ptr<PlatformMessageHandlerStorage>*>(
          Dart_CurrentIsolateGroupData()));
  FML_DCHECK(platform_message_handler);
  auto weak_platform_message_handler =
      platform_message_handler->GetPlatformMessageHandler(root_isolate_token);
  dart_state->SetPlatformMessageHandler(weak_platform_message_handler);
}

}  // namespace flutter
