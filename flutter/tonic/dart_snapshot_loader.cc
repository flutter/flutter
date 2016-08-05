// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tonic/dart_snapshot_loader.h"

#include "base/callback.h"
#include "base/trace_event/trace_event.h"
#include "lib/tonic/scopes/dart_api_scope.h"
#include "lib/tonic/logging/dart_error.h"
#include "lib/tonic/scopes/dart_isolate_scope.h"
#include "flutter/tonic/dart_state.h"
#include "lib/tonic/converter/dart_converter.h"

using mojo::common::DataPipeDrainer;
using tonic::LogIfError;

namespace blink {

DartSnapshotLoader::DartSnapshotLoader(tonic::DartState* dart_state)
    : dart_state_(dart_state->GetWeakPtr()) {}

DartSnapshotLoader::~DartSnapshotLoader() {}

void DartSnapshotLoader::LoadSnapshot(mojo::ScopedDataPipeConsumerHandle pipe,
                                      const base::Closure& callback) {
  TRACE_EVENT_ASYNC_BEGIN0("flutter", "DartSnapshotLoader::LoadSnapshot", this);

  callback_ = callback;
  drainer_.reset(new DataPipeDrainer(this, pipe.Pass()));
}

void DartSnapshotLoader::OnDataAvailable(const void* data, size_t num_bytes) {
  const uint8_t* bytes = static_cast<const uint8_t*>(data);
  buffer_.insert(buffer_.end(), bytes, bytes + num_bytes);
}

void DartSnapshotLoader::OnDataComplete() {
  TRACE_EVENT_ASYNC_END0("flutter", "DartSnapshotLoader::LoadSnapshot", this);
  // TODO(abarth): Should we check dart_state_ for null?
  {
    tonic::DartIsolateScope scope(dart_state_->isolate());
    tonic::DartApiScope api_scope;

    LogIfError(Dart_LoadScriptFromSnapshot(buffer_.data(), buffer_.size()));
  }

  callback_.Run();
}

}  // namespace blink
