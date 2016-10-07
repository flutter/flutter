// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/window/window.h"

#include "flutter/lib/ui/compositing/scene.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_args.h"
#include "lib/tonic/dart_library_natives.h"
#include "lib/tonic/logging/dart_invoke.h"
#include "lib/tonic/typed_data/dart_byte_data.h"

using tonic::DartInvokeField;
using tonic::DartState;
using tonic::StdStringToDart;
using tonic::ToDart;

namespace blink {
namespace {

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

void SendPlatformMessage(Dart_Handle window,
                         const std::string& name,
                         Dart_Handle callback,
                         const tonic::DartByteData& data) {
  UIDartState* dart_state = UIDartState::Current();
  const char* buffer = static_cast<const char*>(data.data());
  auto message = ftl::MakeRefCounted<blink::PlatformMessage>(
      name, std::vector<char>(buffer, buffer + data.length_in_bytes()),
      tonic::DartPersistentValue(dart_state, callback));
  if (const auto& sink = dart_state->platform_message_sink()) {
    sink(std::move(message));
  } else {
    message->InvokeCallbackWithError();
  }
}

void _SendPlatformMessage(Dart_NativeArguments args) {
  tonic::DartCallStatic(&SendPlatformMessage, args);
}

}  // namespace

WindowClient::~WindowClient() {}

Window::Window(WindowClient* client) : client_(client) {}

Window::~Window() {}

void Window::DidCreateIsolate() {
  library_.Set(DartState::Current(), Dart_LookupLibrary(ToDart("dart:ui")));
}

void Window::UpdateWindowMetrics(const sky::ViewportMetricsPtr& metrics) {
  tonic::DartState* dart_state = library_.dart_state().get();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);
  DartInvokeField(
      library_.value(), "_updateWindowMetrics",
      {
          ToDart(metrics->device_pixel_ratio),
          ToDart(static_cast<double>(metrics->physical_width)),
          ToDart(static_cast<double>(metrics->physical_height)),
          ToDart(static_cast<double>(metrics->physical_padding_top)),
          ToDart(static_cast<double>(metrics->physical_padding_right)),
          ToDart(static_cast<double>(metrics->physical_padding_bottom)),
          ToDart(static_cast<double>(metrics->physical_padding_left)),
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

void Window::PushRoute(const std::string& route) {
  tonic::DartState* dart_state = library_.dart_state().get();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);

  DartInvokeField(library_.value(), "_pushRoute", {
                                                      StdStringToDart(route),
                                                  });
}

void Window::PopRoute() {
  tonic::DartState* dart_state = library_.dart_state().get();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);

  DartInvokeField(library_.value(), "_popRoute", {});
}

void Window::DispatchPointerDataPacket(const PointerDataPacket& packet) {
  tonic::DartState* dart_state = library_.dart_state().get();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);

  Dart_Handle data_handle =
      Dart_NewTypedData(Dart_TypedData_kByteData, packet.data().size());
  if (Dart_IsError(data_handle))
    return;

  Dart_TypedData_Type type;
  void* data = nullptr;
  intptr_t len = 0;
  if (Dart_IsError(Dart_TypedDataAcquireData(data_handle, &type, &data, &len)))
    return;

  memcpy(data, packet.data().data(), len);

  Dart_TypedDataReleaseData(data_handle);
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

void Window::BeginFrame(ftl::TimePoint frameTime) {
  tonic::DartState* dart_state = library_.dart_state().get();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);

  int64_t microseconds = (frameTime - ftl::TimePoint()).ToMicroseconds();

  DartInvokeField(library_.value(), "_beginFrame",
                  {
                      Dart_NewInteger(microseconds),
                  });
}

void Window::OnAppLifecycleStateChanged(sky::AppLifecycleState state) {
  tonic::DartState* dart_state = library_.dart_state().get();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);

  DartInvokeField(library_.value(), "_onAppLifecycleStateChanged",
                  {ToDart(static_cast<int>(state))});
}

void Window::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register(
      {{"Window_scheduleFrame", ScheduleFrame, 1, true},
       {"Window_render", Render, 2, true},
       {"Window_sendPlatformMessage", _SendPlatformMessage, 4, true}});
}

}  // namespace blink
