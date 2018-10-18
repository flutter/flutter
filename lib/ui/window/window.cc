// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/window/window.h"

#include "flutter/lib/ui/compositing/scene.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/platform_message_response_dart.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_library_natives.h"
#include "third_party/tonic/dart_microtask_queue.h"
#include "third_party/tonic/logging/dart_invoke.h"
#include "third_party/tonic/typed_data/dart_byte_data.h"

using tonic::DartInvokeField;
using tonic::DartState;
using tonic::StdStringToDart;
using tonic::ToDart;

namespace blink {
namespace {

void DefaultRouteName(Dart_NativeArguments args) {
  std::string routeName =
      UIDartState::Current()->window()->client()->DefaultRouteName();
  Dart_SetReturnValue(args, StdStringToDart(routeName));
}

void ScheduleFrame(Dart_NativeArguments args) {
  UIDartState::Current()->window()->client()->ScheduleFrame();
}

void Render(Dart_NativeArguments args) {
  Dart_Handle exception = nullptr;
  Scene* scene =
      tonic::DartConverter<Scene*>::FromArguments(args, 1, exception);
  if (exception) {
    Dart_ThrowException(exception);
    return;
  }
  UIDartState::Current()->window()->client()->Render(scene);
}

void UpdateSemantics(Dart_NativeArguments args) {
  Dart_Handle exception = nullptr;
  SemanticsUpdate* update =
      tonic::DartConverter<SemanticsUpdate*>::FromArguments(args, 1, exception);
  if (exception) {
    Dart_ThrowException(exception);
    return;
  }
  UIDartState::Current()->window()->client()->UpdateSemantics(update);
}

void SetIsolateDebugName(Dart_NativeArguments args) {
  Dart_Handle exception = nullptr;
  const std::string name =
      tonic::DartConverter<std::string>::FromArguments(args, 1, exception);
  if (exception) {
    Dart_ThrowException(exception);
    return;
  }
  UIDartState::Current()->window()->client()->SetIsolateDebugName(name);
}

Dart_Handle SendPlatformMessage(Dart_Handle window,
                                const std::string& name,
                                Dart_Handle callback,
                                const tonic::DartByteData& data) {
  UIDartState* dart_state = UIDartState::Current();

  if (!dart_state->window()) {
    // Must release the TypedData buffer before allocating other Dart objects.
    data.Release();
    return ToDart("Platform messages can only be sent from the main isolate");
  }

  fml::RefPtr<PlatformMessageResponse> response;
  if (!Dart_IsNull(callback)) {
    response = fml::MakeRefCounted<PlatformMessageResponseDart>(
        tonic::DartPersistentValue(dart_state, callback),
        dart_state->GetTaskRunners().GetUITaskRunner());
  }
  if (Dart_IsNull(data.dart_handle())) {
    dart_state->window()->client()->HandlePlatformMessage(
        fml::MakeRefCounted<PlatformMessage>(name, response));
  } else {
    const uint8_t* buffer = static_cast<const uint8_t*>(data.data());

    dart_state->window()->client()->HandlePlatformMessage(
        fml::MakeRefCounted<PlatformMessage>(
            name, std::vector<uint8_t>(buffer, buffer + data.length_in_bytes()),
            response));
  }

  return Dart_Null();
}

void _SendPlatformMessage(Dart_NativeArguments args) {
  tonic::DartCallStatic(&SendPlatformMessage, args);
}

void RespondToPlatformMessage(Dart_Handle window,
                              int response_id,
                              const tonic::DartByteData& data) {
  if (Dart_IsNull(data.dart_handle())) {
    UIDartState::Current()->window()->CompletePlatformMessageEmptyResponse(
        response_id);
  } else {
    // TODO(engine): Avoid this copy.
    const uint8_t* buffer = static_cast<const uint8_t*>(data.data());
    UIDartState::Current()->window()->CompletePlatformMessageResponse(
        response_id,
        std::vector<uint8_t>(buffer, buffer + data.length_in_bytes()));
  }
}

void _RespondToPlatformMessage(Dart_NativeArguments args) {
  tonic::DartCallStatic(&RespondToPlatformMessage, args);
}

}  // namespace

Dart_Handle ToByteData(const std::vector<uint8_t>& buffer) {
  Dart_Handle data_handle =
      Dart_NewTypedData(Dart_TypedData_kByteData, buffer.size());
  if (Dart_IsError(data_handle))
    return data_handle;

  Dart_TypedData_Type type;
  void* data = nullptr;
  intptr_t num_bytes = 0;
  FML_CHECK(!Dart_IsError(
      Dart_TypedDataAcquireData(data_handle, &type, &data, &num_bytes)));

  memcpy(data, buffer.data(), num_bytes);
  Dart_TypedDataReleaseData(data_handle);
  return data_handle;
}

WindowClient::~WindowClient() {}

Window::Window(WindowClient* client) : client_(client) {}

Window::~Window() {}

void Window::DidCreateIsolate() {
  library_.Set(DartState::Current(), Dart_LookupLibrary(ToDart("dart:ui")));
}

void Window::UpdateWindowMetrics(const ViewportMetrics& metrics) {
  viewport_metrics_ = metrics;

  std::shared_ptr<tonic::DartState> dart_state = library_.dart_state().lock();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);
  DartInvokeField(library_.value(), "_updateWindowMetrics",
                  {
                      ToDart(metrics.device_pixel_ratio),
                      ToDart(metrics.physical_width),
                      ToDart(metrics.physical_height),
                      ToDart(metrics.physical_padding_top),
                      ToDart(metrics.physical_padding_right),
                      ToDart(metrics.physical_padding_bottom),
                      ToDart(metrics.physical_padding_left),
                      ToDart(metrics.physical_view_inset_top),
                      ToDart(metrics.physical_view_inset_right),
                      ToDart(metrics.physical_view_inset_bottom),
                      ToDart(metrics.physical_view_inset_left),
                  });
}

void Window::UpdateLocales(const std::vector<std::string>& locales) {
  std::shared_ptr<tonic::DartState> dart_state = library_.dart_state().lock();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);
  DartInvokeField(library_.value(), "_updateLocales",
                  {
                      tonic::ToDart<std::vector<std::string>>(locales),
                  });
}

void Window::UpdateUserSettingsData(const std::string& data) {
  std::shared_ptr<tonic::DartState> dart_state = library_.dart_state().lock();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);

  DartInvokeField(library_.value(), "_updateUserSettingsData",
                  {
                      StdStringToDart(data),
                  });
}

void Window::UpdateSemanticsEnabled(bool enabled) {
  std::shared_ptr<tonic::DartState> dart_state = library_.dart_state().lock();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);

  DartInvokeField(library_.value(), "_updateSemanticsEnabled",
                  {ToDart(enabled)});
}

void Window::UpdateAccessibilityFeatures(int32_t values) {
  std::shared_ptr<tonic::DartState> dart_state = library_.dart_state().lock();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);

  DartInvokeField(library_.value(), "_updateAccessibilityFeatures",
                  {ToDart(values)});
}

void Window::DispatchPlatformMessage(fml::RefPtr<PlatformMessage> message) {
  std::shared_ptr<tonic::DartState> dart_state = library_.dart_state().lock();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);
  Dart_Handle data_handle =
      (message->hasData()) ? ToByteData(message->data()) : Dart_Null();
  if (Dart_IsError(data_handle))
    return;

  int response_id = 0;
  if (auto response = message->response()) {
    response_id = next_response_id_++;
    pending_responses_[response_id] = response;
  }

  DartInvokeField(
      library_.value(), "_dispatchPlatformMessage",
      {ToDart(message->channel()), data_handle, ToDart(response_id)});
}

void Window::DispatchPointerDataPacket(const PointerDataPacket& packet) {
  std::shared_ptr<tonic::DartState> dart_state = library_.dart_state().lock();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);

  Dart_Handle data_handle = ToByteData(packet.data());
  if (Dart_IsError(data_handle))
    return;
  DartInvokeField(library_.value(), "_dispatchPointerDataPacket",
                  {data_handle});
}

void Window::DispatchSemanticsAction(int32_t id,
                                     SemanticsAction action,
                                     std::vector<uint8_t> args) {
  std::shared_ptr<tonic::DartState> dart_state = library_.dart_state().lock();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);

  Dart_Handle args_handle = (args.empty()) ? Dart_Null() : ToByteData(args);

  if (Dart_IsError(args_handle))
    return;

  DartInvokeField(
      library_.value(), "_dispatchSemanticsAction",
      {ToDart(id), ToDart(static_cast<int32_t>(action)), args_handle});
}

void Window::BeginFrame(fml::TimePoint frameTime) {
  std::shared_ptr<tonic::DartState> dart_state = library_.dart_state().lock();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);

  int64_t microseconds = (frameTime - fml::TimePoint()).ToMicroseconds();

  DartInvokeField(library_.value(), "_beginFrame",
                  {
                      Dart_NewInteger(microseconds),
                  });

  UIDartState::Current()->FlushMicrotasksNow();

  DartInvokeField(library_.value(), "_drawFrame", {});
}

void Window::CompletePlatformMessageEmptyResponse(int response_id) {
  if (!response_id)
    return;
  auto it = pending_responses_.find(response_id);
  if (it == pending_responses_.end())
    return;
  auto response = std::move(it->second);
  pending_responses_.erase(it);
  response->CompleteEmpty();
}

void Window::CompletePlatformMessageResponse(int response_id,
                                             std::vector<uint8_t> data) {
  if (!response_id)
    return;
  auto it = pending_responses_.find(response_id);
  if (it == pending_responses_.end())
    return;
  auto response = std::move(it->second);
  pending_responses_.erase(it);
  response->Complete(std::make_unique<fml::DataMapping>(std::move(data)));
}

void Window::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({
      {"Window_defaultRouteName", DefaultRouteName, 1, true},
      {"Window_scheduleFrame", ScheduleFrame, 1, true},
      {"Window_sendPlatformMessage", _SendPlatformMessage, 4, true},
      {"Window_respondToPlatformMessage", _RespondToPlatformMessage, 3, true},
      {"Window_render", Render, 2, true},
      {"Window_updateSemantics", UpdateSemantics, 2, true},
      {"Window_setIsolateDebugName", SetIsolateDebugName, 2, true},
  });
}

}  // namespace blink
