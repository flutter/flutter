// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/assets/zip_asset_bundle.h"

#include <utility>

namespace blink {

void ZipAssetBundle::GetAsStream(
    const mojo::String& asset_name,
    const mojo::Callback<void(mojo::ScopedDataPipeConsumerHandle)>& callback) {
  mojo::DataPipe pipe;
  callback.Run(std::move(pipe.consumer_handle));
  store_->GetAsStream(asset_name.get(), std::move(pipe.producer_handle));
}

ZipAssetBundle::ZipAssetBundle(
    mojo::InterfaceRequest<mojo::asset_bundle::AssetBundle> request,
    ftl::RefPtr<ZipAssetStore> store)
    : binding_(this, std::move(request)), store_(std::move(store)) {}

ZipAssetBundle::~ZipAssetBundle() {}

}  // namespace blink
