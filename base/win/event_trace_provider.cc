// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
#include "base/win/event_trace_provider.h"
#include <windows.h>
#include <cguid.h>

namespace base {
namespace win {

TRACE_GUID_REGISTRATION EtwTraceProvider::obligatory_guid_registration_ = {
  &GUID_NULL,
  NULL
};

EtwTraceProvider::EtwTraceProvider(const GUID& provider_name)
    : provider_name_(provider_name), registration_handle_(NULL),
      session_handle_(NULL), enable_flags_(0), enable_level_(0) {
}

EtwTraceProvider::EtwTraceProvider()
    : provider_name_(GUID_NULL), registration_handle_(NULL),
      session_handle_(NULL), enable_flags_(0), enable_level_(0) {
}

EtwTraceProvider::~EtwTraceProvider() {
  Unregister();
}

ULONG EtwTraceProvider::EnableEvents(void* buffer) {
  session_handle_ = ::GetTraceLoggerHandle(buffer);
  if (NULL == session_handle_) {
    return ::GetLastError();
  }

  enable_flags_ = ::GetTraceEnableFlags(session_handle_);
  enable_level_ = ::GetTraceEnableLevel(session_handle_);

  // Give subclasses a chance to digest the state change.
  OnEventsEnabled();

  return ERROR_SUCCESS;
}

ULONG EtwTraceProvider::DisableEvents() {
  // Give subclasses a chance to digest the state change.
  OnEventsDisabled();

  enable_level_ = 0;
  enable_flags_ = 0;
  session_handle_ = NULL;

  PostEventsDisabled();

  return ERROR_SUCCESS;
}

ULONG EtwTraceProvider::Callback(WMIDPREQUESTCODE request, void* buffer) {
  switch (request) {
    case WMI_ENABLE_EVENTS:
      return EnableEvents(buffer);
    case WMI_DISABLE_EVENTS:
      return DisableEvents();
    default:
      return ERROR_INVALID_PARAMETER;
  }
  // Not reached.
}

ULONG WINAPI EtwTraceProvider::ControlCallback(WMIDPREQUESTCODE request,
    void* context, ULONG *reserved, void* buffer) {
  EtwTraceProvider *provider = reinterpret_cast<EtwTraceProvider*>(context);

  return provider->Callback(request, buffer);
}

ULONG EtwTraceProvider::Register() {
  if (provider_name_ == GUID_NULL)
    return ERROR_INVALID_NAME;

  return ::RegisterTraceGuids(ControlCallback, this, &provider_name_,
      1, &obligatory_guid_registration_, NULL, NULL, &registration_handle_);
}

ULONG EtwTraceProvider::Unregister() {
  // If a session is active, notify subclasses that it's going away.
  if (session_handle_ != NULL)
    DisableEvents();

  ULONG ret = ::UnregisterTraceGuids(registration_handle_);

  registration_handle_ = NULL;

  return ret;
}

ULONG EtwTraceProvider::Log(const EtwEventClass& event_class,
    EtwEventType type, EtwEventLevel level, const char *message) {
  if (NULL == session_handle_ || enable_level_ < level)
    return ERROR_SUCCESS;  // No one listening.

  EtwMofEvent<1> event(event_class, type, level);

  event.fields[0].DataPtr = reinterpret_cast<ULONG64>(message);
  event.fields[0].Length = message ?
      static_cast<ULONG>(sizeof(message[0]) * (1 + strlen(message))) : 0;

  return ::TraceEvent(session_handle_, &event.header);
}

ULONG EtwTraceProvider::Log(const EtwEventClass& event_class,
    EtwEventType type, EtwEventLevel level, const wchar_t *message) {
  if (NULL == session_handle_ || enable_level_ < level)
    return ERROR_SUCCESS;  // No one listening.

  EtwMofEvent<1> event(event_class, type, level);

  event.fields[0].DataPtr = reinterpret_cast<ULONG64>(message);
  event.fields[0].Length = message ?
      static_cast<ULONG>(sizeof(message[0]) * (1 + wcslen(message))) : 0;

  return ::TraceEvent(session_handle_, &event.header);
}

ULONG EtwTraceProvider::Log(EVENT_TRACE_HEADER* event) {
  if (enable_level_ < event->Class.Level)
    return ERROR_SUCCESS;

  return ::TraceEvent(session_handle_, event);
}

}  // namespace win
}  // namespace base
