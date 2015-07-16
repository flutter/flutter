// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Implementation of a Windows event trace controller class.
#include "base/win/event_trace_controller.h"
#include "base/logging.h"

namespace base {
namespace win {

EtwTraceProperties::EtwTraceProperties() {
  memset(buffer_, 0, sizeof(buffer_));
  EVENT_TRACE_PROPERTIES* prop = get();

  prop->Wnode.BufferSize = sizeof(buffer_);
  prop->Wnode.Flags = WNODE_FLAG_TRACED_GUID;
  prop->LoggerNameOffset = sizeof(EVENT_TRACE_PROPERTIES);
  prop->LogFileNameOffset = sizeof(EVENT_TRACE_PROPERTIES) +
                            sizeof(wchar_t) * kMaxStringLen;
}

HRESULT EtwTraceProperties::SetLoggerName(const wchar_t* logger_name) {
  size_t len = wcslen(logger_name) + 1;
  if (kMaxStringLen < len)
    return E_INVALIDARG;

  memcpy(buffer_ + get()->LoggerNameOffset,
         logger_name,
         sizeof(wchar_t) * len);
  return S_OK;
}

HRESULT EtwTraceProperties::SetLoggerFileName(const wchar_t* logger_file_name) {
  size_t len = wcslen(logger_file_name) + 1;
  if (kMaxStringLen < len)
    return E_INVALIDARG;

  memcpy(buffer_ + get()->LogFileNameOffset,
         logger_file_name,
         sizeof(wchar_t) * len);
  return S_OK;
}

EtwTraceController::EtwTraceController() : session_(NULL) {
}

EtwTraceController::~EtwTraceController() {
  Stop(NULL);
}

HRESULT EtwTraceController::Start(const wchar_t* session_name,
    EtwTraceProperties* prop) {
  DCHECK(NULL == session_ && session_name_.empty());
  EtwTraceProperties ignore;
  if (prop == NULL)
    prop = &ignore;

  HRESULT hr = Start(session_name, prop, &session_);
  if (SUCCEEDED(hr))
    session_name_ = session_name;

  return hr;
}

HRESULT EtwTraceController::StartFileSession(const wchar_t* session_name,
    const wchar_t* logfile_path, bool realtime) {
  DCHECK(NULL == session_ && session_name_.empty());

  EtwTraceProperties prop;
  prop.SetLoggerFileName(logfile_path);
  EVENT_TRACE_PROPERTIES& p = *prop.get();
  p.Wnode.ClientContext = 1;  // QPC timer accuracy.
  p.LogFileMode = EVENT_TRACE_FILE_MODE_SEQUENTIAL;  // Sequential log.
  if (realtime)
    p.LogFileMode |= EVENT_TRACE_REAL_TIME_MODE;

  p.MaximumFileSize = 100;  // 100M file size.
  p.FlushTimer = 30;  // 30 seconds flush lag.
  return Start(session_name, &prop);
}

HRESULT EtwTraceController::StartRealtimeSession(const wchar_t* session_name,
    size_t buffer_size) {
  DCHECK(NULL == session_ && session_name_.empty());
  EtwTraceProperties prop;
  EVENT_TRACE_PROPERTIES& p = *prop.get();
  p.LogFileMode = EVENT_TRACE_REAL_TIME_MODE | EVENT_TRACE_USE_PAGED_MEMORY;
  p.FlushTimer = 1;  // flush every second.
  p.BufferSize = 16;  // 16 K buffers.
  p.LogFileNameOffset = 0;
  return Start(session_name, &prop);
}

HRESULT EtwTraceController::EnableProvider(REFGUID provider, UCHAR level,
    ULONG flags) {
  ULONG error = ::EnableTrace(TRUE, flags, level, &provider, session_);
  return HRESULT_FROM_WIN32(error);
}

HRESULT EtwTraceController::DisableProvider(REFGUID provider) {
  ULONG error = ::EnableTrace(FALSE, 0, 0, &provider, session_);
  return HRESULT_FROM_WIN32(error);
}

HRESULT EtwTraceController::Stop(EtwTraceProperties* properties) {
  EtwTraceProperties ignore;
  if (properties == NULL)
    properties = &ignore;

  ULONG error = ::ControlTrace(session_, NULL, properties->get(),
    EVENT_TRACE_CONTROL_STOP);
  if (ERROR_SUCCESS != error)
    return HRESULT_FROM_WIN32(error);

  session_ = NULL;
  session_name_.clear();
  return S_OK;
}

HRESULT EtwTraceController::Flush(EtwTraceProperties* properties) {
  EtwTraceProperties ignore;
  if (properties == NULL)
    properties = &ignore;

  ULONG error = ::ControlTrace(session_, NULL, properties->get(),
                               EVENT_TRACE_CONTROL_FLUSH);
  if (ERROR_SUCCESS != error)
    return HRESULT_FROM_WIN32(error);

  return S_OK;
}

HRESULT EtwTraceController::Start(const wchar_t* session_name,
    EtwTraceProperties* properties, TRACEHANDLE* session_handle) {
  DCHECK(properties != NULL);
  ULONG err = ::StartTrace(session_handle, session_name, properties->get());
  return HRESULT_FROM_WIN32(err);
}

HRESULT EtwTraceController::Query(const wchar_t* session_name,
    EtwTraceProperties* properties) {
  ULONG err = ::ControlTrace(NULL, session_name, properties->get(),
                             EVENT_TRACE_CONTROL_QUERY);
  return HRESULT_FROM_WIN32(err);
};

HRESULT EtwTraceController::Update(const wchar_t* session_name,
    EtwTraceProperties* properties) {
  DCHECK(properties != NULL);
  ULONG err = ::ControlTrace(NULL, session_name, properties->get(),
                             EVENT_TRACE_CONTROL_UPDATE);
  return HRESULT_FROM_WIN32(err);
}

HRESULT EtwTraceController::Stop(const wchar_t* session_name,
    EtwTraceProperties* properties) {
  DCHECK(properties != NULL);
  ULONG err = ::ControlTrace(NULL, session_name, properties->get(),
                             EVENT_TRACE_CONTROL_STOP);
  return HRESULT_FROM_WIN32(err);
}

HRESULT EtwTraceController::Flush(const wchar_t* session_name,
    EtwTraceProperties* properties) {
  DCHECK(properties != NULL);
  ULONG err = ::ControlTrace(NULL, session_name, properties->get(),
                             EVENT_TRACE_CONTROL_FLUSH);
  return HRESULT_FROM_WIN32(err);
}

}  // namespace win
}  // namespace base
