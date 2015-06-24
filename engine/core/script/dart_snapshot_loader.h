// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_SCRIPT_DART_SNAPSHOT_LOADER_H_
#define SKY_ENGINE_CORE_SCRIPT_DART_SNAPSHOT_LOADER_H_

#include "base/callback_forward.h"
#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "dart/runtime/include/dart_api.h"
#include "mojo/common/data_pipe_drainer.h"
#include "mojo/services/network/public/interfaces/url_loader.mojom.h"
#include "sky/engine/platform/fetcher/MojoFetcher.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

class DartState;
class KURL;

class DartSnapshotLoader : public MojoFetcher::Client,
                           public mojo::common::DataPipeDrainer::Client {
 public:
  explicit DartSnapshotLoader(DartState* dart_state);
  ~DartSnapshotLoader();

  void LoadSnapshot(const KURL& url, mojo::URLResponsePtr response,
                    const base::Closure& callback);

  DartState* dart_state() const { return dart_state_.get(); }

 private:
  // MojoFetcher::Client
  void OnReceivedResponse(mojo::URLResponsePtr response) override;

  // mojo::common::DataPipeDrainer::Client
  void OnDataAvailable(const void* data, size_t num_bytes) override;
  void OnDataComplete() override;

  base::WeakPtr<DartState> dart_state_;
  // TODO(abarth): Should we be using SharedBuffer to buffer the data?
  Vector<uint8_t> buffer_;
  OwnPtr<MojoFetcher> fetcher_;
  OwnPtr<mojo::common::DataPipeDrainer> drainer_;
  base::Closure callback_;

  DISALLOW_COPY_AND_ASSIGN(DartSnapshotLoader);
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_SCRIPT_DART_SNAPSHOT_LOADER_H_
