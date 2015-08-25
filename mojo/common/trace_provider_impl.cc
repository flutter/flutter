// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/common/trace_provider_impl.h"

#include "base/logging.h"
#include "base/trace_event/trace_config.h"
#include "base/trace_event/trace_event.h"
#include "mojo/public/cpp/application/application_connection.h"
#include "mojo/public/cpp/application/application_impl.h"

namespace mojo {

TraceProviderImpl::TraceProviderImpl(
    InterfaceRequest<tracing::TraceProvider> request)
    : tracing_already_started_(false), binding_(this, request.Pass()) {
}

TraceProviderImpl::~TraceProviderImpl() {
}

void TraceProviderImpl::StartTracing(const String& categories,
                                     tracing::TraceRecorderPtr collector) {
  DCHECK(!recorder_.get());
  recorder_ = collector.Pass();
  if (!tracing_already_started_) {
    std::string categories_str = categories.To<std::string>();
    base::trace_event::TraceLog::GetInstance()->SetEnabled(
        base::trace_event::TraceConfig(categories_str,
                                       base::trace_event::RECORD_UNTIL_FULL),
        base::trace_event::TraceLog::RECORDING_MODE);
  }
}

void TraceProviderImpl::StopTracing() {
  DCHECK(recorder_);
  base::trace_event::TraceLog::GetInstance()->SetDisabled();

  base::trace_event::TraceLog::GetInstance()->Flush(
      base::Bind(&TraceProviderImpl::SendChunk, base::Unretained(this)));
}

void TraceProviderImpl::SendChunk(
    const scoped_refptr<base::RefCountedString>& events_str,
    bool has_more_events) {
  DCHECK(recorder_);
  recorder_->Record(mojo::String(events_str->data()));
  if (!has_more_events) {
    recorder_.reset();
  }
}

}  // namespace mojo
