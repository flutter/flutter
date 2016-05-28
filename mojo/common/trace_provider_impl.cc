// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/common/trace_provider_impl.h"

#include <utility>

#include "base/callback.h"
#include "base/logging.h"
#include "base/memory/weak_ptr.h"
#include "base/time/time.h"
#include "base/trace_event/trace_config.h"
#include "base/trace_event/trace_event.h"
#include "mojo/public/cpp/application/application_impl.h"

namespace mojo {

TraceProviderImpl::TraceProviderImpl()
    : binding_(this), tracing_forced_(false), weak_factory_(this) {}

TraceProviderImpl::~TraceProviderImpl() {}

void TraceProviderImpl::Bind(InterfaceRequest<tracing::TraceProvider> request) {
  if (!binding_.is_bound()) {
    binding_.Bind(request.Pass());
  } else {
    LOG(ERROR) << "Cannot accept two connections to TraceProvider.";
  }
}

void TraceProviderImpl::StartTracing(
    const String& categories,
    mojo::InterfaceHandle<tracing::TraceRecorder> recorder) {
  DCHECK(!recorder_.get());
  recorder_ = tracing::TraceRecorderPtr::Create(std::move(recorder));
  tracing_forced_ = false;
  if (!base::trace_event::TraceLog::GetInstance()->IsEnabled()) {
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

void TraceProviderImpl::ForceEnableTracing() {
  base::trace_event::TraceLog::GetInstance()->SetEnabled(
      base::trace_event::TraceConfig("*", base::trace_event::RECORD_UNTIL_FULL),
      base::trace_event::TraceLog::RECORDING_MODE);
  tracing_forced_ = true;
  base::MessageLoop::current()->PostTask(
      FROM_HERE,
      base::Bind(&TraceProviderImpl::DelayedStop, weak_factory_.GetWeakPtr()));
}

void TraceProviderImpl::DelayedStop() {
  // We use this indirection to account for cases where the Initialize app
  // method (within which TraceProviderImpl is created) takes more than one
  // second to finish; thus we start the countdown only when the current thread
  // is unblocked.
  base::MessageLoop::current()->PostDelayedTask(
      FROM_HERE,
      base::Bind(&TraceProviderImpl::StopIfForced, weak_factory_.GetWeakPtr()),
      base::TimeDelta::FromSeconds(1));
}

void TraceProviderImpl::StopIfForced() {
  if (!tracing_forced_) {
    return;
  }
  base::trace_event::TraceLog::GetInstance()->SetDisabled();
  base::trace_event::TraceLog::GetInstance()->Flush(
      base::Callback<void(const scoped_refptr<base::RefCountedString>&,
                          bool)>());
}

void TraceProviderImpl::SendChunk(
    const scoped_refptr<base::RefCountedString>& events_str,
    bool has_more_events) {
  DCHECK(recorder_);
  // The string will be empty if an error eccured or there were no trace
  // events. Empty string is not a valid chunk to record so skip in this case.
  if (!events_str->data().empty()) {
    recorder_->Record(mojo::String(events_str->data()));
  }
  if (!has_more_events) {
    recorder_.reset();
  }
}

}  // namespace mojo
