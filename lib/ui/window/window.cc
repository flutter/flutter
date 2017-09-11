// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/window/window.h"

#include "flutter/lib/ui/compositing/scene.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/platform_message_response_dart.h"
#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_args.h"
#include "lib/tonic/dart_library_natives.h"
#include "lib/tonic/dart_microtask_queue.h"
#include "lib/tonic/logging/dart_invoke.h"
#include "lib/tonic/typed_data/dart_byte_data.h"

using tonic::DartInvokeField;
using tonic::DartState;
using tonic::StdStringToDart;
using tonic::ToDart;

namespace blink {
namespace {

Dart_Handle ToByteData(const std::vector<uint8_t>& buffer) {
  Dart_Handle data_handle =
      Dart_NewTypedData(Dart_TypedData_kByteData, buffer.size());
  if (Dart_IsError(data_handle))
    return data_handle;

  Dart_TypedData_Type type;
  void* data = nullptr;
  intptr_t num_bytes = 0;
  FXL_CHECK(!Dart_IsError(
      Dart_TypedDataAcquireData(data_handle, &type, &data, &num_bytes)));

  memcpy(data, buffer.data(), num_bytes);
  Dart_TypedDataReleaseData(data_handle);
  return data_handle;
}

void DefaultRouteName(Dart_NativeArguments args) {
  std::string routeName = UIDartState::Current()->window()->client()->DefaultRouteName();
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

void SendPlatformMessage(Dart_Handle window,
                         const std::string& name,
                         Dart_Handle callback,
                         const tonic::DartByteData& data) {
  UIDartState* dart_state = UIDartState::Current();

  fxl::RefPtr<PlatformMessageResponse> response;
  if (!Dart_IsNull(callback)) {
    response = fxl::MakeRefCounted<PlatformMessageResponseDart>(
        tonic::DartPersistentValue(dart_state, callback));
  }
  if (Dart_IsNull(data.dart_handle())) {
    UIDartState::Current()->window()->client()->HandlePlatformMessage(
        fxl::MakeRefCounted<PlatformMessage>(name, response));
  } else {
    const uint8_t* buffer = static_cast<const uint8_t*>(data.data());

    UIDartState::Current()->window()->client()->HandlePlatformMessage(
        fxl::MakeRefCounted<PlatformMessage>(
            name, std::vector<uint8_t>(buffer, buffer + data.length_in_bytes()),
            response));
  }
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

WindowClient::~WindowClient() {}

Window::Window(WindowClient* client) : client_(client) {}

Window::~Window() {}

void Window::DidCreateIsolate() {
  library_.Set(DartState::Current(), Dart_LookupLibrary(ToDart("dart:ui")));
}

void Window::UpdateWindowMetrics(const ViewportMetrics& metrics) {
  viewport_metrics_ = metrics;

  tonic::DartState* dart_state = library_.dart_state().get();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);
  DartInvokeField(
      library_.value(), "_updateWindowMetrics",
      {
          ToDart(metrics.device_pixel_ratio),
          ToDart(static_cast<double>(metrics.physical_width)),
          ToDart(static_cast<double>(metrics.physical_height)),
          ToDart(static_cast<double>(metrics.physical_padding_top)),
          ToDart(static_cast<double>(metrics.physical_padding_right)),
          ToDart(static_cast<double>(metrics.physical_padding_bottom)),
          ToDart(static_cast<double>(metrics.physical_padding_left)),
      });
}

void Window::UpdateLocale(const std::string& language_code,
                          const std::string& country_code) {
  tonic::DartState* dart_state = library_.dart_state().get();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);

  DartInvokeField(
      library_.value(), "_updateLocale",
      {
          StdStringToDart(language_code), StdStringToDart(country_code),
      });
}

void Window::UpdateSemanticsEnabled(bool enabled) {
  tonic::DartState* dart_state = library_.dart_state().get();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);

  DartInvokeField(library_.value(), "_updateSemanticsEnabled",
                  {ToDart(enabled)});
}

void Window::DispatchPlatformMessage(fxl::RefPtr<PlatformMessage> message) {
  tonic::DartState* dart_state = library_.dart_state().get();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);
  Dart_Handle data_handle = (message->hasData())
      ? ToByteData(message->data())
      : Dart_Null();
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
  tonic::DartState* dart_state = library_.dart_state().get();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);

  Dart_Handle data_handle = ToByteData(packet.data());
  if (Dart_IsError(data_handle))
    return;
  DartInvokeField(library_.value(), "_dispatchPointerDataPacket",
                  {data_handle});
}

void Window::DispatchSemanticsAction(int32_t id, SemanticsAction action) {
  tonic::DartState* dart_state = library_.dart_state().get();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);

  DartInvokeField(library_.value(), "_dispatchSemanticsAction",
                  {ToDart(id), ToDart(static_cast<int32_t>(action))});
}

void Window::BeginFrame(fxl::TimePoint frameTime) {
  tonic::DartState* dart_state = library_.dart_state().get();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);

  int64_t microseconds = (frameTime - fxl::TimePoint()).ToMicroseconds();

  DartInvokeField(library_.value(), "_beginFrame",
                  {
                      Dart_NewInteger(microseconds),
                  });

  tonic::DartMicrotaskQueue::GetForCurrentThread()->RunMicrotasks();

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
  response->Complete(std::move(data));
}

void Window::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({
      {"Window_defaultRouteName", DefaultRouteName, 1, true},
      {"Window_scheduleFrame", ScheduleFrame, 1, true},
      {"Window_sendPlatformMessage", _SendPlatformMessage, 4, true},
      {"Window_respondToPlatformMessage", _RespondToPlatformMessage, 3, true},
      {"Window_render", Render, 2, true},
      {"Window_updateSemantics", UpdateSemantics, 2, true},
  });
}

}  // namespace blink
