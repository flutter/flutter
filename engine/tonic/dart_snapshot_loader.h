// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_DART_SNAPSHOT_LOADER_H_
#define SKY_ENGINE_TONIC_DART_SNAPSHOT_LOADER_H_

#include <vector>

#include "base/callback_forward.h"
#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "dart/runtime/include/dart_api.h"
#include "mojo/common/data_pipe_drainer.h"
#include "sky/engine/wtf/OwnPtr.h"

namespace blink {
class DartState;

class DartSnapshotLoader : public mojo::common::DataPipeDrainer::Client {
 public:
  explicit DartSnapshotLoader(DartState* dart_state);
  ~DartSnapshotLoader();

  void LoadSnapshot(mojo::ScopedDataPipeConsumerHandle pipe,
                    const base::Closure& callback);

 private:
  // mojo::common::DataPipeDrainer::Client
  void OnDataAvailable(const void* data, size_t num_bytes) override;
  void OnDataComplete() override;

  base::WeakPtr<DartState> dart_state_;
  OwnPtr<mojo::common::DataPipeDrainer> drainer_;
  // TODO(abarth): Should we be using SharedBuffer to buffer the data?
  std::vector<uint8_t> buffer_;
  base::Closure callback_;

  DISALLOW_COPY_AND_ASSIGN(DartSnapshotLoader);
};

}  // namespace blink

#endif  // SKY_ENGINE_TONIC_DART_SNAPSHOT_LOADER_H_
