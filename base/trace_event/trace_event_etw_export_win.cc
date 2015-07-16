// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/trace_event_etw_export_win.h"

#include "base/command_line.h"
#include "base/logging.h"
#include "base/memory/singleton.h"
#include "base/strings/utf_string_conversions.h"
#include "base/trace_event/trace_event.h"
#include "base/trace_event/trace_event_impl.h"

// The GetProcAddress technique is borrowed from
// https://github.com/google/UIforETW/tree/master/ETWProviders
//
// EVNTAPI is used in evntprov.h which is included by chrome_events_win.h.
// We define EVNTAPI without the DECLSPEC_IMPORT specifier so that we can
// implement these functions locally instead of using the import library, and
// can therefore still run on Windows XP.
#define EVNTAPI __stdcall
// Include the event register/write/unregister macros compiled from the manifest
// file. Note that this includes evntprov.h which requires a Vista+ Windows SDK.
//
// In SHARED_INTERMEDIATE_DIR.
#include "base/trace_event/etw_manifest/chrome_events_win.h"  // NOLINT

namespace {
// Typedefs for use with GetProcAddress
typedef ULONG(__stdcall* tEventRegister)(LPCGUID ProviderId,
                                         PENABLECALLBACK EnableCallback,
                                         PVOID CallbackContext,
                                         PREGHANDLE RegHandle);
typedef ULONG(__stdcall* tEventWrite)(REGHANDLE RegHandle,
                                      PCEVENT_DESCRIPTOR EventDescriptor,
                                      ULONG UserDataCount,
                                      PEVENT_DATA_DESCRIPTOR UserData);
typedef ULONG(__stdcall* tEventUnregister)(REGHANDLE RegHandle);

tEventRegister EventRegisterProc = nullptr;
tEventWrite EventWriteProc = nullptr;
tEventUnregister EventUnregisterProc = nullptr;
}  // namespace

// Redirector function for EventRegister. Called by macros in
// chrome_events_win.h
ULONG EVNTAPI EventRegister(LPCGUID ProviderId,
                            PENABLECALLBACK EnableCallback,
                            PVOID CallbackContext,
                            PREGHANDLE RegHandle) {
  if (EventRegisterProc)
    return EventRegisterProc(ProviderId, EnableCallback, CallbackContext,
                             RegHandle);
  *RegHandle = 0;
  return 0;
}

// Redirector function for EventWrite. Called by macros in
// chrome_events_win.h
ULONG EVNTAPI EventWrite(REGHANDLE RegHandle,
                         PCEVENT_DESCRIPTOR EventDescriptor,
                         ULONG UserDataCount,
                         PEVENT_DATA_DESCRIPTOR UserData) {
  if (EventWriteProc)
    return EventWriteProc(RegHandle, EventDescriptor, UserDataCount, UserData);
  return 0;
}

// Redirector function for EventUnregister. Called by macros in
// chrome_events_win.h
ULONG EVNTAPI EventUnregister(REGHANDLE RegHandle) {
  if (EventUnregisterProc)
    return EventUnregisterProc(RegHandle);
  return 0;
}

namespace base {
namespace trace_event {

TraceEventETWExport::TraceEventETWExport() : ETWExportEnabled_(false) {
  // Find Advapi32.dll. This should always succeed.
  HMODULE AdvapiDLL = ::LoadLibraryW(L"Advapi32.dll");
  if (AdvapiDLL) {
    // Try to find the ETW functions. This will fail on XP.
    EventRegisterProc = reinterpret_cast<tEventRegister>(
        ::GetProcAddress(AdvapiDLL, "EventRegister"));
    EventWriteProc = reinterpret_cast<tEventWrite>(
        ::GetProcAddress(AdvapiDLL, "EventWrite"));
    EventUnregisterProc = reinterpret_cast<tEventUnregister>(
        ::GetProcAddress(AdvapiDLL, "EventUnregister"));

    // Register the ETW provider. If registration fails then the event logging
    // calls will fail (on XP this call will do nothing).
    EventRegisterChrome();
  }
}

TraceEventETWExport::~TraceEventETWExport() {
  EventUnregisterChrome();
}

// static
TraceEventETWExport* TraceEventETWExport::GetInstance() {
  return Singleton<TraceEventETWExport,
                   StaticMemorySingletonTraits<TraceEventETWExport>>::get();
}

// static
void TraceEventETWExport::EnableETWExport() {
  if (GetInstance())
    GetInstance()->ETWExportEnabled_ = true;
}

// static
void TraceEventETWExport::DisableETWExport() {
  if (GetInstance())
    GetInstance()->ETWExportEnabled_ = false;
}

// static
void TraceEventETWExport::AddEvent(
    char phase,
    const unsigned char* category_group_enabled,
    const char* name,
    unsigned long long id,
    int num_args,
    const char** arg_names,
    const unsigned char* arg_types,
    const unsigned long long* arg_values,
    const scoped_refptr<ConvertableToTraceFormat>* convertable_values) {
  // We bail early in case exporting is disabled or no consumer is listening.
  if (!GetInstance() || !GetInstance()->ETWExportEnabled_ ||
      !EventEnabledChromeEvent())
    return;

  const char* phase_string = nullptr;
  // Space to store the phase identifier and null-terminator, when needed.
  char phase_buffer[2];
  switch (phase) {
    case TRACE_EVENT_PHASE_BEGIN:
      phase_string = "Begin";
      break;
    case TRACE_EVENT_PHASE_END:
      phase_string = "End";
      break;
    case TRACE_EVENT_PHASE_COMPLETE:
      phase_string = "Complete";
      break;
    case TRACE_EVENT_PHASE_INSTANT:
      phase_string = "Instant";
      break;
    case TRACE_EVENT_PHASE_ASYNC_BEGIN:
      phase_string = "Async Begin";
      break;
    case TRACE_EVENT_PHASE_ASYNC_STEP_INTO:
      phase_string = "Async Step Into";
      break;
    case TRACE_EVENT_PHASE_ASYNC_STEP_PAST:
      phase_string = "Async Step Past";
      break;
    case TRACE_EVENT_PHASE_ASYNC_END:
      phase_string = "Async End";
      break;
    case TRACE_EVENT_PHASE_NESTABLE_ASYNC_BEGIN:
      phase_string = "Nestable Async Begin";
      break;
    case TRACE_EVENT_PHASE_NESTABLE_ASYNC_END:
      phase_string = "Nestable Async End";
      break;
    case TRACE_EVENT_PHASE_NESTABLE_ASYNC_INSTANT:
      phase_string = "Nestable Async Instant";
      break;
    case TRACE_EVENT_PHASE_FLOW_BEGIN:
      phase_string = "Phase Flow Begin";
      break;
    case TRACE_EVENT_PHASE_FLOW_STEP:
      phase_string = "Phase Flow Step";
      break;
    case TRACE_EVENT_PHASE_FLOW_END:
      phase_string = "Phase Flow End";
      break;
    case TRACE_EVENT_PHASE_METADATA:
      phase_string = "Phase Metadata";
      break;
    case TRACE_EVENT_PHASE_COUNTER:
      phase_string = "Phase Counter";
      break;
    case TRACE_EVENT_PHASE_SAMPLE:
      phase_string = "Phase Sample";
      break;
    case TRACE_EVENT_PHASE_CREATE_OBJECT:
      phase_string = "Phase Create Object";
      break;
    case TRACE_EVENT_PHASE_SNAPSHOT_OBJECT:
      phase_string = "Phase Snapshot Object";
      break;
    case TRACE_EVENT_PHASE_DELETE_OBJECT:
      phase_string = "Phase Delete Object";
      break;
    default:
      phase_buffer[0] = phase;
      phase_buffer[1] = 0;
      phase_string = phase_buffer;
      break;
  }

  std::string arg_values_string[3];
  for (int i = 0; i < num_args; i++) {
    if (arg_types[i] == TRACE_VALUE_TYPE_CONVERTABLE) {
      // Temporarily do nothing here. This function consumes 1/3 to 1/2 of
      // *total* process CPU time when ETW tracing, and many of the strings
      // created exceed WPA's 4094 byte limit and are shown as:
      // "Unable to parse data". See crbug.com/488257
      //convertable_values[i]->AppendAsTraceFormat(arg_values_string + i);
    } else {
      TraceEvent::TraceValue trace_event;
      trace_event.as_uint = arg_values[i];
      TraceEvent::AppendValueAsJSON(arg_types[i], trace_event,
                                    arg_values_string + i);
    }
  }

  EventWriteChromeEvent(
      name, phase_string, num_args > 0 ? arg_names[0] : "",
      arg_values_string[0].c_str(), num_args > 1 ? arg_names[1] : "",
      arg_values_string[1].c_str(), num_args > 2 ? arg_names[2] : "",
      arg_values_string[2].c_str());
}

// static
void TraceEventETWExport::AddCustomEvent(const char* name,
                                         char const* phase,
                                         const char* arg_name_1,
                                         const char* arg_value_1,
                                         const char* arg_name_2,
                                         const char* arg_value_2,
                                         const char* arg_name_3,
                                         const char* arg_value_3) {
  if (!GetInstance() || !GetInstance()->ETWExportEnabled_ ||
      !EventEnabledChromeEvent())
    return;

  EventWriteChromeEvent(name, phase, arg_name_1, arg_value_1, arg_name_2,
                        arg_value_2, arg_name_3, arg_value_3);
}

void TraceEventETWExport::Resurrect() {
  StaticMemorySingletonTraits<TraceEventETWExport>::Resurrect();
}

}  // namespace trace_event
}  // namespace base
